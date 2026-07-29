# Naming Convention

The most expensive-to-change decision in the facility. This chapter shows the grammar, the reserved vocabulary, the character budget, and the three places the convention had to bend.

Background on why this matters: [Architecture → Naming Conventions](../architecture/naming-conventions.md).

## The grammar

```text
<SEC> - <AREA> - <CLS> [ - <TYP> ] - <NN> : <Signal> [ - <Qual> ]
```

| Field | Chars | Meaning |
| --- | --- | --- |
| `SEC` | 2–4 | Machine section: `LI`, `BO`, `SR`, `BL07`, `HLS` |
| `AREA` | 2–3 | Location within the section: cell `C05`, straight `S07`, `CF` for facility-wide |
| `CLS` | 2–3 | Device class: `PS`, `VA`, `RF`, `DI`, `MO` |
| `TYP` | 2–4 | Device type within the class: `QF`, `IP`, `BPM`, `CAV`. **Optional** where the class is specific enough. |
| `NN` | 2–3 | Instance number within its area, zero-padded |
| `Signal` | — | What this PV *is*: `Current`, `Pressure`, `Gap`, `BeamPermit` |
| `Qual` | 2–4 | Role: `SP`, `RB`, `Mon`, `Sts`, `Cmd`, `Sum` |

Separators: `-` between structural fields, **one** `:` separating location from signal. `.` is never used — it's reserved for [record fields](../architecture/process-database.md#anatomy-of-a-record).

### Worked examples

```text
SR-C05-PS-QF-01:Current-SP        Storage ring, cell 5, power supply, focusing quad 1, current setpoint
SR-C05-PS-QF-01:Current-RB        …the readback
SR-C05-VA-IP-03:Pressure-Mon      Cell 5, vacuum, ion pump 3, pressure
SR-C05-DI-BPM-02:X-Mon            Cell 5, diagnostics, BPM 2, horizontal position
SR-S07-ID-U18-01:Gap-SP           Straight 7, insertion device, 18 mm-period undulator, gap setpoint
SR-CF-RF-CAV-01:Volt-Mon          Ring-wide, RF, cavity 1, voltage
HLS-CF-DI-DCCT-01:Current-Mon     Facility-wide, diagnostics, DCCT 1, stored current
HLS-CF-MPS-01:BeamPermit-Sts      Facility-wide machine protection, beam permit status (read-only)
BO-C03-PS-BEND-01:Current-RB      Booster, cell 3, dipole supply
LI-S02-RF-KLY-01:Power-Mon        Linac, section 2, klystron 1, forward power
BL07-OP-DCM-01:Energy-SP          Beamline 7, optics, double-crystal monochromator, energy
BL07-EA-DET-01:cam1:AcquireTime   Beamline 7, experimental area, detector 1 — areaDetector suffix
```

Read left to right and you know where you're standing before you know what you're looking at. That's deliberate.

## Reserved vocabulary

Controlled lists. Additions go through the convention's owner, because organically-grown code lists end up containing `PS`, `PSU`, `POW` and `PWR` all meaning power supply.

### Sections

| Code | Section |
| --- | --- |
| `LI` | Linac (including gun) |
| `LTB` | Linac-to-booster transfer line |
| `BO` | Booster |
| `BTS` | Booster-to-storage-ring transfer line |
| `SR` | Storage ring |
| `FE` | Front ends |
| `BL01`–`BL20` | Beamlines |
| `HLS` | Facility-wide (spans sections) |

### Areas

| Code | Meaning |
| --- | --- |
| `C01`–`C20` | Storage ring / booster cells |
| `S01`–`S20` | Storage ring straight sections |
| `S01`–`S06` | Linac sections (within `LI`) |
| `CF` | Section-wide or facility-wide, no specific location |
| `OP` | Optics area (beamlines) |
| `EA` | Experimental area (beamlines) |
| `CT` | Control area / cabin (beamlines) |

### Device classes

