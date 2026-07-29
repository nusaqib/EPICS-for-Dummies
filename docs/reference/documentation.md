# Official Documentation

Where to go when this guide isn't enough — which for anything authoritative is immediately.

## Start here

| Resource | What it is |
| --- | --- |
| **[epics-controls.org](https://epics-controls.org)** | The community's front door. Downloads, module directories, news, meetings. |
| **[docs.epics-controls.org](https://docs.epics-controls.org)** | The modern consolidated documentation site. **This is the canonical reference.** |
| [epics.anl.gov](https://epics.anl.gov) | The historic Argonne site. Still hosts some documents that exist nowhere else, including version-specific manuals. |
| [github.com/epics-docs/epics-docs](https://github.com/epics-docs/epics-docs) | The documentation's own source. Corrections go here. |

## The core manuals

| Document | Read it for |
| --- | --- |
**[EPICS Application Developer's Guide](https://docs.epics-controls.org/en/latest/appdevguide/AppDevGuide.html)** | **The specification.** Database, records, device support, CA, access security, the build system. Chapters 3–6 are the essential part, and it is more readable than its length suggests. |
| [AppDevGuide PDF, Base 3.16.2](https://epics.anl.gov/base/R3-16/2-docs/AppDevGuide.pdf) | The complete, older PDF. Some readers prefer it, and it covers material the web version hasn't fully absorbed. |
| **[Record Reference Manual](https://epics.anl.gov/base/R7-0/6-docs/RecordReference.html)** | Every field of every standard record type. Keep it bookmarked. |
| **[Channel Access Reference Manual](https://epics.anl.gov/base/R3-14/8-docs/CAref.html)** | The CA protocol, the C API, and the complete environment-variable list. |
| [EPICS Process Database Concepts](https://docs.epics-controls.org/en/latest/guides/EPICS_Process_Database_Concepts.html) | The conceptual introduction to records, links and processing. Read this before the AppDevGuide. |
| [What is EPICS](https://docs.epics-controls.org/en/latest/guides/EPICS_Intro.html) | The official overview |
| [How-to guides](https://docs.epics-controls.org/en/latest/getting-started/EPICS_Intro.html) | Installation and practical tasks, maintained upstream |

If you read one document properly, make it the **Application Developer's Guide**. It's the difference between using EPICS and understanding it.

## PV Access and EPICS 7

| Document | Covers |
| --- | --- |
| [PV Access protocol specification](https://docs.epics-controls.org/en/latest/pv-access/protocol.html) | The wire protocol |
| [Normative Types specification](https://docs.epics-controls.org/en/latest/pv-access/Normative-Types-Specification.html) | `NTScalar`, `NTNDArray`, `NTTable` and the rest — what makes structured data interoperable |
| [PVXS documentation](https://epics-base.github.io/pvxs/) | The modern C++ PVA library |
| [p4p documentation](https://epics-base.github.io/p4p/) | Python PVA, client, server and gateway |

## Base source and releases

| Resource | |
| --- | --- |
| [github.com/epics-base/epics-base](https://github.com/epics-base/epics-base) | Source |
| [Base downloads and release notes](https://epics-controls.org/resources-and-support/base/) | Which version, and what changed |
| [github.com/epics-base](https://github.com/epics-base) | The core organisation: PVXS, p4p, pvaPy, epicsCoreJava, ci-scripts |

Release notes are worth reading before an upgrade. Base is careful about compatibility, and the exceptions are documented there rather than discovered.

## Module directories

| Directory | Contents |
| --- | --- |
| **[Soft support modules](https://epics-controls.org/resources-and-support/modules/soft-support/)** | Record types, software-only support, in-IOC services |
| **[Hardware support modules](https://epics-controls.org/resources-and-support/modules/hardware-support/)** | **Searchable by manufacturer and model.** Check here before writing device support. |
| [github.com/epics-modules](https://github.com/epics-modules) | Where most of them live |
| [github.com/epics-extensions](https://github.com/epics-extensions) | Host-side tools |
| [github.com/areaDetector](https://github.com/areaDetector) | Detector and camera drivers |
| [github.com/EPICS-synApps](https://github.com/EPICS-synApps) | The curated, tested bundle |

## Major project documentation

| Project | Documentation |
| --- | --- |
| **Phoebus / CS-Studio** | [control-system-studio.readthedocs.io](https://control-system-studio.readthedocs.io/) — also covers the archive engine, alarm services, save & restore and scan server |
| **Archiver Appliance** | [epicsarchiver.readthedocs.io](https://epicsarchiver.readthedocs.io/) |
| **ChannelFinder** | [channelfinder.github.io](https://channelfinder.github.io/) |
| **asyn** | [epics-modules.github.io/asyn](https://epics-modules.github.io/asyn/) |
| **StreamDevice** | [paulscherrerinstitute.github.io/StreamDevice](https://paulscherrerinstitute.github.io/StreamDevice/) |
| **areaDetector** | [areadetector.github.io](https://areadetector.github.io/areaDetector/) |
| **motor** | [epics-modules.github.io/motor](https://epics-modules.github.io/motor/) |
| **modbus** | [epics-modules.github.io/modbus](https://epics-modules.github.io/modbus/) |
| **Sequencer / SNL** | [epics-modules.github.io/sequencer](https://epics-modules.github.io/sequencer/) |
| **PyEpics** | [pyepics.github.io/pyepics](https://pyepics.github.io/pyepics/) |
| **caproto** | [caproto.github.io/caproto](https://caproto.github.io/caproto/) |
| **PyDM** | [slaclab.github.io/pydm](https://slaclab.github.io/pydm/) |
| **epics-containers** | [epics-containers.github.io](https://epics-containers.github.io/) |
| **Bluesky** | [blueskyproject.io](https://blueskyproject.io/) |
| **pythonSoftIOC** | [diamondlightsource.github.io/pythonSoftIOC](https://diamondlightsource.github.io/pythonSoftIOC/) |
| **e3 (ESS)** | [e3pages.readthedocs.io](https://e3pages.readthedocs.io/en/latest/) |

## Facility documentation worth reading

Several facilities publish controls documentation that is genuinely useful beyond their own walls:

| Facility | Notable for |
| --- | --- |
| **[SNS / ORNL controls](https://controlssoftware.sns.ornl.gov/)** | The best free EPICS [training material](training.md) in existence, plus practical guides |
| **[Diamond Light Source](https://github.com/DiamondLightSource)** | epics-containers, ibek, PVI, pythonSoftIOC, and a large module ecosystem |
| **[PSI](https://github.com/paulscherrerinstitute)** | StreamDevice, pcaspy, s7plc, and a distinctive module-loading approach |
| **[SLAC](https://github.com/slaclab)** | PyDM, Badger, and their timing and BSA work |
| **[NSLS-II](https://github.com/NSLS-II)** | Bluesky, ophyd, Tiled — the modern beamline data stack |
| **[ISIS](https://github.com/ISISComputingGroup)** | A thorough IOC testing framework and a large Lewis simulator collection |

## What this guide is for, versus these

This guide is a **map**: it tells you what exists, why it exists, and roughly how the pieces relate, so that when you open the Application Developer's Guide you know which chapter you need.

Everything above is **authoritative**. Where they and this guide disagree, they are right and this is out of date — [please say so](https://github.com/nusaqib/EPICS-for-Dummies/issues).

## Next

→ [Training Material](training.md) · [Community](community.md) · [Books & Papers](books-and-papers.md)
