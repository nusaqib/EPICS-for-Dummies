# Subsystems

What has to be controlled, how fast, and — most importantly — **which layer owns it**. That last column is the whole point of this page.

## The layer question

Every control function belongs to exactly one of four layers, and putting it in the wrong one is the most consequential mistake available:

| Layer | Latency | Examples | Can EPICS do it? |
| --- | --- | --- | --- |
| **Hardware / FPGA** | ns–µs | Orbit feedback loop, LLRF regulation, bunch-by-bunch feedback, beam interlocks | No. EPICS sets parameters and reads diagnostics. |
| **Certified PLC** | ms, deterministic, validated | Machine protection, personnel protection, vacuum valve interlocks | **Never.** [See why](machine-protection.md). |
| **IOC** | 10 ms–1 s | Device control, sequences, calculations, alarm limits, ramps | Yes — this is EPICS's job. |
| **Client / service** | seconds+ | Physics applications, optimisation, experiment orchestration, analysis | Yes, and nothing the machine depends on. |

## Injector

| Function | Rate | Layer | Notes |
| --- | --- | --- | --- |
| Gun HV and heater control | 1 Hz | IOC | Serial, StreamDevice |
| Modulator control and interlocks | — | **PLC** + IOC status | Klystron modulators are high-energy; interlocks are hardwired |
| Linac LLRF | µs | **FPGA** | EPICS sets amplitude/phase setpoints, reads waveforms |
| Linac magnet supplies | 1 Hz | IOC | ~40 supplies |
| Screen/flag insertion | on demand | IOC | [motor](../toolbox/motion.md) + [areaDetector](../toolbox/detectors-and-imaging.md) |
| Booster magnet ramp | 1 Hz cycle | **FPGA/controller** waveform playback | EPICS loads the ramp table; hardware plays it back, synchronised to the [timing system](../toolbox/timing-systems.md) |
| Injection/extraction kickers | ns timing | **FPGA + timing system** | EPICS sets delays and amplitudes |
| Top-up sequencing | ~120 s | IOC ([sequencer](../toolbox/scanning-and-automation.md#sequencer-snl)) | Must survive network loss — hence SNL, not a script |

The booster ramp is instructive. A 1 Hz ramp from 150 MeV to 3 GeV across hundreds of magnets cannot be commanded point-by-point over Channel Access. Instead EPICS *loads a table* into each supply's controller and the hardware plays it back on a timing-system trigger. EPICS's job is the table, the trigger configuration, and verifying afterwards that the ramp was followed.

## Storage ring magnets

| Function | Rate | Layer | Notes |
| --- | --- | --- | --- |
| Slow supply setpoint/readback | 1–10 Hz | IOC | ≈900 supplies, ~80 PVs each |
| Fast corrector setpoints | 10 kHz | **FPGA** (orbit feedback) | EPICS sets offsets, gains and limits only |
| Magnet cycling / degaussing | minutes | IOC ([sequencer](../toolbox/scanning-and-automation.md#sequencer-snl)) | Must complete reliably; hysteresis matters |
| Ramp rate limiting | — | IOC + supply | `DRVL`/`DRVH` in the record; ramp rate in the supply |
| Water flow and temperature interlocks | — | **PLC** | A magnet without cooling fails expensively |
| Current-to-field conversion | on demand | IOC | One authoritative conversion, in the IOC, for everyone |
| Optics changes (K-values → currents) | on demand | Client (physics app) | Writes engineering-unit setpoints |

The conversion row matters more than it looks. If the current-to-K1 conversion lives in the physics application, in a spreadsheet, and in a beamline script, they will diverge, and the divergence will be found during a machine study. Putting it in the IOC means there is one answer. See [Physics & Optimisation](../toolbox/physics-and-optimization.md#guidance-for-controls-engineers-supporting-physics).

## RF

| Function | Rate | Layer |
| --- | --- | --- |
| Cavity amplitude/phase regulation | µs | **FPGA (LLRF)** |
| Amplitude/phase setpoints, mode selection | on demand | IOC |
| SSA module monitoring (~600 per amplifier) | 1 Hz | IOC |
| Arc, reflected power, window temperature interlocks | µs | **Hardware** — reported into EPICS read-only |
| Cavity tuner control | 1 Hz | IOC |
| Conditioning sequences | hours | IOC ([sequencer](../toolbox/scanning-and-automation.md#sequencer-snl)) |
| Waveform diagnostics | on trigger | IOC, served over [PVA](../architecture/protocols.md#pv-access-pva) |

600 SSA modules per amplifier is a good example of designing PVs for the question people ask. Nobody wants 600 individual status displays; they want "how many modules are faulted, and is it trending?" So the IOC computes a `-Sum` count and a per-module detail view exists behind it.

## Vacuum

| Function | Rate | Layer | Notes |
| --- | --- | --- | --- |
| Gauge readings | 1 Hz | IOC | 320 gauges, mostly serial + [StreamDevice](../toolbox/plc-and-fieldbus.md#streamdevice) |
| Ion pump current and voltage | 1 Hz | IOC | 140 pumps |
| Sector valve **interlock logic** | ms | **PLC** | Pressure rise closes valves. Non-negotiable. |
| Sector valve open/close commands | on demand | IOC → PLC | The command is EPICS; the permission is PLC |
| Valve position status | 1 Hz | IOC (from PLC) | Read-only |
| Turbo pump station control | 1 Hz | IOC | |
| Bake-out sequences | days | IOC ([sequencer](../toolbox/scanning-and-automation.md#sequencer-snl)) | Ramp temperature, hold, cool, all with limits |

**The valve boundary is the clearest illustration of the PLC line in the whole facility.** A pressure rise must close valves in milliseconds, reliably, whether or not the network, the IOC or the operator is available. That logic is in a PLC. EPICS asks the PLC to open a valve and the PLC decides whether it may. Getting this backwards — EPICS commanding the valve directly with the interlock as a soft check — would be a serious design failure, and it's a mistake that has been made at real facilities.

## Fast orbit feedback

| Component | Rate | Layer |
| --- | --- | --- |
| BPM position acquisition | 10 kHz | **FPGA** |
| Correction computation (inverse response matrix) | 10 kHz | **FPGA**, dedicated network |
| Fast corrector output | 10 kHz | **FPGA** |
| Response matrix upload | on demand | IOC |
| Gains, bandwidth, on/off, per-BPM enable | on demand | IOC |
| Loop diagnostics, RMS orbit, per-corrector strength | 10 Hz | IOC |
| Slow orbit feedback (drift correction) | 0.1–1 Hz | **IOC** — genuinely EPICS |
| Response matrix measurement | hours | Client (physics app) |

180 BPMs × 160 correctors at 10 kHz over a dedicated deterministic network. Nothing in that sentence is achievable with Channel Access, and nobody sensible tries.

But note the *slow* orbit feedback row: correcting thermal drift at 0.1–1 Hz is entirely appropriate for an IOC, is genuinely useful, and is how a lot of facilities operated before fast feedback existed. "Feedback" isn't automatically off-limits — the *rate* is what decides the layer.

## Insertion devices

| Function | Rate | Layer | Notes |
| --- | --- | --- | --- |
| Gap and phase motion | on demand | IOC ([motor](../toolbox/motion.md)) | Coordinated multi-axis |
| Gap limits and collision protection | ms | **PLC** | An ID closing on itself is expensive |
| Feed-forward correction as gap moves | 10 Hz | IOC | Compensating tune and orbit shift — a table lookup driving correctors |
| Cryocooler control (CPMUs) | 1 Hz | IOC | LN₂ level, temperature |
| Superconducting wiggler cryogenics | 1 Hz | IOC + **PLC** interlocks | Quench detection is hardware |
| Gap tracking monochromator energy | on demand | IOC | **Not** a client script — see below |

**Gap tracking is a boundary case worth dwelling on.** A beamline wants the undulator gap to follow its monochromator energy. Implemented as a Python script on a beamline workstation, it stops when the workstation is rebooted, mid-scan, and the user's data becomes quietly wrong. Implemented as `calc`/`transform` records in an IOC, it works because it's part of the control system. This is the [most frequently ignored piece of advice](../toolbox/scanning-and-automation.md#guidance) in EPICS.

## Diagnostics

| Function | Rate | Layer |
| --- | --- | --- |
| Slow orbit (BPM averaged) | 10 Hz | IOC — served as one 180-element waveform, not 180 scalars |
| Turn-by-turn / bunch-by-bunch capture | 568 kHz / on trigger | **FPGA** buffer, read out by IOC after the event |
| Stored current (DCCT) | 10 Hz | IOC |
| Beam loss monitors | 10 Hz | IOC; **interlock function in MPS hardware** |
| Tune measurement | 1 Hz | FPGA + IOC |
| Bunch-by-bunch feedback | 568 kHz | **FPGA** |
| Screens and profile measurement | on demand | IOC ([areaDetector](../toolbox/detectors-and-imaging.md)) |

**The orbit as one waveform, not 180 scalars.** 180 separate PVs read by a physics application give 180 timestamps and a smeared orbit. One waveform assembled in a diagnostics IOC gives a coherent snapshot. This is a small design decision with large downstream consequences, and it must be made before applications are written.

## Front ends

The shielded assembly between ring and beamline: shutters, masks, absorbers, slits, filters, XBPMs, valves.

| Function | Layer |
| --- | --- |
| Photon shutter and safety shutter operation | **PPS PLC** — a shutter is personnel protection |
| Shutter status and open request | IOC (request to PLC) |
| XBPM readings | IOC |
| Absorber and mask temperature | IOC, with **PLC** interlocks |
| Slit motion | IOC ([motor](../toolbox/motion.md)) |
| Beamline vacuum valve interlocks | **PLC** |

The front end is where the accelerator and a beamline meet, and where the personnel protection boundary is most visible. An operator on a beamline requests a shutter open; the PPS decides, based on search state, radiation monitors and interlocks that have nothing to do with EPICS.

## Utilities

| System | Rate | Layer | Notes |
| --- | --- | --- | --- |
| De-ionised water (4 circuits) | 1 Hz | **PLC**, read by EPICS via [OPC UA](../toolbox/plc-and-fieldbus.md#opc-ua) | Flow interlocks protect magnets |
| HVAC / tunnel temperature | 1 Hz | **PLC/BMS**, read by EPICS | Affects orbit stability — archive it |
| Cryogenics | 1 Hz | **PLC**, read by EPICS | |
| Electrical, PDUs, UPS | 1/min | IOC via [SNMP](../toolbox/soft-support-modules.md#other-soft-modules-worth-knowing) | |
| Radiation monitoring | 1 Hz | **PPS**, read-only into EPICS | |

Almost all of conventional facilities is "read a PLC or BMS and present it as PVs". Unglamorous, and it's what lets an operator correlate a beam stability excursion with an air-handling unit changing state at 04:00 — a real and common investigation.

## Summary: what EPICS actually does here

Counting the rows above, EPICS at HLS is responsible for:

- **Device control** — setpoints, readbacks, modes, for several thousand devices
- **Slow sequencing** — startup, cycling, conditioning, bake-out, top-up
- **Slow feedback** — drift correction, feed-forward tables, thermal compensation
- **Aggregation** — turning 180 BPMs into an orbit, 600 SSA modules into a fault count
- **Unit conversion** — one authoritative answer per quantity
- **Alarm limits and summaries**
- **Presenting other systems' state** — PLCs, FPGAs, PPS, BMS
- **Being the interface** for everything above: screens, archiver, physics, experiments

And it is responsible for **no** protection function and **no** loop faster than about 10 Hz.

That division is not a limitation being worked around. It is the design.

## Next

→ [Naming Convention](naming-convention.md)
