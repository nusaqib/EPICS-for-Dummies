# Talk to a Real Device

The step between "I made a PV" and "I control something". This walks one instrument end to end with [StreamDevice](../toolbox/plc-and-fieldbus.md#streamdevice) — from the manual page to a working, alarmed, screen-ready record — and then through the failures you will actually hit.

**Prerequisites:** [EPICS Base](epics-base.md), [Your First IOC](first-ioc.md), and the [asyn](../toolbox/soft-support-modules.md#asyn) and [StreamDevice](https://paulscherrerinstitute.github.io/StreamDevice/) modules built and added to your IOC's `configure/RELEASE`.

**No hardware?** Do the whole thing against a simulator — see [the last section](#no-hardware-simulate-the-device). This is how a lot of real facility software gets written, months before the equipment arrives.

## The device

A bench power supply on the network that speaks **SCPI** — the Standard Commands for Programmable Instruments, an actual standard (IEEE 488.2 / SCPI-99) that a large fraction of laboratory instruments implement. Raw SCPI over TCP conventionally listens on **port 5025**.

The manual gives you something like:

```text
*IDN?                 → manufacturer,model,serial,firmware
MEAS:VOLT?            → measured output voltage, volts, ASCII float
MEAS:CURR?            → measured output current, amps
VOLT?                 → voltage setpoint
VOLT <value>          → set output voltage
CURR?  / CURR <value> → current setpoint / limit
OUTP?                 → 0 or 1
OUTP <0|1>            → output off / on
SYST:ERR?             → <code>,"<message>"  ; 0,"No error" when clean

All commands terminated with a line feed. Replies terminated with a line feed.
```

!!! warning "Read your own manual"
    SCPI is a standard that vendors implement with enthusiasm and variation. Terminators, whether a set command echoes anything, and whether errors are reported at all differ between instruments. Everything below is the *shape* of the job; the details come from the manual in front of you.

## Step 1 — talk to it before writing any EPICS

Do not skip this. Ten minutes here saves an afternoon of debugging the wrong layer.

```bash
nc 192.168.1.100 5025
*IDN?
```

You want to see the identification string come back. What you learn:

- **It's reachable** — so a later failure is yours, not the network's.
- **The exact reply format**, including whether there's a leading space, a trailing `\r`, or units appended.
- **What a set command does.** Send `VOLT 5.0` and see whether it replies with nothing, `OK`, or an echo. This single fact determines whether your protocol needs an `in` line, and getting it wrong produces a timeout on every write.
- **What an error looks like.** Send `VOLT NONSENSE`, then `SYST:ERR?`.

Write down exactly what you see, byte for byte. That transcript is the specification for the next step — and it's also what you'll feed a [simulator](#no-hardware-simulate-the-device) later.

## Step 2 — the protocol file

`protocols/scpi_psu.proto`:

```text
# SCPI bench power supply, raw TCP on port 5025.
# Transcript captured from firmware 2.14 -- recheck after a firmware update.

Terminator   = LF;      # both directions; use "CR LF" if your manual says so
ReplyTimeout = 1000;    # ms to wait for a reply
ReadTimeout  = 100;     # ms of silence that ends a reply
LockTimeout  = 5000;    # ms to wait for the port if another record holds it

# --- Readbacks -------------------------------------------------------------

getVoltage {
    out "MEAS:VOLT?";
    in  "%f";
}

getCurrent {
    out "MEAS:CURR?";
    in  "%f";
}

getOutputState {
    out "OUTP?";
    in  "%d";
}

# --- Setpoints -------------------------------------------------------------
# This instrument returns nothing on a set. So there is no "in" line, and we
# ask SYST:ERR? afterwards rather than assuming the write landed.

setVoltage {
    out "VOLT %.4f";
    @init { out "VOLT?"; in "%f"; }   # read the real setpoint at IOC startup
}

setOutput {
    out "OUTP %d";
    @init { out "OUTP?"; in "%d"; }
}

# --- Error checking --------------------------------------------------------
# 0,"No error" is the clean case. Anything else and we let the record go
# INVALID via @mismatch, so the alarm system sees it.

checkError {
    out "SYST:ERR?";
    in  "0,%*39c";
    @mismatch { in "%d,%39c"; }
}

# --- Identification, read once at startup ---------------------------------

getIdent {
    out "*IDN?";
    in  "%39c";
}
```

Three things in there are the whole point of StreamDevice:

**`@init`** runs at `iocInit` and reads the device's *actual* current setpoint into the record. Without it, your setpoint record starts at whatever the `.db` file said and the IOC's idea of the world disagrees with the hardware until somebody writes. With it, an IOC restart is invisible. This is the single most-forgotten feature in StreamDevice.

**`@mismatch`** handles the reply you didn't want. Without a mismatch handler, an unexpected reply is a protocol error and the record goes `INVALID` with a log line — which is often the correct behaviour, and sometimes you want to parse the error instead.

**`%*39c`** reads and *discards* 39 characters (`*` means "match but don't assign"). Useful for reply fields you must consume but don't want.

## Step 3 — the database

`db/scpi_psu.template`:

```text
#--- Identification, read once ------------------------------------------
record(stringin, "$(P):Ident-Mon") {
    field(DESC, "Device identification")
    field(DTYP, "stream")
    field(INP,  "@scpi_psu.proto getIdent $(PORT)")
    field(PINI, "YES")
}

#--- Readbacks ----------------------------------------------------------
record(ai, "$(P):Volt-Mon") {
    field(DESC, "$(DESC=PSU) output voltage")
    field(DTYP, "stream")
    field(INP,  "@scpi_psu.proto getVoltage $(PORT)")
    field(SCAN, "1 second")
    field(EGU,  "V")
    field(PREC, "4")
    field(HOPR, "$(VMAX=30)")  field(LOPR, "0")
    field(HIHI, "$(VTRIP=28)") field(HHSV, "MAJOR")
    field(MDEL, "0.001")       # network load
    field(ADEL, "0.01")        # storage cost
}

record(ai, "$(P):Curr-Mon") {
    field(DESC, "$(DESC=PSU) output current")
    field(DTYP, "stream")
    field(INP,  "@scpi_psu.proto getCurrent $(PORT)")
    field(SCAN, "1 second")
    field(EGU,  "A")
    field(PREC, "4")
    field(MDEL, "0.001")
    field(ADEL, "0.01")
}

#--- Setpoints ----------------------------------------------------------
record(ao, "$(P):Volt-SP") {
    field(DESC, "$(DESC=PSU) voltage setpoint")
    field(DTYP, "stream")
    field(OUT,  "@scpi_psu.proto setVoltage $(PORT)")
    field(EGU,  "V")
    field(PREC, "4")
    field(DRVL, "0")             # writes are CLAMPED in the IOC --
    field(DRVH, "$(VMAX=30)")    # no client can exceed this
    field(FLNK, "$(P):Err-Mon")  # after every write, ask the device for errors
}

record(bo, "$(P):Output-Cmd") {
    field(DESC, "$(DESC=PSU) output enable")
    field(DTYP, "stream")
    field(OUT,  "@scpi_psu.proto setOutput $(PORT)")
    field(ZNAM, "OFF")  field(ONAM, "ON")
    field(FLNK, "$(P):Err-Mon")
}

#--- Status -------------------------------------------------------------
record(bi, "$(P):Output-Sts") {
    field(DESC, "$(DESC=PSU) output state")
    field(DTYP, "stream")
    field(INP,  "@scpi_psu.proto getOutputState $(PORT)")
    field(SCAN, "1 second")
    field(ZNAM, "OFF")  field(ONAM, "ON")
}

record(stringin, "$(P):Err-Mon") {
    field(DESC, "Last device error")
    field(DTYP, "stream")
    field(INP,  "@scpi_psu.proto checkError $(PORT)")
    field(SCAN, "10 second")
}

#--- Did it do what we asked? -------------------------------------------
record(calc, "$(P):AtVolt-Sts") {
    field(DESC, "Output voltage within tolerance of setpoint")
    field(INPA, "$(P):Volt-SP CP")
    field(INPB, "$(P):Volt-Mon CP")
    field(INPC, "$(P):Output-Sts CP")
    field(CALC, "C && (ABS(A-B) < $(VTOL=0.05))")
    field(ZSV,  "MINOR")
}
```

Decisions worth noticing, because they're the difference between a record set that works and one that's trusted:

**`-Mon` comes from the device, `-SP` goes to it.** `Volt-Mon` reads `MEAS:VOLT?`, not the setpoint. A readback implemented as a copy of the setpoint always agrees and is always a lie — see [naming conventions](../architecture/naming-conventions.md#setpoint-versus-readback).

**`DRVL`/`DRVH` on the setpoint.** Clamped inside the IOC, unbypassable by any client. One line, real protection, routinely left unset.

**`FLNK` to the error record after each write.** SCPI errors are queued in the device, not returned by the failing command. Without asking, a rejected write looks exactly like a successful one.

**`AtVolt-Sts` closes the loop.** "I asked for 12 V, the output is on, and the measurement agrees" is a different claim from "I wrote 12 V", and it's the one an operator actually needs.

**`MDEL`/`ADEL` set at creation.** [Retrofitting deadbands across a facility is much harder than typing them now.](../example-facility/archiving-plan.md#the-decision-that-dominates-everything)

## Step 4 — wire it up in `st.cmd`

```text
#--- before iocInit ---

# Where StreamDevice looks for .proto files
epicsEnvSet("STREAM_PROTOCOL_PATH", "$(TOP)/protocols")

# The TCP connection. "PSU1" is the asyn port name the records refer to.
#                      name    host:port           prio noAutoConnect noProcessEos
drvAsynIPPortConfigure("PSU1", "192.168.1.100:5025", 0,   0,            0)

# Optional but recommended: an asynRecord for interactive debugging
dbLoadRecords("$(ASYN)/db/asynRecord.db", "P=LAB:PSU1,R=:asyn,PORT=PSU1,ADDR=0,IMAX=100,OMAX=100")

dbLoadRecords("db/scpi_psu.template", "P=LAB:PSU1,PORT=PSU1,VMAX=30,VTRIP=28")

iocInit()
```

Serial instead of Ethernet? Swap the port configuration and keep everything else:

```text
drvAsynSerialPortConfigure("PSU1", "/dev/ttyUSB0", 0, 0, 0)
asynSetOption("PSU1", 0, "baud",   "9600")
asynSetOption("PSU1", 0, "bits",   "8")
asynSetOption("PSU1", 0, "parity", "none")
asynSetOption("PSU1", 0, "stop",   "1")
asynSetOption("PSU1", 0, "clocal", "Y")
asynSetOption("PSU1", 0, "crtscts","N")
```

That the protocol file and the database don't change is the point of [asyn](../toolbox/soft-support-modules.md#asyn). A serial-to-Ethernet converter later changes one line.

## Step 5 — test it

```bash
caget LAB:PSU1:Ident-Mon          # proves the protocol works at all
caget -a LAB:PSU1:Volt-Mon        # note the severity field
camonitor LAB:PSU1:Volt-Mon LAB:PSU1:AtVolt-Sts &

caput LAB:PSU1:Output-Cmd 1
caput LAB:PSU1:Volt-SP 12.0       # watch Volt-Mon follow, AtVolt-Sts go true
caput LAB:PSU1:Volt-SP 999        # clamped to VMAX by DRVH
caget LAB:PSU1:Err-Mon            # did the device complain about anything?
```

Then the tests that matter more:

```bash
# 1. Pull the network cable, or kill the simulator.
caget -a LAB:PSU1:Volt-Mon        # should go INVALID, not "0.0, fine"

# 2. Plug it back in. Does it recover on its own, without an IOC restart?

# 3. Restart the IOC while the output is on at 12 V.
caget LAB:PSU1:Volt-SP            # @init should have read back 12, not 0
```

Test 3 is the one people skip and then get wrong in production. Test 1 is the one that determines whether anybody can trust a screen.

## When it doesn't work

In the order the problems actually occur.

### Turn on tracing first

```text
epics> asynSetTraceIOMask("PSU1", 0, 0x2)   # show I/O as escaped ASCII
epics> asynSetTraceMask("PSU1", 0, 0x9)     # ASYN_TRACE_ERROR | ASYN_TRACEIO_DRIVER
```

Now every byte in and out is logged, with `\n` and `\r` visible rather than invisible. Turn it off with `asynSetTraceMask("PSU1", 0, 0x1)`.

**This is the tool.** Nine times out of ten the log makes the problem obvious in one line.

### The symptoms

| Symptom | Cause |
| --- | --- |
| **Every read times out, nothing in the trace** | Wrong host/port, or the device only accepts one connection and something else holds it. Check with `nc` again. |
| **Reads time out, trace shows the command going out** | **Terminator mismatch** — the single most common StreamDevice problem. The device wants `CR LF` and you sent `LF`, or vice versa. Try `Terminator = CR LF;`, then `OutTerminator`/`InTerminator` separately if they differ. |
| **First read works, subsequent reads time out** | Leftover bytes in the buffer from a reply longer than you parsed. Add `ExtraInput = Ignore;` or consume the rest with `%*c`. |
| **Writes time out** | You gave a set command an `in` line but the device replies with nothing. Remove the `in`. |
| **Record goes `INVALID` with a parse error** | Format string doesn't match reality. The trace shows the actual reply; make `%f` match it. Watch for units appended to the number (`12.0V`) and for leading spaces. |
| **Values are right but a factor out** | Units. The device reports millivolts and you assumed volts. Use `LINR`/`ESLO` on the record rather than fudging the protocol. |
| **Intermittent timeouts under load** | `LockTimeout` too short: many records are queuing for one port. Reduce scan rates, or ask for several values in one command and parse them with `Separator`. |
| **Works alone, breaks with several records** | Same cause. One serial line is one resource, and each record takes a turn. |
| **Random failures after a firmware update** | The reply format changed. This is why the protocol file has a firmware version in its comments. |

### Reducing traffic

If one port serves many records, ask once and parse several values:

```text
Separator = ",";

getAll {
    out "MEAS:VOLT?;MEAS:CURR?";
    in  "%f", "%f";
}
```

Bind that to a `waveform` or use StreamDevice's redirection to distribute into other records. One round trip instead of two matters when the round trip is 200 ms and you have forty records.

## No hardware? Simulate the device

The same records, the same protocol file, no instrument. Two routes.

**A throwaway listener,** enough to develop the protocol against:

```bash
# Answers on TCP 5025 with plausible SCPI replies
while true; do
  printf '' | nc -l -p 5025 -q1 2>/dev/null || break
done
```

That's crude. For anything real use **[Lewis](../toolbox/simulation-and-testing.md#lewis)**, which models the device as a Python state machine with a protocol adapter, so the output voltage actually follows the setpoint and you can make it fail on purpose:

```bash
pip install lewis
lewis -k lewis.examples <device> -p "stream://port=5025"
```

Then point `drvAsynIPPortConfigure` at `localhost:5025` and everything above works unchanged.

**Keep the simulator afterwards.** It is your CI target and the only way to test the failure paths — device stops answering mid-scan, malformed reply, plausible-but-wrong value. Those are the cases that occur at 03:00 and the ones you cannot create on real hardware. See [Simulation & Testing](../toolbox/simulation-and-testing.md).

## When StreamDevice isn't the answer

Escalate in this order, and only when the previous option genuinely can't work:

1. **An existing module.** Check the [hardware support directory](https://epics-controls.org/resources-and-support/modules/hardware-support/) and search [tech-talk](../reference/community.md) for the model number first. The commonest avoidable waste of a new controls engineer's first month is writing support that already existed.
2. **StreamDevice** — anything ASCII or simple binary over serial/TCP, including checksummed binary protocols.
3. **A protocol module** — [Modbus](../toolbox/plc-and-fieldbus.md#modbus), [ether_ip](../toolbox/plc-and-fieldbus.md#ether_ip-allen-bradley), [OPC UA](../toolbox/plc-and-fieldbus.md#opc-ua), [s7plc](../toolbox/plc-and-fieldbus.md#s7plc).
4. **`asynPortDriver` in C++** — a vendor SDK, or a register-mapped card.
5. **C device support from scratch** — custom hardware, bus-level access, an RTOS target. Weeks of work and real EPICS depth.

## Then

- **Publish the protocol file.** Somebody else has your instrument. Put it on GitHub, mention it on tech-talk, add it to the [hardware support directory](https://epics-controls.org/resources-and-support/modules/hardware-support/). The ecosystem is built entirely from people who did this.
- Add [autosave](../toolbox/soft-support-modules.md#autosave) so setpoints survive a reboot.
- Add [iocStats](../toolbox/soft-support-modules.md#iocstats-and-deviocstats) so you know when the IOC restarts.
- Build a screen: [Phoebus](phoebus.md) or PyDM.
- Archive the readbacks: [archiving](../toolbox/archiving.md).
- Alarm the trips: [alarms](../toolbox/alarms.md).

## Next

→ [Phoebus](phoebus.md) to put a screen on it, or the [Toolbox](../toolbox/hardware-support-modules.md) for the device families this approach covers.
