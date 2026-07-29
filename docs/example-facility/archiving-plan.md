# Archiving Plan

Where 24 TB/year comes from, term by term — and why the arithmetic matters before you deploy rather than after.

Tool background: [Toolbox → Archiving](../toolbox/archiving.md).

## What gets archived

| Class | PVs | Policy |
| --- | --- | --- |
| Physical readbacks (all subsystems) | 150 000 | MONITOR, deadband on the record, **keep forever** |
| Setpoints and discrete status | 90 000 | MONITOR, **keep forever** |
| Beam diagnostics scalars | 40 000 | MONITOR, **keep forever** |
| Fast machine scalars (RF, current, orbit RMS) | 8 000 | MONITOR, keep forever |
| Waveforms (orbit arrays, RF traces, decimated) | 2 000 | MONITOR, 90-day full resolution then decimated |
| **Archived total** | **290 000** | |
| Not archived | 125 000 | Internal/debug PVs, areaDetector plugin internals, image data |

Of 415 000 PVs, 70% are archived. The 30% that aren't are mostly [areaDetector](../toolbox/detectors-and-imaging.md) plugin internals — buffer counts, queue depths, plugin-internal state — which change meaning between releases and whose useful summaries are archived instead.

**Images are never in the archiver.** They go through the [file-writing path](beamline.md#the-data-path). What's archived is the metadata and the [statistics plugin](../toolbox/detectors-and-imaging.md#analysis-plugins) outputs — centroid, total, dropped-frame counters.

## The decision that dominates everything

**MONITOR sampling with deliberate deadbands, set on the record when it is created.**

```text
record(ai, "SR-C05-VA-IP-03:Pressure-Mon") {
    field(MDEL, "0.02")     # monitor deadband — network traffic
    field(ADEL, "0.05")     # archive deadband — storage cost
}
```

This is the choice that determines whether the archive costs 24 TB/year or 116 TB/year, and it lives in the IOC, not the archiver. Consequences:

- A pressure that isn't changing produces **no data at all**. A step change is captured at full fidelity.
- SCAN sampling at 1 Hz across 290 000 PVs would produce 250 GB/day of mostly-identical numbers.
- **You cannot fix this from the archiver side.** `ADEL` is a record field, so a badly-behaved archived PV needs an IOC change and a restart.

Which is why HLS treats `MDEL`/`ADEL` as mandatory review items in database design, alongside `EGU` and alarm limits. Retrofitting deadbands across 290 000 PVs after deployment is a facility-wide campaign; setting them at creation costs one line each.

## The arithmetic

Event rates are estimates from commissioning measurements on similar machines — the point is the *method*, and the caveat that you must measure your own.

| Class | PVs | Events/s per PV | Events/s | Bytes/event | Bytes/s |
| --- | --- | --- | --- | --- | --- |
| Slow physical readbacks | 150 000 | 0.02 | 3 000 | 22 | 66 000 |
| Setpoints and status | 90 000 | 0.005 | 450 | 22 | 9 900 |
| Beam diagnostics scalars | 40 000 | 0.5 | 20 000 | 22 | 440 000 |
| Fast machine scalars | 8 000 | 1.0 | 8 000 | 22 | 176 000 |
| Waveforms | 2 000 | 0.01 | 20 | 4 000 | 80 000 |
| **Total** | **290 000** | | **≈31 500** | | **≈772 000** |

```text
772 000 B/s  ×  86 400 s/day   =  66.7 GB/day
66.7 GB/day  ×  365 days       =  24.3 TB/year
```

**≈24 TB/year at full resolution.**

Where each term comes from:

- **22 bytes/event** — a compressed timestamped sample: value, seconds, nanoseconds, status, severity, with the Appliance's per-chunk compression. Measure yours; it varies with data type.
- **0.02 events/s** for slow readbacks — a temperature or pressure with a sensible deadband genuinely changes about once a minute. This is the term people get wrong by two orders of magnitude, because they assume scan rate rather than change rate.
- **0.5 events/s** for diagnostics — the largest single contributor at 440 kB/s, because BPM positions and beam current genuinely move.
- **Waveforms are the surprise.** 2 000 PVs at one event per hundred seconds is 80 kB/s — comparable to 150 000 slow scalars. Arrays are expensive per event, and this is why waveform archiving needs an explicit policy rather than a default.

## Storage tiers

```text
STS  short-term    24 hours     local NVMe on each appliance     ~70 GB
MTS  medium-term   90 days      local SSD on each appliance      ~6 TB
LTS  long-term     forever      shared replicated bulk storage   see below
```

With 10:1 decimation into LTS after 90 days:

| Period | Full resolution | Decimated | Cumulative |
| --- | --- | --- | --- |
| Last 90 days | 6.0 TB | — | 6.0 TB |
| Year 1 (remainder) | — | 1.8 TB | 7.8 TB |
| After 5 years | 6.0 TB | 11.0 TB | 17 TB |
| After 10 years | 6.0 TB | 23.5 TB | 30 TB |

**Decimation is what makes "forever" affordable.** Without it, ten years is 243 TB; with it, 30 TB. And ten-year-old data at reduced resolution answers the questions people actually ask of it — long-term drift, seasonal correlation, "has this always been like this?" — while full resolution matters only for recent fault investigation.

Waveforms and a small set of critical scalars (stored current, beam permit, machine mode, orbit RMS) are exempt from decimation and kept at full resolution forever, because those are the signals an incident review will need.

## Clustering

Four [Archiver Appliances](../build-install/archiver-appliance.md), each owning a PV subset, federated for retrieval:

| Appliance | PV subset | PVs |
| --- | --- | --- |
| `arch-01` | Storage ring magnets and RF | ~85 000 |
| `arch-02` | Vacuum, cryogenics, utilities | ~50 000 |
| `arch-03` | Diagnostics, timing, injector, insertion devices | ~65 000 |
| `arch-04` | Beamlines and front ends | ~90 000 |

Split by subsystem rather than evenly, so an appliance failure has a comprehensible blast radius: losing `arch-02` means a vacuum-data gap, which is a sentence you can say to an operations meeting. Losing "a random 25% of everything" is not.

Retrieval is federated — a client asks any appliance and gets data from wherever it lives.

## Configuration by query

PVs are added from [ChannelFinder](../build-install/channelfinder-recsync.md) queries, not lists:

```text
archive=monitor AND subsystem=vacuum        → arch-02, monitor, forever
archive=monitor AND subsystem=diagnostics   → arch-03, monitor, forever
archive=waveform                            → per-appliance, 90-day + decimate
archive=none                                → excluded
```

The `archive` property is declared in the database with `info()` tags, [where the record is defined](../build-install/channelfinder-recsync.md#attaching-your-own-metadata):

```text
record(ai, "SR-C05-VA-IP-03:Pressure-Mon") {
    field(ADEL, "0.05")
    info(recceiver:archive,   "monitor")
    info(recceiver:subsystem, "vacuum")
}
```

So a newly installed ion pump is archived because its record says so — no archiver-side work, no chance of being forgotten. This is the strongest practical argument for deploying a directory service, and it's why HLS did it before the first archiver rather than after.

## Retention policy, decided once and written down

Agreed with the physics and operations groups, and recorded as a controlled document:

| Data | Retention |
| --- | --- |
| Stored current, beam permit, machine mode, orbit RMS | Full resolution, forever, never decimated |
| All physical readbacks and setpoints | Full resolution 90 days, 10:1 decimated forever |
| Waveforms | Full resolution 90 days, then event-selected retention only |
| Beamline PVs | Full resolution 90 days, 10:1 decimated 5 years |
| IOC health PVs | Full resolution 30 days, decimated 1 year |
| Detector plugin internals | Not archived |

The one to note is the first row. Those are the signals every incident review and every long-term stability study starts from, they are cheap, and exempting them from decimation costs almost nothing. Deciding that in advance is much easier than discovering, during a review, that the data was decimated away.

## Operating it

**Monitor the archiver as a system.** Per appliance: connected vs configured PV count, the **disconnected PV list**, ingest rate, per-tier free space, ETL job success. All in the `Controls` [alarm configuration](alarm-plan.md) and in Grafana.

**Alarm on the disconnected-PV count.** A configured PV that stopped connecting three months ago is a gap you'll find exactly when you need the data.

**Back up the MariaDB configuration database nightly, offsite.** Losing the 290 000 per-PV policies is worse than losing samples for a week.

**Test retrieval quarterly.** Pull a value from a year ago. Facilities have discovered, two years in, that their long-term store was never actually being written.

**Handle renames deliberately.** The archiver stores by name; a rename produces two half-histories unless you tell it they're the same signal. Combined with [`alias()`](../architecture/naming-conventions.md#aliases-and-the-migration-escape-hatch) during migrations.

## Access

| Route | Audience |
| --- | --- |
| [Phoebus Data Browser](../build-install/phoebus.md) | Operators — live and archived on one plot |
| Appliance web UI | Engineers — ad-hoc plots, export, PV status |
| [Grafana](../toolbox/web-interfaces.md#grafana) via the [archiver data source](https://github.com/sasaki77/archiverappliance-datasource) | Shift dashboards, wall displays, long-term trends |
| REST API + pandas | Physics analysis, machine learning |
| [pvinfo](../build-install/pvinfo.md) | "What is this PV and what has it been doing?" |

The REST + pandas route is worth calling out: ten years of well-timestamped, consistently-named history is the training set that makes [anomaly detection and fault prediction](../toolbox/physics-and-optimization.md#machine-learning) possible at all. Archiving discipline turns out to be an ML prerequisite, which nobody anticipated when the archivers were designed.

## Next

→ [Alarm Plan](alarm-plan.md)
