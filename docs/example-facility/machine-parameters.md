# Machine Parameters

What the Helios Light Source is, physically. Every later chapter's device counts, PV counts and IOC counts derive from this page.

!!! warning "Fictional"
    Plausible, internally consistent, and invented. See the [caveat](index.md).

## Storage ring

| Parameter | Value |
| --- | --- |
| Beam energy | 3.0 GeV |
| Circumference | 528 m |
| Lattice | 20 × seven-bend achromat (MBA) |
| Number of cells | 20 |
| Straight sections | 20 (5.0 m usable) |
| Horizontal emittance | 100 pm·rad |
| Vertical emittance | 8 pm·rad (coupling ~8%) |
| Stored current | 500 mA (500 mA multibunch; 200 mA in timing mode) |
| Fill pattern | 400 of 704 buckets, multibunch; 40-bunch timing mode |
| RF frequency | 499.68 MHz |
| Harmonic number | 704 |
| Revolution frequency | 568 kHz |
| Beam lifetime | ~4 h at 500 mA with harmonic cavities |
| Injection | Off-axis, top-up every ~120 s, current held within ±0.5% |
| Orbit stability target | < 10% of beam size, 0.1–1000 Hz, with fast orbit feedback |

## Injector

| Parameter | Value |
| --- | --- |
| Gun | Thermionic, 90 kV |
| Linac | 150 MeV, S-band (2998 MHz), 4 accelerating structures |
| Linac repetition rate | 10 Hz |
| Booster | 3.0 GeV, 528 m, concentric with the storage ring in the same tunnel |
| Booster ramp | 1 Hz, 150 MeV → 3.0 GeV |
| Booster RF | 499.68 MHz, one cavity |
| Transfer lines | LTB (linac→booster), BTS (booster→storage ring) |

Concentric booster in the same tunnel is a real design choice at several 4th-generation facilities: it saves civil cost and constrains the controls layout, since booster and ring equipment share racks, cable routes and radiation zones. It matters here because it means booster and ring IOCs sit in the same technical galleries, and a radiation zone spans both.

## Magnets

| Type | Count | Notes |
| --- | --- | --- |
| Dipoles (combined function) | 140 | 7 per cell; powered in strings |
| Quadrupoles | 480 | Individually powered where the optics require it |
| Sextupoles | 240 | Chromaticity and harmonic correction |
| Slow correctors | 360 | Horizontal and vertical, DC to ~1 Hz |
| Fast correctors | 160 | Air-coil, part of the 10 kHz orbit feedback loop |
| Skew quadrupoles | 40 | Coupling correction |
| **Total magnets** | **1 420** | |
| **Individually powered supplies** | **≈ 900** | The rest are in series strings |

