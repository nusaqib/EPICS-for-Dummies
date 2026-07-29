# Save and Restore

Two different problems that people conflate, then solve badly.

| | **autosave** | **save & restore service** |
| --- | --- | --- |
| Question it answers | "How do I survive an IOC reboot?" | "What settings did we run the 2 keV experiment with?" |
| Scope | One IOC, its own PVs | Facility-wide, cross-IOC |
| Who uses it | Nobody — it's invisible | Operators and physicists, deliberately |
| Storage | Local `.sav` files | A service with a database and history |
| Granularity | Everything configured, automatically | Named, curated sets |
| Comparison | No | Yes — diff a snapshot against now |

**You want both.** They don't overlap.

## autosave

Covered in [Soft Support Modules → autosave](soft-support-modules.md#autosave). In one line: it periodically writes selected PV values to a local file and restores them at `iocInit`, so restarting an IOC doesn't reset every setpoint to zero.

- [github.com/epics-modules/autosave](https://github.com/epics-modules/autosave)
- [autoSaveRestore.md](https://github.com/epics-modules/autosave/blob/master/docs/autoSaveRestore.md)
- [Autosave](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/09%20Autosave.pdf) and [its lab exercise](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/09l%20Autosave%20Lab.pdf) (USPAS)

## Phoebus Save & Restore service

| | |
| --- | --- |
| Documentation | [Save-and-restore service](https://control-system-studio.readthedocs.io/en/latest/services/save-and-restore/doc/index.html) |
| Source | Part of [phoebus](https://github.com/ControlSystemStudio/phoebus) |
| UI | The Save & Restore application in [Phoebus](operator-interfaces.md#phoebus) |
| This guide | [Install save & restore](../build-install/save-and-restore.md) |

A REST service with two core concepts:

- **Configuration** (historically "save set") — a named list of PVs, optionally with per-PV readback PVs and comparison tolerances.
- **Snapshot** — the values of a configuration's PVs at a moment in time, with a comment and an author, stored forever.

What you do with them:

| Operation | Use |
| --- | --- |
| **Take a snapshot** | Before changing anything. Before and after a shutdown. At the end of a successful run. |
| **Compare snapshot to live** | "What's different from Tuesday?" — the single most valuable feature. |
| **Compare snapshot to snapshot** | "What changed between the good run and the bad one?" |
| **Restore** | Write the snapshot's values back, selectively or wholesale |
| **Golden snapshots** | Mark a snapshot as the reference configuration for a machine mode |
| **Composite configurations** | Build a machine-wide set from subsystem sets |

**The comparison feature is the point.** Restoring is occasionally useful and slightly frightening; *diffing* is useful every single day. "The machine behaved differently after the maintenance day" becomes a list of 23 PVs that changed, in about ten seconds, instead of an afternoon of guessing.

### Readback PVs and tolerances

A configuration can pair each setpoint with its readback and a tolerance. Then a snapshot comparison distinguishes:

- *the setpoint changed* — somebody adjusted something;
- *the setpoint is the same but the readback disagrees* — **the hardware is not doing what it's told**.

The second case is a fault you would otherwise find much later. Configuring readbacks and tolerances properly is the difference between a save/restore system that documents your machine and one that also diagnoses it.

## Restoring safely

Restore writes hundreds or thousands of PVs. That deserves respect.

**Order matters and the service doesn't know your machine.** Enabling a power supply before setting its current, or setting current before enabling, are not equivalent. For anything with a sequence requirement, drive the restore through a [sequencer](scanning-and-automation.md#sequencer-snl) or a scripted procedure that knows the order, using the snapshot as data.

**Restore into a safe machine state.** Full restores belong in "beam off, systems idle", not during operation. [Access security](../architecture/access-security.md) `CALC` rules that make setpoints writable only when the beam permit is off enforce this in the IOC, independently of anyone's discipline.

**Ramp, don't step.** Writing a magnet's current setpoint from 0 to 200 A instantaneously is a request the supply will honour as fast as it can. Where ramping matters, it belongs in the IOC (a `calcout`-driven ramp, or the supply's own ramp-rate setting) so it applies to *every* write, not only to restores.

**Restore selectively by default.** Review the diff, restore what you meant to. A wholesale restore of a set assembled two years ago will include PVs nobody remembers adding.

**Don't restore readbacks.** A configuration should contain setpoints. Including readbacks in the restore list means writing to records that either reject it or, worse, accept it and lie.

## Related tools

| Tool | Notes |
| --- | --- |
| **MASAR** | MAchine Snapshot, Archiving and Retrieval — an earlier PVA-based service from NSLS-II. Largely superseded by the Phoebus service; you may meet it. |
| **[Archiver](archiving.md)** | Not a save/restore system, but "what were all these values at 14:03 last Tuesday?" is a retrieval query, and a legitimate way to reconstruct a configuration when no snapshot exists. |
| **[caputRecorder](https://github.com/epics-modules/caputRecorder)** | Records operator `caput` actions as replayable Python. A different tool for a related need: capturing a *procedure* rather than a *state*. |
| **Facility scripts** | Many labs have homegrown snapshot tooling predating these services. Fine, until the author leaves. |

## What to put in a configuration

| Configuration | Contents |
| --- | --- |
| **Machine mode: user operation** | Every accelerator setpoint that defines the standard delivered beam. The golden reference. |
| **Machine mode: injection / commissioning / machine study** | The alternatives, so switching modes is a restore rather than an afternoon. |
| **Per-subsystem** | Magnets, RF, insertion devices, diagnostics — so a subsystem can be reverted alone after work on it. |
| **Per-beamline** | Optics, slits, detectors, sample environment — beamlines change configuration between every experiment, and this is where save/restore gets used most heavily. |
| **Per-experiment** | The configuration a particular user group ran. Restoring it six months later when they return is a genuinely valued capability. |
| **Post-shutdown reference** | A snapshot of the working machine taken immediately before a long shutdown. Startup after a shutdown is where this earns its cost several times over. |

## Guidance

**Snapshot before you touch anything.** Free, takes seconds, and it's the difference between "revert" and "reconstruct".

**Snapshot when things are good, with a comment saying why.** `"Best injection efficiency of the run, 94%, after Tuesday's tune adjustment"` is worth more in a year than the values alone.

**Build configurations from [ChannelFinder](directory-services.md) queries.** "All storage ring magnet setpoints" as a query means a new magnet is included automatically. A hand-maintained list of 900 PVs will be wrong within a month.

**Back up the service's database.** Save sets and snapshots may be the only record of a configuration that worked. Ranked highly in [what to protect](../architecture/scaling-and-ha.md#what-to-protect-first) for good reason.

**Review who can restore.** A wholesale restore is one of the most disruptive single actions available through the control system. Restrict it in the service and with [access security](../architecture/access-security.md), and log it.

**Test restores during a maintenance day.** A snapshot nobody has restored is a hypothesis about a file format.

## Next

→ [Electronic Logbooks](logbooks.md)
