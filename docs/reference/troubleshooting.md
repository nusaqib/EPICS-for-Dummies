# Troubleshooting

Symptoms, in the order you're likely to meet them. If you have a literal error string to paste, the [Error Message Index](error-messages.md) is keyed on the text instead.

## "Channel connect timed out"

The most common message in EPICS, and it means "nothing answered my search". Work through these in order — the first three account for most cases.

| # | Check | How |
| --- | --- | --- |
| 1 | **Does the record exist?** A typo looks identical to a network fault. | `dbl` on the IOC, or `dbgrep "PART*"` |
| 2 | **Is the IOC on a different subnet?** Broadcasts don't route. | `EPICS_CA_AUTO_ADDR_LIST=NO EPICS_CA_ADDR_LIST=<ioc-ip> caget PV` |
| 3 | **Firewall blocking UDP?** A rule permitting TCP 5064 but not UDP 5064 fails at the search stage, before TCP is attempted. | `ss -lunp \| grep 5064` on the IOC; `tcpdump -n 'udp port 5064'` |
| 4 | **Did `iocInit` succeed?** An IOC can be running and serving nothing. | Read its startup log from the beginning |
| 5 | **Is the IOC serving on the right interface?** Multi-homed hosts default badly. | Set `EPICS_CAS_INTF_ADDR_LIST` |
| 6 | **Container networking?** Docker's default bridge NATs, so inbound searches never arrive. | `--network host` |
| 7 | **VPN?** Broadcasts usually don't go out the VPN interface. | Explicit `EPICS_CA_ADDR_LIST` |
| 8 | **Wrong port?** Someone may have set up an isolated universe. | `echo $EPICS_CA_SERVER_PORT` |

Step 2 is the decisive diagnostic: **if an explicit address works and the default doesn't, your problem is discovery, not the IOC.**

## Values

### The value is 0 and the severity is INVALID

The record processed and the read *failed*. This is not a magnitude — it means "unknown".

```bash
caget -a PV          # confirm: INVALID
```

Then on the IOC:

```text
dbpr PV 4            # look at STAT for the reason
asynSetTraceMask("PORT",-1,0xff)     # if it's an asyn device: see the wire
```

Usual causes: the device isn't answering, the protocol doesn't match, a timeout, or an unconverted raw value. Look at the device support, not the record.

### The value never changes

```text
dbpr PV 1            # what is SCAN?
```

`Passive` is the default and means "nobody has asked". Then check that whatever should trigger it does: an input link with `PP`, an `FLNK` from another record, `I/O Intr` with driver support, or a periodic rate. `dbtr PV` test-processes it — if that produces a fresh value, your trigger is the problem, not the device.

### The value is stale but looks fine

The most dangerous case. Possibilities:

