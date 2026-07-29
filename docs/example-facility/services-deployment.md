# Service Deployment

Where the archiver, alarm system, directory and logbook actually run — and what happens to the machine when each one dies.

## The inversion worth noticing

Zone 1, nearest the beam, has almost no dependencies: IOCs, an OS, a container runtime. Zone 3, furthest from the beam, depends on Kubernetes, Kafka, Elasticsearch, MariaDB and a shared filesystem.

That is deliberate. **Infrastructure complexity is kept away from the beam**, and the price is that the services tier is where the operational engineering effort goes.

## Hardware

| Role | Hosts | Notes |
| --- | --- | --- |
| Kubernetes control plane | 3 | Also schedules service pods |
| Kubernetes workers (services) | 5 | Stateless services, web front ends |
| Kafka brokers | 3 | Replication factor 3 for the alarm topics |
| Elasticsearch nodes | 3 | Shared by ChannelFinder, Olog, alarm logger |
| MariaDB | 2 | Primary + replica; archiver configuration, save/restore |
| Archiver appliances | 4 | Each owns a PV subset; see [archiving plan](archiving-plan.md) |
| Archiver storage | — | Per-appliance local SSD (STS/MTS) + shared bulk storage (LTS) |
| Gateway hosts | 3 | GW-1 in the DMZ; GW-2/3/4 on their boundaries |
| Web tier | 2 | nginx + SSO, PVWS, DBWR, pvinfo |

Twenty-six machines for the services tier, against thirty-two for all 330 IOCs. That ratio surprises people, and it's normal.

## Service placement

