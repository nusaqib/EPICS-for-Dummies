# Scaling and Availability

EPICS scales over five orders of magnitude, from a 20-PV test stand to facilities well past a million PVs. This page is about what actually changes on the way up, and what redundancy is and isn't available.

## What EPICS gives you for free

**No central point of failure in Tiers 1 and 2.** There is no broker, no name server, no master. Two hundred IOCs form one namespace by broadcast. Kill one and the other 199 are unaffected; its clients show disconnected channels and reconnect automatically when it returns.

This is unusual and valuable. It means a facility can restart one subsystem's IOC during operations, upgrade one rack on a Tuesday, and add a new subsystem without touching anything existing. Most of EPICS's 35-year longevity traces back to this property.

**What is *not* free:** every service in Tier 3 — archiver, alarm server, ChannelFinder, save/restore, Olog — is a normal client, and each is a single point of failure *for its own function*. That's a much better failure mode than a central bus (the machine keeps running; you lose history or alarm annunciation), but it is not nothing, and it means the services are where your availability engineering goes.

## What breaks as you grow

### At ~10 IOCs / 10 000 PVs — nothing

A flat network, no address lists, one archiver, one alarm server, IOCs started by hand or `systemd`. Everything works. This is a test stand or a small beamline, and none of the machinery below is needed.

### At ~50 IOCs / 100 000 PVs — the first real problems

