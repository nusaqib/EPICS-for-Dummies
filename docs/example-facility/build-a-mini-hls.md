# Build a Mini-HLS

Everything in the preceding chapters, shrunk onto a laptop. Not a simulation of a synchrotron — a simulation of the *control system patterns* a synchrotron needs, at a scale you can hold in your head.

**Time:** an afternoon for stage 1, a weekend for all of it.

**Prerequisites:** [EPICS Base built](../build-install/epics-base.md), Python 3.

!!! note "No files in this repo"
    This guide is documentation only — the databases below are written out so you can read and type them, deliberately, rather than clone and run something you haven't looked at. Typing them is most of the learning.

## What you'll build

```text
Mini-HLS
├── 2 "cells", each with
│   ├── 1 quadrupole power supply   (setpoint, readback, ramping, interlock)
│   ├── 2 vacuum gauges             (pressure, alarm limits)
│   └── 2 BPMs                      (position, driven by a fake orbit)
├── A stored-current model          (fills on injection, decays with lifetime)
├── A machine mode PV               (gating alarms and writes)
├── A fake MPS                      (beam permit, first-fault, read-only)
├── Subsystem summary PVs           (severity propagation)
└── One "beamline" with a shutter and a monochromator energy pseudo-motor
```

Roughly 200 PVs, three IOCs, and every architectural pattern from the [example facility](index.md): naming, setpoint/readback, summaries, severity propagation, machine modes, a protection boundary, and a pseudo-motor.

## Stage 1: the vacuum IOC

Create `mini/vacuum.template`:

```text
# One vacuum gauge
record(ai, "$(SEC)-$(CELL)-VA-GAUGE-$(N):Pressure-Mon") {
    field(DESC, "$(CELL) gauge $(N) pressure")
    field(SCAN, "1 second")
    field(INP,  "$(SEC)-$(CELL)-VA-GAUGE-$(N):Sim-Mon CP")
    field(EGU,  "mbar")
    field(PREC, "3")
    field(HIGH, "1e-8")   field(HSV,  "MINOR")
    field(HIHI, "1e-7")   field(HHSV, "MAJOR")
    field(HYST, "1e-10")
    field(MDEL, "1e-11")
    field(ADEL, "5e-11")
}

# The "physics": a base pressure with noise, rising if we say it should
record(calc, "$(SEC)-$(CELL)-VA-GAUGE-$(N):Sim-Mon") {
    field(SCAN, "1 second")
    field(INPA, "$(SEC)-$(CELL)-VA-GAUGE-$(N):SimLeak-SP")
    field(CALC, "1e-9 + A + 1e-10*RNDM")
}
record(ao, "$(SEC)-$(CELL)-VA-GAUGE-$(N):SimLeak-SP") {
    field(DESC, "Simulated leak size")
    field(EGU,  "mbar")
    field(DRVL, "0")   field(DRVH, "1e-5")
    field(PINI, "YES")
}
```

Create `mini/vacuum_cell.template` — the per-cell summary:

```text
# Worst severity of the cell's gauges, computed IN THE IOC
record(calc, "$(SEC)-$(CELL)-VA-CF-01:Pressure-Sum") {
    field(DESC, "$(CELL) vacuum summary")
    field(INPA, "$(SEC)-$(CELL)-VA-GAUGE-01:Pressure-Mon CP MS")
    field(INPB, "$(SEC)-$(CELL)-VA-GAUGE-02:Pressure-Mon CP MS")
    field(CALC, "A>B?A:B")
    field(EGU,  "mbar")
    field(PREC, "3")
}

# Valve status: read-only, "from the PLC". EPICS observes; it does not decide.
record(bi, "$(SEC)-$(CELL)-VA-VALVE-01:Open-Sts") {
    field(DESC, "$(CELL) sector valve (from PLC)")
    field(INP,  "$(SEC)-$(CELL)-VA-CF-01:PlcValve-Sim CP")
    field(ZNAM, "CLOSED")  field(ONAM, "OPEN")
    field(ZSV,  "MAJOR")
}

# The fake PLC interlock: closes the valve above 5e-8 mbar.
# In a real facility this logic is NOT here -- see the machine
# protection chapter. It is here so you can watch it behave.
record(calc, "$(SEC)-$(CELL)-VA-CF-01:PlcValve-Sim") {
    field(INPA, "$(SEC)-$(CELL)-VA-CF-01:Pressure-Sum CP")
    field(CALC, "A<5e-8")
}
```

