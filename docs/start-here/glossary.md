# Glossary

Every acronym and term used in this guide. EPICS conversations are dense with these, and nobody expands them.

## A–C

**ADCore** — The core of [areaDetector](../toolbox/detectors-and-imaging.md); the plugin framework all detector drivers build on.

**ai / ao** — Analog input / analog output record types. The most common record types in existence.

**Alarm** — A record's abnormal-state indication, expressed as [severity and status](core-concepts.md#8-alarms-and-severity). Not the same as an interlock.

**Alias** — A second PV name for the same record, declared with `alias()`. Useful during renaming campaigns.

**ALH** — Alarm Handler. The legacy Motif alarm GUI, superseded by the [Phoebus alarm system](../toolbox/alarms.md).

**AOI** — Area of interest. A cropped region of a detector image, in areaDetector terms.

**APS** — Advanced Photon Source, Argonne National Laboratory. Co-birthplace of EPICS.

**Archiver Appliance** — The [scalable EPICS archiver](../toolbox/archiving.md#epics-archiver-appliance), originally from SLAC, now community-maintained.

**AS / ASG / ACF** — [Access Security](../architecture/access-security.md); Access Security Group; Access Configuration File. EPICS's built-in write-permission mechanism.

**asyn** — [The universal I/O abstraction module](../toolbox/soft-support-modules.md#asyn). Serial, TCP, UDP, GPIB, USB, and the `asynPortDriver` C++ base class.

**Autosave** — [Module](../toolbox/soft-support-modules.md#autosave) that periodically writes PV values to disk and restores them at IOC boot.

**Base** — [EPICS Base](../toolbox/base-and-iocs.md). The core: build system, libraries, protocol implementations, standard record types, `softIoc`.

**BEAST** — Best Ever Alarm System Toolkit. The CS-Studio-era alarm system; its successor is the Kafka-based Phoebus alarm system.

**Bluesky** — [Experiment orchestration framework](../toolbox/scientific-data.md#bluesky) from NSLS-II. Python; sits above EPICS.

**BPM** — Beam Position Monitor. In light sources, typically a four-button electrode assembly plus digitiser electronics.

**BSA / BSAS** — Beam Synchronous Acquisition (SLAC). Timestamp-correlated data capture across many IOCs.

**bi / bo** — Binary input / binary output record types. One bit, two states, named strings for each.

**CA** — [Channel Access](../architecture/protocols.md#channel-access-ca). The original EPICS network protocol.

**caget / caput / camonitor / cainfo** — The Channel Access command-line tools. See the [cheat sheet](../reference/cheatsheet.md).

**calc / calcout** — Record types evaluating an arithmetic/logical expression over up to twelve inputs. `calcout` can also write an output and act on a delay.

**caLab** — LabVIEW Channel Access bindings.

**caproto** — [Pure-Python Channel Access implementation](../toolbox/client-libraries.md#caproto), client and server.

**caPutLog** — [Module](../toolbox/logbooks.md#caputlog) that logs every Channel Access write: who, from where, old value, new value.

**caQtDM** — [Qt-based display manager](../toolbox/operator-interfaces.md#caqtdm); reads MEDM `.adl` files. Popular at PSI and in Europe.

**CATCA / CAJ** — Java Channel Access implementations, now inside `epicsCoreJava`.

**ChannelFinder** — [Directory service](../toolbox/directory-services.md) mapping PV names to properties and tags.

**CS-Studio** — Control System Studio. The Eclipse-based toolset; its modern, Eclipse-free successor is [Phoebus](../toolbox/operator-interfaces.md#phoebus).

**CPMU** — Cryogenic Permanent Magnet Undulator. An insertion device cooled to ~80 K for higher field.

## D–I

**DAQ** — Data acquisition.

**DBD** — Database Definition file. Declares record types, device supports, drivers, and menus available to an IOC.

**dbior / dbl / dbpr / dbtr** — IOC shell commands: report driver state, list records, print a record, test-process a record.

**DBWR** — [Display Builder Web Runtime](../toolbox/web-interfaces.md#dbwr-display-builder-web-runtime). Renders Phoebus displays in a browser.

**DCCT** — DC Current Transformer. Measures stored beam current non-destructively.

**Device support** — The layer adapting a record type to a device class, selected by the `DTYP` field.

**DTYP** — Device TYPe: the record field naming which device support to use.

**e3** — [ESS EPICS Environment](../toolbox/deployment-and-operations.md#e3-ess-epics-environment). ESS's module build and deployment framework.

**EDM** — Extensible Display Manager. Legacy Motif OPI tool; still in production at several labs.

**EGU** — Engineering UnitS. The record field holding the unit string.

**ELOG** — [Electronic logbook](../toolbox/logbooks.md#psi-elog), PSI's implementation.

**Emittance** — Beam phase-space area. Lower is better for a light source; the figure of merit for 4th-generation rings.

**epicsdeb** — [Debian/Ubuntu packaging](../toolbox/deployment-and-operations.md#distribution-packages) of EPICS Base and modules.

**epics-containers** — [Container-based IOC deployment framework](../toolbox/deployment-and-operations.md#epics-containers) from Diamond Light Source; includes `ibek` and PVI.

**ESS** — European Spallation Source, Lund, Sweden.

**ether_ip** — [Allen-Bradley ControlLogix/CompactLogix driver](../toolbox/plc-and-fieldbus.md#ether_ip-allen-bradley) speaking EtherNet/IP.

**EVG / EVR** — Event Generator / Event Receiver. [Timing system](../toolbox/timing-systems.md) hardware, typically Micro-Research Finland, driven by `mrfioc2`.

**FLNK** — Forward LiNK. The record field naming the next record to process after this one.

**FOFB** — Fast Orbit Feedback. kHz-rate closed loop holding the electron beam position stable. FPGA-based; EPICS configures and monitors it.

**Front end** — In a light source, the shielded assembly between the storage ring and a beamline: shutters, slits, masks, absorbers, valves.

**Gateway** — A [process bridging two network segments](../toolbox/gateways.md) at the CA or PVA level, usually adding access control and reducing server load.

**ibek** — [IOC Builder for EPICS and Kubernetes](../toolbox/deployment-and-operations.md#ibek). Generates `st.cmd` from YAML.

**ID** — Insertion Device. An undulator or wiggler in a straight section; the light source for most beamlines.

**INVALID** — The alarm severity meaning "this value cannot be trusted". Not a magnitude.

**I/O Intr** — A `SCAN` value: process when the driver says there's new data, rather than on a clock.

**IOC** — [Input/Output Controller](core-concepts.md#4-ioc-inputoutput-controller). A process that owns PVs and serves them on the network.

**iocStats / devIocStats** — [Module](../toolbox/soft-support-modules.md#iocstats-and-deviocstats) exposing IOC health as PVs: CPU, memory, uptime, CA client count.

**ipac** — IndustryPack carrier support for VME. Legacy but alive.

## J–P

**JCA** — Java Channel Access.

**LLRF** — Low-Level RF. The control loops regulating cavity amplitude and phase. FPGA-based; EPICS sets points and reads diagnostics.

**Lewis** — [Device simulation framework](../toolbox/simulation-and-testing.md#lewis) — pretends to be an instrument on a TCP or serial port.

**MASAR** — MAchine Snapshot, Archiving, and Retrieval. An earlier save/restore service.

**MBA** — Multi-Bend Achromat. The lattice design that defines 4th-generation storage rings.

**mbbi / mbbo** — Multi-Bit Binary In / Out. Enumerated record types: up to sixteen named states.

**MEDM** — Motif Editor and Display Manager. The original EPICS OPI tool; `.adl` files. Largely superseded, widely still installed.

**Modbus** — [Industrial protocol](../toolbox/plc-and-fieldbus.md#modbus) (TCP and serial) with an EPICS module of the same name.

**motor** — [The motion control module](../toolbox/motion.md). Provides the `motor` record and dozens of controller drivers.

**MPS** — Machine Protection System. Protects equipment from beam. Not EPICS. See [machine protection](../example-facility/machine-protection.md).

**mrfioc2** — [Driver](../toolbox/timing-systems.md#mrfioc2) for Micro-Research Finland timing hardware.

**NDArray / NDPlugin** — areaDetector's image buffer type and its plugin base class.

**NeXus** — [HDF5-based scientific data format](../toolbox/scientific-data.md#nexus) standard for neutron, X-ray and muon science.

**Normative types** — The standard PV Access structure definitions (`NTScalar`, `NTNDArray`, `NTTable`, …) that make structured data interoperable.

**NSLS-II** — National Synchrotron Light Source II, Brookhaven.

**Olog** — [Electronic logbook](../toolbox/logbooks.md#olog) integrated with Phoebus.

**ophyd / ophyd-async** — [Bluesky's device abstraction layer](../toolbox/scientific-data.md#ophyd-and-ophyd-async); wraps EPICS PVs as Python objects with a uniform interface.

**OPI** — Operator Interface. A screen; also the file format thereof (Phoebus `.bob`, older `.opi`).

**OPC UA** — Industrial interoperability standard; the EPICS [opcua module](../toolbox/plc-and-fieldbus.md#opc-ua) is a client for it.

**p4p** — [Python bindings to PVA](../toolbox/client-libraries.md#p4p), built on PVXS. Includes a PVA gateway and server.

**pcaspy** — [Python Channel Access server](../toolbox/simulation-and-testing.md#pcaspy) framework. Quick fake IOCs.

**PPS** — Personnel Protection System. Life safety. Certified PLCs and hard-wired logic. Absolutely not EPICS.

**procServ** — [Process supervisor](../toolbox/deployment-and-operations.md#procserv) giving an IOC a telnet-accessible console and automatic restart.

**PV** — [Process Variable](core-concepts.md#1-process-variable-pv).

**pvAccess / PVA** — [The EPICS 7 network protocol](../architecture/protocols.md#pv-access-pva).

**pvaPy** — Python bindings to the C++ pvAccess implementation.

**pva2pva** — The original PVA-to-PVA gateway; superseded in practice by the p4p gateway.

**PVI** — [Process Variable Interface](../toolbox/deployment-and-operations.md#pvi). Generates screens and device docs from one device description.

**pvinfo** — [Web front end to ChannelFinder](../toolbox/web-interfaces.md#pv-info).

**PVWS** — [PV Web Socket](../toolbox/web-interfaces.md#pvws-pv-web-socket). WebSocket bridge exposing PVs to browsers.

**PVXS** — [The modern C++ PVA library](../toolbox/client-libraries.md#pvxs). Replaces pvAccessCPP for new work.

**pyDevice** — [Module](../toolbox/scanning-and-automation.md#pydevice) letting record processing call Python inside the IOC.

**PyDM** — [Python Display Manager](../toolbox/operator-interfaces.md#pydm) from SLAC. PyQt-based OPI toolkit.

**PyEpics** — [The most widely used Python CA client library](../toolbox/client-libraries.md#pyepics).

**pythonSoftIOC** — [Diamond's library](../toolbox/simulation-and-testing.md#pythonsoftioc) for writing a real IOC in Python.

## R–Z

**RDB archiver** — The [Phoebus archive engine](../toolbox/archiving.md#phoebus-rdb-archive-engine) writing to a relational database.

**Record** — [The implementation of a PV inside an IOC](core-concepts.md#2-record).

**recsync / RecCaster / RecCeiver** — [The module](../toolbox/directory-services.md#recsync) by which IOCs self-report their record lists into ChannelFinder.

**RTOS** — Real-Time Operating System. RTEMS and VxWorks are the EPICS-supported ones.

**Save & restore** — Capturing and reapplying sets of PV values. [Phoebus service](../toolbox/save-and-restore.md) at facility level; [autosave](../toolbox/soft-support-modules.md#autosave) inside an IOC.

**SCAN** — The record field controlling [when a record processes](core-concepts.md#7-scanning-when-does-a-record-process).

**Scan server** — [Phoebus service](../toolbox/scanning-and-automation.md#phoebus-scan-server) executing experiment scan sequences.

**SEVR / STAT** — The record fields holding current alarm severity and status.

**SNL / seq** — State Notation Language and the [Sequencer](../toolbox/scanning-and-automation.md#sequencer-snl). A C-like language for finite state machines running inside an IOC.

**SNS** — Spallation Neutron Source, Oak Ridge. Source of much EPICS training material and many services.

**Soft IOC** — An IOC with no local hardware I/O.

**sscan** — [Module](../toolbox/scanning-and-automation.md#sscan) implementing multi-dimensional scans entirely inside the IOC.

**SSA** — Solid State Amplifier. Modern replacement for klystrons in storage ring RF.

**StreamDevice** — [Protocol-description-driven device support](../toolbox/plc-and-fieldbus.md#streamdevice). Talk to an ASCII instrument without writing C.

**st.cmd** — An IOC's startup script.

**Substitutions / template** — The macro-expansion mechanism for instantiating many similar records.

**synApps** — [Curated collection](../toolbox/deployment-and-operations.md#synapps) of EPICS modules from APS/BCDA, released as a tested set.

**Tiled** — [Data access service](../toolbox/scientific-data.md#tiled) from the Bluesky project.

**Top-up** — Injecting electrons into a storage ring every few minutes to hold current constant, rather than refilling from empty.

**VDCT** — [Visual Database Configuration Tool](../toolbox/base-and-iocs.md#vdct). Graphical `.db` editor; Java, legacy, still used.

**VME / VXI / MTCA** — Crate standards for control and diagnostics electronics. MicroTCA is the modern choice for fast diagnostics.

**waveform** — The record type holding an array.

**Xopt / Badger / Ocelot** — [Optimisation and online-tuning frameworks](../toolbox/physics-and-optimization.md) that drive accelerators through EPICS.
