# Physics Applications and Optimisation

The layer where accelerator physicists drive the machine. These tools sit above EPICS, reading and writing PVs, and they are how a machine gets from "all subsystems nominal" to "beam with the properties we want".

Worth understanding even if you're a controls engineer rather than a physicist: these are your most demanding clients, and the reason they need what they need.

## What a high-level application needs from you

Physics applications ask for things ordinary clients don't:

| Need | Why | What it means for the control system |
| --- | --- | --- |
| **Read hundreds of PVs coherently** | An orbit is 176 BPMs measured at the same time | Either an aggregated array PV, or a [PVA structure/table](../architecture/protocols.md#pv-access-pva) — not 176 separate `caget` calls with 176 different timestamps |
| **Write hundreds of PVs coherently** | A correction applies to 152 correctors at once | No atomic multi-PV write exists. Either an array PV that fans out in the IOC, or accept a spread of a few tens of milliseconds |
| **Engineering ↔ physics units** | Physicists think in K1 (m⁻²), operators and supplies work in amps | Conversion belongs somewhere defined — ideally in the IOC, so everyone shares one answer |
| **A model of the machine** | Response matrices, optics functions, tune predictions | An offline lattice model, kept in sync with reality |
| **Reproducibility** | "Restore the configuration from Tuesday's good run" | [Save & restore](save-and-restore.md) with real configurations |
| **Sensible failure behaviour** | An optimiser must not drive the machine somewhere unsafe | `DRVL`/`DRVH` on every output record; [state-dependent access rules](../architecture/access-security.md) |

The recurring theme: **aggregate the array in the IOC.** A physics application reading 176 BPMs individually gets 176 timestamps and a smeared orbit; reading one waveform PV assembled in a diagnostics IOC gets a coherent snapshot. This is worth designing for early, because retrofitting it means changing every application.

## Lattice modelling and simulation

Offline codes that model the accelerator. EPICS doesn't run these; physicists run them beside the machine and compare.

| Tool | Domain |
| --- | --- |
| **[Accelerator Toolbox (AT / pyAT)](https://github.com/atcollab/at)** | Storage ring lattice modelling, MATLAB and Python. The standard tool in the light source community. |
| **elegant** | Electron accelerator tracking (APS). [aps.anl.gov](https://www.aps.anl.gov/Accelerator-Operations-Physics/Software) |
| **[Ocelot](https://github.com/ocelot-collab/ocelot)** | Python framework for accelerator physics — tracking, optimisation, and online control |
| **MAD-X** | CERN's lattice design code. [madx.web.cern.ch](https://madx.web.cern.ch/) |
| **[OPAL](https://gitlab.psi.ch/OPAL/src)** | Space-charge-dominated beam dynamics (PSI) |
| **[Xsuite](https://xsuite.readthedocs.io/)** | Modern Python tracking suite from CERN |
| **[Bmad / Tao](https://www.classe.cornell.edu/bmad/)** | Cornell's beam dynamics library, with an online-model tradition |

**The online model** is the interesting connection point: a lattice model fed live magnet readbacks, computing optics functions the machine cannot measure directly, and publishing them back as PVs. Facilities that do this well give operators a tune and beta-function display that would otherwise require a measurement. It also gives you a consistency check — a model disagreeing with a measurement means one of them is wrong, and that's a useful alarm.

## High-level application frameworks

| Framework | Notes |
| --- | --- |
| **Matlab Middle Layer (MML)** | The long-standing accelerator physics application layer: a device-abstraction and unit-conversion layer over CA, with orbit correction, response matrix measurement, tune and chromaticity routines. Decades of entrenchment at light sources. [github.com/atcollab/MML](https://github.com/atcollab/MML) |
| **[aphla](https://github.com/NSLS-II/aphla)** | NSLS-II's Python high-level applications layer, an early Python answer to MML. Check current status before adopting. |
| **[pyaccel / PyDM physics apps](https://github.com/slaclab/pydm)** | Several facilities build physics applications as [PyDM](operator-interfaces.md#pydm) screens with Python behind them |
| **Facility-specific** | Every facility has its own. This is genuinely the least standardised area in the ecosystem, because the applications encode the machine's specific physics. |

The MML-to-Python migration is a live, slow conversation at most light sources. The obstacle is not language preference; it's that MML encodes twenty years of validated machine-specific procedures, and reimplementing those correctly is a physics project rather than a porting project.

## Online optimisation

Machine tuning as an optimisation problem: adjust N parameters to maximise an objective (injection efficiency, beam lifetime, photon flux, emittance), where each evaluation costs a measurement on the real machine.

### Xopt

| | |
| --- | --- |
| Source | [github.com/xopt-org/Xopt](https://github.com/xopt-org/Xopt) |
| Documentation | [xopt-org.github.io/Xopt](https://xopt-org.github.io/Xopt/) |

A flexible optimisation framework designed for accelerators: Bayesian optimisation, genetic algorithms, and gradient-free methods, with the machine (or a simulation) as the evaluator. Bayesian methods matter here specifically because evaluations are *expensive* — each one is machine time — so sample efficiency dominates.

### Badger

| | |
| --- | --- |
| Source | [github.com/slaclab/Badger](https://github.com/slaclab/Badger) |

SLAC's optimisation *application* — a GUI and framework wrapping optimisation algorithms for use by operators rather than developers. The distinction matters: Xopt is a library a physicist scripts; Badger is a tool an operator runs during a shift, with the safety rails and visibility that implies.

### Ocelot

[Ocelot](https://github.com/ocelot-collab/ocelot) includes online-optimisation tooling alongside its simulation capabilities, and has been used for machine tuning at several facilities.

## Machine learning

An active research area with real deployments and considerable hype. Where it has demonstrably worked:

- **Surrogate models** — a neural network trained on simulation or archived data, standing in for an expensive computation, enabling optimisation that would otherwise be too slow.
- **Anomaly detection** — learning normal behaviour from [archived](archiving.md) data and flagging deviation. Complements rather than replaces limit-based [alarms](alarms.md), and this is where facility archives suddenly become extremely valuable.
- **Virtual diagnostics** — inferring a quantity that isn't directly measurable from ones that are.
- **Trip and fault prediction** — RF cavity breakdown, in particular, has published successes.

What makes it possible at all is the [archiver](archiving.md): a facility with ten years of well-timestamped, well-named history has a training set, and one without has nothing. That's an argument for archiving discipline that nobody anticipated when the archivers were designed.

The controls-side requirement is unromantic: **trustworthy timestamps, consistent names, and known provenance.** A model trained on data with unsynchronised clocks learns the clock skew.

## Fast feedback

Not EPICS, and important to understand why.

**Fast orbit feedback** at a light source reads ~176 BPMs and drives ~150 correctors at 10 kHz. That's an FPGA system with a dedicated network — the loop closes in hardware, deterministically, with a latency budget in microseconds.

EPICS's role: setpoints, gains, the response matrix, on/off, mode selection, and diagnostics. Every parameter of the loop is a PV; the loop itself is untouchable by the network.

Same picture for LLRF amplitude/phase regulation, and for beam-based interlocks. The dividing line is the [determinism boundary](../architecture/index.md#where-the-boundaries-are-drawn): anything requiring guaranteed latency below roughly 10 ms is not a Channel Access problem.

Understanding this saves a specific, recurring conversation. "Can we do orbit feedback in EPICS?" — the honest answer is that you can do *slow* orbit feedback in EPICS (0.1–1 Hz, correcting drift), and it's genuinely useful; the fast loop is hardware, and always will be.

## Guidance for controls engineers supporting physics

**Give them arrays.** One waveform PV containing 176 BPM readings with one timestamp is worth more than 176 scalar PVs, and it's a change in one diagnostics IOC rather than in every application.

**Put unit conversion in one place.** If the magnet-current-to-K1 conversion exists in MML, in a Python script, and in a spreadsheet, they will disagree, and the disagreement will be discovered during a machine study. In the IOC is best; in one shared library is acceptable; in three places is a future incident.

**Set `DRVL`/`DRVH` on everything an optimiser can touch.** An optimisation algorithm will explore. It should not be able to explore somewhere harmful, and record-level clamping is the protection that cannot be bypassed by a client bug. This is the single most important thing you can do to make online optimisation safe.

**Expect them to want to write a lot of PVs quickly.** Design for it: array PVs that fan out inside the IOC, and honest documentation of what "simultaneous" actually means on your system.

**Make save/restore work well.** Physics studies are experiments, and reverting is part of the method. A physicist who trusts the restore path takes more useful risks.

**Archive everything they might correlate.** Physics analysis is retrospective by nature, and the request is always for data nobody thought to keep. See [what to archive](archiving.md#what-to-archive).

**Learn some of the physics.** You don't need to design a lattice, but knowing what a tune is, why chromaticity matters, and what an orbit correction does will make you dramatically better at your job — and it's the difference between implementing requests and understanding them.

## Next

→ [Deployment & Operations](deployment-and-operations.md)