And `mini/vacuum.substitutions`:

```text
file "vacuum.template" {
    pattern { SEC, CELL, N }
            { "SR", "C01", "01" }
            { "SR", "C01", "02" }
            { "SR", "C02", "01" }
            { "SR", "C02", "02" }
}
file "vacuum_cell.template" {
    pattern { SEC, CELL }
            { "SR", "C01" }
            { "SR", "C02" }
}
```

Run it:

```bash
cd mini
softIoc -d <(msi -I. -S vacuum.substitutions)
```

Or, if your `msi` invocation differs, expand first:

```bash
msi -I. -S vacuum.substitutions > vacuum_expanded.db
softIoc -d vacuum_expanded.db
```

Play with it:

```bash
camonitor SR-C01-VA-CF-01:Pressure-Sum SR-C01-VA-VALVE-01:Open-Sts &

caget -a SR-C01-VA-GAUGE-01:Pressure-Mon      # note the severity field
caput SR-C01-VA-GAUGE-01:SimLeak-SP 2e-8      # spring a leak
# → gauge goes MINOR, cell summary inherits MAJOR via MS, valve closes
caput SR-C01-VA-GAUGE-01:SimLeak-SP 0         # fix it
```

**What you just demonstrated:**

| Pattern | Where |
| --- | --- |
| [Templates and substitutions](../architecture/process-database.md#templates-and-substitutions) | Four gauges from one file |
| [The naming convention](naming-convention.md) | `SR-C01-VA-GAUGE-01:Pressure-Mon` |
| [Severity propagation with `MS`](../architecture/process-database.md#link-modifiers-the-part-that-bites) | The cell summary inherits the worst gauge |
| [Event-driven processing with `CP`](../architecture/process-database.md#links-how-records-connect) | Nothing polls; changes propagate |
| Deadbands | `MDEL` and `ADEL`, set at creation |
| [Simulation](../toolbox/simulation-and-testing.md) | `SimLeak-SP` injects a fault you could never create on real hardware |
| [The protection boundary](machine-protection.md) | The valve is `-Sts`, read-only, driven by "the PLC" |

That last row is the one worth pausing on. The valve record has no setpoint. Nothing in EPICS can open it. That is the pattern, in miniature.

## Stage 2: magnets with ramping and interlocks

`mini/magnet.template`:

```text
record(ao, "$(SEC)-$(CELL)-PS-QF-$(N):Current-SP") {
    field(DESC, "$(CELL) QF$(N) current setpoint")
    field(EGU,  "A")
    field(PREC, "3")
    field(DRVL, "0")      field(DRVH, "180")      # unbypassable clamping
    field(PINI, "YES")
}

# Readback: ramps toward the setpoint at a finite rate, and only
# if the interlock permits. This is the DEVICE's behaviour, not a copy
# of the setpoint -- see naming-convention.md on why that matters.
record(calc, "$(SEC)-$(CELL)-PS-QF-$(N):Current-RB") {
    field(SCAN, ".1 second")
    field(INPA, "$(SEC)-$(CELL)-PS-QF-$(N):Current-SP")
    field(INPB, "$(SEC)-$(CELL)-PS-QF-$(N):Current-RB")
    field(INPC, "$(SEC)-$(CELL)-PS-QF-$(N):Intlk-Sts")
    field(CALC, "C?(ABS(A-B)<0.5?A:B+(A>B?0.5:-0.5)):0")
    field(EGU,  "A")
    field(PREC, "3")
}

# Water-flow interlock, "from the PLC". 1 = permit.
record(bi, "$(SEC)-$(CELL)-PS-QF-$(N):Intlk-Sts") {
    field(DESC, "$(CELL) QF$(N) cooling interlock (from PLC)")
    field(INP,  "$(SEC)-$(CELL)-PS-QF-$(N):SimIntlk-SP CP")
    field(ZNAM, "TRIPPED")  field(ONAM, "OK")
    field(ZSV,  "MAJOR")
}
record(bo, "$(SEC)-$(CELL)-PS-QF-$(N):SimIntlk-SP") {
    field(ZNAM, "TRIPPED")  field(ONAM, "OK")
    field(VAL,  "1")   field(PINI, "YES")
}

# Are we where we asked to be?
record(calc, "$(SEC)-$(CELL)-PS-QF-$(N):AtField-Sts") {
    field(INPA, "$(SEC)-$(CELL)-PS-QF-$(N):Current-SP CP")
    field(INPB, "$(SEC)-$(CELL)-PS-QF-$(N):Current-RB CP")
    field(CALC, "ABS(A-B)<0.5")
}
```

```bash
caput SR-C01-PS-QF-01:Current-SP 120     # watch Current-RB ramp, 5 A/s
caput SR-C01-PS-QF-01:Current-SP 500     # clamped to 180 by DRVH
caput SR-C01-PS-QF-01:SimIntlk-SP 0      # trip the cooling — current falls to 0
```

**New patterns:** [`DRVL`/`DRVH` as real protection](../architecture/access-security.md#layering-in-the-order-you-should-think-about-it); a readback that reflects the *device*, not the setpoint; a ramp implemented in the IOC so it applies to every write including restores; and an `-Sts` interlock that EPICS reads and cannot set.

## Stage 3: the machine, in Python

Some things are easier in Python than in `calc` records. Use [pythonSoftIOC](../toolbox/simulation-and-testing.md#pythonsoftioc) or [pcaspy](../toolbox/simulation-and-testing.md#pcaspy) for a stored-current model, a fake MPS, and an orbit:

```python
# mini/machine.py  — with pythonSoftIOC
from softioc import softioc, builder, asyncio_dispatcher
import asyncio, math, random

dispatcher = asyncio_dispatcher.AsyncioDispatcher()

builder.SetDeviceName("HLS-CF-DI-DCCT-01")
current  = builder.aIn('Current-Mon',  EGU='mA', PREC=2, LOLO=100, LLSV='MAJOR')
lifetime = builder.aIn('Lifetime-Mon', EGU='h',  PREC=2)

builder.SetDeviceName("HLS-CF-MPS-01")
permit     = builder.boolIn('BeamPermit-Sts', 'NO PERMIT', 'PERMIT', ZSV='MAJOR')
firstfault = builder.stringIn('FirstFault-Sts')

builder.SetDeviceName("HLS-CF-MODE-01")
mode = builder.mbbOut('Mode-SP',
                      'Beam off', 'Injector only', 'User operation', 'Machine study')

builder.SetDeviceName("SR-CF-DI-ORBIT-01")
orbit_x = builder.WaveformIn('X-Mon', [0.0] * 8, EGU='mm')   # ONE waveform,
orbit_y = builder.WaveformIn('Y-Mon', [0.0] * 8, EGU='mm')   # not 8 scalars

builder.LoadDatabase()
softioc.iocInit(dispatcher)

state = {'I': 0.0, 'topup_countdown': 0}

async def machine():
    while True:
        await asyncio.sleep(1.0)
        beam_ok = permit.get() and mode.get() >= 2

        if beam_ok:
            # decay with a current-dependent lifetime
            tau = 4.0 * (1 + 200.0 / max(state['I'], 20.0))
            state['I'] *= math.exp(-1.0 / (tau * 3600.0))
            lifetime.set(tau)
            # top up every 120 s
            state['topup_countdown'] -= 1
            if state['topup_countdown'] <= 0:
                state['I'] = min(500.0, state['I'] + 3.0)
                state['topup_countdown'] = 120
        else:
            state['I'] = max(0.0, state['I'] - 50.0)
            lifetime.set(0.0)

        current.set(state['I'])
        # a drifting orbit, so there is something to correct
        t = asyncio.get_event_loop().time()
        orbit_x.set([0.05 * math.sin(t / 30 + i) + 0.01 * random.gauss(0, 1)
                     for i in range(8)])
        orbit_y.set([0.03 * math.cos(t / 40 + i) + 0.01 * random.gauss(0, 1)
                     for i in range(8)])

permit.set(1)
firstfault.set("None")
dispatcher(machine)
softioc.interactive_ioc(globals())
```

```bash
pip install softioc
python mini/machine.py
```

```bash
camonitor HLS-CF-DI-DCCT-01:Current-Mon &
caput HLS-CF-MODE-01:Mode-SP 2        # "User operation" — current fills to 500 mA
caput HLS-CF-MPS-01:BeamPermit-Sts 0  # dump the beam
```

**New patterns:** [the orbit as one waveform, not N scalars](subsystems.md#diagnostics); a machine mode PV; a read-only MPS with a `FirstFault` PV; and [an IOC written in Python](../toolbox/simulation-and-testing.md#pythonsoftioc) where that's the better tool.

## Stage 4: add the services

Now the interesting part: point real services at your fake machine. Every one of these works identically against 200 PVs and 400 000.

| Do this | Following | You'll learn |
| --- | --- | --- |
| Build a [Phoebus](../build-install/phoebus.md) screen hierarchy: overview → cell → device | [operator-interfaces](operator-interfaces.md) | Why templated displays with macros beat per-device files |
| Archive it with the [RDB engine](../toolbox/archiving.md#phoebus-rdb-archive-engine) | [archiving-plan](archiving-plan.md) | Spring a leak, then find it in the archive an hour later |
| Configure the [alarm system](../build-install/alarm-system.md), with **delays** | [alarm-plan](alarm-plan.md) | Drop the beam permit and watch the cause arrive alone, 5 s before the consequences |
| Write [guidance text](alarm-plan.md#the-guidance-text) for three alarms | | How much work 9 000 of them would be — and why it's the work that matters |
| [Save & restore](../build-install/save-and-restore.md): snapshot, change things, **compare** | [operations-scenarios](operations-scenarios.md) | The single highest-value operation in the facility |
| Add [iocStats](../toolbox/soft-support-modules.md#iocstats-and-deviocstats) to all three IOCs | [observability](../toolbox/observability.md) | Kill an IOC; see the heartbeat alarm |
| Add [caPutLog](../toolbox/logbooks.md#caputlog) | [logbooks](../toolbox/logbooks.md) | "Who changed this?" with an actual answer |
| Run a [CA gateway](../build-install/gateways.md), read-only, and connect through it | [network-design](network-design.md) | `caget` works, `caput` fails. Verify it. |
| Write an [SNL sequencer](../toolbox/scanning-and-automation.md#sequencer-snl) that ramps both magnets in order | [subsystems](subsystems.md) | Why sequences belong in IOCs |
| Add [autosave](../toolbox/soft-support-modules.md#autosave), then restart an IOC | | Settings survive; and what happens when the save directory isn't writable |

## Reproduce the scenarios

With stage 4 in place, run the [operations scenarios](operations-scenarios.md) for real:

**Morning startup.** Mode to `Beam off`, restore a golden snapshot, compare, cycle the magnets with your sequencer, mode to `User operation`, watch the current fill. Snapshot.

**Beam dump at 03:14.** Set `FirstFault-Sts` to something, drop the permit. Watch your alarm delays produce two alarms then a flood. Diagnose from the archive. Log it.

**An IOC dies.** `kill` the vacuum IOC. Watch the heartbeat alarm after 30 s, the disconnected widgets in Phoebus, the archive gap — and note that the magnet IOC and the machine model carry on untouched.

**Maintenance day.** Snapshot, change fifteen things, compare, find the two you didn't mean to change.

Doing these four things is worth more than re-reading any chapter of this guide.

## Then break it deliberately

The tests you can never run on real hardware, and the reason simulation is worth keeping forever:

- Set `EPICS_CA_ADDR_LIST` to a wrong address. Observe that "the PV doesn't exist" and "the network is broken" look identical.
- Start a second `softIoc` serving the same database. Watch two clients get different values from a duplicate PV name.
- Set `SCAN` to `Passive` on the pressure record and work out why nothing updates.
- Remove `MS` from a summary record's links and watch severity stop propagating.
- Remove the alarm delay from a consequential alarm and watch the flood become unnavigable.
- Make the autosave directory read-only and discover how silent that failure is.
- Point a `-RB` record at its own `-SP`. Note that everything looks perfect and is a lie.

Each of those is a real failure mode from earlier in this guide. Producing them on purpose, once, is how you learn to recognise them at 03:00.

## Where to go from here

You have now built, in miniature, every pattern the [Helios Light Source](index.md) uses. Scaling from 200 PVs to 400 000 changes the *tooling* — generated configuration, containers, clustering, directory services — and changes none of the patterns.

Next steps that actually help:

- Talk to **real hardware**: a [StreamDevice](../toolbox/plc-and-fieldbus.md#streamdevice) protocol for any serial instrument you can find, or a [Lewis](../toolbox/simulation-and-testing.md#lewis) simulation of one.
- Read the [Application Developer's Guide](../reference/documentation.md) properly, now that the vocabulary means something.
- Work through the [USPAS training material](../reference/training.md), which has exercises and answers.
- Subscribe to [tech-talk](../reference/community.md) and lurk.
- Find out how *your* facility actually deploys IOCs. That's the most site-specific knowledge you'll acquire, and none of it is in this guide.
