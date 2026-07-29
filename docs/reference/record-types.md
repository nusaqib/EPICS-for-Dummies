# Record Types

A map of what exists and what each type is for. The authoritative field-by-field reference is the [Record Reference Manual](https://epics.anl.gov/base/R7-0/6-docs/RecordReference.html); this page helps you choose.

Conceptual background: [Process Database](../architecture/process-database.md).

## From EPICS Base

### Input

| Type | Data | Use for |
| --- | --- | --- |
| `ai` | double | **Analog input.** Any measurement. Raw-to-engineering conversion via `LINR`, alarm limits, deadbands. The most common record type in existence. |
| `bi` | 0/1 | **Binary input.** One bit with named states (`ZNAM`/`ONAM`) and per-state severity (`ZSV`/`OSV`). |
| `mbbi` | enum | **Multi-bit binary input.** Up to sixteen named states with per-state severity. For device modes, status codes, positions. |
| `mbbiDirect` | 16 bits | A register exposed as sixteen individual bit fields. For PLC status words. |
| `longin` | int32 | Integer input where scaling is meaningless — counters, IDs, bit masks. |
| `int64in` | int64 | 64-bit integer |
| `stringin` | 40 chars | Short text. **40 characters, hard limit.** |
| `lsi` | long string | Longer text. Use instead of a char waveform where you can. |
| `waveform` | array | **Arrays of anything**: spectra, images, orbits, traces, long strings. |
| `aai` | array | Array analog input with array-specific device support |
| `histogram` | array | Accumulates values into bins in the IOC |

### Output

| Type | Use for |
| --- | --- |
| `ao` | **Analog output.** Setpoints. `DRVL`/`DRVH` clamp writes — set them always. `OROC` rate-limits output change. |
| `bo` | **Binary output.** On/off, and momentary commands via `HIGH` (return to 0 after N seconds). |
| `mbbo` | Enumerated output — mode selection |
| `mbboDirect` | Write sixteen individual bits as a word |
| `longout`, `int64out` | Integer outputs |
| `stringout`, `lso` | Text output |
| `aao` | Array output |

### Computation and control flow

| Type | Use for |
| --- | --- |
| `calc` | **An expression over inputs `INPA`–`INPL`.** The workhorse of every EPICS database. |
| `calcout` | `calc` plus an output link, a delay (`ODLY`), and output conditions (`OOPT`: on change, on transition to non-zero, when zero, …). Two of these replace a surprising number of scripts. |
| `acalcout` | Array calculation with output |
| `sub` | Calls a C function you registered. The escape hatch when expressions run out. |
| `aSub` | Array version, with typed inputs and outputs |
| `fanout` | Process up to sixteen records, in order |
| `dfanout` | Distribute one value to up to eight output links |
| `seq` | Write up to sixteen values to sixteen links, with optional per-step delays. Sequencing without a state machine. |
| `sel` | Select one of several inputs: by index, max, or min |
| `compress` | **Array compression**: circular buffer, N-to-1 averaging, min/max. How you build a local history buffer in an IOC. |
| `state` | A simple string-valued state holder |
| `permissive` | A small operator-acknowledgement helper |
| `event` | Post an EPICS event, so `SCAN = Event` records process |
| `lsi`/`lso` | (also useful as pure software records for long strings) |

`compress` deserves more attention than it gets: when you need the last 1 000 samples of something and monitors [aren't a reliable history](../architecture/protocols.md#monitors-the-part-people-misunderstand), a `compress` record in the IOC is the answer.

## From support modules

| Type | Module | Use for |
| --- | --- | --- |
| `transform` | [calc](../toolbox/soft-support-modules.md#calc) | **Sixteen interdependent expressions in one record**, evaluated in dependency order. Replaces a rat's nest of `calc` records. |
| `swait` | calc | `calc` with wait/delay semantics |
| `sCalcout` | calc | **String calculation output.** Build a filename or command string from PV values, inside the IOC. |
| `aCalcout` | calc | Array calculation output |
| `motor` | [motor](../toolbox/motion.md) | **An axis.** Device-independent motion: `VAL`, `RBV`, `DMOV`, limits, velocity, homing, `MSTA`. |
| `busy` | [busy](../toolbox/soft-support-modules.md#busy) | **"Still working".** A `bo` variant that stays 1 until the operation it triggered actually completes, so put-callback works. |
| `sscan` | [sscan](../toolbox/scanning-and-automation.md#sscan) | A multi-dimensional scan: 4 positioners, 70 detectors, 4 triggers, data in the record |
| `sseq` | [sseq](../toolbox/scanning-and-automation.md) | Sequenced string/value output with delays and conditions |
| `asyn` | [asyn](../toolbox/soft-support-modules.md#asyn) | **A diagnostic record**: send arbitrary strings to a port from a screen and see the reply. Invaluable when commissioning an instrument. |
| `epid` | [std](../toolbox/soft-support-modules.md#std) | **A PID controller as a record.** Slow feedback loops with no code. |
| `scaler` | mca/std | Counting scaler |
| `mca` | [mca](../toolbox/soft-support-modules.md#other-soft-modules-worth-knowing) | Multi-channel analyser |
| `timestamp` | std | Formatted timestamp as a string |
| `NDPlugin*`-driven records | [areaDetector](../toolbox/detectors-and-imaging.md) | Hundreds, generated by the plugin framework |
| `seq` (SNL programs) | [sequencer](../toolbox/scanning-and-automation.md#sequencer-snl) | Not a record type — state machines compiled into the IOC |

## Choosing

| You need | Use |
| --- | --- |
| A measurement in engineering units | `ai` |
| A setpoint | `ao` with `DRVL`/`DRVH` |
| An on/off state with meaningful names | `bi` / `bo` |
| A momentary command | `bo` with `HIGH` set |
| A device mode with several named states | `mbbi` / `mbbo` |
| A PLC status word, bit by bit | `mbbiDirect` |
| A counter or an ID | `longin` |
| Any array — spectrum, image, orbit | `waveform` |
| Text longer than 40 characters | `lsi` / `lso`, or a `char` waveform |
| Arithmetic over a few PVs | `calc` |
| Arithmetic *and* write the result somewhere | `calcout` |
| More than a few interdependent expressions | `transform` |
| A delay before acting | `calcout` with `ODLY` |
| A local rolling history buffer | `compress` |
| To move something | `motor` |
| To tell clients an operation is still running | `busy` |
| Slow closed-loop control | `epid`, or a `calcout` loop |
| A state machine | [SNL sequencer](../toolbox/scanning-and-automation.md#sequencer-snl), not records |
| Logic too complex for an expression | `sub`/`aSub`, or reconsider the design |

## Fields common to every record

| Field | Notes |
| --- | --- |
| `VAL` | The value. A bare PV name means `.VAL`. |
| `NAME`, `DESC` | Name; 40-char description that appears on screens and in the alarm tree |
| `SCAN` | `Passive` (default), `I/O Intr`, `Event`, or a period |
| `DTYP` | Device support. `Soft Channel` = no hardware. |
| `PHAS` | Ordering within a scan pass — lower first. For "read all inputs before computing". |
| `PINI` | Process once at `iocInit`. Essential for output records that must push an initial value. |
| `PRIO` | Callback queue priority: `LOW`/`MEDIUM`/`HIGH` |
| `SEVR`, `STAT` | Current alarm severity and status. Read-only. |
| `TIME`, `TSE`, `TSEL` | Timestamp and [where it comes from](../toolbox/timing-systems.md#timestamps-in-the-record-layer) |
| `DISA`, `DISV`, `SDIS`, `DISS` | Conditional disabling, and the severity while disabled |
| `ASG` | [Access security](../architecture/access-security.md) group |
| `FLNK` | Forward link — process this record next |
| `PROC` | Write anything to force processing |
| `UDF` | Undefined — set until the record has a valid value. `UDF` records report `INVALID`. |
| `TPRO` | Set to 1 for per-process trace output. A good debugging tool. |
| `SIML`, `SIOL`, `SIMS`, `SIMM` | [Simulation mode](../toolbox/simulation-and-testing.md#built-into-the-tools) — on every input record, and widely forgotten |

`UDF` catches people out: a freshly-loaded record that has never processed is `UDF` and therefore `INVALID`, which is correct and looks like a fault. `PINI` or a first scan clears it.

## Analog-specific fields

| Field | Notes |
| --- | --- |
| `EGU` | Units. Every screen shows it. Fill it in. |
| `PREC` | Display precision |
| `LOPR`, `HOPR` | Display range — what a bar graph scales to |
| `DRVL`, `DRVH` | **Drive limits: writes are clamped in the IOC. Unbypassable. Free.** |
| `LOLO`, `LOW`, `HIGH`, `HIHI` | Alarm limits |
| `LLSV`, `LSV`, `HSV`, `HHSV` | Their severities |
| `HYST` | Alarm hysteresis — the cure for chatter |
| `MDEL` | Monitor deadband — controls network load |
| `ADEL` | Archive deadband — controls storage cost |
| `SMOO` | First-order smoothing, 0–1. Convenient, and note you are then archiving a filtered value and calling it a measurement. |
| `LINR` | Conversion: `NO CONVERSION`, `SLOPE`, `LINEAR`, or a breakpoint table (thermocouples, RTDs) |
| `EGUL`, `EGUF` | Engineering range for `LINEAR` conversion |
| `ESLO`, `EOFF` | Slope and offset for `SLOPE` conversion |
| `AOFF`, `ASLO` | Adjustment applied after conversion |
| `RVAL`, `ROFF` | Raw value and raw offset |
| `OROC` | Output rate of change limit (`ao`) — a per-write ramp |
| `OIF` | Output is incremental or absolute (`ao`) |

Three of these are consistently underused: `DRVL`/`DRVH` (free protection), `HYST` (free alarm quality), and `MDEL`/`ADEL` (free scalability). All three cost one line at record-creation time and are painful to retrofit.

## Binary and enum fields

| Field | Notes |
| --- | --- |
| `ZNAM`, `ONAM` | State names for `bi`/`bo` |
| `ZSV`, `OSV`, `COSV` | Severity in zero state, one state, on change of state |
| `HIGH` | On a `bo`, return to 0 after this many seconds — momentary commands |
| `ZRST`…`FFST` | The sixteen state strings for `mbbi`/`mbbo` |
| `ZRSV`…`FFSV` | Their severities |
| `ZRVL`…`FFVL` | Raw values corresponding to each state |
| `NOBT`, `SHFT`, `MASK` | Bit field extraction for `mbbi`/`mbbo` |

## Where to look things up

| Need | Source |
| --- | --- |
| Every field of a standard record type | [Record Reference Manual](https://epics.anl.gov/base/R7-0/6-docs/RecordReference.html) |
| How processing actually works | [Application Developer's Guide](https://docs.epics-controls.org/en/latest/appdevguide/AppDevGuide.html), chapters 3–6 |
| Concepts and worked examples | [Process Database Concepts](https://docs.epics-controls.org/en/latest/guides/EPICS_Process_Database_Concepts.html) |
| A module's record types | That module's own documentation |
| **What a running record is actually doing** | `dbpr <record> 4` on the IOC shell |

The last row is worth internalising. `dbpr` at level 4 shows every field's current value including resolved links — faster and more reliable than reading documentation about what you think you configured.
