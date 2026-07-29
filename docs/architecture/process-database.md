# The Process Database

The process database is EPICS's central idea and the part that takes longest to internalise. It is a **declarative, continuously evaluated dataflow graph** that happens to be written in a syntax resembling a config file.

Authoritative references:

- [EPICS Process Database Concepts](https://docs.epics-controls.org/en/latest/guides/EPICS_Process_Database_Concepts.html) — start here
- [Application Developer's Guide](https://docs.epics-controls.org/en/latest/appdevguide/AppDevGuide.html) — chapters 3–6 are the specification
- [Record Reference Manual](https://epics.anl.gov/base/R7-0/6-docs/RecordReference.html) — every field of every standard record type

## Anatomy of a record

```text
record(ai, "SR-C05-VA-IP-03:Pressure") {
    field(DESC, "Sector 5 ion pump 3 pressure")
    field(DTYP, "stream")
    field(INP,  "@ionpump.proto getPressure($(PORT))")
    field(SCAN, "1 second")
    field(EGU,  "mbar")
    field(PREC, "3")
    field(LINR, "NO CONVERSION")
    field(HIGH, "1e-8")   field(HSV,  "MINOR")
    field(HIHI, "1e-7")   field(HHSV, "MAJOR")
    field(ADEL, "5")      # archive deadband: log if changed by >5%
    field(MDEL, "1")      # monitor deadband: notify if changed by >1%
    field(TSE,  "0")      # timestamp source: 0 = IOC clock at processing
}
```

`record(<type>, "<name>")` then fields. That's the whole syntax. The subtlety is entirely in which fields exist and what they do.

### Fields every record has

| Field | Purpose |
| --- | --- |
| `VAL` | The value. `PVname` alone means `PVname.VAL`. |
| `NAME`, `DESC` | Name and a 40-character description. `DESC` shows up on screens and in the alarm tree, so writing it well is real work. |
| `SCAN` | [When this record processes](#scanning-and-processing). |
| `DTYP` | Which device support to use. `Soft Channel` means "no hardware, get the value from a link". |
| `PHAS` | Ordering within a scan pass — lower phases process first. The tool for "read all inputs before computing". |
| `PINI` | Process once at `iocInit`. Essential for output records that must push an initial value. |
| `SEVR`, `STAT` | Current [alarm severity and status](../start-here/core-concepts.md#8-alarms-and-severity). Read-only. |
| `TIME`, `TSE`, `TSEL` | The timestamp, and where it comes from — the IOC clock, a hardware event, or another record. |
| `DISA`, `DISV`, `SDIS` | Conditional disabling. `SDIS` supplies a value; if it equals `DISV`, the record does not process. |
| `ASG` | [Access security](access-security.md) group. |
| `FLNK` | Forward link: process this record next, after I'm done. |

### Analog-record fields you'll set constantly

| Field | Purpose |
| --- | --- |
| `EGU` | Units string. Every screen displays it. Fill it in. |
| `PREC` | Display precision. |
| `LOPR`, `HOPR` | Display range — what a bar graph or dial scales to. |
| `DRVL`, `DRVH` | Drive limits on output records: writes are **clamped** to this range by the IOC. A cheap, local, always-enforced protection that no client can bypass. |
| `LOLO`/`LOW`/`HIGH`/`HIHI` + `LLSV`/`LSV`/`HSV`/`HHSV` | Alarm limits and the severity each raises. |
| `HYST` | Alarm hysteresis — the cure for a value chattering across a limit. |
| `MDEL` | Monitor deadband. Change smaller than this posts no monitor. Directly controls network load. |
| `ADEL` | Archive deadband. Change smaller than this posts no archive event. Directly controls storage cost. |
| `SMOO` | First-order smoothing filter, 0–1. Convenient and occasionally a trap: you are now archiving a filtered value and calling it a measurement. |
| `LINR`, `EGUL`, `EGUF`, `ESLO`, `EOFF` | Raw-to-engineering conversion. Linear, or one of the built-in breakpoint tables for thermocouples and RTDs. |

!!! tip "`MDEL` and `ADEL` are the two most consequential fields nobody sets"
    A noisy analog input with `MDEL` unset posts a monitor on every process, to every client, forever. Multiply by 400 000 records and you have designed a network problem. Setting these thoughtfully at record-creation time is much easier than retrofitting them across a facility.

## Record types worth knowing

Grouped by what they're for. Full list in the [record types reference](../reference/record-types.md).

**Input**: `ai` (analog), `bi` (binary), `mbbi` (enumerated), `mbbiDirect` (bit field → 16 bits), `longin`, `int64in`, `stringin`, `lsi` (long string), `waveform` (arrays), `aai`.

**Output**: `ao`, `bo`, `mbbo`, `mbboDirect`, `longout`, `int64out`, `stringout`, `lso`, `aao`.

**Computation and logic**:

| Type | What it does |
| --- | --- |
| `calc` | Evaluates `CALC` expression over inputs `INPA`–`INPL`. The workhorse. |
| `calcout` | `calc` plus an output link, optional delay (`ODLY`), and output-execution conditions (`OOPT`) — "write only when the result changes", "only on transition to non-zero". |
| `acalcout` | Array version. |
| `seq` | Writes up to sixteen values to sixteen links, optionally with delays. Sequencing without a state machine. |
| `sub`, `aSub` | Calls a C function you've registered. The escape hatch when expressions run out. |
| `fanout` | Processes up to sixteen records in order. |
| `dfanout` | Distributes one value to up to eight outputs. |
| `sel` | Selects one of several inputs — specific index, max, min. |
| `compress` | Array compression: circular buffer, N-to-1 averaging, min/max. How you build a local history buffer. |
| `histogram` | Accumulates a value into bins. |
| `state`, `permissive` | Small stateful helpers, occasionally exactly right. |

**From modules**: `motor` ([motor](../toolbox/motion.md)), `scaler`, `transform` and `swait` ([calc](../toolbox/soft-support-modules.md#calc)), `sscan` ([sscan](../toolbox/scanning-and-automation.md#sscan)), `busy` ([busy](../toolbox/soft-support-modules.md#busy)), `asyn` ([asyn](../toolbox/soft-support-modules.md#asyn)), `NDPluginBase`-driven records ([areaDetector](../toolbox/detectors-and-imaging.md)).

## Links: how records connect

A link is a field whose value is a *reference*, not data. Three kinds:

| Kind | Example | Meaning |
| --- | --- | --- |
| **Constant** | `field(INPA, "3.14")` | A literal, applied at init. |
| **Database (DB) link** | `field(INPA, "OtherRecord.VAL PP")` | A record in *this* IOC. Resolved at init; direct memory access, no network, and the source of lock sets. |
| **Channel Access (CA) link** | `field(INPA, "OtherIoc:Record CP")` | Goes over the network, even to a record in the same IOC if you force it with `CA`. |

### Link modifiers: the part that bites

| Modifier | Effect |
| --- | --- |
| `NPP` | *No Process Passive*: read the target's current value without processing it. **Default.** Fast; may be stale. |
| `PP` | *Process Passive*: process the target first (if it's `Passive`), then read it. Gets you a fresh value. |
| `CA` | Force the link through Channel Access even for a local record — breaks the lock set deliberately. |
| `CP` | *CA + Process*: monitor the target; process **this** record whenever the target changes. Event-driven, no polling. |
| `CPP` | Like `CP` but only processes this record if it is `Passive`. |
| `MS` / `MSS` / `MSI` / `NMS` | Maximise Severity: propagate the target's alarm severity (all / status too / only `INVALID` / not at all). This is how alarms flow through a database. |

Two idioms cover most real work:

```text
# 1. Pull-on-demand: a summary computed only when someone reads it
record(calc, "Sys:TotalPower") {
    field(SCAN, "Passive")
    field(INPA, "PS1:Power PP MS")   # process each source, inherit its severity
    field(INPB, "PS2:Power PP MS")
    field(CALC, "A+B")
}

# 2. Push-on-change: react immediately, no polling anywhere
record(calc, "Sys:Interlock") {
    field(INPA, "Vac:Pressure CP MS")  # any change to either input...
    field(INPB, "Temp:Reading CP MS")  # ...processes this record
    field(CALC, "(A<1e-7)&&(B<40)")
    field(OUT,  "Perm:Beam PP")
}
```

Prefer `CP` over periodic scanning wherever the semantics allow: fewer wasted cycles, lower latency, and the resulting behaviour is easier to reason about.

## Scanning and processing

| `SCAN` | When it processes |
| --- | --- |
| `Passive` | Only when asked — a `PP` link, an `FLNK`, or a client write. The default and the most common. |
| `Event` | On event number `EVNT`. Post events from software (`post_event`) or a [timing system](../toolbox/timing-systems.md). The tool for machine-synchronous acquisition. |
| `I/O Intr` | When the driver says there's new data. Lowest latency, least waste — use it whenever support offers it. |
| `10 second` … `.1 second` | The ten standard periodic rates. Configurable in `dbd` if you need others. |

**Scan tasks and priority.** Each periodic rate runs on its own thread; records also carry `PRIO` (`LOW`/`MEDIUM`/`HIGH`) which selects the callback queue for processing triggered asynchronously. A slow device on the wrong priority can starve the queue it shares.

**Synchronous vs asynchronous processing.** Device support that can't answer immediately (a 200 ms serial round trip) marks the record `PACT` (processing active), returns, and completes later via a callback. The scan thread isn't blocked — but a second process request while `PACT` is set is *discarded*, which is why hammering a slow record with `caput` silently loses writes. This is also why the [busy record](../toolbox/soft-support-modules.md#busy) exists: to represent "still working" to clients honestly.

## Lock sets: the thing that eventually bites you

Records connected by **DB links** (not CA links) form a **lock set**. Before processing any record in a lock set, the IOC takes a single lock covering the whole set.

Consequences:

- A large, densely linked database can produce a lock set of hundreds of records, all serialised behind one mutex. One slow record then throttles the lot.
- A DB link chain that loops back on itself is a deadlock risk; Base detects some cases and refuses, but not all.
- **Inserting a `CA` link deliberately splits a lock set.** That's the standard remedy for "my fast records are being blocked by a slow one", at the cost of a network hop and slightly looser consistency.

`dbLockShowLocked` on the IOC shell shows lock sets. If a database "feels slow" for no visible reason, look here.

## Templates and substitutions

You do not write 176 BPMs by hand.

```text
# bpm.template
record(ai, "$(P)$(R):X") {
    field(DESC, "$(DESC=Horizontal position)")
    field(INP,  "@$(PORT) X $(ADDR)")
    field(EGU,  "mm")
    field(PREC, "4")
    field(HIHI, "$(XLIMIT=2.0)")  field(HHSV, "MAJOR")
}
record(ai, "$(P)$(R):Y") {
    field(INP,  "@$(PORT) Y $(ADDR)")
    field(EGU,  "mm")
    field(PREC, "4")
}
```

```text
# bpms.substitutions
file "bpm.template" {
    pattern { P,          R,        PORT,    ADDR, XLIMIT }
            { "SR-C01-", "DI-BPM-01", "BPM1", 0,    2.0 }
            { "SR-C01-", "DI-BPM-02", "BPM1", 1,    2.0 }
            { "SR-C02-", "DI-BPM-01", "BPM2", 0,    1.5 }
}
```

`msi` (macro substitution and include) expands these at build time; `dbLoadTemplate` can expand at load time. Notes from experience:

- `$(MACRO=default)` gives defaults. Use them heavily; a template with 30 mandatory macros is unusable.
- Substitution files are generated from the facility's device database at serious installations, not hand-maintained. Then your PV names are traceable to an engineering source of truth, which is the only way naming stays consistent past a few thousand devices.
- `dbLoadRecords` with a `macro=value,macro=value` string does the same for one-off instances.

## Database design guidance

Accumulated wisdom, mostly learned the hard way by other people:

**Do the work in the database, not in a client.** Logic in a `calc` record runs at IOC priority, survives network partitions, is visible to `dbpr`, and keeps working when the operator's laptop closes. The same logic in a Python script is invisible, unmonitored, and stops when someone reboots a workstation. If a client script is holding your machine in a state, that logic is in the wrong place.

**Put alarm limits on the record, not on the screen.** Screen-side thresholds are invisible to the alarm system, the archiver, and everyone not looking at that screen.

**Use `DRVL`/`DRVH` on every output record.** Free, local, unbypassable clamping. Set them the day you create the record.

**Name the record for what it is, not where it's wired.** `...:Current-RB` outlives three generations of ADC channel assignment.

**Distinguish setpoint from readback in the name.** The `-SP` / `-RB` (or `:Set` / `:Get`) convention exists because confusing "what I asked for" with "what it's doing" is a genuinely dangerous class of mistake. See [naming conventions](naming-conventions.md).

**Set `MDEL` and `ADEL` on anything noisy.** Before it's deployed, not after the network team calls.

**Don't build big cross-IOC link webs.** CA links between IOCs are fine in small numbers and become an unmaintainable, order-dependent tangle in large ones. Where subsystems must interlock, prefer one IOC that owns the decision, or push it to hardware.

**Keep `PINI` in mind for output records.** Without it, an output record's value on a fresh boot is whatever `VAL` defaulted to, and it will not be pushed to hardware until something processes it. With [autosave](../toolbox/soft-support-modules.md#autosave), it's restored — which is why autosave and `PINI` are usually discussed together.

## Tools for working on databases

| Tool | Use |
| --- | --- |
| `dbl` / `dbgrep` | List records in a running IOC, optionally by pattern. |
| `dbpr <record> <level>` | Print all fields of a record. Levels 0–4 for increasing detail. Your primary debugging tool. |
| `dbtr <record>` | Test-process a record and print the result. |
| `dbLockShowLocked` | Show lock sets. |
| `dbdr` / `dbior` | Report DBD contents / driver state. |
| [VDCT](../toolbox/base-and-iocs.md#vdct) | Graphical `.db` editor showing links as a wiring diagram. Legacy Java, still genuinely useful for reading someone else's database. |
| [ibek](../toolbox/deployment-and-operations.md#ibek) | Generates databases and startup scripts from YAML device descriptions. |
| `dbVerify` / `dbLoadRecords` at build time | Catch syntax errors before deployment rather than at 2 a.m. |

## Next

→ [Protocols](protocols.md) — how those records get onto the network.