The ≈900 figure drives the largest single block of PVs in the facility. See [PV inventory](ioc-inventory.md#pv-inventory).

## RF

| Parameter | Value |
| --- | --- |
| Main cavities | 2 × normal-conducting, 499.68 MHz |
| Amplifiers | 2 × 160 kW solid-state (SSA), each ~600 modules |
| Harmonic cavities | 3 × passive, 1.499 GHz, for bunch lengthening |
| Booster cavity | 1 × 499.68 MHz, 50 kW SSA |
| Linac | 4 × S-band structures, 2 klystrons + modulators |
| LLRF | FPGA-based amplitude/phase regulation per cavity |

Solid-state amplifiers matter for the control system in a way klystrons don't: 600 modules per amplifier means a large number of individually monitored sub-devices, and the interesting operational question is "how many modules are we down?" rather than "is it on?".

## Vacuum

| Item | Count |
| --- | --- |
| Vacuum sectors | 100 (with sector valves) |
| Ion pumps | 140 |
| NEG-coated chamber sections | Most of the ring |
| Cold-cathode / Bayard-Alpert gauges | 320 |
| Turbo pump stations | 40 |
| Sector valves | 100 |
| Design pressure | < 1 × 10⁻⁹ mbar |

Vacuum is the archetypal EPICS subsystem: many identical slow devices, mostly serial protocols, all needing alarm limits and long-term trending. It's also where the [PLC boundary](machine-protection.md) is clearest — valve *interlocks* are PLC logic; valve *status and commands* are EPICS.

## Diagnostics

| Device | Count | Notes |
| --- | --- | --- |
| Beam position monitors | 180 | 9 per cell; button electrodes + digitiser electronics |
| X-ray BPMs | 30 | In the front ends, 2 per ID beamline |
| DC current transformers | 2 | Stored current, redundant |
| Beam loss monitors | 120 | Distributed around the ring |
| Screens / flags | 24 | Injector and transfer lines |
| Streak camera | 1 | Bunch length |
| Tune measurement | 1 system | Bunch-by-bunch capable |
| Bunch-by-bunch feedback | 3 systems | Horizontal, vertical, longitudinal |

180 BPMs at 10 kHz is what makes [fast orbit feedback](subsystems.md#fast-orbit-feedback) an FPGA problem rather than an EPICS problem.

## Insertion devices

| Type | Count | Notes |
| --- | --- | --- |
| In-vacuum undulators | 8 | Gap 4–20 mm |
| Cryogenic permanent magnet undulators | 4 | ~80 K, LN₂ cooled |
| Elliptically polarising undulators | 2 | Gap and phase control |
| Superconducting wiggler | 1 | Cryogenic, own cryostat |
| **Total** | **15** | In 20 straights: 15 IDs, 1 injection, 1 RF, 3 reserved |

## Beamlines

Twenty at full build-out: 15 on insertion devices, 5 on bending magnets. The [beamline chapter](beamline.md) works through one of them (BL07, a hard X-ray microfocus beamline) in full.

Phase 1 commissions 8; the [inventory](ioc-inventory.md) numbers below are at full build-out.

## Utilities and conventional facilities

Not glamorous, and a substantial fraction of the control system:

| System | Notes |
| --- | --- |
| De-ionised water | 4 circuits: magnets, RF, front ends, beamlines. Flow, temperature, conductivity, pressure. |
| HVAC | Tunnel and experimental hall temperature stability ±0.5 °C — directly affects beam stability |
| Cryogenics | LN₂ distribution for CPMUs; a helium plant for the superconducting wiggler |
| Compressed air | Pneumatic valves and actuators |
| Electrical | 30 PDUs, UPS for controls and diagnostics |
| Radiation monitoring | Area monitors, interlocked to the [PPS](machine-protection.md) |

Tunnel temperature stability is a *beam physics* parameter dressed as a building service. Air temperature changes move girders, which moves magnets, which moves the orbit. Which is why HVAC data is archived alongside orbit data and correlated during stability investigations.

## Timing

| Parameter | Value |
| --- | --- |
| Reference | 499.68 MHz RF master oscillator |
| Event system | Micro-Research Finland EVG/EVR over fibre, driven by [mrfioc2](../toolbox/timing-systems.md#mrfioc2) |
| Machine cycle | 10 Hz (linac), 1 Hz (booster ramp) |
| Event receivers | ~60, in injector, booster, ring diagnostics, front ends and beamlines |
| Timestamp accuracy | ns-level within the event system; NTP elsewhere |

## Operating modes

| Mode | Description |
| --- | --- |
| **User operation** | 500 mA multibunch, top-up, all beamlines, orbit feedback on. The default. |
| **Timing mode** | 200 mA, 40 bunches, for time-resolved experiments |
| **Machine study** | Beam available, physicists have expanded write access, beamline shutters closed |
| **Injector only** | Booster and linac running, ring off — commissioning and tuning |
| **Beam off / access** | No beam, tunnel accessible, PPS in access state |
| **Shutdown** | Extended maintenance; large parts of the machine powered down |

Modes matter to the control system in three concrete ways: they gate write permissions via [access-security `CALC` rules](../architecture/access-security.md), they select which [alarms are enabled](alarm-plan.md), and each has a [golden save set](../toolbox/save-and-restore.md) defining its configuration.

## Next

→ [Subsystems](subsystems.md) — what all this means for control.
