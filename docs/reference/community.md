# Community

EPICS is thirty-five years old and maintained by people who answer questions. That combination is unusual and it is the ecosystem's most valuable asset.

## tech-talk

**The main mailing list.** Where you ask, and where core developers answer.

| | |
| --- | --- |
| Archive | [epics.anl.gov/tech-talk](https://epics.anl.gov/tech-talk/) |
| Subscribe | See [epics-controls.org support](https://epics-controls.org/resources-and-support/support/) |

Two things to know:

**Search the archive first.** It is the largest EPICS troubleshooting corpus in existence — thirty years of "why doesn't this work?" with answers, well indexed by search engines. Your question is probably already answered, often by the person who wrote the code.

**When you do post, post well.** Include:

1. EPICS Base version and relevant module versions
2. Platform — distribution, kernel, architecture
3. The actual error text, pasted, not paraphrased
4. The relevant `.db` and `st.cmd` fragments
5. `dbpr <record> 4` output for the record in question
6. What you already tried

A well-formed question usually gets a useful answer within hours. A vague one gets asked to clarify, which costs everyone a day.

**core-talk** is the developers' list, for Base internals and development discussion. Read it if you're contributing to Base; don't ask usage questions there.

## GitHub

Issues and discussions on the relevant repository are increasingly where project-specific conversation happens — particularly for [Phoebus](https://github.com/ControlSystemStudio/phoebus), [epics-containers](https://github.com/epics-containers), [Bluesky](https://github.com/bluesky), and the [Archiver Appliance](https://github.com/archiver-appliance/epicsarchiverap).

For a question about one project, its GitHub issues are often better than tech-talk. For a question about EPICS in general, tech-talk.

## Meetings

| Event | |
| --- | --- |
| **[EPICS Collaboration Meetings](https://epics-controls.org/news-and-events/meetings/)** | Roughly twice a year, rotating between regions. Talks, tutorials, and the place where cross-facility work gets agreed. Slides are published. |
| **[Codeathons / Documentathons](https://epics-controls.org/news-and-events/codeathons/)** | Working sessions. The most efficient way to learn from experienced people, and to make a first contribution. |
| ICALEPCS | The broader accelerator and physics controls conference, biennial. Substantial EPICS content, and [published proceedings](books-and-papers.md). |
| Regional meetings | Europe, Asia and North America hold their own. |

Even if you can't attend, **the published slides from Collaboration Meetings are one of the best sources on current work** — they cover things not yet in any documentation, and they show you what facilities are actually doing rather than what the manuals describe.

## The GitHub organisations

| Organisation | Contents |
| --- | --- |
| [epics-base](https://github.com/epics-base) | Base, PVXS, p4p, pvaPy, epicsCoreJava, ci-scripts |
| [epics-modules](https://github.com/epics-modules) | Support modules: asyn, autosave, calc, motor, modbus, iocStats, and ~60 more |
| [epics-extensions](https://github.com/epics-extensions) | Host tools: ca-gateway, MEDM, EDM, VDCT, StripTool |
| [areaDetector](https://github.com/areaDetector) | Detector and camera drivers |
| [ControlSystemStudio](https://github.com/ControlSystemStudio) | Phoebus and the Java services |
| [ChannelFinder](https://github.com/ChannelFinder) | ChannelFinder, recsync, pvinfo |
| [Olog](https://github.com/Olog) | The electronic logbook |
| [epics-containers](https://github.com/epics-containers) | Container deployment, ibek, PVI |
| [EPICS-synApps](https://github.com/EPICS-synApps) | The curated module bundle |
| [epics-docs](https://github.com/epics-docs) | The documentation source |
| [archiver-appliance](https://github.com/archiver-appliance) | The Archiver Appliance |
| [caproto](https://github.com/caproto) · [pyepics](https://github.com/pyepics) | Python client libraries |
| [bluesky](https://github.com/bluesky) | Bluesky, ophyd, databroker, Tiled |

Facility organisations publishing substantial EPICS work: [DiamondLightSource](https://github.com/DiamondLightSource), [paulscherrerinstitute](https://github.com/paulscherrerinstitute), [slaclab](https://github.com/slaclab), [NSLS-II](https://github.com/NSLS-II), [ISISComputingGroup](https://github.com/ISISComputingGroup), [pcdshub](https://github.com/pcdshub) (SLAC LCLS), and ESS on [gitlab.esss.lu.se](https://gitlab.esss.lu.se).

Facilities publish far more than they announce. If you need something, look at three or four facility organisations before writing it.

## How to contribute

You do not need to be an expert. In rough order of accessibility:

**Answer a question on tech-talk.** If you solved a problem last week, and someone asks about it this week, you are the best-placed person to answer. This is genuinely valuable and consistently underdone by newer members.

**Fix documentation.** [epics-docs](https://github.com/epics-docs/epics-docs) takes pull requests. So does every project's README. A newcomer knows exactly which sentence was confusing, and that knowledge evaporates within six months.

**Publish your device support.** You wrote a [StreamDevice](../toolbox/plc-and-fieldbus.md#streamdevice) protocol for an instrument. Someone else has that instrument. Put it on GitHub, mention it on tech-talk, and add it to the [hardware support directory](https://epics-controls.org/resources-and-support/modules/hardware-support/). The entire ecosystem is built from people who did this.

**Report bugs properly.** With a reproducer. Maintainers are responsive and mostly volunteering their time; a good bug report is a gift.

**Come to a codeathon.** Designed for exactly this.

**Add to the module directories.** The hardware support database is only as good as its submissions.

## Norms worth knowing

**Questions are welcome, including basic ones.** The community remembers that everyone arrives from a physics or engineering background rather than a software one. "How do I talk to this power supply?" is a normal question, not a burden.

**People share freely.** Protocol files, database templates, screens, configurations — ask and you'll usually be given. This is a small field where everyone is solving the same problems.

**Facility context matters.** "How do you deploy IOCs?" gets six different answers because there are six reasonable approaches. Saying which facility you're at, or what constraints you're under, gets you a relevant answer instead of a survey.

**Old code is not necessarily abandoned.** A module with no commits in four years may be finished. Check the issues, not just the commit date, and ask on tech-talk if it matters.

**Version numbers are per-module and unrelated.** Nobody can tell you "the EPICS 2026 stack". Compatible sets exist by testing — which is what [synApps](../toolbox/deployment-and-operations.md#synapps) is for.

## Getting help, by question type

| Question | Where |
| --- | --- |
| "Why doesn't this work?" | tech-talk, after searching the archive |
| "Is there a module for this device?" | The [hardware support directory](https://epics-controls.org/resources-and-support/modules/hardware-support/), then tech-talk |
| A bug in a specific project | That project's GitHub issues |
| Base internals or development | core-talk |
| "How do other facilities do X?" | tech-talk, or Collaboration Meeting slides |
| "How does *my* facility do X?" | Your colleagues. This is the most site-specific knowledge there is, and none of it is on the internet. |
| Something in this guide is wrong | [Issues here](https://github.com/nusaqib/EPICS-for-Dummies/issues) |