| Service | Zone | Runs as | Instances |
| --- | --- | --- | --- |
| [Archiver Appliance](../build-install/archiver-appliance.md) | 3 | Tomcat on dedicated hosts | 4 appliances, clustered |
| [Alarm server](../build-install/alarm-system.md) | 3 | Kubernetes pod | 3 — one per alarm configuration |
| [Alarm logger](../build-install/alarm-system.md) | 3 | Kubernetes pod | 1 |
| [Alarm config logger](../build-install/alarm-system.md) | 3 | Kubernetes pod | 1 |
| [ChannelFinder](../build-install/channelfinder-recsync.md) | 3 | Kubernetes pod | 2 behind a load balancer |
| RecCeiver | 3 | Kubernetes pod | 2 |
| [Save & restore](../build-install/save-and-restore.md) | 3 | Kubernetes pod | 1 |
| [Olog](../build-install/olog.md) | 3 | Kubernetes pod | 1 |
| [Scan server](../toolbox/scanning-and-automation.md#phoebus-scan-server) | 2 | Per-beamline, on the beamline server | 20 |
| Grafana | 3 | Kubernetes pod | 1 |
| [PVWS](../build-install/pvws.md), [DBWR](../build-install/dbwr.md), [pvinfo](../build-install/pvinfo.md) | 5 | Tomcat on the web tier | 2 each |
| [Gateways](../build-install/gateways.md) | 5 / boundaries | systemd on gateway hosts | 4 |
| Log aggregation | 3 | Kubernetes + Elasticsearch | 1 |

### Three alarm configurations, not one

`Accelerator`, `Beamlines`, `Controls` — separate Kafka topics with separate alarm server instances.

Because the audiences differ: operators watch `Accelerator`, beamline staff watch their part of `Beamlines`, and the controls team watches `Controls` (IOC heartbeats, service health). One combined tree would page the controls team about a vacuum excursion and the operators about a full disk. See [alarm plan](alarm-plan.md).

### Scan servers live on the beamlines

Not in zone 3. A scan server is per-experiment, needs low latency to its beamline's IOCs, and must keep running if the services network has a problem. Putting it on the beamline's own server keeps its failure domain equal to the beamline it serves.

## Failure analysis

The question that matters: **what stops the machine?**

| If this dies | Machine keeps running? | What you lose | Recovery |
| --- | --- | --- | --- |
| One IOC | ✅ Yes | Observation and control of one device group. **Hardware keeps doing what it was last told.** | Restart, seconds. [autosave](../toolbox/soft-support-modules.md#autosave) restores settings. |
| An IOC server | ✅ Yes | ~18 IOCs' worth of visibility | Kubernetes reschedules, minutes |
| Archiver appliance | ✅ Yes | **Ingest for its PV subset — permanently.** A gap, not a corruption. | Restart; the gap remains |
| All archivers | ✅ Yes | All history collection | The most urgent non-machine failure there is |
| Alarm server | ✅ Yes | Alarm annunciation | Restart; state rebuilt from Kafka in seconds |
| Kafka (majority) | ✅ Yes | Alarm system entirely | Real infrastructure incident |
| ChannelFinder | ✅ Yes | PV lookup, and *configuration-time* queries | Not runtime-critical; services already have their configuration |
| Save & restore | ✅ Yes | Snapshot/compare/restore | Restart; **protect the database** |
| Olog | ✅ Yes | Logbook | Restart |
| GW-1 | ✅ Yes | All web and office visibility | Restart; control room unaffected |
| GW-2/3 | ✅ Yes | Beamlines can't see machine status — **beamline operations degrade** | Two instances for exactly this reason |
| Elasticsearch | ✅ Yes | Alarm history, Olog, ChannelFinder queries | Cluster tolerates one node |
| Kubernetes control plane | ✅ Yes | Ability to reschedule; running pods continue | |
| The entire services tier | ✅ **Yes** | Everything except control | Operators can still run the machine from the control room |

**The machine never stops because a service died.** That's the payoff of EPICS's architecture: services are ordinary clients with no privileged hook into the IOCs. It also means the services tier can be upgraded during operations, which is how it actually gets maintained.

The two failures that hurt most are both silent:

1. **An archiver appliance not archiving.** Everyone believes the data exists. Alarmed on connected-PV count and ingest rate.
2. **GW-2/3 down, so beamlines are blind to machine status.** Users don't know whether beam is coming. Hence two instances.

## What gets protected

Ranked by consequence, because effort is finite:

| Rank | Asset | Why | How |
| --- | --- | --- | --- |
| 1 | **Archived data** | Unrecoverable. You cannot go back and collect last year. | Multi-tier storage, LTS on replicated bulk storage, restore tested quarterly |
| 2 | **Archiver configuration DB** | Losing the *policies* means collecting future data wrongly; reconstructing 290 000 per-PV policies is a project | MariaDB replica + nightly dump, offsite |
| 3 | **Save sets and snapshots** | Sometimes the only record of a configuration that worked | Database backup |
| 4 | **Alarm configuration** | Rebuildable, but represents years of operational tuning | XML in git, plus the [config logger's](../build-install/alarm-system.md) git repo |
| 5 | **Olog** | Institutional memory | Elasticsearch snapshots + attachment store backup |
| 6 | **IOC source and deploy config** | Already in git — **verify deployed state matches git** | CI drift detection |
| 7 | IOC processes | They restart | Nothing |

Item 6's caveat is the one facilities get wrong. "It's all in git" is a claim about the repository, not about the servers. A scheduled job comparing running container image tags against the deployment manifests turns that claim into a fact.

## Deployment mechanics

Everything is containerised and everything comes from git.

```text
git repository per IOC / service
        ↓  CI: build, test, tag
container registry
        ↓  Kubernetes manifests (also in git)
running pods
        ↓  drift detection job
comparison report against git
```

| Artefact | Where it lives |
| --- | --- |
| IOC definitions | Per-IOC repo, YAML for [ibek](../toolbox/deployment-and-operations.md#ibek) |
| Databases and templates | Same repo; substitutions **generated** from the device database |
| Container images | Registry, tagged by git SHA and release |
| Kubernetes manifests | A deployment repo |
| Gateway `pvlist` / `access` | A config repo — **these are security configuration** |
| Access security `.acf` | Same config repo, one file, deployed to every IOC |
| Archiver policies | Same config repo |
| Alarm configuration XML | Same config repo |
| Phoebus `settings.ini` and displays | A displays repo, served over HTTP to both Phoebus and DBWR |

The single most important line in that table is the gateway rules. They are the facility's write boundary; they are edited under pressure at 02:00; and they must be reviewed, versioned and deployed like code rather than edited in place.

## Monitoring the services

Every service reports into the `Controls` alarm configuration and into Grafana:

- Archiver: connected vs configured PVs, **disconnected PV list**, ingest rate, per-tier free space, ETL job success
- Alarm system: server alive, Kafka broker health, consumer lag, **alarm rate — alarmed on going to zero**
- ChannelFinder / Olog: service up, Elasticsearch cluster health
- Gateways: connected channels, client count, CPU
- Databases: replication lag, backup success
- Kubernetes: pod restarts, node health

Alarming on **absence** — a heartbeat that stopped, an ingest rate at zero, an alarm system that suddenly reports nothing — catches the silent failures that threshold alarms miss. See [Observability](../toolbox/observability.md).

## Next

→ [Operator Interfaces](operator-interfaces.md)
