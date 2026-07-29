# Your First IOC

Thirty minutes, and by the end you'll have records that compute, alarm, and respond over the network — which is the moment EPICS stops being abstract.

Prerequisite: [EPICS Base built and on your `PATH`](epics-base.md).

## Part 1: softIoc, no build required

The fastest possible start. No application, no Makefile, no `st.cmd`.

Create `~/first.db`:

```text
# A setpoint an operator would write to
record(ao, "DEMO:Heater-SP") {
    field(DESC, "Heater power setpoint")
    field(EGU,  "%")
    field(PREC, "1")
    field(DRVL, "0")        # writes are CLAMPED to 0-100 by the IOC
    field(DRVH, "100")      # no client can exceed this
    field(PINI, "YES")      # push the initial value at startup
}

# A "measurement" that follows the setpoint with lag, standing in for physics
record(calc, "DEMO:Temperature") {
    field(DESC, "Chamber temperature")
    field(SCAN, "1 second")
    field(INPA, "DEMO:Heater-SP")      # the setpoint
    field(INPB, "DEMO:Temperature")    # my own previous value
    field(CALC, "B + (20 + A*0.6 - B) * 0.15")   # first-order approach
    field(EGU,  "degC")
    field(PREC, "2")
    field(HIGH, "60")   field(HSV,  "MINOR")
    field(HIHI, "75")   field(HHSV, "MAJOR")
    field(MDEL, "0.05")   # don't post monitors for changes below this
    field(ADEL, "0.5")    # don't post archive events for changes below this
}

# Interlock logic: trip if too hot. Note this is DEMONSTRATION logic --
# a real interlock belongs in hardware, not here.
record(calc, "DEMO:OverTemp-Sts") {
    field(DESC, "Over-temperature detected")
    field(INPA, "DEMO:Temperature CP MS")   # CP: process me when A changes
    field(CALC, "A > 75")                   # MS: inherit A's alarm severity
    field(SCAN, "Passive")
}

# A summary of everything, for a top-level display
record(calc, "DEMO:Summary") {
    field(DESC, "Demo subsystem summary")
    field(INPA, "DEMO:Temperature CP MS")
    field(INPB, "DEMO:OverTemp-Sts CP MS")
    field(CALC, "A")
}
```

Run it:

```bash
softIoc -d ~/first.db
```

In a second terminal:

```bash
caget DEMO:Heater-SP DEMO:Temperature
camonitor DEMO:Temperature DEMO:OverTemp-Sts &

caput DEMO:Heater-SP 50      # watch the temperature climb toward 50
caput DEMO:Heater-SP 100     # watch it pass MINOR at 60, MAJOR at 75
caput DEMO:Heater-SP 200     # clamped to 100 by DRVH
caget DEMO:Heater-SP         # 100, not 200

caget -a DEMO:Temperature    # value, timestamp, severity, status
```

### What just happened, and why it matters

**Nine things worth noticing:**

