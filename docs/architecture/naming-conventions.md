# Naming Conventions

The PV name is the whole API. It is also flat, global, and limited to 60 characters. This page is about why that combination makes naming a design activity rather than a clerical one.

## Why it matters more than it looks

Rename one PV and you break, silently and in parallel:

- every operator screen that references it;
- the archiver's continuity — history is stored *by name*, so a rename splits one signal into two half-histories;
- alarm configuration and its acknowledgement history;
- every save set that includes it;
- every physics script, notebook, and MATLAB file anyone has written in ten years;
- other IOCs' CA links, which will simply report the channel as never connecting.

A PV name is a public interface with an indefinite support obligation. Facilities that got this wrong early carry the cost for decades, usually as a translation layer or a second parallel namespace nobody trusts.

## The hard constraints

| Constraint | Value | Consequence |
| --- | --- | --- |
| Max name length | **60 characters** (`PVNAME_STRINGSZ` = 61 with terminator) | Every field of your convention competes for a fixed budget. |
| Namespace | **Flat and global** per broadcast domain | Two IOCs serving one name is a live bug; there is no namespacing to save you. |
| Case | Sensitive | `Current` and `current` are different PVs. Pick one style and enforce it. |
| Field suffix | `.FIELD` is reserved | `:Current.EGU` is the units field. Never use `.` as a structural separator in your own names. |
| Practical safe characters | `A–Z a–z 0–9 : - _ [ ] < > ;` | `:` and `-` are near-universal. Avoid spaces, `*`, `?`, and `.`. Wildcards in `camonitor`, ChannelFinder queries, and Phoebus regex will trip over exotic characters. |
| Field name length | 4 characters | Why record fields are `HIHI` and `MDEL` rather than words. |

## The standard shape

Most conventions in the community are variations on:

```text
<location/system> : <device> <index> - <property/signal>
```

Real examples, so you can see the family resemblance:

| Facility style | Example | Reading |
| --- | --- | --- |
| SNS | `SCL_LLRF:FCM01a:cavAmpSet` | System : device : signal |
| NSLS-II | `SR:C03-MG{PS:QH1}I:Sp1-SP` | System : cell - type { device } signal |
| ESS | `LEBT-010:PBI-BPM-001:XPos` | Section-subsection : discipline-device-index : signal |
| Diamond | `BL13I-MO-TABLE-01:X.RBV` | Beamline - discipline - device - index : signal |
| APS | `S05:ID:Gap` | Sector : device : signal |

Common structure, different punctuation. The lesson is not "copy one of these" — it's that every one of them encodes **location**, **device class**, **instance**, and **signal**, in that order, because that ordering is what makes wildcards useful.

### Why location comes first

`SR-C05-*` gets you everything in cell 5. `*-PS-*` gets you every power supply. Put the device class first instead and "show me everything in the cell I'm standing in" — the single most common operational query — becomes impossible to express as a prefix.

Prefix-matching is also how [gateway](../toolbox/gateways.md) access rules, [archiver](../toolbox/archiving.md) policies, [alarm](../toolbox/alarms.md) tree structure, and [access security](access-security.md) rules are all written. Your name structure *is* your policy structure. Get the ordering wrong and every policy file becomes a list of special cases.

## Setpoint versus readback

The one distinction to get right if you get nothing else right.

```text
SR-C05-PS-QF-01:Current-SP    what we asked for
SR-C05-PS-QF-01:Current-RB    what the supply reports
```

Confusing these is a genuinely dangerous class of error: an operator reads back the value they typed, concludes the magnet is at field, and it isn't. Common conventions: `-SP`/`-RB`, `:Set`/`:Get`, `-Cmd`/`-Sts` for discrete commands, `-I`/`-O`. Any of them work. Ambiguity does not.

Corollary worth stating: **a readback should come from the device, not from the setpoint record.** A `Current-RB` implemented as a soft copy of `Current-SP` is a lie with a plausible face, and it will eventually be believed at exactly the wrong moment.

## Property suffix vocabulary

Facilities converge on a small suffix vocabulary, which is worth defining once and enforcing:

