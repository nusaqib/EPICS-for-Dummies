# Logging and Electronic Logbooks

*"Oh look, we're logging sensitive information… don't worry, nobody will ever read it."*

Two distinct needs: **machine-generated records** of what the control system did, and **human-written records** of what people did and observed. Different tools, both essential during an incident review.

## caPutLog

**Every write to the control system, recorded.**

| | |
| --- | --- |
| Source | [github.com/epics-modules/caPutLog](https://github.com/epics-modules/caPutLog) |
| Documentation | [docs/index.rst](https://github.com/epics-modules/caPutLog/blob/master/docs/index.rst) |

An IOC module that logs every Channel Access write:

```text
2026-07-29 14:03:21 opr@console2  SR-C05-PS-QF-01:Current-SP  new=105.0  old=102.5
```

Captures the timestamp, the *claimed* user name, the client host, the PV, and both old and new values. Output goes to a log file, syslog, or a central [caPutLog server](https://github.com/epics-modules/caPutLog).

**Why it's near-mandatory:** "who changed this, and what was it before?" is among the most frequently asked questions in a control room, and without caPutLog the answer is genuinely unavailable. The [archiver](archiving.md) tells you the value changed; caPutLog tells you *who asked for it*.

**Its limitation, stated honestly:** the user name is self-declared, exactly as in [access security](../architecture/access-security.md). caPutLog is a record of what clients *said* about themselves. That's entirely adequate for the real use case — reconstructing events among colleagues who aren't lying — and inadequate as forensic evidence. Don't oversell it to a security review.

**Deployment notes:** load it on every IOC where operators can write. Ship the logs somewhere central (syslog to an aggregator, or into Elasticsearch alongside the [alarm log](alarms.md#alarm-logger)) so that correlating "the alarm fired at 14:03" with "someone wrote to it at 14:02" is one search rather than a hunt across 300 IOC hosts.

## Olog

| | |
| --- | --- |
| Service | [github.com/Olog/phoebus-olog](https://github.com/Olog/phoebus-olog) |
| Organisation | [github.com/Olog](https://github.com/Olog) |
| Client | The Logbook application in [Phoebus](operator-interfaces.md#phoebus), plus a web UI |
| This guide | [Install Olog](../build-install/olog.md) |

The human logbook, integrated with the control system. A REST service (Elasticsearch-backed) with:

- **Logbooks and tags** for categorisation — per-subsystem, per-beamline, per-shift.
- **Attachments** — screenshots, plots, data files, photographs of the thing that's broken.
- **Properties** — structured key/value metadata alongside prose text, so entries are queryable rather than just readable.
- **Full-text search** across everything.
- **Integration from Phoebus**: send a screenshot of the display you're looking at, or a Data Browser plot, into the logbook in two clicks, with the PV names and time range recorded automatically.

That last point is what distinguishes an integrated logbook from a wiki. The friction of documenting something is the only thing that determines whether it gets documented. A logbook entry that takes twenty seconds and captures the plot you were already looking at will be written; one that requires opening a browser, finding the right page, and re-creating the context will not.

## PSI ELOG

| | |
| --- | --- |
| Home | [elog.psi.ch](https://elog.psi.ch/elog/) |

A lightweight, self-contained web logbook from PSI, in wide use well beyond the EPICS community. Configurable entry forms, email notification, attachments, and a simple deployment story (a single daemon, no Elasticsearch).

**Choose ELOG over Olog when** you want a logbook running this afternoon with no infrastructure, or your facility already runs it. **Choose Olog when** you want Phoebus integration and structured, queryable entries as first-class features.

## IOC and infrastructure logging

The unglamorous layer that matters during a failure.

| Source | What it gives you | Where it should go |
| --- | --- | --- |
| **IOC stdout/stderr** | Startup messages, `iocInit` failures, driver errors, record-processing complaints | Captured by [procServ](deployment-and-operations.md#procserv) or systemd, shipped to a central aggregator |
| **`errlog`** | EPICS's internal error channel — every `errlogPrintf` from Base and modules | Also on stdout; can be forwarded to a central `iocLogServer` |
| **`iocLogServer`** | Base's own log collector: IOCs send `errlog` messages over the network to one host | Simple and effective; many facilities use syslog instead |
| **[caPutLog](#caputlog)** | Writes | Central log store |
| **[Alarm logger](alarms.md#alarm-logger)** | Alarm transitions and acknowledgements | Elasticsearch |
| **[iocStats](soft-support-modules.md#iocstats--deviocstats)** | IOC health as PVs | The [archiver](archiving.md), and [Grafana](observability.md) |
| **Host logs** | OS, network, hardware, NTP | Standard IT log aggregation |

**Get all of these into one searchable place.** During an incident you want a single timeline spanning "the IOC restarted", "the alarm fired", "someone wrote a setpoint", "the host lost its network link" and "an operator wrote a logbook entry". Assembling that timeline from six disconnected systems, at 03:00, is how short incidents become long ones.

The corollary is that **timestamps must agree** — see [Timing Systems](timing-systems.md). A log aggregation built on unsynchronised clocks produces a timeline that is confidently wrong about causality.

## What belongs where

| Event | Goes to |
| --- | --- |
| An operator changed a setpoint | [caPutLog](#caputlog) (automatic) |
| An operator changed a setpoint *and why* | Olog / ELOG (human) |
| A value went out of range | [Archiver](archiving.md) + [alarm log](alarms.md) (automatic) |
| An IOC crashed and restarted | IOC log + [iocStats](soft-support-modules.md#iocstats--deviocstats) (automatic) |
| A subsystem was worked on during maintenance | Logbook, with what was done and what to watch for |
| An unexplained beam dump | Logbook entry linking to the archiver time range and the alarm log |
| A configuration was changed | [Alarm config logger](alarms.md#alarm-config-logger) for alarms; git for everything else |
| A shift handover | Logbook |

## Guidance

**Automate everything that can be automated.** Humans reliably log the interesting 10% and omit the routine 90% that turns out to matter. caPutLog, the archiver, iocStats and the alarm logger cost nothing per event and never forget.

**Make human logging nearly free.** Phoebus's "send this screenshot to the logbook" button is worth more than any policy requiring documentation.

**Log the "why", not the "what".** The what is already captured automatically. `"Raised QF current 2.5 A to compensate the tune shift from ID07 closing"` is irreplaceable; `"changed QF current"` duplicates caPutLog with less precision.

**Search is the whole value.** A logbook nobody can search is a diary. Tags, structured properties, and full-text indexing are what make it an operational tool, and they must be designed rather than accumulated.

**Retain forever.** Text and metadata are trivially small. Logbook entries from a decade ago are read during commissioning of the next machine, and every facility that pruned its logs regrets it.

**Be careful what you attach.** Personal data, credentials in a pasted config, unpublished scientific results — logbooks are widely readable and permanently retained. Have a stated policy, and mean the joke at the top of this page.

## Next

→ [Gateways](gateways.md)