| Problem | Symptom | Response |
| --- | --- | --- |
| Nobody knows which IOC serves what | Half-hour investigations for "where does this PV come from?" | [ChannelFinder + recsync](../toolbox/directory-services.md) |
| IOCs restarted by hand, occasionally not restarted at all | Silent gaps in coverage | [procServ](../toolbox/deployment-and-operations.md#procserv) or systemd, plus [iocStats](../toolbox/soft-support-modules.md#iocstats--deviocstats) monitoring |
| Naming drift | Four spellings of "power supply" | Enforced [convention](naming-conventions.md) + CI validation |
| Deployment is per-IOC artisanal work | Nobody can reproduce an IOC from source | Consistent build/deploy tooling: [containers](../toolbox/deployment-and-operations.md#epics-containers), [e3](../toolbox/deployment-and-operations.md#e3-ess-epics-environment), or a site standard |
| Archive is growing faster than expected | Disk alarms | `MDEL`/`ADEL` audit, archiving policy per PV class |

### At ~300 IOCs / 400 000 PVs — the facility scale

This is the [example facility](../example-facility/index.md), and this is where architecture stops being optional.

**Monitor fan-out becomes the dominant load.** Fifty consoles each monitoring 10 000 PVs at 10 Hz asks 5 million updates/second of your IOCs. [Gateways](../toolbox/gateways.md) collapse that: one monitor per PV at the IOC, fan-out at the gateway. Without them, IOC CPU goes into serving screens instead of controlling hardware.

**Search traffic becomes visible.** A console opening a large synoptic emits thousands of UDP searches. Multiply by shift change, when everyone opens their screens at once. Base's backoff handles it; small broadcast domains and gateways handle it better.

**Archiver becomes a distributed system.** One process cannot ingest 400 000 PVs. The [Archiver Appliance](../toolbox/archiving.md#epics-archiver-appliance) is designed for this — multiple appliances sharing a cluster, each owning a subset of PVs, with a common retrieval front end. Sizing arithmetic: [archiving plan](../example-facility/archiving-plan.md).

**Alarm floods become the alarm system's main design problem.** A beam dump can set thousands of records into `MAJOR` within a second. If your alarm display shows all of them, it shows nothing useful. Hierarchy, latching, and delays are what make it usable — see [alarm plan](../example-facility/alarm-plan.md).

**Deployment must be automated.** Three hundred IOCs cannot be hand-managed. Whichever tooling you choose, the requirement is: rebuild any IOC from version control, deploy without a human editing files on a server, and know what version is running where.

**Time synchronisation becomes correctness, not hygiene.** Timestamps come from IOCs. Correlating a BPM reading with the RF trip that caused it requires clocks agreeing to better than the phenomenon's timescale. NTP gives milliseconds; an [event system](../toolbox/timing-systems.md) gives you beam-synchronous timestamps and is what diagnostics actually need.

### At >1 000 000 PVs — the frontier

A handful of facilities. Everything above, plus: multiple archiver clusters, hierarchical gateways, careful subnet design, and an operations team with dedicated controls infrastructure engineers. If you're here you're not reading this guide.

## IOC granularity: the recurring argument

| Approach | Pros | Cons |
| --- | --- | --- |
| **One IOC per device** | Tiny failure domain; restart affects one device; clear ownership; trivial to test | Hundreds of processes to deploy and monitor; cross-device logic needs CA links |
| **One IOC per subsystem** | Fewer processes; local DB links for related logic; one place to look | A crash takes out the subsystem; restarts are disruptive; database gets large and lock sets get wide |
| **One IOC per crate/rack** | Matches physical reality and maintenance boundaries; a rack shutdown maps to one IOC | Mixed responsibilities in one process |

Most modern facilities lean toward the fine-grained end, because [container-based deployment](../toolbox/deployment-and-operations.md#epics-containers) has made process count nearly free while failure-domain size never got cheaper. The countervailing force is genuine: records that must interlock reliably belong in one IOC, where DB links are synchronous and lock sets guarantee consistency. A cross-IOC CA link is asynchronous, can be disconnected, and gives you no ordering guarantee.

Rule of thumb: **draw IOC boundaries where you are willing to lose everything inside them at once.**

## Redundancy: what's actually possible

Honest assessment, because this is often overstated.

### IOCs

**There is no general IOC failover in EPICS.** Two IOCs serving the same PV name is a *bug*, not a redundancy strategy — clients bind to whichever answers first, and different clients get different servers.

What exists:

- **Redundant IOC support** existed for VxWorks in the EPICS 3.14 era (from DESY). It is not the modern mainstream answer and should not be planned around without checking its current state.
- **Fast restart** is the practical strategy: [procServ](../toolbox/deployment-and-operations.md#procserv) or Kubernetes restarts a dead IOC in seconds, [autosave](../toolbox/soft-support-modules.md#autosave) restores its settings, and clients reconnect automatically. Outage measured in seconds, and no split-brain risk. This is what almost everyone does.
- **Redundancy in the hardware layer**, below EPICS — dual-redundant PLCs, hardware watchdogs, latching outputs that hold state when their controller dies. This is where genuine high availability lives, and it's a hardware design decision.

The key insight: an IOC dying rarely stops the machine, because the hardware keeps doing what it was last told. You lose *observation and control*, not the process. That reframes the requirement from "never fail" to "fail visibly and recover fast" — which is achievable.

### Services

| Service | Redundancy story |
| --- | --- |
| **Archiver Appliance** | Multi-appliance clustering is native. Losing one appliance loses ingest for its PV subset — a gap, not a corruption. |
| **Alarm system (Phoebus)** | Kafka-backed. Kafka replicates across brokers; the alarm server itself is a single process, restartable in seconds with state rebuilt from the Kafka log. Genuinely good design. |
| **ChannelFinder** | Stateless service over Elasticsearch; run several behind a load balancer, replicate Elasticsearch. |
| **Save & restore** | Stateless service over a database; the database is the thing to protect. |
| **Olog** | Same pattern — service plus Elasticsearch/database. |
| **Gateways** | Two gateways can serve the same PVs to the same clients, and clients bind to one. Acceptable for read-only paths; not a clean active/active story. |

The general shape: **services are restartable, their data stores need real protection.** Back up the archiver's configuration database (losing it means losing the definition of what you archive, which is worse than losing samples), the alarm configuration, the save sets, and ChannelFinder's contents.

### What to protect first

Ranked by consequence, for a facility with limited effort to spend:

1. **The archiver's configuration and data.** History is unrecoverable. Everything else can be rebuilt from version control.
2. **Save sets.** They encode "the machine configuration that worked", sometimes the only record of it.
3. **The alarm configuration.** Rebuildable but represents years of accumulated operational tuning.
4. **IOC source and deployment configuration.** In git, therefore already safe — verify that the *deployed* state matches git, which is a different claim.
5. **The IOC processes themselves.** Least important. They restart.

## Performance limits worth knowing

Order-of-magnitude figures, not benchmarks — measure your own system.

| Resource | Practical guidance |
| --- | --- |
| Records per IOC | Tens of thousands is routine. The limit is processing rate, not count: 100 000 idle records are cheaper than 5 000 at 10 Hz. |
| Records × scan rate per IOC | Watch CPU with [iocStats](../toolbox/soft-support-modules.md#iocstats--deviocstats). A scan task that can't complete within its period is the failure to detect, and it manifests as jitter and late timestamps rather than an error. |
| CA clients per IOC | Hundreds work. Thousands mean you should have a gateway. `casr 2` shows the reality. |
| Monitor rate | The dominant cost. Small-packet rate limits switches before bandwidth does. |
| Array traffic | One 4 MP camera at 30 fps ≈ 250 Mbit/s. Plan interfaces and segments accordingly, and keep it away from control traffic. |
| Archiver ingest | Per-appliance throughput depends on storage; the [Archiver Appliance](../toolbox/archiving.md#epics-archiver-appliance) documentation gives current guidance. Plan multiple appliances above ~100 000 archived PVs. |
| Lock set size | Watch for wide lock sets serialising fast records behind slow ones. `dbLockShowLocked`. Split with a `CA` link. |

## Operational practices that determine availability more than architecture

Uncomfortable truth: at most facilities, uptime is limited by process rather than by design.

- **Know what's running.** [iocStats](../toolbox/soft-support-modules.md#iocstats--deviocstats) on every IOC, alarmed on uptime resets and heartbeat loss. An IOC that has been down for three weeks and nobody noticed is a real and common occurrence.
- **Version-control everything, deploy from it.** Including `.acf` files, gateway rules, archiver policies, and alarm configuration. Especially those, because they're the files people edit in place at 2 a.m.
- **Make restarts boring.** If restarting an IOC is frightening, it will be avoided, and problems accumulate until something worse happens. Boring restarts require autosave, `PINI`, and hardware that holds state.
- **Test the restore path, not just the backup.** Archiver backups nobody has restored are a hypothesis.
- **Watch the archiver's own health.** It is the component whose failure is silent and whose loss is permanent.
- **Keep a written machine-state configuration.** Save sets plus a document saying which set is "the" configuration for each mode.

## Next

→ [The Toolbox](../toolbox/index.md) — the catalogue of everything you might deploy.
