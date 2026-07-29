# FAQ

The questions newcomers ask, in roughly the order they ask them.

## Getting started

### Do I have to compile EPICS Base from source?

No, but you probably should once — the build system is something you'll interact with constantly, and 30 minutes of watching it work pays off. Alternatives:

- **conda**: `conda install -c conda-forge epics-base` — fast, and how a lot of Python-side people work.
- **Distribution packages**: `apt install epics-dev` on Debian/Ubuntu via [epicsdeb](../toolbox/deployment-and-operations.md#distribution-packages).
- **Containers**: images from [epics-containers](../toolbox/deployment-and-operations.md#epics-containers).
- **A [training VM](../reference/training.md)** with the entire stack pre-installed.

### How long until I'm useful?

A week to serve and read your own PVs. A month to write an IOC for real hardware with someone reviewing it. Six months to a year to have opinions about database design, and that's the point at which you stop needing guides like this one.

### Which programming language do I need?

For a great deal of IOC work, **none** — databases are declarative and [StreamDevice](../toolbox/plc-and-fieldbus.md#streamdevice) protocols are text files. Beyond that: **Python** for clients, scripting, and tests; **C** for classic device support; **C++** for `asynPortDriver` and areaDetector; **Java** if you touch Phoebus or the services; **Perl** if you go digging in the build system. Nobody knows all of these on day one.

### Where do I ask for help?

[tech-talk](../reference/community.md), the main EPICS mailing list. Read the archive first — it's a huge, well-indexed corpus and your question is probably in it. When you do post, include your Base version, module versions, platform, the actual error text, and what you already tried. The core developers read that list and answer, which is genuinely unusual for software of this age.

## Concepts

### CA or PVA: which should I use?

Learn with CA: more tools, more examples, more of everything you'll encounter. Use PVA when you need what it adds — structured data, images with metadata attached, tables, RPC-style calls, or a service that requires it. An EPICS 7 IOC serves both from the same records, so this is not a lock-in decision. See [Protocols](../architecture/protocols.md).

### Is a PV the same thing as a record?

Nearly. A record *is* a set of PVs: the record's own name maps to its `.VAL` field, and every other field is addressable too (`MyRecord.EGU`, `MyRecord.HIGH`). One record can also answer to several names via `alias()`. So: records live inside IOCs, PVs are what the network sees.

### Why is my value flat and green when the device is unplugged?

Because you're ignoring severity. Comms failure sets `INVALID`, usually leaving the last value or zero in `VAL`. A screen or script that reads only the number cannot tell "0.0, correct" from "0.0, meaningless". Always check `SEVR`/`STAT` — `caget -a` shows them. This is the single most common category of "the control system lied to me".

### Should one IOC serve everything, or should I have many small ones?

Many small ones, biased toward one IOC per device or per crate. Failure domains stay small, restarts are cheap, and ownership is clear. The counter-pressure is real though: several hundred IOCs need [deployment tooling](../toolbox/deployment-and-operations.md) and [monitoring](../toolbox/observability.md), and records that must interlock with each other are simpler in one IOC than across two. See the [example facility's reasoning](../example-facility/ioc-inventory.md).

### What's the difference between autosave and save and restore?

[autosave](../toolbox/soft-support-modules.md#autosave) runs *inside* an IOC and exists to survive reboots: it periodically writes values to a local file and restores them at `iocInit`, invisibly. [save & restore](../toolbox/save-and-restore.md) is a *facility service* for deliberate configurations: "the settings we ran the 2 keV experiment with", compared and restored by operators, with history. You want both. They solve different problems.

## Practical problems

### `caget` says "Channel connect timed out" but the IOC is definitely running

In order of likelihood:

1. `EPICS_CA_ADDR_LIST` unset while the IOC is on a different subnet — broadcasts don't route.
2. A host firewall dropping inbound UDP/5064 on the IOC or the reply path.
3. The record isn't there. Check `dbl` on the IOC console; a typo in the name looks identical to a network fault.
4. The IOC is running but `iocInit` failed, so it serves nothing. Read its startup log.
5. Docker/VPN networking. Try `EPICS_CA_ADDR_LIST=<ioc-ip>` with `EPICS_CA_AUTO_ADDR_LIST=NO`.

Fuller list: [Troubleshooting](../reference/troubleshooting.md), or the [Error Message Index](../reference/error-messages.md) if you have an error string to paste.

### Two IOCs are serving the same PV name. What happens?

Whichever answers a client's search first wins, per client. Different clients get different IOCs; readings become mysteriously inconsistent and irreproducible. Base logs a warning about duplicate names when it notices, but you must be watching. This is a bug with no upside — prevented by a [naming convention](../architecture/naming-conventions.md) plus a [directory service](../toolbox/directory-services.md) that makes collisions visible.

### My record won't update

Check `SCAN` first — `Passive` means "nobody has asked", and it's the default. Then check that whatever should be triggering it actually is: an input link with `PP`, an `FLNK` from another record, `I/O Intr` with a driver that supports it, or a periodic rate. Then check `SEVR`/`STAT` for `INVALID`, which means processing is happening and failing.

### Can I write an IOC in Python?

Yes, and increasingly people do. [pythonSoftIOC](../toolbox/simulation-and-testing.md#pythonsoftioc) (Diamond) and [caproto](../toolbox/client-libraries.md#caproto)'s server are the main routes; [pcaspy](../toolbox/simulation-and-testing.md#pcaspy) for quick fakes; [pyDevice](../toolbox/scanning-and-automation.md#pydevice) to call Python from inside a conventional IOC. Excellent for simulation, tests, aggregation, and slow devices. For hard real-time hardware loops, stay in C/C++.

### How do I talk to a PLC?

By protocol: Allen-Bradley → [ether_ip](../toolbox/plc-and-fieldbus.md#ether_ip-allen-bradley); Siemens S7 → [s7plc](../toolbox/plc-and-fieldbus.md#s7plc) or OPC UA; anything with OPC UA → [the opcua module](../toolbox/plc-and-fieldbus.md#opc-ua); Beckhoff → ADS or OPC UA; generic → [Modbus](../toolbox/plc-and-fieldbus.md#modbus). Decide *with the PLC engineer* which side owns which logic, and write it down — that boundary being fuzzy causes more grief than any protocol detail.

### Can EPICS run my safety interlock?

No.

!!! danger "Not ever"
    Personnel protection and machine protection belong in certified PLCs or hard-wired logic designed to IEC 61508 / IEC 61511. EPICS has no safety certification, no deterministic network latency, and no failure analysis suitable for a safety case. EPICS *monitors and displays* those systems. See [Machine Protection](../example-facility/machine-protection.md).

## Scale and operations

### How many PVs can one IOC serve?

Tens of thousands is routine. The limits you actually hit are CPU (record processing rate × record count) and the number of monitored channels × update rate × client count. An IOC pushing 50 000 monitors a second to 40 clients is doing more work than one holding a million idle records. Measure with [iocStats](../toolbox/soft-support-modules.md#iocstats-and-deviocstats) rather than guessing.

### How much does archiving everything cost?

Cheaper than you fear if you use monitor-based (event-driven) archiving with sensible deadbands, and ruinous if you scan everything at 10 Hz. The [example facility's archiving plan](../example-facility/archiving-plan.md) works the arithmetic end to end: ~415 000 PVs, ~24 TB/year, and where every term comes from.

### Do I need Kafka, Elasticsearch, MySQL and Kubernetes?

Not to learn, and not for a test stand. Those are dependencies of the *services* — the Phoebus alarm system needs Kafka, Olog and ChannelFinder want Elasticsearch, the Archiver Appliance wants MySQL/MariaDB for configuration. A single IOC plus a GUI needs none of it. Add each service when you have the problem it solves.

### Is EPICS still actively developed?

Yes. Base 7 releases regularly, PVXS and p4p are current work, [epics-containers](../toolbox/deployment-and-operations.md#epics-containers) is reshaping deployment, and Phoebus is under continuous development. There are annual [collaboration meetings and codeathons](../reference/community.md). It's a 35-year-old codebase with a live community — the interesting kind of old.

## Meta

### Why does this guide invent a fake synchrotron?

Because "you need a naming convention" teaches nothing, and *watching* a naming convention get chosen — with its constraints, its compromises, and the 60-character CA limit pressing on it — teaches a lot. The [Helios Light Source](../example-facility/index.md) exists so every architectural claim in this guide has to survive contact with a concrete machine.

### Can I trust everything on this site?

Trust it as a map. It's written by someone learning EPICS, so where it disagrees with [docs.epics-controls.org](https://docs.epics-controls.org) or a project's own README, believe them and [file an issue here](https://github.com/nusaqib/EPICS-for-Dummies/issues).
