# PLCs, Fieldbus, and Instrument Protocols

Most of the equipment in a real facility does not speak EPICS. It speaks Modbus, EtherNet/IP, S7, OPC UA, or ASCII over a serial line. This page is the bridge.

## StreamDevice

**The most useful tool in this guide for a beginner.** Talk to an ASCII or binary instrument by *describing* its protocol in a text file. No C, no compilation, no build.

| | |
| --- | --- |
| Documentation | [paulscherrerinstitute.github.io/StreamDevice](https://paulscherrerinstitute.github.io/StreamDevice/) |
| Source | [github.com/paulscherrerinstitute/StreamDevice](https://github.com/paulscherrerinstitute/StreamDevice) |
| Author | Dirk Zimoch (PSI) |
| Requires | [asyn](soft-support-modules.md#asyn) |

A protocol file:

```text
# vacuum_gauge.proto
Terminator = CR LF;
ReplyTimeout = 1000;
LockTimeout = 5000;

getPressure {
    out "PR1?";
    in  "%f";
}

getUnits {
    out "UNI?";
    in  "%{mbar|Torr|Pa}";     # parse into an mbbi's enum states
}

setSetpoint {
    out "SP1,%.3e";
    in  "OK";
    @mismatch { in "ERR%d"; }   # handle the error reply explicitly
}
```

And the records that use it:

```text
record(ai, "$(P):Pressure") {
    field(DTYP, "stream")
    field(INP,  "@vacuum_gauge.proto getPressure $(PORT)")
    field(SCAN, "1 second")
    field(EGU,  "mbar")
}
record(ao, "$(P):Setpoint-SP") {
    field(DTYP, "stream")
    field(OUT,  "@vacuum_gauge.proto setSetpoint $(PORT)")
    field(EGU,  "mbar")
    field(DRVL, "1e-9")  field(DRVH, "1e-3")
}
```

That's a complete, production-quality device support for a vacuum gauge.

**Why it matters so much:** protocol files are readable by the person who owns the instrument, not just the person who owns the IOC. They're diffable, reviewable, and don't need a compiler. Facilities accumulate hundreds of them, and they get shared on tech-talk freely.

**Features you'll grow into:** `@init` handlers (query the device at startup for units and ranges), `@mismatch`/`@replytimeout`/`@writetimeout` exception handlers, `Separator` for parsing multi-value replies into arrays, `ExtraInput = Ignore` for chatty devices, checksum functions (`%<crc16>`, `%<sum>`) for binary protocols, and variable formats for devices whose reply format depends on their mode.

**Debugging:** protocol-level tracing via asyn (`asynSetTraceMask("PORT",-1,0x9)` shows I/O and errors) plus `asynSetTraceIOMask("PORT",-1,0x2)` for escaped ASCII. Nine times out of ten the problem is a terminator character.

## Modbus

The industrial lowest common denominator. TCP and serial (RTU/ASCII), and almost every PLC, VFD, power supply, and controller supports it.

| | |
| --- | --- |
| Source | [github.com/epics-modules/modbus](https://github.com/epics-modules/modbus) |
| Documentation | [epics-modules.github.io/modbus](https://epics-modules.github.io/modbus/) |
| Maintainer | Mark Rivers (APS) |
| Requires | asyn |

Configuration is per *memory region*, not per point — you declare a block of coils or registers as an asyn port, then bind records to offsets within it:

```text
drvAsynIPPortConfigure("PLC1", "192.168.1.50:502", 0, 0, 1)
modbusInterposeConfig("PLC1", 0, 2000, 0)
# name        port  slave func  start len  dataType   pollDelay
drvModbusAsynConfigure("PLC1_HR", "PLC1", 0, 3, 0, 100, 0, 100, "PLC")
```

```text
record(ai, "$(P):Temperature") {
    field(DTYP, "asynInt32")
    field(INP,  "@asyn(PLC1_HR 12)")      # holding register offset 12
    field(SCAN, "I/O Intr")
    field(LINR, "LINEAR")
    field(EGUL, "0")  field(EGUF, "100")
    field(EGU,  "degC")
}
```

Practical notes:

- **Block polling is the point.** One request fetching 100 registers beats 100 requests. Choose block boundaries to match how the PLC engineer laid out the memory map, and get that map in writing.
- **Modbus has no data types.** A 32-bit float is two registers, and whether it's big- or little-endian word order is a per-vendor decision documented inconsistently. The module supports the common encodings (`INT32_LE`, `FLOAT32_BE`, …); expect to try a couple.
- **No timestamps, no alarm status.** Modbus gives you a number. Quality and time come from the IOC, meaning a stale PLC value looks fresh. Include a PLC-side heartbeat register and alarm on it going stale — this is the single most important thing to get right in a Modbus integration.
- **Signed/unsigned and scaling** live in the record's `LINR`/`ESLO`/`EOFF` fields, and must match a document the PLC engineer maintains.

## ether_ip (Allen-Bradley)

EtherNet/IP for ControlLogix and CompactLogix PLCs — reads and writes **tags by name**, which is a considerable improvement over register offsets.

| | |
| --- | --- |
| Source | [github.com/epics-modules/ether_ip](https://github.com/epics-modules/ether_ip) |
| Origin | Kay Kasemir (SNS) |
| Training | [Allen-Bradley PLCs](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/15%20Allen%20Bradley%20PLCs.pdf) (USPAS) |

```text
EIP_buffer_limit(500)
drvEtherIP_define_PLC("plc1", "192.168.1.60", 0)
```

```text
record(ai, "$(P):Flow") {
    field(DTYP, "EtherIP")
    field(INP,  "@plc1 CoolingFlow_GPM")     # the tag name in the PLC program
    field(SCAN, "1 second")
    field(EGU,  "gpm")
}
```

Tag names mean the PLC program is the interface contract, which is much more maintainable than offsets — provided the PLC engineer doesn't rename tags without telling you. Heavily used at SNS and across the US lab community. Supports scan-list optimisation so many tags share one request.

## S7plc

Siemens S7 PLCs over a simple periodic data-block exchange.

| | |
| --- | --- |
| Source | [github.com/paulscherrerinstitute/s7plc](https://github.com/paulscherrerinstitute/s7plc) |
| Author | Dirk Zimoch (PSI) |

The model is deliberately simple: the PLC pushes a fixed data block at a fixed rate, EPICS parses offsets out of it. Very robust, very predictable, and it requires the PLC side to be configured to send the block — so it's a joint design, not something you can bolt on to an existing PLC program unilaterally.

For newer Siemens installations, OPC UA is usually the better choice.

## OPC UA

The modern industrial interoperability standard. The EPICS `opcua` module is a client that maps OPC UA nodes to records.

| | |
| --- | --- |
| Source | [github.com/epics-modules/opcua](https://github.com/epics-modules/opcua) |
| Author | Ralph Lange |

```text
record(ai, "$(P):Pressure") {
    field(DTYP, "OPCUA")
    field(INP,  "@session=PLC1 ns=3;s=Machine.Vacuum.Pressure")
    field(SCAN, "I/O Intr")
}
```

Why it's the right default for new PLC work:

- **Real data types**, including structures and arrays — no register-offset archaeology.
- **Timestamps and quality codes come from the source.** OPC UA carries both natively, and the module maps quality onto EPICS alarm severity. This solves the Modbus staleness problem properly.
- **Subscriptions**, so `I/O Intr` scanning works and you're not polling.
- **Browsable address space** — you can discover what a PLC exposes without a spreadsheet.
- **Security** — OPC UA has certificates and encryption. Whether your PLC's implementation is any good is a separate question, but the standard provides for it.

Cost: heavier than Modbus, needs an OPC UA stack as a build dependency, and PLC-side licensing sometimes applies. Worth it.

## Beckhoff ADS / TwinCAT

Beckhoff PLCs speak ADS natively. Options: their OPC UA server (simplest, and often the right answer), or an ADS-protocol driver — several facilities maintain these, notably SLAC's [ads-ioc](https://github.com/pcdshub/ads-ioc) and ESS's ADS support. Check current status before committing; this area has more facility-specific forks than settled community modules.

## EtherCAT

Real-time fieldbus, common for distributed I/O and motion. EPICS integration is generally facility-specific — Diamond and ESS have both built EtherCAT masters with EPICS layers, and the usual practical path at other sites is an EtherCAT master in a PLC or dedicated controller, with EPICS talking to *that* over OPC UA or Modbus rather than acting as master itself.

## GPIB, serial, and the legacy bus world

| Bus | Support |
| --- | --- |
| GPIB / IEEE-488 | [asyn](soft-support-modules.md#asyn) with a VXI-11 or USB-GPIB gateway; StreamDevice on top |
| RS-232 / RS-422 / RS-485 | asyn serial port + StreamDevice. Serial-to-Ethernet converters (Moxa, Lantronix) are ubiquitous, and mean the IOC needn't be near the device |
| USB-TMC | asyn USB-TMC support |
| VME | Board-specific modules in `epics-modules`; [ipac](https://github.com/epics-modules/ipac) for IndustryPack carriers |
| CAN bus | Facility-specific; several published modules |
| SNMP | [snmp module](https://github.com/epics-modules/snmp) — PDUs, UPSs, network switches, environmental monitors |

Serial-over-Ethernet deserves a note: it decouples IOC placement from device location entirely, which is why most modern installations use it even for devices in the same rack. The downside is one more box to fail, and its failure looks like a device failure.

## Where to draw the PLC/EPICS line

The single most consequential decision in a PLC integration, and it's an organisational one as much as a technical one.

| Belongs in the PLC | Belongs in EPICS |
| --- | --- |
| Anything protection-related: interlocks, permits, trips | Setpoints, modes, and operator commands |
| Logic that must run when the network is down | Sequencing that a human supervises |
| Logic that must be validated for a safety case | Archiving, alarming, display, and trending |
| Timing-critical local loops | Facility-wide coordination |
| Anything you'd need a certified change process for | Anything you'd want to change during a shift |

Two rules that save arguments later:

**Write the interface contract down.** A document listing every tag/register, its type, its scaling, its units, its direction, and who owns it. Both sides sign it. Version it. Without this, a PLC program change silently breaks EPICS records, and diagnosis takes days because nothing logged an error — the value just became wrong.

**Include a heartbeat in both directions.** A PLC-side counter EPICS watches, and an EPICS-side counter the PLC watches. Alarm on staleness at both ends. Without it, a hung comms link presents as perfectly plausible, perfectly stale data. This is the failure mode that catches everyone once.

## Next

→ [Motion Control](motion.md)
