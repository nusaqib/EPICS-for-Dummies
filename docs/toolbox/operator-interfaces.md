# Operator Interfaces

Screens. There is a history of these in EPICS — MEDM (1990s), EDM (2000s), CS-Studio (2010s), Phoebus (2020s) — and all four are still running somewhere.

## Phoebus

**The current mainstream choice.**

| | |
| --- | --- |
| Source | [github.com/ControlSystemStudio/phoebus](https://github.com/ControlSystemStudio/phoebus) |
| Documentation | [control-system-studio.readthedocs.io](https://control-system-studio.readthedocs.io/) |
| Technology | Java 17+, JavaFX |
| This guide | [Build Phoebus](../build-install/phoebus.md) |

Phoebus is the Eclipse-free successor to Control System Studio: same toolset, none of the Eclipse RCP/SWT dependency that made CS-Studio heavy to build and awkward to deploy.

It is not just a display tool — it's an application platform:

| Application | Purpose |
| --- | --- |
| **Display Builder** | The OPI editor and runtime. `.bob` files; imports MEDM `.adl`, EDM `.edl`, and legacy CS-Studio `.opi`. |
| **Data Browser** | Live and archived trending, against the [RDB archiver](archiving.md#phoebus-rdb-archive-engine) or [Archiver Appliance](archiving.md#epics-archiver-appliance) |
| **Alarm Tree / Table / Panel** | The UI for the [Phoebus alarm system](alarms.md) |
| **PV Table / PV Tree** | Inspect many PVs at once; walk a record's links graphically — the best available tool for understanding an unfamiliar database |
| **Save & Restore** | UI for the [save/restore service](save-and-restore.md) |
| **Olog / Logbook** | [Electronic logbook](logbooks.md#olog) integration |
| **Scan** | Client for the [scan server](scanning-and-automation.md#phoebus-scan-server) |
| **Channel Table / ChannelFinder** | [Directory service](directory-services.md) queries |
| **Probe, Perspectives, Scripting** | Quick PV inspection, saved layouts, Python/JavaScript inside displays |

**Why it wins on balance:** one tool covers displays, trends, alarms, logbook and save/restore, so an operator learns one thing; it speaks both CA and PVA through a clean `core-pv` abstraction; displays are portable across facilities; and the same `.bob` files render in a browser via [DBWR](web-interfaces.md#dbwr-display-builder-web-runtime), which is a genuinely valuable property.

**Costs:** it's a large Java application (JavaFX, so a real desktop install), the build has a dependency-fetch step that surprises people, and the documentation assumes more EPICS context than a newcomer has.

## PyDM

| | |
| --- | --- |
| Documentation | [slaclab.github.io/pydm](https://slaclab.github.io/pydm/) |
| Source | [github.com/slaclab/pydm](https://github.com/slaclab/pydm) |
| Origin | SLAC |
| Technology | Python, PyQt/Qt Designer |

Python Display Manager: build screens in Qt Designer, or write them in Python. `pip install pydm` and you're running.

**Choose it when** your team is Python-fluent, you want screens that are *programs* rather than documents, or you need tight integration with Python analysis code. A PyDM screen embedding a matplotlib plot driven by your own analysis of live PVs is straightforward, and awkward in any other toolkit.

**Trade-offs:** a screen with logic in it is code — versioned, reviewed, and debuggable, but also a thing that can break in ways a declarative display can't. PyDM screens aren't portable to other toolkits, and it has a smaller (though active) community than Phoebus. Adopted well beyond SLAC.

## caQtDM

| | |
| --- | --- |
| Source | [github.com/caqtdm/caqtdm](https://github.com/caqtdm/caqtdm) |
| Origin | PSI (Anton Mezger, Helge Brands) |
| Technology | C++, Qt |

A Qt display manager that **reads MEDM `.adl` files directly**, which is why it exists: facilities with thousands of legacy MEDM screens got a modern, fast, native viewer without a migration project.

**Choose it for:** MEDM legacy, low resource use, embedded or touch-panel displays, and mobile/tablet operation (it has Android support). Popular at PSI and across European facilities. Fast and light in a way Java tools are not.

## MEDM and EDM

| Tool | Status |
| --- | --- |
| **MEDM** — Motif Editor and Display Manager | The original. `.adl` files. [github.com/epics-extensions/medm](https://github.com/epics-extensions/medm). Still installed nearly everywhere, still occasionally the fastest thing available, and the source of an enormous body of existing screens. |
| **EDM** — Extensible Display Manager | ORNL/SNS's Motif tool, `.edl` files. [github.com/epics-extensions/edm](https://github.com/epics-extensions/edm). Still in production at several facilities. |

Neither is a reasonable choice for new work — Motif, X11-era look, and increasingly hard to build on modern distributions. Both matter because **you will inherit their files**. Phoebus and caQtDM both import `.adl`; Phoebus imports `.edl`. Converted screens always need cleanup, so treat conversion as a starting point rather than a migration.

## CS-Studio (Eclipse)

The Eclipse RCP predecessor to Phoebus: [github.com/ControlSystemStudio/cs-studio](https://github.com/ControlSystemStudio/cs-studio). Historically important, effectively superseded. If a facility mentions "CSS" they may mean this or Phoebus, and it's worth asking which.

## Choosing

| If… | Then |
| --- | --- |
| You're starting fresh at a facility with no existing screens | **Phoebus**. Broadest toolset, most active, best future-proofing. |
| Your team lives in Python and wants logic in displays | **PyDM** |
| You have thousands of MEDM `.adl` files and no migration budget | **caQtDM** (or Phoebus's importer, if you *do* have budget) |
| You need screens in a browser, on tablets, off-site | **Phoebus + [DBWR](web-interfaces.md#dbwr-display-builder-web-runtime)**, or [PVWS](web-interfaces.md#pvws-pv-web-socket) with your own front end |
| Your facility already standardised on one | **That one.** This is not a decision worth being the exception on. |

## Screen design guidance

More consequential than the toolkit choice, and much more often got wrong. Screens are how operators understand the machine at 03:00 under stress.

**Show what it is, not what you asked for.** Readbacks prominent, setpoints editable but visually secondary. If both are shown, make which-is-which unmistakable. See [setpoint vs readback](../architecture/naming-conventions.md#setpoint-versus-readback).

**Make disconnection obvious.** Every toolkit marks disconnected widgets distinctively. Never override that with your own styling, and never design a widget that looks the same connected and disconnected — a stale value presented as live is the most dangerous thing a screen can do.

**Show alarm state, not just values.** Colour by `SEVR`. An operator scanning a synoptic should see *where* the problem is before reading any numbers.

**Put units on everything.** `EGU` is a record field; every toolkit can display it. A number without units is an invitation to a mistake.

**Design a hierarchy: overview → subsystem → device.** One synoptic showing machine state, drilling to subsystem screens, drilling to device detail. Operators navigate by structure, and a flat pile of 400 screens is unnavigable regardless of how good each one is.

**Don't put logic in screens.** A screen that computes an interlock, or holds a state machine, only works while it's open on somebody's desktop. That logic belongs in the [database](../architecture/process-database.md). This is the single most common architectural mistake in operator interfaces.

**Use templates and macros.** One display with `$(P)` and `$(R)` macros, opened 176 times with different arguments, beats 176 near-identical files — the same argument as [database templates](../architecture/process-database.md#templates-and-substitutions), for the same reasons.

**Version-control the screens.** They are configuration, not artefacts. A facility whose screens live only on a shared drive has no history of what an operator was looking at last Tuesday.

**Ask the operators.** They use these twelve hours a day. They know which screen is unusable and why, and they are rarely asked. This produces better results than any style guide.

## Next

→ [Web Interfaces](web-interfaces.md)
