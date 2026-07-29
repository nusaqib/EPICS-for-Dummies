# Install the EPICS Archiver Appliance

Facility-scale history. This is the biggest single deployment in the [stage 3](index.md) list, and the one whose absence you'll regret most.

| | |
| --- | --- |
| Source | [github.com/archiver-appliance/epicsarchiverap](https://github.com/archiver-appliance/epicsarchiverap) |
| Documentation | [epicsarchiver.readthedocs.io](https://epicsarchiver.readthedocs.io/) |
| Overview | [Toolbox → Archiving](../toolbox/archiving.md#epics-archiver-appliance) |

!!! warning "Follow upstream, not this page, for the actual procedure"
    The Appliance's installation has several version-specific details — Tomcat version, `appliances.xml`, the deployment script, storage-tier configuration. **Use the [official installation guide](https://epicsarchiver.readthedocs.io/).** This page explains the shape of the thing so that guide makes sense, and lists what goes wrong.

## What you're deploying

Four web applications plus storage plus a database:

| Component | Role |
| --- | --- |
| **mgmt** | Management: the web UI, the PV configuration, the policies |
| **engine** | Connects to PVs and captures samples |
| **etl** | Extract/transform/load — moves data down the storage tiers on a schedule |
| **retrieval** | Serves data out: REST API, plots, exports |
| **MySQL/MariaDB** | *Configuration* storage — which PVs, which policies. **Not** the sample data. |
| **Storage tiers** | Where the samples actually live: short, medium, long term |

The four web apps can run in one Tomcat (small deployments) or separate ones (production). They discover each other through `appliances.xml`.

## Prerequisites

- A [JDK](jdk.md)
- [Tomcat](tomcat.md) — **check the documentation for the supported version**, don't assume the newest
- MySQL or MariaDB
- Disk: three paths, ideally on different storage classes
- Maven and `git`, if building from source rather than using a release

## The storage tier decision

Get this right before you start, because migrating later is real work.

```text
STS  short-term   hours to a few days    fastest disk, or tmpfs/ramdisk
MTS  medium-term  weeks to months        local SSD or HDD
LTS  long-term    years to forever       bulk or network storage
```

Set by environment variables that the Appliance reads:

```bash
export ARCHAPPL_SHORT_TERM_FOLDER=/data/archiver/sts
export ARCHAPPL_MEDIUM_TERM_FOLDER=/data/archiver/mts
export ARCHAPPL_LONG_TERM_FOLDER=/data/archiver/lts
export ARCHAPPL_MYIDENTITY=appliance0
export ARCHAPPL_APPLIANCES=/etc/archappl/appliances.xml
```

Considerations:

- **STS on a ramdisk** is fast and is lost on reboot. Acceptable *only* if ETL to MTS runs frequently enough that the loss window is small — and you must understand that you are trading a few minutes of data for write performance.
- **LTS on NFS or object storage** is normal and works, provided the ETL job's throughput is adequate. Watch for the case where ETL falls behind and MTS fills up.
- **Decimation on the way down** — full resolution in MTS, reduced in LTS — is often the difference between an affordable archive and an unaffordable one. Configure it in the policy file, deliberately.

## Policies

`policies.py` decides, per PV, how it's archived — sampling method, period, retention, decimation — matched by PV name pattern. It's Python, evaluated when a PV is added.

This is where your [naming convention](../architecture/naming-conventions.md) pays off or bites. `SR-*-VA-*:Pressure` → monitor, keep forever. `*-DI-BPM-*:Waveform` → scan at 1 Hz, 30-day retention. If your names have no structure, your policy file becomes a list of thousands of special cases.

Get the defaults right before adding PVs in bulk. Changing a policy afterwards affects new data, and the old data keeps whatever policy it was captured under.

## Adding PVs

Three routes:

1. **The web UI** — paste a list. Fine for tens.
2. **The REST API** — `.../mgmt/bpl/archivePV` with a JSON body. Fine for thousands, and scriptable.
3. **[ChannelFinder](channelfinder-recsync.md) integration** — the Appliance queries a directory service and archives what matches. **This is the right answer at facility scale**: a new IOC's PVs get archived because they're tagged, with no archiver-side work at all.

Whichever you use, do it from a version-controlled source, so "what do we archive?" has an answer that isn't "query the archiver and hope".

## Verify it works

```bash
# Is the PV being archived, and connected?
curl 'http://archiver:17665/mgmt/bpl/getPVStatus?pv=DEMO:Temperature'

# Pull some data back
curl 'http://archiver:17665/retrieval/data/getData.json?pv=DEMO:Temperature&from=2026-07-29T00:00:00Z&to=2026-07-29T23:59:59Z'
```

Then, more importantly:

- Add a PV, change it, and confirm the change appears in a retrieval query.
- Plot it in the Appliance's own web UI.
- Plot it in the [Phoebus Data Browser](phoebus.md) — configure the archiver URL in Phoebus preferences.
- Leave it a day and confirm ETL moved data from STS into MTS. **This is the step people skip, and a broken ETL is silent until STS fills up.**

## Grafana

Add the [archiverappliance-datasource](https://github.com/sasaki77/archiverappliance-datasource) plugin, point it at the retrieval URL, and you have dashboards over your control-system history — including the server-side decimation operators, so a year-long plot doesn't try to send 31 million points to a browser. See [Web Interfaces](../toolbox/web-interfaces.md#grafana).

## Operating it

**Monitor it as a system, not a service.** Connected vs configured PV count, the disconnected-PV list, ingest rate, per-tier free space, ETL job success. See [Observability](../toolbox/observability.md).

**Alarm on disconnected PVs.** A configured PV that stopped connecting three months ago is a gap you'll find exactly when you need the data.

**Back up the MySQL configuration database.** Losing the *list of what you archive*, with all its policies, is worse than losing samples — you stop collecting correctly going forward, and reconstructing thousands of per-PV policies is a project.

**Test retrieval of old data quarterly.** Pull something from a year ago. Facilities have discovered, two years in, that their long-term store was never actually being written to.

**Plan capacity from arithmetic, not intuition.** The [Helios archiving plan](../example-facility/archiving-plan.md) works through a full facility estimate — PV counts, event rates, bytes per sample, and where 24 TB/year comes from.

## The easier alternative

For a first archiver, or a beamline, the [Phoebus RDB archive engine](../toolbox/archiving.md#phoebus-rdb-archive-engine) needs only a database and a JAR you already built with [Phoebus](phoebus.md):

```bash
java -jar archive-engine-*.jar -engine myengine -config config.xml -settings settings.ini
```

Much less to deploy, plots in the same Data Browser, and entirely adequate up to thousands of PVs. Migrating to the Appliance later is a real project, but a smaller one than never having archived anything.

## Next

→ [Alarm System](alarm-system.md)
