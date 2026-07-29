# Motion Control

Moving things is the most common non-trivial task in a beamline control system, and EPICS has one dominant answer.

## The motor module

| | |
| --- | --- |
| Source | [github.com/epics-modules/motor](https://github.com/epics-modules/motor) |
| Documentation | [epics-modules.github.io/motor](https://epics-modules.github.io/motor/) |
| Maintainers | Mark Rivers, Ron Sluiter, Kevin Peterson, and community |
| Part of | [synApps](deployment-and-operations.md#synapps) |

The module provides the **`motor` record** — a device-independent abstraction of "an axis" — plus drivers for several dozen controller families. Learn the record once and every controller looks the same to your screens and scripts.

### The motor record's important fields

| Field | Meaning |
| --- | --- |
| `VAL` / `DVAL` / `RVAL` | Target position in user / dial / raw units |
| `RBV` | Readback position — **the field your screens and scans should read** |
| `DMOV` | Done-moving flag. 0 while in motion. |
| `MOVN` | Motion in progress (from the controller). |
| `STOP` | Write 1 to stop. |
| `VELO`, `VBAS`, `ACCL` | Slew velocity, base velocity, acceleration time |
| `HLM` / `LLM` | Soft limits in user units |
| `HLS` / `LLS` | Hard limit switch states |
| `OFF`, `DIR` | User-to-dial offset and direction — how you re-zero without touching the controller |
| `MRES`, `ERES`, `UREG` | Motor step, encoder resolution, unit conversion |
| `RTRY`, `RDBD`, `RCNT` | Retry count, retry deadband, retries used — closed-loop position correction |
| `SET` | Switch to "set" mode: change position calibration without moving |
| `HOMF` / `HOMR` | Home forward / reverse |
| `MSTA` | Bit-mapped status: direction, done, limits, home, following error, power |
| `TWF` / `TWR` / `TWV` | Tweak forward/reverse by `TWV`. The field operators use most. |

**The distinction that matters most:** `VAL` is where you asked it to go, `RBV` is where it is. Screens must show `RBV`, scans must record `RBV`, and interlocks must use `RBV`. A screen showing `VAL` as "position" is the [setpoint/readback confusion](../architecture/naming-conventions.md#setpoint-versus-readback) in its most consequential form — the operator sees the stage at 45 mm when it is jammed at 12 mm.

**Waiting for completion:** write with `ca_put_callback` (`caput -c`) and the put completes when `DMOV` goes to 1. Polling `DMOV` in a loop works but races; the callback is the correct mechanism, and it's what [sscan](scanning-and-automation.md#sscan) and [ophyd](scientific-data.md#ophyd--ophyd-async) use.

### Supported controllers

Dozens, in `motor`'s own tree or as separate `motor<Vendor>` repositories:

| Family | Examples |
| --- | --- |
| Stepper/servo controllers | Newport (XPS, SMC100, ESP), Galil, Delta Tau (PMAC/Power PMAC), ACS, Aerotech (Ensemble, A3200), Physik Instrumente, SmarAct, Attocube, Micos, Kohzu, OMS, MicroMo/Faulhaber |
| Motion in a PLC | Beckhoff (via ADS or OPC UA), Omron, Siemens — usually a facility-specific layer |
| Piezo controllers | PI, SmarAct, Attocube, Queensgate |
| Simulated | `motorMotorSim` — a working virtual axis, no hardware. Use this to develop everything before the stages arrive. |

Newer drivers subclass asyn's `asynMotorController`/`asynMotorAxis` C++ classes, which is also the path if you must write your own.

!!! tip "Develop against motorMotorSim first"
    A simulated axis behaves like a real one: it accelerates, has limits, reports `DMOV`, and can be made to fail. You can build and test every screen, scan and sequence before the hardware exists, and keep the simulation in CI afterwards. See [Simulation & Testing](simulation-and-testing.md).

## Coordinated and virtual motion

Real beamline devices are rarely one axis. A double-crystal monochromator, a mirror on three jacks, a four-blade slit, or a hexapod all need a *coordinate transformation* between what the physicist wants (energy, pitch, gap, centre) and what the motors do.

| Approach | When to use |
| --- | --- |
| **Controller-level coordination** (PMAC kinematics, Aerotech coordinate systems) | Best when the motion must be genuinely simultaneous and interpolated. The controller does the maths in real time. |
| **[pmac](https://github.com/dls-controls/pmac)** (Diamond) | Mature Delta Tau/PMAC support including coordinate systems and trajectory scanning — the reference implementation for continuous, hardware-timed scanning. |
| **`transform` / `calc` records** ([calc](soft-support-modules.md#calc)) | Simple two- or three-axis relationships. Cheap, declarative, no code. |
| **Soft pseudo-motor in a separate IOC layer** | The general answer for beamline optics: a `motor`-record-shaped façade over real axes. |
| **Client-side (ophyd, Bluesky)** | For scan-level combinations. Fine for experiments; wrong for anything an operator relies on continuously, since it lives outside the control system. |

Common beamline pseudo-motors: monochromator energy (from Bragg angle), slit gap and centre (from two blades), mirror pitch/roll/height (from three jacks), sample-stage rotation about an off-axis point, and undulator gap tracking monochromator energy.

**Slits are the canonical example.** Two blades at positions `x1`, `x2` become `gap = x2 - x1` and `centre = (x1 + x2)/2`. The operator wants gap and centre; the motors want positions. The transformation is trivial and the *limit handling* is not: a legal gap-and-centre combination can require an illegal blade position, and getting that wrong drives blades into each other. Slit pseudo-motor implementations spend most of their code on limits, which is a good lesson about coordinated motion generally.

## Trajectory and continuous scanning

Step-scanning — move, settle, count, repeat — wastes most of the beam time on settling. Continuous ("fly") scanning moves the axis at constant velocity while the detector integrates, with hardware triggers keeping positions and frames correlated.

This requires:

- a controller that can execute a **trajectory** and emit position-based triggers ([pmac](https://github.com/dls-controls/pmac), Aerotech, ACS);
- a detector accepting external triggers ([areaDetector](detectors-and-imaging.md));
- **position capture** — the controller latching actual position at each trigger, so you record where it *was*, not where it was commanded;
- an orchestration layer: Diamond's malcolm/`pandABlocks` approach, [Bluesky](scientific-data.md#bluesky) flyer scans, or facility-specific tooling.

The essential insight is that correctness comes from hardware timing, not software: a trigger derived from the encoder is trustworthy, and a timestamp applied by a script is not.

## Practical guidance

**Set soft limits (`HLM`/`LLM`) before the first move.** Every time. Hard limit switches are the backstop, not the plan, and a stage that hits a hard limit at slew velocity may need realignment.

**Understand `OFF`, `DIR`, and `SET` before you re-zero anything.** `SET` mode changes the calibration without moving — powerful and easy to misuse. A stage that is "at 0" but 3 mm from where 0 used to be is a subtle and expensive kind of wrong, especially if it happened during a shift nobody documented.

**Use `RDBD` and `RTRY` deliberately.** Position retries mask backlash and closed-loop error, which is helpful for accuracy and terrible for diagnosis if you don't know they're happening. A stage retrying five times per move is telling you something about the mechanics.

**Autosave motor positions.** With [autosave](soft-support-modules.md#autosave), an IOC restart doesn't lose your calibration — but note that for absolute-encoder axes the *controller* knows the truth, whereas for incremental axes the saved value is all you have. That distinction determines whether an IOC restart requires re-homing.

**`MSTA` is your diagnostic.** Following error, limit switches, amplifier fault and home status are all in there, and a screen showing only position hides all of it.

**Motion is where people get hurt and equipment gets broken.** Not because EPICS is unsafe, but because a moving stage has energy and often has fragile things near it. Collision avoidance between independently controlled devices, and anything protecting a person, belongs in [PLC or hardware interlocks](../example-facility/machine-protection.md) — not in a motor record's soft limits and not in a Python script.

## Next

→ [Detectors & Imaging](detectors-and-imaging.md)
