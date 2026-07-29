# Command Cheat Sheet

Everything you'll type. Keep this tab open for your first month.

## Channel Access

```bash
caget PV                          # read
caget -a PV                       # + timestamp, alarm severity and status
caget -t PV                       # value only, no name (for scripts)
caget -# 10 PV                    # first 10 elements of an array
caget -S PV                       # char array as a string
caget -d DBR_CTRL_DOUBLE PV       # everything: units, limits, precision
caget PV1 PV2 PV3                 # several at once
caget -w 5 PV                     # 5 s timeout instead of the default

caput PV 42                       # write
caput -c PV 42                    # write and wait for COMPLETION (put-callback)
caput -c -w 30 PV 42              # ...with a 30 s timeout — use for motors
caput -a PV 3 1 2 3               # write an array of 3 elements
caput PV "Some text"              # string

camonitor PV                      # subscribe: print every update
camonitor -t s PV                 # timestamps as seconds since epoch
camonitor -g 3 PV                 # 3 significant digits
camonitor PV1 PV2                 # several

cainfo PV                         # connection details: server address, native
                                  # type, element count, ACCESS RIGHTS
```

!!! tip "`caget -a` and `cainfo` are the two you'll underuse"
    `caget` alone gives you a number that may be `INVALID` — a reading from an unplugged instrument looks identical to a real one. `caget -a` shows the severity.

    `cainfo` tells you *which server answered*, which is how you diagnose duplicate PV names and confirm that traffic is going through a [gateway](../toolbox/gateways.md) rather than around it.

## PV Access

```bash
pvget PV                          # read
pvget -r 'value,timeStamp' PV     # only these fields of the structure
pvget -M json PV                  # JSON output
pvput PV 42                       # write
pvput PV field=value              # write into a structure field
pvmonitor PV                      # subscribe
pvinfo PV                         # introspect the structure's type
pvlist                            # ENUMERATE PVA servers on this segment
pvlist <server-guid>              # channels served by one server
pvcall SERVICE arg=value          # RPC call
```

`pvlist` has no Channel Access equivalent — CA cannot be enumerated. It's often the quickest way to answer "is anything out there?".

## The IOC shell

