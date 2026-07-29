# Simulation and Testing

Two related needs: developing before the hardware exists, and proving that what you wrote still works.

Both matter more in controls than in most software, because the cost of testing on the real thing ranges from "an hour of beam time" to "we broke the detector".

## Why simulate

- **Hardware arrives late.** Screens, databases, scans and services can all be built and tested against a simulator months earlier.
- **Beam time is expensive.** Debugging a scan sequence during a user run is the most expensive possible way to do it.
- **You cannot test failure on real hardware.** "What does the screen do when the gauge controller stops answering mid-scan?" is trivial in simulation and unacceptable in production.
- **CI needs something to talk to.** A test suite that requires a vacuum gauge doesn't run.
- **Training.** Operators can practise on a simulated machine, including on faults you'd never deliberately create.

## Lewis

**Pretends to be an instrument.**

| | |
| --- | --- |
| Documentation | [lewis.readthedocs.io](https://lewis.readthedocs.io/) |
| Source | [github.com/ess-dmsc/lewis](https://github.com/ess-dmsc/lewis) |
| Origin | ESS / ISIS |

Lewis simulates a *device*, not a PV. You describe the device as a Python state machine with a protocol adapter, and it listens on a TCP port or a serial device — so your IOC talks to it exactly as it would to the real instrument, using the real [StreamDevice](plc-and-fieldbus.md#streamdevice) protocol file or the real Modbus driver.

```bash
lewis -k lewis.examples chopper -p "stream://port=9999"
# now point drvAsynIPPortConfigure at localhost:9999
```

**This is the highest-fidelity simulation available**, because the thing under test is your actual device support with its actual protocol handling. It's also where you inject the failures that matter: unplug the device, delay a reply past the timeout, return a malformed response, return a plausible-but-wrong value. Those are the tests that find real bugs.

ISIS maintains a large collection of device simulators built on Lewis, and their [IOC test framework](https://github.com/ISISComputingGroup/EPICS-IOC_Test_Framework) drives IOCs against them in CI — a mature example of this approach done thoroughly.

## pcaspy

**Quick fake PVs from Python.**

| | |
| --- | --- |
| Documentation | [pcaspy.readthedocs.io](https://pcaspy.readthedocs.io/) |
| Source | [github.com/paulscherrerinstitute/pcaspy](https://github.com/paulscherrerinstitute/pcaspy) |

A Python CA *server* built on `pcas`. Define PVs in a dict, implement `read`/`write`, done:

```python
from pcaspy import Driver, SimpleServer
import random

pvdb = {
    'PRESSURE': {'prec': 3, 'unit': 'mbar', 'hihi': 1e-7, 'hhsv': 'MAJOR'},
    'SETPOINT': {'prec': 3, 'unit': 'mbar'},
}

class MyDriver(Driver):
    def read(self, reason):
        if reason == 'PRESSURE':
            return 1e-9 * (1 + random.random())
        return self.getParam(reason)

server = SimpleServer()
server.createPV('SIM:VAC:', pvdb)
driver = MyDriver()
while True:
    server.process(0.1)
```

Perfect for: giving a screen something to display, faking a subsystem you don't have, standing up a hundred plausible PVs in ten minutes. Not a real IOC — no record semantics, no scanning, no device support layering — so don't grow production logic in it.

## pythonSoftIOC

**A real IOC, in Python.**

| | |
| --- | --- |
| Documentation | [diamondlightsource.github.io/pythonSoftIOC](https://diamondlightsource.github.io/pythonSoftIOC/) |
| Source | [github.com/DiamondLightSource/pythonSoftIOC](https://github.com/DiamondLightSource/pythonSoftIOC) |
| Origin | Diamond Light Source |

This one embeds actual EPICS Base — so you get real records, real scanning, real alarm handling, real CA and PVA — with the records created and driven from Python.

```python
from softioc import softioc, builder, asyncio_dispatcher
import asyncio

dispatcher = asyncio_dispatcher.AsyncioDispatcher()
builder.SetDeviceName("SIM:VAC")

pressure = builder.aIn('PRESSURE', EGU='mbar', PREC=3, HIHI=1e-7, HHSV='MAJOR')
setpoint = builder.aOut('SETPOINT', EGU='mbar', PREC=3, always_update=True)

builder.LoadDatabase()
softioc.iocInit(dispatcher)

async def update():
    while True:
        pressure.set(read_the_real_thing())
        await asyncio.sleep(1)

dispatcher(update)
softioc.interactive_ioc(globals())
```

Increasingly used for **production** IOCs, not only simulation — particularly for devices with Python-only SDKs, for aggregation and calculation layers, and for services that need to look like an IOC. Because the record layer is genuine, everything downstream (archiver, alarms, screens) behaves normally.

## caproto's server

[caproto](client-libraries.md#caproto) includes a pure-Python CA server with a nice decorator-based API and no compiled dependencies at all. Choose it over pcaspy when you want async, want no C extensions, or are already using caproto as a client.

## Built into the tools

| Simulation | Provided by |
| --- | --- |
| **`ADSimDetector`** | [areaDetector](detectors-and-imaging.md) — a fully functional detector generating test patterns, with the complete plugin chain |
| **`motorMotorSim`** | [motor](motion.md) — virtual axes that accelerate, have limits, report `DMOV`, and can be made to fault |
| **`softIoc` with a `.db`** | [Base](base-and-iocs.md) — `Soft Channel` device support plus `calc` records makes a plausible fake subsystem with no code |
| **asyn's simulation modes** | Several drivers have a simulation flag that returns synthetic data |
| **Device `SIM`/`SIML`/`SIOL` fields** | Base's own record-level simulation: when `SIML`'s value is non-zero, the record reads from `SIOL` instead of hardware. **Built into every input record type** and widely forgotten. |

That last one deserves emphasis. Every input record has simulation fields, so *any* record can be switched to a simulated source at runtime with no code and no separate simulator:

```text
record(ai, "$(P):Pressure") {
    field(DTYP, "stream")
    field(INP,  "@gauge.proto getPressure $(PORT)")
    field(SIML, "$(P):SimMode")      # 0 = real, 1 = simulated
    field(SIOL, "$(P):SimPressure")  # where the fake value comes from
    field(SIMS, "MINOR")             # alarm severity while simulating — so nobody
}                                    # mistakes simulated data for real data
```

`SIMS` is the detail that makes this safe: a simulated record carries a `MINOR` alarm, so the screen and the archive both show that this reading isn't real. Facilities that build simulation in this way from the start can run the whole control system in simulation mode for training and commissioning.

## Testing

### Unit testing databases and modules

| Tool | Purpose |
| --- | --- |
| **`epicsUnitTest`** (in Base) | Base's own C test harness, TAP output. How Base and most modules test themselves. |
| **`dbUnitTest`** (in Base) | Load a database in a test harness, process records, assert on field values. The right tool for testing database *logic* — a `calc` chain, an alarm limit, a link topology. |
| **pytest + [PyEpics](client-libraries.md#pyepics)/[caproto](client-libraries.md#caproto)** | Integration tests: start an IOC, poke it over CA, assert. The commonest approach. |
| **[ISIS IOC Test Framework](https://github.com/ISISComputingGroup/EPICS-IOC_Test_Framework)** | A full framework for testing IOCs against Lewis-simulated devices. Worth studying even if you don't adopt it. |
| **[ci-scripts](https://github.com/epics-base/ci-scripts)** | The community's CI harness — builds your module against multiple Base versions on multiple platforms |

### What's worth testing

Order these by what actually breaks:

1. **Database logic.** Does the `calc` chain compute what you think? Do alarm limits trigger at the right values? Does the interlock summary go `MAJOR` when any input does? `dbUnitTest` handles all of this, fast, with no hardware.
2. **Protocol handling.** Does the StreamDevice protocol parse the real replies, including the error replies and the weird one the manual doesn't document? Lewis plus a captured transcript of the real device.
3. **Failure behaviour.** Device disconnects mid-operation; timeout; malformed reply; value out of range; device returns success but does nothing. **This is where the bugs are**, and it's untestable on real hardware.
4. **Startup.** Does the IOC start cleanly from nothing? Does [autosave](soft-support-modules.md#autosave) restore correctly? Does a record with `PINI` push its value? Startup is the most-executed and least-tested code path in an IOC.
5. **Screens.** At minimum, that every widget's PV exists — a script cross-referencing display files against [ChannelFinder](directory-services.md) catches typos that would otherwise appear as a blank field during a shift.

### CI for a controls repository

A realistic pipeline:

```text
1. Lint      — PV names against the naming convention regex
2. Build     — the IOC application, against the site's Base and module versions
3. dbUnitTest— database logic
4. Start     — launch the IOC against Lewis simulators
5. Integrate — pytest over CA: does it do what it claims?
6. Check     — every PV referenced by the screens exists
```

Steps 1 and 6 are cheap, mechanical, and catch a disproportionate share of real problems. If you do nothing else, do those.

## Guidance

**Build the simulator before the hardware arrives.** Not as a nice-to-have — as the way you develop. By the time the device is on the bench, the screens, the database, the scans and the alarms are done and tested, and commissioning becomes "does the real protocol match the simulated one" rather than "let's write everything now, with the beam waiting".

**Keep the simulator forever.** It's your CI target and your training environment. A simulator that is deleted once the hardware works has thrown away most of its value.

**Use `SIML`/`SIOL`/`SIMS` from the start.** Adding simulation fields to records at creation time costs three lines per record and makes the entire control system runnable without hardware. Retrofitting means touching every database.

**Test the failure paths.** Everyone tests that it works. Almost nobody tests what happens when the device stops answering, and that's the case that occurs at 03:00.

**Never let simulated data look real.** `SIMS` with a `MINOR` severity, a prominent simulation-mode indicator on every screen, and if possible a distinct PV prefix for a purely simulated system. Simulated values that reach an operator or an archive undetected is the one genuinely dangerous failure mode of this whole practice.

## Next

→ [Scientific Data](scientific-data.md)
