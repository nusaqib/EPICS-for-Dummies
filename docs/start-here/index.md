# Start Here

You are about to learn a control system that has been in continuous development since 1988, is deployed at several hundred facilities, and has no single installer. That's fine. Thousands of people have done it, most of them from a physics or engineering background rather than a software one.

This section is the on-ramp.

| Page | What it gives you |
| --- | --- |
| [What is EPICS?](what-is-epics.md) | The 10-minute version. What problem it solves, who uses it, what it is *not*. |
| [Core Concepts](core-concepts.md) | Process variables, records, the database, IOCs, Channel Access, PV Access. The vocabulary everything else assumes. |
| [Linux Prerequisites](linux-prerequisites.md) | The shell, paths, environment variables, and build tools you need before compiling anything. |
| [Glossary](glossary.md) | Every acronym in this guide, expanded. |
| [FAQ](faq.md) | The questions every newcomer asks on the mailing list. |

## A realistic learning path

Nobody learns EPICS by reading. You learn it by making a number change on a screen and then working out why.

=== "Week 1 — Get a PV to move"

    **Goal: understand what a process variable is by owning one.**

    1. Read [What is EPICS?](what-is-epics.md) and [Core Concepts](core-concepts.md). Don't try to memorise; you'll come back.
    2. Get EPICS Base onto a Linux machine — either [build it](../build-install/epics-base.md) (30 minutes, teaches you the build system) or `conda install epics-base` / grab a [training VM](../reference/training.md) (5 minutes, teaches you nothing but gets you moving).
    3. Run `softIoc` with no arguments. Type `dbl` at the `epics>` prompt. Nothing there yet.
    4. Follow [Your First IOC](../build-install/first-ioc.md) to create two records and watch one drive the other.
    5. In a second terminal: `caget`, `caput`, `camonitor` your records. See the [cheat sheet](../reference/cheatsheet.md).

    **You have finished week 1 when** you can explain, out loud, what happened between `caput` in one terminal and the value changing in the other.

=== "Week 2 — Make a screen"

    **Goal: connect a GUI to your IOC.**

    1. [Install Phoebus](../build-install/phoebus.md) (Java) or `pip install pydm` ([PyDM](../toolbox/operator-interfaces.md), Python). Either is fine; Phoebus is what most facilities run.
    2. Build a display with a text-entry widget and a meter bound to your two PVs.
    3. Break it deliberately: stop the IOC and watch the widgets go disconnected (pink/white, depending on the toolkit). That disconnect behaviour is a feature, and understanding it early saves hours later.
    4. Read [Protocols](../architecture/protocols.md) up to the section on search and connect, so you know what "disconnected" actually means on the wire.

=== "Week 3 — Talk to something real"

    **Goal: an IOC that isn't making its numbers up.**

    Pick whichever you can get your hands on:

    - A serial or Ethernet instrument (power supply, temperature controller, pressure gauge) → [StreamDevice](../toolbox/plc-and-fieldbus.md#streamdevice) over [asyn](../toolbox/soft-support-modules.md#asyn).
    - A PLC → [Modbus](../toolbox/plc-and-fieldbus.md#modbus), [ether_ip](../toolbox/plc-and-fieldbus.md#ether_ip-allen-bradley) or [opcua](../toolbox/plc-and-fieldbus.md#opc-ua).
    - A USB webcam → [areaDetector](../toolbox/detectors-and-imaging.md) with ADUVC, or `ADSimDetector` if you have no camera.
    - Nothing at all → simulate a device with [Lewis](../toolbox/simulation-and-testing.md#lewis) and talk to it over TCP as if it were real. This is genuinely how a lot of facility software gets developed.

    You will spend most of this week on protocol details and terminator characters. That is the job.

=== "Week 4 — Add the services"

    **Goal: see why a facility needs more than IOCs.**

    1. Archive your PVs: the [Phoebus RDB archive engine](../toolbox/archiving.md#phoebus-rdb-archive-engine) is easier for a first run; the [Archiver Appliance](../toolbox/archiving.md#epics-archiver-appliance) is what scales. Plot a trend of yesterday.
    2. Put one PV into an [alarm state](../toolbox/alarms.md) and acknowledge it in the Phoebus alarm tree.
    3. Snapshot and restore your PV values with [save & restore](../toolbox/save-and-restore.md), or crash-proof your IOC with [autosave](../toolbox/soft-support-modules.md#autosave).
    4. Skim [The Toolbox](../toolbox/index.md) index in full — one pass, no depth. You now have hooks to hang the names on.

=== "Month 2+ — Think like a facility"

    **Goal: understand the decisions, not just the commands.**

    1. Read the [Example Facility](../example-facility/index.md) chapters in order. This is where naming, segmentation, sizing, and alarm philosophy stop being abstract.
    2. Read the [EPICS Application Developer's Guide](../reference/documentation.md) properly. Yes, all of it. It is the actual specification and it is readable.
    3. Work through a real training course: the [USPAS and EPICS Collaboration Meeting material](../reference/training.md) is free, complete, and has exercises.
    4. Subscribe to [tech-talk](../reference/community.md). Lurk for a month. The archive is the largest EPICS troubleshooting corpus in existence.
    5. Learn how your site actually deploys IOCs — [containers](../toolbox/deployment-and-operations.md#epics-containers), [e3](../toolbox/deployment-and-operations.md#e3-ess-epics-environment), plain `make` and `procServ`, or something homegrown. This is the most site-specific knowledge you will acquire, and none of it is in this guide.

## Three things that will confuse you, stated up front

**1. "EPICS" means two different things.** Sometimes it means EPICS Base, the core library. Sometimes it means the whole ecosystem — Base plus modules plus Phoebus plus the archiver plus everything in [the Toolbox](../toolbox/index.md). When someone says "we run EPICS 7", they mean Base 7. When someone says "the EPICS ecosystem", they mean the other thing.

**2. There are two network protocols and both are current.** Channel Access (CA) dates from the early 1990s and carries the overwhelming majority of production traffic. PV Access (PVA) arrived with EPICS 7, carries structured data, and is what new services target. Neither replaces the other yet. See [Protocols](../architecture/protocols.md).

**3. Version numbers are per-module and unrelated.** Base is at 7.0.x. asyn, autosave, motor, areaDetector, Phoebus and everything else version independently, and any given combination may or may not have been tested together. Curated bundles like [synApps](../toolbox/deployment-and-operations.md#synapps) exist precisely because this is a real problem.