At the `epics>` prompt, or over `telnet` to a [procServ](../toolbox/deployment-and-operations.md#procserv) port.

```text
help                        every registered command
dbl                         list all records
dbl "" ".*Current.*"        list matching records
dbl "ai"                    list records of one type
dbgrep "SR-C05-*"           grep record names

dbpr REC                    print a record's main fields
dbpr REC 1                  more
dbpr REC 4                  everything, including link details
dbtr REC                    test-process a record and show the result
dbgf REC.FIELD              get one field directly (no network)
dbpf REC.FIELD value        put one field directly
dbnr                        count records by type

casr                        CA server report: summary
casr 1                      + per-client list
casr 2                      + per-client channel counts and event queues
dbLockShowLocked            show lock sets
dbior "" 1                  driver I/O report
dbdr                        DBD report

epicsThreadShowAll          every thread, priority, state
epicsMutexShowAll           mutexes
scanppl                     periodic scan lists and their records
scanpel                     event scan lists
asdbdump                    loaded access security rules
aspuag / asphag             print user / host access groups
asInit                      reload the access security file

var                         list IOC shell variables
system "ls -l"              run a shell command (if enabled)
exit                        stop the IOC
```

!!! danger "`Ctrl-C` in a procServ session stops the IOC"
    Detach with `Ctrl-]` then `quit`. On a live machine, `Ctrl-C` is a memorable mistake.

The three you'll use most: **`dbl`** (does the record exist?), **`dbpr`** (what is it doing?), **`casr 2`** (who is hammering this IOC?).

## Environment

```bash
echo $EPICS_BASE $EPICS_HOST_ARCH
$EPICS_BASE/startup/EpicsHostArch          # compute the arch string

export EPICS_CA_ADDR_LIST="10.1.5.255 10.1.6.42"
export EPICS_CA_AUTO_ADDR_LIST=NO
export EPICS_PVA_ADDR_LIST="10.1.5.255"
export EPICS_PVA_AUTO_ADDR_LIST=NO
```

Full list: [Environment Variables](environment-variables.md).

## Running IOCs

```bash
softIoc                             # empty IOC, epics> prompt
softIoc -d my.db                    # load a database
softIoc -m P=TEST:,R=DEV1 -d my.db  # with macros
softIoc -s -d my.db                 # no interactive shell
softIocPVA -d my.db                 # + a PVA server

./st.cmd                            # a built IOC application
                                    # (run from its iocBoot directory)

makeBaseApp.pl -t ioc myioc         # generate an application skeleton
makeBaseApp.pl -i -t ioc myioc      # add the boot directory
msi -I. -S my.substitutions         # expand templates
msi -M P=TEST: my.template          # expand with macros
```

## procServ

```bash
procServ -n "myioc" -L /var/log/ioc/myioc.log --allow --autorestart \
         20101 /opt/epics/ioc/myioc/st.cmd

telnet localhost 20101              # attach to the console
# Ctrl-] then "quit"                to detach WITHOUT killing the IOC
```

## Diagnosing the network

```bash
ss -lunp | grep -E '5064|5076'      # UDP: is the IOC listening?
ss -ltnp | grep -E '5064|5075'      # TCP
sudo tcpdump -n -i any 'udp port 5064 or udp port 5076'   # watch searches
ps aux | grep -i -E 'ioc|softIoc|caRepeater'
```

## Python one-liners

```python
# PyEpics
import epics
epics.caget('PV'); epics.caput('PV', 42, wait=True)
pv = epics.PV('PV'); pv.value, pv.timestamp, pv.severity, pv.units

# p4p (PVA)
from p4p.client.thread import Context
ctx = Context('pva'); v = ctx.get('PV'); ctx.put('PV', 42)

# caproto
from caproto.threading.client import Context
pv, = Context().get_pvs('PV'); pv.read().data
```

See [Client Libraries](../toolbox/client-libraries.md).

## Useful shell recipes

```bash
# Are all these PVs connected?
for pv in $(cat pvlist.txt); do
  caget -w 2 -t "$pv" >/dev/null 2>&1 || echo "DEAD: $pv"
done

# Anything in alarm?
caget -a $(cat pvlist.txt) | grep -v NO_ALARM

# Snapshot values to a file, and diff later
caget -t $(cat pvlist.txt) > /tmp/before.txt
# ...do something...
caget -t $(cat pvlist.txt) > /tmp/after.txt
diff /tmp/before.txt /tmp/after.txt

# Watch a PV, timestamped, into a log
camonitor -t sr PV | tee /tmp/pv.log
```

The snapshot-and-diff recipe is a poor cousin of [save & restore](../toolbox/save-and-restore.md), and it's genuinely useful when you don't have that service yet.

## Record fields you'll set constantly

| Field | Meaning |
| --- | --- |
| `DESC` | Description, 40 chars. Appears on screens and in the alarm tree. |
| `SCAN` | `Passive`, `I/O Intr`, `Event`, or a period. Default `Passive`. |
| `DTYP` | Device support. `Soft Channel` for no hardware. |
| `EGU` | Units. Fill it in. |
| `PREC` | Display precision |
| `LOPR`/`HOPR` | Display range |
| `DRVL`/`DRVH` | **Drive limits — writes are clamped. Free protection.** |
| `LOLO`/`LOW`/`HIGH`/`HIHI` | Alarm limits |
| `LLSV`/`LSV`/`HSV`/`HHSV` | Their severities |
| `HYST` | Alarm hysteresis — cures chatter |
| `MDEL` | Monitor deadband — controls network load |
| `ADEL` | Archive deadband — controls storage cost |
| `PINI` | Process once at `iocInit` |
| `FLNK` | Process this record next |
| `ASG` | [Access security](../architecture/access-security.md) group |
| `SIML`/`SIOL`/`SIMS` | [Simulation mode](../toolbox/simulation-and-testing.md#built-into-the-tools) |

Full detail: [Record Types](record-types.md) and [Process Database](../architecture/process-database.md).

## Link modifiers

| Modifier | Effect |
| --- | --- |
| `NPP` | Don't process the target; read its current value. **Default.** |
| `PP` | Process the target first, then read it |
| `CA` | Force through Channel Access — splits the lock set |
| `CP` | Monitor the target; **process me when it changes** |
| `CPP` | Like `CP`, but only if I'm `Passive` |
| `MS` | Propagate the target's alarm severity to me |
| `MSS` | Propagate severity and status |
| `MSI` | Propagate only `INVALID` |
| `NMS` | Don't propagate. Default. |

`CP` + `MS` together is the idiom behind every summary record in a facility.
