# The Toolbox

The catalogue. Every significant piece of the EPICS ecosystem, what it does, who maintains it, and where to get it.

**How to use this section:** don't read it top to bottom. Skim this index once so the names become familiar, then come back when you have a specific problem. Nobody deploys all of this — a small beamline runs Base, asyn, StreamDevice, autosave and Phoebus, and that's a complete control system.

## Where things live

| Organisation | What's there |
| --- | --- |
| [github.com/epics-base](https://github.com/epics-base) | Base, PVXS, p4p, pvaPy, epicsCoreJava, ci-scripts — core, maintained by the core developers |
| [github.com/epics-modules](https://github.com/epics-modules) | Support modules: asyn, autosave, calc, motor, modbus, iocStats, sscan, busy, and ~60 more |
| [github.com/epics-extensions](https://github.com/epics-extensions) | Host-side tools: ca-gateway, MEDM, EDM, VDCT, StripTool |
| [github.com/areaDetector](https://github.com/areaDetector) | Detector and camera drivers — its own organisation, that's how many there are |
| [github.com/ControlSystemStudio](https://github.com/ControlSystemStudio) | Phoebus and the Java services (archiver, alarm, save/restore, scan) |
| [github.com/ChannelFinder](https://github.com/ChannelFinder) | ChannelFinder, recsync, pvinfo |
| [github.com/Olog](https://github.com/Olog) | The Olog electronic logbook |
| [github.com/epics-containers](https://github.com/epics-containers) | Container-based deployment, ibek, PVI |
| [github.com/paulscherrerinstitute](https://github.com/paulscherrerinstitute) | StreamDevice, pcaspy, s7plc, and much else from PSI |
| [github.com/DiamondLightSource](https://github.com/DiamondLightSource) | pythonSoftIOC, aioca, and Diamond's module ecosystem |
| [github.com/slaclab](https://github.com/slaclab) | PyDM, Badger, and SLAC's stack |
| [github.com/EPICS-synApps](https://github.com/EPICS-synApps) | synApps — a curated, tested bundle of the above |
| [epics-controls.org](https://epics-controls.org) | The community's front door, including the [module directories](https://epics-controls.org/resources-and-support/modules/) |

## The categories

| Page | Answers the question |
| --- | --- |
| [Base & IOCs](base-and-iocs.md) | What's in the core, and what tools come with it? |
| [Soft Support Modules](soft-support-modules.md) | How do I add records, persistence, statistics, calculations? |
| [Hardware Support Modules](hardware-support-modules.md) | How do I talk to *this specific* device? |
| [PLCs & Fieldbus](plc-and-fieldbus.md) | How do I talk to industrial equipment? |
| [Motion Control](motion.md) | How do I move something? |
| [Detectors & Imaging](detectors-and-imaging.md) | How do I take pictures and handle the data rate? |
| [Timing Systems](timing-systems.md) | How do things happen at the same time across the facility? |
| [Client Libraries](client-libraries.md) | How do I write a program that talks to EPICS? |
| [Operator Interfaces](operator-interfaces.md) | How do I build screens? |
| [Web Interfaces](web-interfaces.md) | How do I see PVs in a browser? |
| [Archiving](archiving.md) | How do I know what happened yesterday? |
| [Alarms](alarms.md) | How does an operator find out something's wrong? |
| [Directory Services](directory-services.md) | Which IOC serves this PV, and what else is like it? |
| [Save & Restore](save-and-restore.md) | How do I get back to a known configuration? |
| [Electronic Logbooks](logbooks.md) | Who did what, when, and why? |
| [Gateways](gateways.md) | How do I cross a network boundary safely? |
| [Scanning & Automation](scanning-and-automation.md) | How do I run a sequence without a human? |
| [Simulation & Testing](simulation-and-testing.md) | How do I develop without the hardware, and test what I wrote? |
| [Scientific Data](scientific-data.md) | How does experiment data get from detector to publication? |
| [Physics & Optimisation](physics-and-optimization.md) | How do accelerator physicists drive the machine? |
| [Deployment & Operations](deployment-and-operations.md) | How do I run 300 IOCs without going mad? |
| [Observability](observability.md) | Is the control system itself healthy? |

## Quick index: "I need a tool that…"

<div class="annotate" markdown>

| I need to… | Use |
| --- | --- |
| serve a PV with no hardware | `softIoc` / `softIocPVA` ([Base](base-and-iocs.md)) |
| talk to a serial or TCP instrument | [StreamDevice](plc-and-fieldbus.md#streamdevice) over [asyn](soft-support-modules.md#asyn) |
| talk to an Allen-Bradley PLC | [ether_ip](plc-and-fieldbus.md#ether_ip-allen-bradley) |
| talk to a Siemens PLC | [s7plc](plc-and-fieldbus.md#s7plc) or [opcua](plc-and-fieldbus.md#opc-ua) |
| talk to anything with Modbus | [modbus](plc-and-fieldbus.md#modbus) |
| move a motor | [motor](motion.md) |
| run a camera or detector | [areaDetector](detectors-and-imaging.md) |
| survive an IOC reboot with settings intact | [autosave](soft-support-modules.md#autosave) |
| build an operator screen | [Phoebus](operator-interfaces.md#phoebus) or [PyDM](operator-interfaces.md#pydm) |
| put a screen in a browser | [DBWR](web-interfaces.md#dbwr-display-builder-web-runtime) + [PVWS](web-interfaces.md#pvws-pv-web-socket) |
| plot history | [Archiver Appliance](archiving.md#epics-archiver-appliance) + [Grafana plugin](archiving.md#grafana-integration) |
| annunciate alarms | [Phoebus alarm system](alarms.md#phoebus-alarm-system) |
| find PVs by property | [ChannelFinder](directory-services.md) |
| know which IOC owns a PV | [recsync](directory-services.md#recsync) → ChannelFinder |
| snapshot and restore machine settings | [save & restore](save-and-restore.md) |
| log who wrote what | [caPutLog](logbooks.md#caputlog) |
| keep a shift log | [Olog](logbooks.md#olog) or [ELOG](logbooks.md#psi-elog) |
| expose PVs read-only to another network | [CA Gateway](gateways.md#ca-gateway) / [p4p gateway](gateways.md#p4p-pva-gateway) |
| write a state machine in the IOC | [Sequencer / SNL](scanning-and-automation.md#sequencer-snl) |
| run a multi-dimensional scan | [sscan](scanning-and-automation.md#sscan), [scan server](scanning-and-automation.md#phoebus-scan-server), or [Bluesky](scientific-data.md#bluesky) |
| script EPICS from Python | [PyEpics](client-libraries.md#pyepics), [caproto](client-libraries.md#caproto), [p4p](client-libraries.md#p4p), [aioca](client-libraries.md#aioca) |
| write modern C++ against PVA | [PVXS](client-libraries.md#pvxs) |
| fake a device that doesn't exist yet | [Lewis](simulation-and-testing.md#lewis), [pcaspy](simulation-and-testing.md#pcaspy) |
| write an IOC in Python | [pythonSoftIOC](simulation-and-testing.md#pythonsoftioc) |
| keep an IOC running and consoled | [procServ](deployment-and-operations.md#procserv) |
| deploy IOCs as containers | [epics-containers](deployment-and-operations.md#epics-containers) + [ibek](deployment-and-operations.md#ibek) |
| get a tested set of modules | [synApps](deployment-and-operations.md#synapps) |
| monitor IOC health | [iocStats](soft-support-modules.md#iocstats--deviocstats) → [Grafana/Prometheus](observability.md) |
| write experiment data as NeXus/HDF5 | [areaDetector HDF5 plugin](detectors-and-imaging.md#file-writing-plugins) or [Bluesky](scientific-data.md#bluesky) |
| optimise machine performance online | [Xopt](physics-and-optimization.md#xopt), [Badger](physics-and-optimization.md#badger), [Ocelot](physics-and-optimization.md#ocelot) |

</div>

## A note on choosing

You will repeatedly face "there are four tools for this". General guidance:

**Prefer what your facility already runs.** The operational cost of a second archiver, or a second GUI toolkit, dwarfs any technical advantage. Being the only person running a tool means being its sole maintainer.

**Prefer what's actively maintained.** Check the commit history, not the README. Several widely-installed EPICS tools have not had a commit in years — sometimes because they're finished, sometimes because they're abandoned, and the distinction matters when you hit a bug.

**Prefer no code.** A [StreamDevice](plc-and-fieldbus.md#streamdevice) protocol file beats C device support. A [calc](soft-support-modules.md#calc) record beats a Python script. Declarative configuration survives staff turnover; clever code does not.

**Prefer the boring option for anything operational.** Novelty is fine in analysis tooling, where a failure costs an afternoon. In the path between an operator and a magnet, choose the thing that has been running somewhere else for ten years.