1. `DRVH` clamped your out-of-range write **inside the IOC**. No client can bypass it. This is the cheapest real protection in EPICS and it's routinely left unset — see [access security](../architecture/access-security.md).
2. `SCAN = 1 second` made `DEMO:Temperature` process on a clock, with no code.
3. `CALC` with `INPB` pointing at its *own* `VAL` gave you state — a first-order lag filter in one field.
4. `CP` on `DEMO:OverTemp-Sts`'s input means it processes **when the temperature changes**, not on a timer. Event-driven, zero polling. This is the idiom to internalise.
5. `MS` propagated the alarm severity up the chain, so `DEMO:Summary` inherits the worst severity of its inputs. That's how a facility-wide summary display works.
6. Alarm limits are on the *record*, so `camonitor`, a screen, the archiver and the alarm system all see the same alarm. A threshold on a screen would be invisible to all of them.
7. `MDEL` suppressed network traffic for tiny changes. Multiply by 400 000 records to see why it matters.
8. `caget -a` showed severity. `caget` alone would have shown you a number with no indication that it was in alarm — the [most common client bug](../toolbox/client-libraries.md#guidance-for-writing-clients).
9. `PINI` pushed the initial setpoint at startup. Without it, the value exists but has never been written anywhere.

Poke at it from the IOC console:

```text
epics> dbl                              # all four records
epics> dbpr DEMO:Temperature 1          # every field, level 1
epics> dbpr DEMO:Temperature 4          # everything, including links
epics> dbtr DEMO:OverTemp-Sts           # test-process it and show the result
epics> casr 1                           # who's connected? (your camonitor)
epics> dbgf DEMO:Temperature.SEVR
```

`dbpr` is the tool you'll use for the rest of your career.

## Part 2: a real IOC application

`softIoc` is genuinely fine for a lot of production work. But you need a built application to load device-support modules, and every facility IOC is one, so build one now.

```bash
mkdir -p ~/EPICS/iocs/demo && cd ~/EPICS/iocs/demo
makeBaseApp.pl -t ioc demo
makeBaseApp.pl -i -t ioc demo      # answer "demo" when prompted for the app
```

What you get:

```text
demo/
├── configure/
│   ├── RELEASE          ← EPICS_BASE and every support module's path
│   └── CONFIG_SITE
├── demoApp/
│   ├── Db/              ← put your .db here, and list it in Makefile
│   └── src/             ← C/C++ and the "DBD includes" list
├── iocBoot/iocdemo/
│   ├── st.cmd           ← the startup script
│   └── envPaths         ← generated; sourced by st.cmd
└── Makefile
```

Add your database:

```bash
cp ~/first.db demoApp/Db/demo.db
```

Tell the build about it — in `demoApp/Db/Makefile`, in the section that installs databases:

```make
DB += demo.db
```

Build:

```bash
make
```

Now edit `iocBoot/iocdemo/st.cmd`. The generated file has the structure; make sure it loads your database:

```text
#!../../bin/linux-x86_64/demo

< envPaths

cd "${TOP}"
dbLoadDatabase "dbd/demo.dbd"
demo_registerRecordDeviceDriver pdbbase

## Load the database
dbLoadRecords("db/demo.db")

cd "${TOP}/iocBoot/${IOC}"
iocInit

## Anything after iocInit runs once the IOC is up
```

Run it:

```bash
cd iocBoot/iocdemo
chmod +x st.cmd
./st.cmd
```

Same PVs, now served by an executable you built and can extend with device support.

### Understanding st.cmd's shape

The order is not arbitrary:

| Phase | What happens |
| --- | --- |
| Before `iocInit` | Load DBDs, register drivers, configure ports (`drvAsynIPPortConfigure`), load databases, set up [autosave](../toolbox/soft-support-modules.md#autosave) paths and pass-0 restore, load [access security](../architecture/access-security.md) |
| `iocInit` | Records initialise, device support connects, scan tasks start, the CA/PVA servers begin serving |
| After `iocInit` | Autosave monitor sets, [sequencer](../toolbox/scanning-and-automation.md#sequencer-snl) programs, anything needing running records |

Putting something on the wrong side of `iocInit` is a classic failure: `dbLoadRecords` after `iocInit` does nothing useful, and `create_monitor_set` before it fails.

## Part 3: add macros so it scales

Real databases are templates. Rewrite `demo.db` as `demo.template`:

```text
record(ao, "$(P)$(R):Heater-SP") {
    field(DESC, "$(DESC=Heater power)")
    field(EGU,  "%")
    field(DRVL, "0")
    field(DRVH, "$(MAXPOWER=100)")
    field(PINI, "YES")
}
record(calc, "$(P)$(R):Temperature") {
    field(SCAN, "1 second")
    field(INPA, "$(P)$(R):Heater-SP")
    field(INPB, "$(P)$(R):Temperature")
    field(CALC, "B + (20 + A*0.6 - B) * 0.15")
    field(EGU,  "degC")
    field(HIHI, "$(TRIP=75)")   field(HHSV, "MAJOR")
}
```

Instantiate three chambers, from `st.cmd`:

```text
dbLoadRecords("db/demo.template", "P=DEMO,R=:CH1,TRIP=75")
dbLoadRecords("db/demo.template", "P=DEMO,R=:CH2,TRIP=80")
dbLoadRecords("db/demo.template", "P=DEMO,R=:CH3,TRIP=65,MAXPOWER=50")
```

Or with a `.substitutions` file and `msi`/`dbLoadTemplate` for larger sets — see [templates and substitutions](../architecture/process-database.md#templates-and-substitutions). This is how 176 BPMs get instantiated, and it's the difference between a database you maintain and a database you generate.

## Where to go next

| Next step | Page |
| --- | --- |
| Put a screen on it | [Phoebus](phoebus.md) or `pip install pydm` |
| Talk to real hardware | **[Talk to a Real Device](talk-to-a-device.md)** — one instrument, end to end |
| Survive a restart | [autosave](../toolbox/soft-support-modules.md#autosave) |
| Understand what you just wrote | [Process Database](../architecture/process-database.md) |
| Add IOC health PVs | [iocStats](../toolbox/soft-support-modules.md#iocstats-and-deviocstats) |
| Fake a device to talk to | [Lewis or pcaspy](../toolbox/simulation-and-testing.md) |
| Do it properly, at scale | [Example Facility](../example-facility/index.md) |

## Common first-IOC problems

| Symptom | Cause |
| --- | --- |
| `Record type "calc" not found` | The DBD wasn't loaded, or the module providing that record type isn't in `configure/RELEASE` |
| Records load but never update | `SCAN` is `Passive` (the default) and nothing is triggering them |
| `st.cmd: Permission denied` | `chmod +x st.cmd` |
| `envPaths: No such file` | Run `st.cmd` from `iocBoot/iocdemo/`, not from anywhere else — relative paths resolve against the working directory |
| Value reads 0 with severity `INVALID` | The record processed and the read failed. Look at the device support, not the record. |
| `caput` appears to work but the value doesn't change | Clamped by `DRVL`/`DRVH`, blocked by [access security](../architecture/access-security.md), or the record is `DISA`bled |
| Two IOCs, one PV name | You started `softIoc` twice. Clients bind to whichever answers first. Kill one. |