- **`SEVR` is `INVALID` and you're ignoring it.** Use `caget -a`.
- **A `-RB` record is a soft copy of its `-SP`.** It will always agree, and always lie. See [naming](../architecture/naming-conventions.md#setpoint-versus-readback).
- **A [Modbus](../toolbox/plc-and-fieldbus.md#modbus) or similar protocol with no quality flag** and a hung comms link. You need a PLC-side heartbeat, alarmed on staleness.
- **`SMOO` is smoothing it** and the underlying value is noisier than you think.

### caput appears to work but nothing changes

| Cause | Check |
| --- | --- |
| Clamped by `DRVL`/`DRVH` | `dbpr PV 1`; `caget PV` after the write |
| [Access security](../architecture/access-security.md) denies the write | `cainfo PV` — it reports access rights |
| The record is disabled | `dbpr PV 1` — look at `DISA`/`DISV` |
| A gateway is read-only | `cainfo PV` — is the server the gateway? |
| The record is `PACT` (busy) and discarded your write | `dbpr PV 1`; see [busy](../toolbox/soft-support-modules.md#busy) |
| Autosave restored an old value over yours | Check the pass-0/pass-1 configuration |

### Arrays are truncated

Array limits must agree at the **client, every gateway, and the IOC**. Raise `EPICS_CA_MAX_ARRAY_BYTES` on all of them. The symptom looks like data corruption rather than a configuration error, which is what makes it memorable.

## Build

| Symptom | Cause |
| --- | --- |
| `Record type "xxx" not found` | The module providing it isn't in `configure/RELEASE`, or its DBD isn't loaded in `st.cmd` |
| Undefined references at link time | A module missing from `configure/RELEASE`, or built for a different `EPICS_HOST_ARCH` |
| `perl: not found`, or a failing `.pl` script | Perl is a hard requirement of the build system |
| `readline.h: No such file` | Install `libreadline-dev` / `readline-devel` |
| No `softIocPVA` after a clean build | Submodules not cloned: `git submodule update --init --recursive` |
| Confusing failure with `make -j` | Retry without `-j`; the real error becomes legible |
| Works after `make clean`, fails otherwise | Stale dependency files. `make distclean` and rebuild. |
| Maven errors that make no sense | Corrupted cache. `rm -rf ~/.m2/repository`. |
| `Unsupported class file major version` | JDK too old for that Java project |
| `NoClassDefFoundError: javafx/...` | [JavaFX is separate from the JDK](../build-install/jdk.md#javafx) |

## IOC startup

| Symptom | Cause |
| --- | --- |
| `st.cmd: Permission denied` | `chmod +x st.cmd` |
| `envPaths: No such file` | Run it from its `iocBoot/ioc<name>/` directory — relative paths resolve against the working directory |
| Records load, then nothing works | Something is on the wrong side of `iocInit`. `dbLoadRecords` must be before; `create_monitor_set` must be after. |
| Autosave restores nothing, silently | **The save directory isn't writable by the IOC's user.** Check after every deployment. |
| Settings restored, then overwritten | Pass-0 vs pass-1 confusion in autosave |
| Output records at 0 after a restart | No `PINI`, and no autosave |
| Two IOCs serving one PV | You started it twice, or two deployments overlap. Clients bind to whichever answers first and see inconsistent values. |
| The IOC exits immediately | Read the log from the top; the first error matters, not the last |

## Performance

| Symptom | Investigate |
| --- | --- |
| IOC CPU pegged | [iocStats](../toolbox/soft-support-modules.md#iocstats-and-deviocstats); `epicsThreadShowAll`; look for records scanning faster than needed |
| Scan tasks running late | `scanppl`; a slow device on a fast scan list |
| Everything in one IOC feels slow | `dbLockShowLocked` — a wide [lock set](../architecture/process-database.md#lock-sets-the-thing-that-eventually-bites-you) serialising fast records behind a slow one. Split it with a `CA` link. |
| Network saturated with small packets | Missing `MDEL` on noisy records. Multiply by record count. |
| One client hammering an IOC | `casr 2` — per-client channel counts and queue state; the offender is usually obvious |
| Monitors being dropped | `casr 2` shows queue overflow. The client is too slow, or the rate is too high. |
| Clients slow to reconnect after an IOC restart | Beacons blocked (UDP 5065), or `caRepeater` can't bind |
| Archiver falling behind | Per-PV event rates; missing `ADEL`. See [archiving plan](../example-facility/archiving-plan.md). |

## Services

| Symptom | Check |
| --- | --- |
| Archiver connected-PV count below configured | The **disconnected PV list**. PVs that stopped connecting months ago are silent gaps. |
| Archiver storage filling | ETL jobs failing, so data isn't moving down the tiers |
| Alarm system shows nothing | Alarm server alive? Kafka healthy? **Alarm on rate going to zero** — silence looks like a quiet machine. |
| Alarm flood after any event | Missing [delays on consequential alarms](../example-facility/alarm-plan.md#2-delays-on-consequential-alarms) |
| Phoebus sees no PVs, but `caget` works in the same shell | Phoebus preferences overriding the environment — check `settings.ini`, especially `auto_addr_list` |
| PVWS shows nothing | EPICS variables not reaching the Tomcat process. [`setenv.sh`](../build-install/pvws.md#configure-epics-access). |
| Gateway passes reads but you expected writes to work | It's `RO`. Verify with `caput` — and verify the opposite too, that a read-only gateway really is. |
| Timestamps wrong or out of order | NTP drift. [This is a data-integrity incident](../toolbox/timing-systems.md), not housekeeping. |

## Diagnostic toolkit

```bash
# Client side
cainfo PV                    # which server, native type, ACCESS RIGHTS
caget -a PV                  # value + timestamp + severity
pvlist                       # enumerate PVA servers (no CA equivalent)
env | grep EPICS             # what is actually set in THIS shell
ss -lunp | grep 5064         # is anything listening?
sudo tcpdump -n 'udp port 5064 or udp port 5076'
```

```text
# IOC side
dbl                          does the record exist?
dbpr REC 4                   what is it doing, including links
dbtr REC                     test-process it
dbgf REC.FIELD               read a field without the network
casr 2                       who is connected, and how hard
dbLockShowLocked             lock sets
epicsThreadShowAll           threads and priorities
scanppl                      periodic scan lists
asdbdump                     access security rules in force
asynSetTraceMask("PORT",-1,0xff)      every byte on the wire
asynSetTraceIOMask("PORT",-1,0x2)     ...as escaped ASCII
```

## How to ask for help well

[tech-talk](community.md) is genuinely responsive, and core developers answer. Include:

1. **EPICS Base version** and the versions of relevant modules
2. **Platform** — distribution, kernel, architecture
3. **The actual error text**, pasted, not paraphrased
4. **The relevant `.db` and `st.cmd` fragments**
5. **`dbpr <record> 4`** output for the record in question
6. **What you already tried**, and what happened

Search the [archive](community.md) first — it's a large, well-indexed corpus and your question is probably in it. A well-formed question usually gets a useful answer within hours.

## The four questions to ask first

Before anything else, for almost any EPICS problem:

1. **Does the PV exist?** (`dbl` on the IOC)
2. **What is its severity?** (`caget -a`)
3. **Which server is answering?** (`cainfo`)
4. **What is `SCAN` set to?** (`dbpr`)

Those four cover a large fraction of everything on this page.
