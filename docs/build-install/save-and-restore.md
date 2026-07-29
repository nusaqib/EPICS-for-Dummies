# Install Save and Restore

The service that stores named machine configurations and their snapshots, and — more usefully day to day — diffs them against the live machine.

Overview: [Toolbox → Save & Restore](../toolbox/save-and-restore.md).

| | |
| --- | --- |
| Documentation | [services/save-and-restore](https://control-system-studio.readthedocs.io/en/latest/services/save-and-restore/doc/index.html) |
| Source | `services/save-and-restore` in [phoebus](https://github.com/ControlSystemStudio/phoebus) |
| Client | The Save & Restore application in [Phoebus](phoebus.md) |

## Prerequisites

- [JDK](jdk.md)
- [Phoebus built](phoebus.md) — the service JAR comes from that build
- A backing store as required by the version you're deploying — consult the service documentation, since this has changed across releases (earlier versions used Elasticsearch; check yours)

## Run it

```bash
cd ~/phoebus/services/save-and-restore/target
java -jar save-and-restore-*.jar
```

Configuration is `application.properties`: the backing store's address, the service's own port, and authentication. If you already run Elasticsearch for [ChannelFinder](channelfinder-recsync.md) or [Olog](olog.md), reuse that cluster rather than standing up another.

## Connect Phoebus

```properties
# settings.ini
org.phoebus.applications.saveandrestore/jmasar.service.url=http://saveandrestore.example.org:8080/save-restore
```

Then Applications → Save & Restore.

## Create your first configuration

1. Create a folder structure that mirrors your machine — `Accelerator/Magnets`, `Accelerator/RF`, `Beamlines/BL07`. This structure is how people will find things in two years, so give it five minutes' thought.
2. Create a **configuration**: add the PVs it covers. For each setpoint, also specify its **readback PV** and a **tolerance**.
3. Take a **snapshot**. Add a comment saying *why* — "reference configuration for 3 GeV user operation, 500 mA" is worth far more in a year than the numbers alone.
4. Change a setpoint, then **compare** the snapshot to the live machine. This is the feature you'll use every day.
5. Restore selectively from the diff.

### Readbacks and tolerances are the point

A configuration with setpoint-only PVs tells you what was asked for. A configuration pairing each setpoint with its readback and a tolerance distinguishes:

- *the setpoint changed* — somebody adjusted something;
- *the setpoint is unchanged but the readback disagrees* — **the hardware is not doing what it's told**.

The second case is a fault you'd otherwise find much later, and configuring readbacks properly is the difference between a system that documents your machine and one that also diagnoses it.

## Build configurations from queries

Hand-maintaining a list of 900 magnet setpoints guarantees it's wrong within a month. Generate configurations from a [ChannelFinder](channelfinder-recsync.md) query — "all PVs with `subsystem=magnets` and a name ending `-SP`" — so a newly installed magnet is included automatically.

This is the same argument as for [archiver configuration](archiver-appliance.md#adding-pvs), and it's the main practical reason to deploy a directory service.

## Restore safely

Restore writes hundreds or thousands of PVs at once. Guidance, expanded in the [toolbox page](../toolbox/save-and-restore.md#restoring-safely):

- **Restore into a safe machine state.** Beam off, systems idle. Enforce it with [access security `CALC` rules](../architecture/access-security.md) rather than relying on discipline.
- **Order matters and the service doesn't know your machine.** Where a sequence is required, drive the restore from a [sequencer](../toolbox/scanning-and-automation.md#sequencer-snl) using the snapshot as data.
- **Restore selectively.** Review the diff; restore what you meant to.
- **Don't include readbacks in the restore set.** A configuration contains setpoints.
- **Restrict who can restore, and log it.** A wholesale restore is among the most disruptive single actions available through the control system.

## Operating it

**Back up the database.** Save sets and snapshots may be the only record of a configuration that worked — ranked highly in [what to protect](../architecture/scaling-and-ha.md#what-to-protect-first).

**Take a snapshot before every shutdown**, and one immediately before beam is lost for a long maintenance period. Startup after a shutdown is where this pays for itself several times over.

**Mark golden snapshots** for each machine mode, and keep a document naming which snapshot is authoritative for which mode.

**Test a restore during a maintenance day.** A snapshot nobody has restored is a hypothesis about a file format.

## Don't confuse this with autosave

Different problems, both needed. [autosave](../toolbox/soft-support-modules.md#autosave) is invisible per-IOC reboot survival; this service is deliberate, named, comparable, cross-IOC configurations. Deploy both. The distinction is set out in the [toolbox page](../toolbox/save-and-restore.md).

## Next

→ [Olog](olog.md)