| Suffix | Meaning |
| --- | --- |
| `-SP` / `-RB` | Setpoint / readback |
| `-Cmd` | Momentary command (write 1 to act) |
| `-Sts` | Discrete status |
| `-On`, `-Off`, `-Rst` | Specific commands |
| `-Mon` | Monitored measurement with no corresponding setpoint |
| `-Cnt` | Counter |
| `-Lim`, `-LimLo`, `-LimHi` | Limits |
| `-Enbl` | Enable/disable |
| `-Intlk` | Interlock status (**read-only status of a real interlock elsewhere**) |
| `-Sum` | Summary — worst severity of a group |
| `-Ver` | Firmware or software version |
| `-Raw` | Unconverted value, for diagnostics |

Reserving `-Intlk` strictly for *reporting* the state of a protection system that lives in a PLC — never for logic implemented in EPICS — is a small discipline that keeps the [safety boundary](../example-facility/machine-protection.md) legible in the namespace itself.

## Budgeting 60 characters

Take the example facility's convention:

```text
SR - C05 - PS - QF - 01 : Current-RB
2    3     2    2    2    10        = 21 characters + 5 separators = 26
```

Comfortable. Now a beamline detector plugin, where areaDetector appends its own long suffixes:

```text
BL07-EA-DET-01:HDF1:FilePath_RBV
                    └─ areaDetector's, not yours ─┘
```

Third-party modules append to *your* prefix, and some of their suffixes are long (`FilePathExists_RBV`, `NDAttributesFile`). The rule that follows: **budget roughly 20 characters of your 60 for suffixes you don't control.** Facilities that used all 60 on their own scheme discovered this when they installed their first detector.

## Making it stick

A convention that isn't mechanically enforced becomes a suggestion within eighteen months.

1. **Write it down as a controlled document**, with a version number and an owner. Not a wiki page that anyone edits.
2. **Maintain the authoritative device list outside EPICS** — usually the facility's asset or engineering database — and *generate* [substitutions files](process-database.md#templates-and-substitutions) from it. Names then trace back to a source of truth, and the same device has the same name in the drawing, the cable label, and the control system.
3. **Validate in CI.** A regex check over every `.db` and `.substitutions` file in every IOC repository, failing the build on a non-conforming name, costs an afternoon to write and pays for itself immediately.
4. **Register everything in [ChannelFinder](../toolbox/directory-services.md)** via [recsync](../toolbox/directory-services.md#recsync). Now duplicates are *visible* — a query that returns one name from two IOCs is a bug report you didn't have to wait for.
5. **Publish the reserved vocabulary** — the area codes, the device-class codes, the suffixes — and require additions to go through the same owner. A device-class code list that grows organically ends up with `PS`, `PSU`, `POW`, and `PWR` all meaning power supply.
6. **Have a deprecation path.** `alias()` lets one record answer to an old and a new name simultaneously, which makes a rename survivable: add the alias, migrate consumers, remove the alias a year later. Plan this before you need it.

## Aliases and the migration escape hatch

```text
record(ai, "SR-C05-PS-QF-01:Current-RB") {
    # ... fields ...
    alias("S05:QF1:currentRB")     # the 2009 name, kept alive
}
```

The alias is a full PV: it connects, monitors, and archives identically. Use it for renames, and for exposing a legacy name to old scripts while new code uses the new one. Do *not* use it to give one signal two names permanently for convenience — then the archiver stores it twice, and two half-populated histories are worse than one.

## Anti-patterns

| Anti-pattern | Why it hurts |
| --- | --- |
| Encoding the IOC name in the PV name | The IOC is deployment detail. Consolidating two IOCs then forces a facility-wide rename. |
| Encoding the hardware channel (`:ADC3CH7`) | Rewiring the crate invalidates the name. Name the *signal*. |
| Free-text-ish names (`Quad5CurrentReadbackValue`) | Not wildcard-able, not policy-able, and 33 of your 60 characters gone. |
| Inconsistent separators (`SR:C05-PS:QF_01`) | Every consumer needs a bespoke parser, and every regex is wrong somewhere. |
| Using all 60 characters | Third-party modules will append to it. See above. |
| One-off exceptions "just for the test stand" | The test stand becomes production. This is the single most reliable prediction in this document. |
| Sequential numbers with no location (`BPM001`…`BPM176`) | Physically meaningless, and renumbering after an insertion is a facility-wide edit. |

## Worked example

The [Helios Light Source naming convention](../example-facility/naming-convention.md) applies all of this to a concrete machine: the full grammar, the reserved area and device-class codes, the character budget, the CI regex, and the cases where the convention had to bend.

## Next

→ [Networking](networking.md) — how those names get resolved across a real facility network.
