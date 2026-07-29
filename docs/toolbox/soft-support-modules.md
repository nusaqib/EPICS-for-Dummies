# Soft Support Modules

A **soft support module** adds record types, software-only device support, or in-IOC services. No specific hardware implied.

Official directory: [epics-controls.org — Soft Support](https://epics-controls.org/resources-and-support/modules/soft-support/) · Source: [github.com/epics-modules](https://github.com/epics-modules)

The first five on this page are effectively standard equipment — most production IOCs load all of them.

## asyn

**The universal I/O abstraction.** If you write device support, you write it against asyn.

| | |
| --- | --- |
| Source | [github.com/epics-modules/asyn](https://github.com/epics-modules/asyn) |
| Documentation | [epics-modules.github.io/asyn](https://epics-modules.github.io/asyn/) |
| Maintainer | Mark Rivers (APS) and community |

What it provides:

- **Port drivers** for serial (RS-232/422/485), TCP/IP, UDP, GPIB/VXI-11, USB-TMC, and local IPC — configured with one line in `st.cmd` (`drvAsynIPPortConfigure`, `drvAsynSerialPortConfigure`).
- **`asynRecord`** — a diagnostic record letting you send arbitrary strings to a port and see the reply *from a screen*, while the IOC is running. Invaluable for commissioning a new instrument: you can test the protocol before writing any of it.
- **Standard device support** (`asynInt32`, `asynFloat64`, `asynOctet`, `asynInt32Array`, …) that connects ordinary records to any asyn driver.
- **`asynPortDriver`** — a C++ base class giving you parameter libraries, callbacks, and asynchronous completion handling. Modern C++ driver development in EPICS means subclassing this.
- **Per-port trace masks**, so you can turn on protocol-level logging for one device without drowning in output.

Almost everything else on this page and in [Hardware Support](hardware-support-modules.md) is built on asyn. Learning it is not optional.

## StreamDevice

Covered in detail under [PLCs & Fieldbus → StreamDevice](plc-and-fieldbus.md#streamdevice), because it's how you talk to instruments — but it belongs in this list too, since it's a soft module that installs alongside asyn and is arguably the single most useful thing in the ecosystem for a newcomer.

## autosave

**Survives reboots.** Periodically writes selected PV values to disk; restores them at `iocInit`.

| | |
| --- | --- |
| Source | [github.com/epics-modules/autosave](https://github.com/epics-modules/autosave) |
| Documentation | [epics-modules.github.io/autosave](https://epics-modules.github.io/autosave/) |

Why you need it: an output record's value after a fresh boot is whatever the `.db` file defaulted to. Without autosave, restarting an IOC means every setpoint returns to zero — which for a magnet power supply IOC is not an academic concern.

How it's set up:

```text
# in st.cmd, before iocInit
set_savefile_path("$(IOC)/autosave")
set_requestfile_path("$(IOC)/autosave")
set_pass0_restoreFile("myioc_settings.sav")
set_pass1_restoreFile("myioc_settings.sav")
save_restoreSet_DatedBackupFiles(1)
save_restoreSet_NumSeqFiles(3)
# after iocInit
create_monitor_set("myioc_settings.req", 30)     # save every 30 s if changed
```

The `.req` file lists PVs, or you tag records with `info(autosaveFields, "VAL")` in the database and let autosave build the list.

Operational notes that cost people time:

- **Pass 0 vs pass 1.** Pass 0 restores before record initialisation (needed for fields that affect init, like `SCAN` or `PREC`); pass 1 restores after. Setpoints usually want pass 1. Getting this wrong produces values that appear restored and then get overwritten.
- **The save directory must be writable by the IOC's user.** If it isn't, autosave logs a complaint and silently does nothing for the rest of the run. Check after every deployment.
- **`.sav` files are the actual state of your machine.** Back them up. Several sequenced backups (`NumSeqFiles`) protect you against saving a corrupt state during a crash.
- Autosave is *not* [save & restore](save-and-restore.md). Autosave is invisible reboot survival; save & restore is deliberate, named, comparable machine configurations. Run both.

## calc

Adds computation record types beyond Base's `calc`/`calcout`.

| | |
| --- | --- |
| Source | [github.com/epics-modules/calc](https://github.com/epics-modules/calc) |

| Record | Purpose |
| --- | --- |
| `transform` | Sixteen interdependent expressions in one record, evaluated in dependency order. Replaces a rat's nest of `calc` records. |
| `swait` | A `calc` with wait/delay semantics; the historical basis of `sscan` sequencing. |
| `sCalcout` | String calculation output — build a filename or a command string from PV values. |
| `aCalcout` | Array calculation output. |

Also provides extra functions to the expression evaluator used by `calc` records everywhere. `sCalcout` deserves a mention: composing a file path from a scan index and a sample name, inside the IOC, is a common need that would otherwise force a client script into your data path.

## iocStats and devIocStats

**The IOC tells you how it's doing.** Exposes IOC health as PVs.

| | |
| --- | --- |
| Source | [github.com/epics-modules/iocStats](https://github.com/epics-modules/iocStats) |

What you get: CPU load, memory usage and free memory, file descriptors in use, uptime, boot time, EPICS Base version, IOC application version, CA client and connection counts, per-scan-task period and actual rate, and a heartbeat.

Load it on **every IOC**, alarm on the heartbeat and on uptime resets, and put the results in [Grafana](observability.md). The single most valuable operational consequence: an IOC that restarted at 03:12 is *visible*, instead of being discovered three weeks later. See [Observability](observability.md).

## caPutLog

Logs every Channel Access write. Covered under [Logbooks → caPutLog](logbooks.md#caputlog).

## Sequencer (SNL)

State machines in the IOC. Covered under [Scanning & Automation → Sequencer](scanning-and-automation.md#sequencer-snl).

## sscan

Multi-dimensional scanning inside the IOC. Covered under [Scanning & Automation → sscan](scanning-and-automation.md#sscan).

## busy

**Tells clients "I'm still working".**

| | |
| --- | --- |
| Source | [github.com/epics-modules/busy](https://github.com/epics-modules/busy) |

The `busy` record is a `bo` variant designed for asynchronous completion: a client writes 1 to start an operation, and the record stays 1 until whatever it triggered actually finishes. Clients that use `ca_put_callback` block until then.

This sounds trivial and is architecturally important. Without it, "start the scan" returns immediately and the client has no way to know when the scan ended — so people invent polling loops that are always subtly wrong. `busy` makes completion a first-class, network-visible fact. [sscan](scanning-and-automation.md#sscan) and [areaDetector](detectors-and-imaging.md) both use it heavily.

## std

The odds-and-ends module: `timestamp` records, `scalcout` support pieces, `epid` (a PID controller record), `femto` amplifier support, and various small device supports that never justified their own module.

- [github.com/epics-modules/std](https://github.com/epics-modules/std)

`epid` is worth knowing about: a proper PID loop as a record. For slow loops (temperature, pressure, a stage following a signal) it means implementing feedback with no code at all. For fast loops, use hardware.

## Other soft modules worth knowing

| Module | Purpose | Link |
| --- | --- | --- |
| **pvxs** | Modern C++ PVA library; also usable as an IOC-side server | [epics-base.github.io/pvxs](https://epics-base.github.io/pvxs/) |
| **pcas** | The portable Channel Access server library — how non-IOC programs serve PVs (used by pcaspy, gateways) | [github.com/epics-modules/pcas](https://github.com/epics-modules/pcas) |
| **recsync** | IOCs self-report their record lists to ChannelFinder | [github.com/ChannelFinder/recsync](https://github.com/ChannelFinder/recsync) |
| **sseq** | Sequenced string/value output; scriptable action sequences as records | [sseqRecord docs](https://epics-modules.github.io/calc/sseqRecord.html), part of `calc` |
| **mca** | Multi-channel analyser records and support | [github.com/epics-modules/mca](https://github.com/epics-modules/mca) |
| **scaler** | Counting scaler record | part of [std](https://github.com/epics-modules/std) / [mca](https://github.com/epics-modules/mca) |
| **alive** | IOC heartbeat reporting to a central server — complements iocStats | [github.com/epics-modules/alive](https://github.com/epics-modules/alive) |
| **snmp** | SNMP client support — network gear, PDUs, UPSs | [github.com/epicsdeb/epics-snmp](https://github.com/epicsdeb/epics-snmp) |
| **ipmiComm** | IPMI monitoring of MTCA/ATCA crates | [github.com/slac-epics-modules/ipmiComm](https://github.com/slac-epics-modules/ipmiComm) |
| **caputRecorder** | Records operator actions as replayable Python | [github.com/epics-modules/caputRecorder](https://github.com/epics-modules/caputRecorder) |
| **pyDevice** | Call Python from record processing | [github.com/klemenv/pyDevice](https://github.com/klemenv/pyDevice) |
| **luaEpics** | Lua scripting inside the IOC shell and in records | [github.com/epics-modules/lua](https://github.com/epics-modules/lua) |
| **etherPSC, dac128V, ip330, …** | A long tail of specific supports | [github.com/epics-modules](https://github.com/epics-modules) |

## The minimum sensible set

For a new IOC talking to a normal instrument:

```text
asyn          ← always
StreamDevice  ← if the device speaks ASCII/binary over serial or TCP
autosave      ← always, if it has any setpoints
iocStats      ← always
calc          ← usually
busy          ← if it has long-running operations
caPutLog      ← if operators can write to it
recsync       ← if your facility runs ChannelFinder
```

That's seven modules and it covers a very large fraction of real IOCs. Getting a tested, mutually compatible set of them is exactly what [synApps](deployment-and-operations.md#synapps) is for.

## Next

→ [Hardware Support Modules](hardware-support-modules.md)
