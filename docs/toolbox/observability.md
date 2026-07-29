# Observability

Is the control system itself healthy? Distinct from "is the machine healthy", and much more often neglected. A control system that has quietly stopped observing part of the facility is a hazard, because everyone believes it's watching.

## What to watch

### IOC health: from iocStats

[iocStats](soft-support-modules.md#iocstats-and-deviocstats) on every IOC gives you PVs for:

| Signal | Alarm on | Why |
| --- | --- | --- |
| **Heartbeat** | Stale for > 30 s | The IOC is dead or unreachable. The single most important control-system alarm there is. |
| **Uptime** | Decreased since last check | The IOC restarted. Something caused that, and nobody may have noticed. |
| **CPU load** | Sustained high | Scan tasks not keeping up; timestamps drifting late. |
| **Free memory** | Trending down | A leak. Slow leaks are found by trends, not thresholds. |
| **File descriptors** | Near limit | Leaked connections; the IOC will stop accepting clients. |
| **CA client count** | Unexpected growth | A client leaking connections, or a runaway script. |
| **Scan task period vs actual** | Actual > nominal | The IOC cannot complete a scan pass in time. A subtle, important, easily-missed failure. |
| **EPICS Base / app version** | (not an alarm) | Inventory. What is actually running where. |

**"An IOC has been down for three weeks and nobody noticed" is a real and common occurrence.** Heartbeat alarms are the cure and they cost nothing.

### Service health

| Service | Watch |
| --- | --- |
| [Archiver](archiving.md) | Connected vs configured PV count, **disconnected PV list**, ingest rate, storage-tier free space, consolidation job success |
| [Alarm system](alarms.md) | Server alive, Kafka broker health, consumer lag, alarm rate (a *drop* to zero is as suspicious as a flood) |
| [ChannelFinder](directory-services.md) | Service up, Elasticsearch health, recsync receiver processing rate |
| [Gateways](gateways.md) | Connected channels, client count, CPU — a saturated gateway degrades everything behind it |
| [Save & restore](save-and-restore.md), [Olog](logbooks.md#olog) | Service up, database/Elasticsearch health, backup success |
| [PVWS / DBWR](web-interfaces.md) | Session count, PV count, upstream connection health |

The archiver's **disconnected PV list** deserves singling out: a PV in the archive configuration that stopped connecting months ago is a gap you'll discover exactly when you need the data. Alarm on the count, and review the list.

### Host and network

Standard IT monitoring, with EPICS-specific additions:

- **NTP offset.** [Timestamps come from IOCs](timing-systems.md); a drifted host silently corrupts correlation. Treat a drift alarm as a data-integrity incident, not a housekeeping item.
- **Interface packet rate**, not just bandwidth. Monitor traffic is small-packet-heavy and saturates packet-per-second capacity long before bit rate.
- **Switch error and discard counters.** Where intermittent CA disconnections come from.
- **UDP receive-buffer drops** on IOC hosts. Search traffic bursts can overflow socket buffers, and the symptom is intermittent connection failures under load.
- **Disk space** on IOC hosts (autosave files, logs) and archiver storage tiers.

## The tooling

### Grafana + a time-series database

The standard approach: get PVs and host metrics into one dashboarding tool.

| Route | Notes |
| --- | --- |
| **[Archiver Appliance data source](https://github.com/sasaki77/archiverappliance-datasource)** | Query archived PVs directly. No second data pipeline; the archiver is already collecting this. **Usually the right answer.** |
| **Prometheus** | Requires an exporter that reads PVs and exposes metrics. Several community exporters exist; check current maintenance. Good if your IT department already runs Prometheus and Alertmanager. |
| **InfluxDB / Telegraf** | Also used; a Telegraf input reading PVs, or a small bridge script. |

If your [archiver](archiving.md) already stores iocStats PVs, Grafana over the archiver data source gives you control-system observability with **no additional infrastructure at all**. Start there before building a second pipeline.

### The EPICS-native route

Don't overlook it: iocStats produces PVs, so the [alarm system](alarms.md) can alarm on them, [Phoebus](operator-interfaces.md#phoebus) can display them, and the [archiver](archiving.md) can trend them. A "control system health" screen in Phoebus showing every IOC's heartbeat and uptime, with alarm colouring, is straightforward and uses only tools you already run.

The advantage over an external stack: it's in the operators' existing toolset, it uses the alarm workflow they already know, and it has no dependency on infrastructure outside the controls network.

### Log aggregation

Elasticsearch/OpenSearch with Kibana, Grafana Loki, or your site's existing platform — collecting IOC stdout, `errlog`, [caPutLog](logbooks.md#caputlog), [alarm logs](alarms.md#alarm-logger), and host logs. The goal is one searchable timeline. See [Logbooks](logbooks.md#ioc-and-infrastructure-logging).

## A dashboard that's actually useful

Four levels, in the order a person needs them:

**1. Facility overview** — one screen, safe for a wall display: how many IOCs are expected vs alive, current alarm count by severity, archiver ingest rate and connected fraction, service up/down, beam status. The question it answers: *is anything wrong right now?*

**2. IOC inventory** — a table of every IOC: alive, uptime, CPU, memory, client count, version, host, subsystem. Sortable. The question: *which one?* This table, generated from [recsync](directory-services.md#recsync) plus iocStats, is the single most useful control-system page a facility can build.

**3. Trends** — CPU, memory, client counts, ingest rates over weeks. The question: *is something getting worse?* Slow degradation is invisible to thresholds and obvious in a trend.

**4. Correlation view** — control-system events on the same time axis as machine events. The question, during an incident: *what happened, in what order?*

## Guidance

**Alarm on absence, not just on badness.** A heartbeat that stopped, a PV count that dropped, an ingest rate that went to zero, an alarm system that suddenly reports nothing. Systems fail silent far more often than they fail loud, and threshold alarms don't catch silence.

**Distinguish "the control system is broken" from "the machine is misbehaving".** Different audiences, different urgency, different responders. Mixing them in one alarm tree means the controls team is paged for a vacuum excursion and the operators are paged for a full disk. Give control-system health its own branch in the [alarm hierarchy](alarms.md).

**Alarm on the archiver.** It is the component whose failure is completely silent and whose loss is permanent.

**Watch trends, not only thresholds.** A memory leak crosses a threshold weeks after it becomes visible in a trend.

**Include the observability stack in your own inventory.** Who monitors the monitor? At minimum, an independent check — even a cron job with `caget` and an email — that the monitoring itself is alive.

**Make the inventory generated, not maintained.** A hand-maintained IOC list is wrong within a month and its wrongness is invisible. recsync plus iocStats gives you an inventory derived from reality.

**Review it periodically with the people who get the alarms.** Observability that nobody looks at is a dashboard, not monitoring. If a screen has been red for two months, either fix the problem or delete the check — a permanently-red indicator trains everyone to ignore indicators.

## Next

→ [Build & Install](../build-install/index.md), or the [Example Facility](../example-facility/index.md) to see all of this assembled.
