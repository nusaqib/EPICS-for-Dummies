# Client Libraries

How to write a program that talks to EPICS. Grouped by language, with an opinion at the end of each group.

## Python

The dominant language for EPICS client work, and there are four serious options because they were built for different reasons.

### PyEpics

| | |
| --- | --- |
| Documentation | [pyepics.github.io/pyepics](https://pyepics.github.io/pyepics/) |
| Source | [github.com/pyepics/pyepics](https://github.com/pyepics/pyepics) |
| Author | Matt Newville (University of Chicago / APS) |
| Protocol | Channel Access |

The most widely used. A thin, well-documented ctypes wrapper over `libca` with a friendly API.

```python
import epics

v = epics.caget('SR-C05-PS-QF-01:Current-RB')
epics.caput('SR-C05-PS-QF-01:Current-SP', 105.0, wait=True)

pv = epics.PV('SR-C05-PS-QF-01:Current-RB')
print(pv.value, pv.timestamp, pv.severity, pv.units)

def on_change(pvname=None, value=None, **kw):
    print(pvname, value)
pv.add_callback(on_change)
```

Choose it for: scripts, notebooks, anything where you want the least friction. It's the default answer, and `pip install pyepics` needs `libca` present (it bundles `epicscorelibs` on most platforms).

### caproto

| | |
| --- | --- |
| Documentation | [caproto.github.io/caproto](https://caproto.github.io/caproto/) |
| Source | [github.com/caproto/caproto](https://github.com/caproto/caproto) |
| Origin | NSLS-II / Bluesky community |
| Protocol | Channel Access — **a pure-Python reimplementation** |

No C library at all. That buys three things: a **CA server** you can write in Python, sync/threading/asyncio/curio/trio flavours of the client, and a "sans-I/O" core that makes the protocol itself inspectable — which makes caproto the best available teaching tool for understanding CA on the wire.

```python
from caproto.threading.client import Context
ctx = Context()
pv, = ctx.get_pvs('SR-C05-PS-QF-01:Current-RB')
print(pv.read().data)
```

Choose it for: writing servers in Python, asyncio applications, protocol debugging, environments where compiling anything is a problem.

### p4p

| | |
| --- | --- |
| Documentation | [epics-base.github.io/p4p](https://epics-base.github.io/p4p/) |
| Source | [github.com/epics-base/p4p](https://github.com/epics-base/p4p) |
| Author | Michael Davidsaver |
| Protocol | **PV Access** (built on PVXS) |

The PVA counterpart, and much more than a client: p4p includes a PVA **server** framework and the [PVA gateway](gateways.md#p4p-pva-gateway) that facilities actually deploy.

```python
from p4p.client.thread import Context
ctx = Context('pva')
value = ctx.get('SR-C05-BPM-01:Orbit')       # a structure, not just a number
print(value.value, value.timeStamp.secondsPastEpoch)
```

Choose it for: anything PVA — structures, `NTNDArray` images, `NTTable`, RPC services — and for writing PVA services in Python.

### aioca

| | |
| --- | --- |
| Documentation | [diamondlightsource.github.io/aioca](https://diamondlightsource.github.io/aioca/) |
| Source | [github.com/DiamondLightSource/aioca](https://github.com/DiamondLightSource/aioca) |
| Origin | Diamond Light Source |
| Protocol | Channel Access, asyncio-native |

An asyncio CA client derived from Diamond's long-standing `cothread`/`catools` work. Choose it for asyncio applications where you want CA rather than PVA and prefer a small, focused library.

### pvapy

Python bindings to the C++ pvAccess implementation, with strong support for building high-throughput `NTNDArray` processing pipelines — used in production for streaming detector analysis.

- [github.com/epics-base/pvaPy](https://github.com/epics-base/pvaPy)

### Also

**cothread** — Diamond's cooperative-threading library with `catools`; predates asyncio and still in service. [github.com/dls-controls/cothread](https://github.com/dls-controls/cothread)

**pcaspy** — for *serving* PVs from Python. See [Simulation & Testing](simulation-and-testing.md#pcaspy).

**pythonSoftIOC** — for writing a real IOC in Python. See [Simulation & Testing](simulation-and-testing.md#pythonsoftioc).

!!! tip "Which Python library?"
    **PyEpics** for scripts and interactive work. **p4p** the moment you need PVA. **caproto** if you're writing a server, doing asyncio, or want to understand the protocol. **aioca** if you're in the Diamond ecosystem or want asyncio CA specifically. All four coexist happily in one environment.

## C and C++

| Library | Protocol | Notes |
| --- | --- | --- |
| **libca** (in Base) | CA | The reference implementation. Every other CA library is ultimately this or a reimplementation of it. C API, callback-based, well documented in the [CA Reference Manual](https://epics.anl.gov/base/R3-14/8-docs/CAref.html). |
| **pvAccessCPP / pvDataCPP** | PVA | The original C++ PVA stack, bundled in Base 7. Still present and used; new code should prefer PVXS. |
| **pcas** | CA server | The [portable CA server](https://github.com/epics-modules/pcas) library — how a non-IOC program serves PVs. Underlies gateways and pcaspy. |

### PVXS

| | |
| --- | --- |
| Documentation | [epics-base.github.io/pvxs](https://epics-base.github.io/pvxs/) |
| Source | [github.com/epics-base/pvxs](https://github.com/epics-base/pvxs) |
| Author | Michael Davidsaver |
| Protocol | PV Access |

**The modern choice for new C++ work.** A clean-sheet PVA implementation: modern C++11 and later, a far simpler API than pvAccessCPP, both client and server, and the foundation [p4p](#p4p) is built on.

If you are writing C++ that speaks PVA — a service, a gateway, a high-throughput data consumer — start here rather than with the older stack.

For device support inside an IOC you generally don't use these directly — you use [asyn](soft-support-modules.md#asyn)'s `asynPortDriver`, and the record layer handles the network.

## Java

| Library | Protocol | Notes |
| --- | --- | --- |
| **[epicsCoreJava](https://github.com/epics-base/epicsCoreJava)** | CA + PVA | The consolidated Java stack: `jca`/`caj` for CA, `pvAccessJava` and `pvDataJava` for PVA, plus normative types. |
| **Phoebus core** | Both | [Phoebus](operator-interfaces.md#phoebus)'s `core-pv` layer is a well-designed abstraction over both protocols, and reusable in your own Java application. |

Java matters here because the whole services tier — [archiver](archiving.md), [alarm system](alarms.md), [save & restore](save-and-restore.md), [ChannelFinder](directory-services.md), [Olog](logbooks.md) — is Java. If you're extending a service, this is your world.

## MATLAB, and the physics-application world

| Option | Notes |
| --- | --- |
| **labCA** | Widely used MEX-based CA interface for MATLAB. [github.com/till-s/epics-labca](https://github.com/till-s/epics-labca) |
| **MCA** | An older MATLAB CA toolbox, still in service at some facilities |
| **Matlab Middle Layer (MML)** | Not a CA library but the accelerator-physics application framework built on one — see [Physics & Optimisation](physics-and-optimization.md#matlab-middle-layer-mml) |

MATLAB remains entrenched in accelerator physics because decades of lattice and orbit-correction code live there. Python is displacing it steadily for new work, but "we should port MML to Python" is a multi-year conversation at most facilities, not a weekend.

## LabVIEW

| Option | Notes |
| --- | --- |
| **CA Lab** | Widely used free CA interface for LabVIEW, from HZB. Search "CA Lab EPICS LabVIEW" for the current release. |
| **NI's EPICS I/O server** | Part of NI's DSC module; works, licensed, limited. |

The recurring pattern with LabVIEW is a working test-stand VI that a facility later needs to integrate. Two approaches: expose the VI's data as PVs with CA Lab, or — usually better long-term — reimplement the device support in an IOC and retire the VI. LabVIEW-in-the-control-path tends to become the thing nobody can maintain after its author leaves.

## Other languages

| Language | Status |
| --- | --- |
| **Go** | Community CA implementations exist; none is a clear community standard. Check current activity before depending on one. |
| **Rust** | Same picture — real projects, no consensus. |
| **JavaScript / TypeScript** | Don't use CA directly. Go through [PVWS](web-interfaces.md#pvws-pv-web-socket) over WebSocket — that's exactly what it's for. |
| **Julia** | Wrappers over `libca` exist; niche. |
| **Shell** | `caget`/`caput` in a script is a perfectly respectable client, and often the right tool for cron jobs and health checks. |

## Guidance for writing clients

**Handle disconnection as a normal event, not an error.** IOCs restart. A client that crashes or hangs when a PV disconnects is broken. Every library gives you connection callbacks — use them, and show disconnection in your UI rather than displaying a stale value as if it were live.

**Always check severity.** `caget` gives you a number; the number may be `INVALID`. A client that ignores `SEVR` will confidently display readings from an unplugged instrument. This is the most common client bug in existence.

**Use monitors, not polling.** A `while True: caget(); sleep(1)` loop reconnects, re-searches, and costs the IOC far more than a subscription. Monitors are the mechanism the protocol is optimised for.

**Don't rely on monitors for completeness.** They deliver current values, and drop intermediate ones under load — [by design](../architecture/protocols.md#monitors-the-part-people-misunderstand). If you need every sample, get it from the IOC or the archiver.

**Use put-callback when you mean "wait until done".** `caput -c` / `wait=True` / `ca_put_callback` completes when the *action* completes, not when the write is accepted. For motors and long operations, the difference is the whole point. See [busy](soft-support-modules.md#busy).

**Don't put control logic in a client.** If your script is holding the machine in a state, that logic belongs in the [database](../architecture/process-database.md) or a [sequencer](scanning-and-automation.md#sequencer-snl), where it survives a closed laptop. This is the most frequently ignored piece of advice in EPICS, and it produces facilities where nobody knows why a magnet changed.

**Name your client.** Set `EPICS_CA_NAME_SERVERS`… no — set the process's user and hostname sensibly, because `casr` on the IOC and [caPutLog](logbooks.md#caputlog) will show them, and "who is this client hammering my IOC?" should have an answer.

## Next

→ [Operator Interfaces](operator-interfaces.md)