| Code | Class |
| --- | --- |
| `PS` | Power supply |
| `MG` | Magnet (the magnet itself: temperature, flow, position) |
| `VA` | Vacuum |
| `RF` | Radio frequency |
| `DI` | Diagnostics |
| `TI` | Timing |
| `ID` | Insertion device |
| `MO` | Motion |
| `OP` | Optics (beamlines) |
| `EA` | End station / detectors |
| `CR` | Cryogenics |
| `WA` | Water / cooling |
| `HV` | HVAC |
| `EL` | Electrical, PDU, UPS |
| `MPS` | Machine protection status (**read-only**) |
| `PPS` | Personnel protection status (**read-only**) |
| `RAD` | Radiation monitoring (**read-only**) |
| `IOC` | IOC self-monitoring ([iocStats](../toolbox/soft-support-modules.md#iocstats--deviocstats)) |
| `GW` | Gateway statistics |

### Signal qualifiers

| Qualifier | Meaning |
| --- | --- |
| `-SP` | Setpoint — what we asked for |
| `-RB` | Readback — what the device reports |
| `-Mon` | Monitored measurement with no corresponding setpoint |
| `-Cmd` | Momentary command (write 1 to act) |
| `-Sts` | Discrete status |
| `-Sum` | Summary: worst severity, or a fault count, over a group |
| `-Enbl` | Enable/disable |
| `-Lim`, `-LimLo`, `-LimHi` | Limits |
| `-Intlk` | **Interlock status, read-only, reflecting a real interlock elsewhere** |
| `-Cnt` | Counter |
| `-Ver` | Firmware/software version |
| `-Raw` | Unconverted value, diagnostics only |

Two of these carry policy weight:

**`-SP` / `-RB` is mandatory wherever both exist.** And a `-RB` must come from the device. A readback implemented as a soft copy of the setpoint is a lie with a plausible face, and it will be believed at the wrong moment.

**`-Intlk` is reserved for reporting.** It may never name logic implemented in EPICS. That one rule makes the [safety boundary](machine-protection.md) legible in the namespace itself: anyone reading a PV list can see which things EPICS merely observes.

## The character budget

```text
S R - C 0 5 - P S - Q F - 0 1 : C u r r e n t - R B
└2┘ └─3─┘ └2┘ └2┘ └2┘   └────10────┘
 2  + 3  + 2 + 2 + 2 = 11 structural + 4 separators + 10 signal = 25 characters
```

Against a 60-character Channel Access limit, that leaves 35 characters of headroom. Deliberately generous, because:

**Third-party modules append to your prefix, and their suffixes are long.**

```text
BL07-EA-DET-01 : HDF1 : FilePathExists_RBV
└─── ours, 14 ───┘ └──── areaDetector's, 24 ────┘
                                          = 38 characters
```

[areaDetector](../toolbox/detectors-and-imaging.md) contributes `NDAttributesFile`, `FilePathExists_RBV`, `PoolUsedBuffers` and similar. [motor](../toolbox/motion.md) contributes its own field conventions. **The rule: budget 20–25 characters for suffixes you don't control.** Facilities that used all 60 characters on their own scheme discovered this when they installed their first detector, and the remedy was a shortened prefix for detector IOCs — a permanent exception to the convention.

## Enforcement

A convention that isn't mechanically checked becomes a suggestion within eighteen months.

**1. The device database is authoritative.** HLS's engineering asset database holds every device, its location and its type. [Substitutions files](../architecture/process-database.md#templates-and-substitutions) are *generated* from it, so a device has the same name in the drawing, on the cable label, and in the control system.

**2. CI validates every name.** A regex over every `.db`, `.template` and `.substitutions` file in every IOC repository, failing the build on a non-conforming name:

```regex
^(LI|LTB|BO|BTS|SR|FE|HLS|BL(0[1-9]|1[0-9]|20))-([A-Z]{2}|C[0-2][0-9]|S[0-2][0-9])-(PS|MG|VA|RF|DI|TI|ID|MO|OP|EA|CR|WA|HV|EL|MPS|PPS|RAD|IOC|GW)(-[A-Z0-9]{2,4})?-[0-9]{2,3}:[A-Za-z0-9]+(-[A-Za-z]{2,4})?$
```

Plus a length check at 60 characters, and an allow-list file for the documented exceptions below. An afternoon to write, and it pays for itself the first week.

**3. [ChannelFinder](../toolbox/directory-services.md) makes duplicates visible.** Every IOC runs [recsync](../toolbox/directory-services.md#recsync); a scheduled job queries for names served by more than one IOC. Two IOCs serving one name is a genuinely nasty bug, and this turns it into an automated report.

**4. `alias()` for migrations.** During a rename, the record answers to both names; consumers migrate; the alias is removed a year later. Planned before it's needed.

## Where the convention bends

Every real convention has exceptions. Documenting them is what separates a convention from a mess.

### 1. Machine protection PVs have no `TYP` field

```text
HLS-CF-MPS-01:BeamPermit-Sts
```

`MPS` is specific enough that a device type adds nothing, and these names are read by operators under stress. Shorter is better. Same for `PPS` and `RAD`.

### 2. Detector IOCs use a shortened prefix

```text
BL07-EA-DET-01:  ← 15 characters, then areaDetector's suffixes
```

No area sub-code, and a two-character instance. Forced by the 60-character limit, as shown above. Documented, allow-listed in CI, and understood by everyone rather than discovered.

### 3. Magnet strings are named for the string, not the magnets

140 dipoles are powered in strings. The supply is `SR-CF-PS-BEND-01`, not seven names implying seven controls. The individual magnets appear only as `MG`-class PVs for temperature and flow — because those *are* per-magnet. Naming a control that doesn't exist is worse than a slightly awkward name.

### 4. Legacy names from the test stand

The magnet test stand predates the convention and its names are wrong. They are aliased, allow-listed, and scheduled for removal — which is honest, and better than either pretending they conform or renaming a working system during commissioning.

## The document

The convention lives as a controlled document with a version number and a named owner, not a wiki page. It contains: the grammar, the complete reserved vocabulary, the character budget with the third-party-suffix rule, the CI regex, the exception allow-list with a reason and an owner for each, and the process for requesting a new code.

Version 3.1 at first beam. It reached 3.1 because versions 1 and 2 were wrong in ways nobody could have predicted from a whiteboard — which is the normal and expected history of a naming convention, and the reason it has a version number at all.

## Next

→ [IOC Inventory](ioc-inventory.md)
