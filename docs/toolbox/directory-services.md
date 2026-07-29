# Directory Services

*"It's always compelling to see how easily everyone agrees on one naming convention."*

EPICS has no name server. PV resolution is by broadcast, and the network cannot tell you what exists. That's fine at 500 PVs and unworkable at 400 000, because the questions people ask constantly have no answer:

- Which IOC serves this PV?
- What PVs does this IOC serve?
- Show me every BPM in the storage ring.
- Is this name already taken?
- Which PVs belong to the vacuum system, regardless of what they're called?

A directory service answers them.

## ChannelFinder

| | |
| --- | --- |
| Home | [channelfinder.github.io](https://channelfinder.github.io/) |
| Service | [github.com/ChannelFinder/ChannelFinderService](https://github.com/ChannelFinder/ChannelFinderService) |
| Training | [ChannelFinder](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/26%20Channel%20Finder.pdf) (USPAS) |
| This guide | [Install ChannelFinder & recsync](../build-install/channelfinder-recsync.md) |

A REST web service holding, for each channel:

- the **name**;
- **properties** — key/value pairs: `hostName`, `iocName`, `recordType`, `alias`, `pvStatus`, plus any you invent (`subsystem`, `cell`, `deviceType`, `beamline`, `archived`);
- **tags** — labels with no value: `archived`, `alarmed`, `bpm`, `orbit-feedback`, `critical`.

Then you query it:

```bash
# Every PV served by one IOC
curl 'https://cf.example.org/ChannelFinder/resources/channels?iocName=vac-sr-c05'

# Every horizontal BPM reading in the storage ring
curl 'https://cf.example.org/ChannelFinder/resources/channels?~name=SR-*-DI-BPM-*:X-Mon'

# Everything tagged as part of orbit feedback
curl 'https://cf.example.org/ChannelFinder/resources/channels?~tag=orbit-feedback'

# Which PVs on this host are currently inactive?
curl 'https://cf.example.org/ChannelFinder/resources/channels?hostName=iocsrv12&pvStatus=Inactive'
```

Backed by Elasticsearch. Clients: [Java](https://github.com/ChannelFinder/javaCFClient), [Python](https://github.com/ChannelFinder/pyCFClient), the REST API directly, [PV Info](web-interfaces.md#pv-info) for humans, and a Phoebus Channel Table application.

## recsync

**The piece that makes it work without anyone maintaining a list.**

| | |
| --- | --- |
| Source | [github.com/ChannelFinder/recsync](https://github.com/ChannelFinder/recsync) |

Two halves:

- **RecCaster** — an EPICS module you load into each IOC. At startup it announces itself and uploads its complete record list, plus record types and any `info()` tags you've attached.
- **RecCeiver** — a standalone daemon that receives those announcements and populates ChannelFinder.

The consequence is worth stating plainly: **your directory is generated from reality, not from documentation.** Add a record, restart the IOC, and it's in ChannelFinder with its IOC name, host, and record type. Delete a record and it disappears. Nobody maintains a spreadsheet, and nobody can forget to.

Loading it is three lines in `st.cmd`:

```text
dbLoadRecords("$(RECSYNC)/db/reccaster.db", "P=SR-C05-VA-IOC-01:")
# optional: attach your own metadata, which RecCaster forwards
# info(recceiver:subsystem, "vacuum")
```

You can attach arbitrary `info()` fields in the database and have them become ChannelFinder properties — so `subsystem`, `cell`, or `criticality` can be declared where the record is defined, which is the only place that stays correct.

## What a directory unlocks

The value isn't the search box; it's what other services do with it.

| Consumer | Use |
| --- | --- |
| [Archiver Appliance](archiving.md) | Auto-discover PVs to archive by query — "archive everything tagged `archived`". New IOC, no archiver configuration work. |
| [Alarm system](alarms.md) | Build alarm configuration from queries rather than hand-maintained lists. |
| [Save & restore](save-and-restore.md) | Define a save set as a query — "all storage ring magnet setpoints" — so a new magnet is included automatically. |
| [PV Info](web-interfaces.md#pv-info) | The human front door: one page linking a PV to its IOC, history, alarms, and save sets. |
| [Phoebus](operator-interfaces.md#phoebus) | Channel Table; and displays that build themselves from a query rather than a hard-coded list. |
| Operations | **Duplicate name detection.** A query returning one name from two IOCs is a bug found before it confuses somebody. |
| Physics scripts | "Give me every BPM in order around the ring" is a query, not a hard-coded array in forty different scripts. |
| Deployment | "Which IOCs are on the host we're about to reboot?" |

That last category is where a directory quietly pays for itself. Every facility has scripts containing hard-coded PV lists that went stale. A query is always current.

## Alternatives and adjuncts

| Tool | Purpose |
| --- | --- |
| **`pvlist`** (PVA) | Enumerates PVA servers on a network segment. Useful, unstructured, and CA has no equivalent. |
| **[alive](https://github.com/epics-modules/alive)** | IOC heartbeat and inventory reporting to a central server. Overlaps with iocStats+recsync; some facilities prefer it. |
| **Facility asset databases** | Many labs have an authoritative device/asset database and treat ChannelFinder as a derived view. This is the mature pattern: engineering data is the source of truth, PV names are generated from it, and ChannelFinder reflects what's actually running. |
| **Spreadsheets** | What you have if you have nothing else. They are always wrong, and the discrepancy is invisible. |

## Guidance

**Deploy recsync from the start, not after 200 IOCs.** Retrofitting is mechanical but touches every IOC, and every IOC touch needs a restart window.

**Define your property vocabulary deliberately.** `subsystem`, `deviceType`, `area`, `criticality`, `archived`, `alarmed` — agreed once and documented, in the same place as the [naming convention](../architecture/naming-conventions.md). Ad-hoc properties accumulate into an unqueryable mess (`system`, `subsystem`, `sys`, `Subsystem`).

**Attach metadata in the database with `info()`.** Then it's version-controlled alongside the record, reviewed with it, and correct by construction. Metadata added later through the REST API drifts from reality.

**Query, don't hard-code.** Every list of PVs in every script and configuration file is a maintenance liability. Where a service supports query-based configuration — the archiver and save/restore both do — use it.

**Watch for duplicates in CI.** A scheduled job querying for names served by more than one IOC catches a genuinely nasty class of bug automatically.

**It's a convenience, not a dependency.** ChannelFinder being down must not stop the machine. Services should tolerate its absence — they generally do, since they use it at configuration time rather than at runtime. Verify that assumption for anything you build on it.

## Next

→ [Save & Restore](save-and-restore.md)
