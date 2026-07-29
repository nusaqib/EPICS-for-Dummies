# Install Olog

The electronic logbook, integrated with Phoebus so that sending a screenshot or a plot into the log takes two clicks.

Overview: [Toolbox → Logbooks](../toolbox/logbooks.md#olog).

| | |
| --- | --- |
| Service | [github.com/Olog/phoebus-olog](https://github.com/Olog/phoebus-olog) |
| Organisation | [github.com/Olog](https://github.com/Olog) |
| Client | The Logbook application in [Phoebus](phoebus.md), plus a web UI |

## Prerequisites

- [JDK](jdk.md)
- **Elasticsearch** — the search index
- **MongoDB** — attachment storage (check the current README; the backing stores have changed across versions)

Reuse the Elasticsearch cluster you stood up for [ChannelFinder](channelfinder-recsync.md) or the [alarm logger](alarm-system.md) rather than running a third.

!!! note "Check the README for backing-store requirements"
    Olog's storage arrangement has evolved. The repository's README and `application.properties` are authoritative; this page describes the shape rather than the specifics.

## Run it

A Spring Boot service:

```bash
git clone https://github.com/Olog/phoebus-olog.git
cd phoebus-olog
mvn clean install
java -jar target/service-olog-*.jar
```

Configuration in `application.properties`: Elasticsearch and MongoDB addresses, the service port, and authentication (LDAP is the usual facility choice — you want logbook entries attributed to real people).

Container images are also published, which is generally less work.

## Set up logbooks and tags

Before anyone writes an entry, define the structure — logbooks and tags are the thing that makes the log searchable rather than merely readable:

| Concept | Examples |
| --- | --- |
| **Logbooks** | `Operations`, `Accelerator`, `BL07`, `Vacuum`, `Controls`, `Maintenance` |
| **Tags** | `beam-dump`, `rf-trip`, `vacuum-event`, `shutdown`, `commissioning`, `user-run`, `follow-up-required` |

A `follow-up-required` tag, reviewed at every shift handover, turns the logbook into a work-tracking tool as well as a record. Cheap and unreasonably effective.

Both are created through the service's API or web UI, and both should be a deliberate, documented set rather than something anyone can add ad hoc — otherwise you get `rf-trip`, `RF trip`, `rftrip`, and no useful search.

## Connect Phoebus

```properties
# settings.ini
org.phoebus.olog.es.api/olog_url=http://olog.example.org:8080/Olog
org.phoebus.logbook/logbook_factory=olog-es
```

Then:

- Applications → Utility → Send To Logbook, or the context menu on almost anything.
- **Right-click any display or Data Browser plot → Send to Logbook.** The screenshot, the PV names and the time range are captured automatically.

That last one is the entire value proposition. The friction of documenting something is the only thing that determines whether it gets documented, and an entry that takes twenty seconds and captures the plot you were already looking at will be written.

## Verify

1. Create an entry from Phoebus with a screenshot attached.
2. Find it in the web UI.
3. Search for it by text, by tag, and by logbook.
4. Attach a file. Retrieve it.
5. Confirm the author is your real identity, not `anonymous` — if it is, fix authentication now rather than after six months of unattributed entries.

## Guidance

**Log the "why", not the "what".** [caPutLog](../toolbox/logbooks.md#caputlog) and the [archiver](../toolbox/archiving.md) already record what changed. `"Raised QF current 2.5 A to compensate the tune shift from ID07 closing"` is irreplaceable.

**Retain forever.** Text and metadata are trivially small, and entries from a decade ago get read during the commissioning of the next machine.

**Be careful what you attach.** Personal data, credentials in a pasted config, unpublished results. Logbooks are widely readable and permanently retained — have a stated policy.

**Back it up**, including the attachment store. The logbook is institutional memory.

## Alternative: PSI ELOG

If you want a logbook running this afternoon with no Elasticsearch and no MongoDB, [PSI ELOG](https://elog.psi.ch/elog/) is a single self-contained daemon with configurable entry forms, email notification and attachments. Widely used well beyond the EPICS community.

Trade-off: no Phoebus integration, so the two-click screenshot workflow doesn't exist, and entries are less structured. For a test stand or a small group it's a very reasonable choice.

## Next

→ [PVWS](pvws.md) for browser access.
