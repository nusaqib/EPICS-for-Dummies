# Error Message Index

Organised by the text you'd paste into a search engine, rather than by subsystem. If you arrived here from a search, you're in the right place.

!!! note "Exact wording varies"
    Messages differ between EPICS Base versions, between modules, and between platforms. Match on the distinctive keywords rather than the whole string. Where the precise text matters and isn't reproduced here, search the [tech-talk archive](https://epics.anl.gov/tech-talk/) for it — thirty years of the same errors, with answers.

Symptom-first version of the same ground: [Troubleshooting](troubleshooting.md).

## Connection and networking

### `Channel connect timed out` · `... not found`

Nothing answered the name search. In order of likelihood:

1. **The record doesn't exist.** A typo is indistinguishable from a network fault. Check with `dbl` on the IOC.
2. **Different subnet.** [Broadcasts don't route.](../architecture/networking.md) Test with an explicit address:
   ```bash
   EPICS_CA_AUTO_ADDR_LIST=NO EPICS_CA_ADDR_LIST=<ioc-ip> caget PV
   ```
   **If that works and the default doesn't, your problem is discovery, not the IOC.**
3. **Firewall blocking UDP.** A rule permitting TCP 5064 but not UDP 5064 fails before TCP is attempted, and nothing in the message hints at it.
4. **`iocInit` failed**, so the IOC is running and serving nothing. Read its log from the top.
5. **Container on Docker's default bridge.** NAT means inbound searches never arrive — use `--network host`. See [containers](../build-install/containers.md).
6. **Wrong port**, because someone set up an isolated universe with `EPICS_CA_SERVER_PORT`.

### `Virtual circuit disconnect`

The TCP connection to an IOC dropped — the IOC stopped, its host went away, or the network broke. Normal and expected during an IOC restart; clients reconnect automatically. Repeated occurrences on a stable IOC point at network trouble: check switch error and discard counters.

### `Virtual circuit unresponsive`

The connection is open but the IOC stopped answering within `EPICS_CA_CONN_TMO`. Usually the IOC is alive but blocked — a scan task wedged behind slow device support, or CPU saturation. Check `casr 2` and [iocStats](../toolbox/soft-support-modules.md#iocstats-and-deviocstats).

### `Identical process variable name on multiple servers`

**Two IOCs are serving the same PV name.** This is a bug with no upside: clients bind to whichever answers first, so different clients silently get different values.

Find both servers with `cainfo PV` from several hosts, then kill or rename one. Prevented by an enforced [naming convention](../architecture/naming-conventions.md) plus a [directory service](../toolbox/directory-services.md) that makes duplicates visible.

### Messages mentioning `caRepeater`

`caRepeater` is a small process that redistributes server beacons to every CA client on a host. It starts automatically and binds UDP 5065. If it can't bind — blocked, or something else is on that port — clients still work but reconnect slowly after an IOC restarts.

### `Requested array size exceeds` · truncated arrays

Array size limits must agree at the **client, every [gateway](../toolbox/gateways.md), and the IOC**. Raise `EPICS_CA_MAX_ARRAY_BYTES` on all of them. Modern Base sizes buffers dynamically, but older clients, older IOCs and gateways in the path may not — and the symptom looks like data corruption rather than a limit.

## Record and database

### `Record type ... not found` · `Can't find record type`

The DBD describing that record type wasn't loaded. Either the module providing it is missing from `configure/RELEASE`, or its DBD isn't included in your app's DBD, or `dbLoadDatabase` didn't run before `dbLoadRecords`.

### `Record already exists` · duplicate record name

The same record name is defined twice — usually a substitutions file instantiated twice, or two templates that overlap. Non-fatal in some Base versions and always a bug.

### `Illegal SCAN` · `Illegal ... field value`

A field was given a value outside its menu. Check spelling and case: `1 second` is valid, `1 Second` and `1s` are not.

### `PV Link` errors · `dbGetLink` failures · `link ... not found`

A record's `INP`/`OUT`/`FLNK` names a record that doesn't exist. Frequently a macro that didn't expand, leaving a literal `$(P)` in the link. Check with `dbpr <record> 4`, which shows resolved links.

### Record reads `0` with severity `INVALID`

Processing happened and **the read failed**. This is not a magnitude — it means "unknown". Look at the device support, not the record: `dbpr <rec> 4` for `STAT`, and asyn tracing for the wire. A screen or script that ignores `SEVR` will present this as a real measurement.

### `UDF` · `Undefined`

The record has never successfully processed, so its value is undefined and it reports `INVALID`. Correct behaviour for a freshly loaded record; cleared by `PINI` or the first successful scan. If it persists, nothing is processing the record — check `SCAN`.

### The value never changes

`SCAN` is `Passive` — the default — and nothing is triggering it. Check that something does: a `PP` input link, an `FLNK`, `I/O Intr` with driver support, or a periodic rate. `dbtr <record>` test-processes it; if that produces a fresh value, your trigger is the problem.

### `caput` succeeds but the value doesn't change

Clamped by `DRVL`/`DRVH`; denied by [access security](../architecture/access-security.md) (check `cainfo`, which reports access rights); the record is disabled via `DISA`/`DISV`; a read-only [gateway](../toolbox/gateways.md) is in the path; or the record is `PACT` and discarded the write — see [busy](../toolbox/soft-support-modules.md#busy).

## IOC startup

### `st.cmd: Permission denied`

`chmod +x st.cmd`.

### `envPaths: No such file or directory`

Run `st.cmd` from its own `iocBoot/ioc<name>/` directory. Relative paths resolve against the working directory.

### Segmentation fault during `iocInit`

Most often `<app>_registerRecordDeviceDriver pdbbase` missing or misnamed in `st.cmd`, or a mismatch between the loaded DBD and the built binary. Rebuild, then check `st.cmd` against a freshly generated one from `makeBaseApp.pl`.

### The IOC exits immediately with no obvious error

Read the log **from the top**. The first error matters; the last line is usually a consequence. A failed `dbLoadRecords` early on often produces a cascade.

### Autosave restored nothing, and said nothing

**The save directory isn't writable by the IOC's user.** Autosave logs a complaint once and then silently does nothing for the rest of the run. Check after every deployment. See [autosave](../toolbox/soft-support-modules.md#autosave).

### Output records are at zero after a restart

No `PINI`, and no autosave. Both, together, are the fix.

## Device support and asyn

### Every read times out, nothing on the wire

Wrong host/port, or the device accepts a single connection that something else holds. Verify outside EPICS with `nc <host> <port>`.

### Reads time out, but the trace shows the command going out

**Terminator mismatch** — the most common [StreamDevice](../build-install/talk-to-a-device.md) problem by a wide margin. Try `Terminator = CR LF;`, and `InTerminator`/`OutTerminator` separately if the device differs by direction.

### First read works, later reads time out

Leftover bytes from a reply longer than your format string consumed. Add `ExtraInput = Ignore;`.

### Writes time out

A set command was given an `in` line but the device replies with nothing. Remove the `in`.

### `Mismatch` · protocol parse errors

The format string doesn't match the actual reply. Turn on tracing and compare byte for byte:

```text
asynSetTraceIOMask("PORT", 0, 0x2)   # escaped ASCII: terminators become visible
asynSetTraceMask("PORT", 0, 0x9)     # errors + driver I/O
```

Watch for units appended to numbers and for leading spaces.

### `LockTimeout` · intermittent failures with several records on one port

Records queue for one port, and one physical link is one resource. Reduce scan rates, or fetch several values per round trip with `Separator`.

## Build

### `perl: not found`, or a failing `.pl` script

Perl is a hard requirement of the EPICS build system, not an optional nicety.

### `readline.h: No such file or directory`

Install `libreadline-dev` (Debian/Ubuntu) or `readline-devel` (RHEL family), then rebuild.

### No `softIocPVA` after a successful build

Submodules weren't cloned. `git submodule update --init --recursive`, then rebuild.

### Undefined references at link time

A module is missing from `configure/RELEASE`, or was built for a different `EPICS_HOST_ARCH`.

### A confusing failure with `make -j`

Retry with plain `make`. Parallel builds interleave output and hide the real error.

### It builds after `make clean` but not otherwise

Stale dependency files. `make distclean` and rebuild.

## Java tools

### `Unsupported class file major version`

The JDK is older than the project requires. Check the project's README for its minimum — Phoebus in particular has raised its several times. See [JDK](../build-install/jdk.md).

### `NoClassDefFoundError: javafx/...`

[JavaFX is separate from the JDK](../build-install/jdk.md#javafx) since Java 11. Use a JDK that bundles it, let Maven fetch it, or install `openjfx`.

### Missing-artefact errors early in a Phoebus build

The `mvn clean verify -f dependencies/pom.xml` step was skipped. It's easy to miss and nothing in the error hints at it. See [Phoebus](../build-install/phoebus.md#build).

### Bizarre, inconsistent Maven failures

Corrupted local cache: `rm -rf ~/.m2/repository` and rebuild, at the cost of a re-download.

### `export JAVA_HOME = /path` had no effect

No spaces around `=` in shell assignments. Bash read that as a command with three arguments and `JAVA_HOME` is unset. Subsequent Maven errors mention neither.

## Services

### Phoebus sees no PVs, but `caget` works in the same shell

Phoebus preferences override the environment. Check `settings.ini`, particularly `auto_addr_list`. See [Phoebus](../build-install/phoebus.md#point-it-at-your-pvs).

### PVWS or DBWR shows nothing

The EPICS environment variables aren't reaching the Tomcat process. Set them in `$CATALINA_HOME/bin/setenv.sh` and restart. [The usual cause of a dead-looking fresh PVWS.](../build-install/pvws.md#configure-epics-access)

### A WAR deployed but the application doesn't work

Read `$CATALINA_HOME/logs/catalina.out`. Deployment failures almost always log their reason there.

### Archiver: connected PV count below configured count

Check the **disconnected PV list**. A PV that stopped connecting months ago is a silent gap you'll discover exactly when you need the data. Alarm on the count.

### The alarm system has gone quiet

Suspicious rather than reassuring — a dead alarm system looks exactly like a quiet machine. Check the alarm server, Kafka broker health and consumer lag, and [alarm on the rate reaching zero](../example-facility/alarm-plan.md#the-controls-configuration).

### Timestamps are wrong, or events appear out of order

NTP drift on an IOC host. [Timestamps come from IOCs](../toolbox/timing-systems.md), so a drifted clock corrupts the archive and makes causality analysis wrong. Treat it as a data-integrity incident, not housekeeping.

## The four questions to ask first

Before anything on this page, for almost any EPICS problem:

1. **Does the PV exist?** — `dbl` on the IOC
2. **What is its severity?** — `caget -a`
3. **Which server is answering?** — `cainfo`
4. **What is `SCAN` set to?** — `dbpr`

Those four resolve a large fraction of everything above.

## Still stuck?

[tech-talk](community.md), after searching the archive. Include your Base version, module versions, platform, the actual error text, the relevant `.db` and `st.cmd` fragments, `dbpr <record> 4` output, and what you already tried. A well-formed question usually gets a useful answer within hours.
