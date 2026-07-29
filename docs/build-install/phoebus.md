# Build and Install Phoebus

Phoebus gives you displays, trending, PV tables, and the client applications for the [alarm system](alarm-system.md), [save & restore](save-and-restore.md), [Olog](olog.md) and the [scan server](../toolbox/scanning-and-automation.md#phoebus-scan-server). Building it also builds all of those **services**.

| | |
| --- | --- |
| Source | [github.com/ControlSystemStudio/phoebus](https://github.com/ControlSystemStudio/phoebus) |
| Documentation | [control-system-studio.readthedocs.io](https://control-system-studio.readthedocs.io/) |
| Overview | [Toolbox → Phoebus](../toolbox/operator-interfaces.md#phoebus) |

!!! tip "Prebuilt releases exist"
    Check the [releases page](https://github.com/ControlSystemStudio/phoebus/releases) before building. If a prebuilt product for your platform is available, take it — building Phoebus is instructive but not necessary, and it takes an hour.

## Prerequisites

- A [JDK](jdk.md) meeting the version stated in Phoebus's own README, with `JAVA_HOME` set
- Maven 3.x
- `git`
- **JavaFX** available to the JDK — see [the JavaFX section](jdk.md#javafx)
- Network access for the dependency fetch

## Build

```bash
cd ${HOME}
git clone https://github.com/ControlSystemStudio/phoebus.git
cd phoebus
```

**Step 1 — external dependencies.** This is a separate, easily-missed step:

```bash
mvn clean verify -f dependencies/pom.xml
```

Skipping it produces missing-artefact errors during the main build that give no hint that this step exists.

**Step 2 — the build:**

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64   # your actual path
mvn clean install
```

Fifteen to sixty minutes on a first run, most of it Maven downloading. `BUILD SUCCESS` means you're done.

To skip the test suite while iterating:

```bash
mvn clean install -DskipTests
```

## Run

```bash
cd phoebus-product/target
java -jar product-*.jar
```

There are also generated launcher scripts in `phoebus-product/target/` — usually `phoebus.sh` — which set up the module path for you and are the better way to launch it routinely.

### Point it at your PVs

Phoebus reads the standard [EPICS environment variables](../reference/environment-variables.md), so if `caget` works in the shell you launch it from, Phoebus works too. Settings can also go in a preferences file:

```properties
# settings.ini
org.phoebus.pv.ca/addr_list=10.1.5.255 10.1.6.255
org.phoebus.pv.ca/auto_addr_list=false
org.phoebus.pv/default=ca
```

```bash
java -jar product-*.jar -settings settings.ini
```

A facility distributes one `settings.ini` to every console, containing the address lists, the archiver URLs, the alarm system's Kafka address, the save/restore and Olog service URLs, and the display file root. **This file is the entire client-side configuration of your control system**, and it belongs in version control.

## First things to try

1. **Probe** — Applications → Diagnostics → Probe. Type a PV name. The simplest possible check that Phoebus can see your IOC.
2. **PV Table** — paste several PV names, see values, timestamps and severities in one view.
3. **Display Builder** — Applications → Display → New Display. Drop a Text Entry bound to `DEMO:Heater-SP` and a Meter bound to `DEMO:Temperature` (from [Your First IOC](first-ioc.md)). Ctrl-S, then run it.
4. **Kill the IOC and watch.** The widgets go to their disconnected appearance. Understanding this immediately is worth more than another hour of building screens.
5. **Data Browser** — plot a live PV. It trends from the moment you open it, with no archiver needed.
6. **PV Tree** — enter a `calc` record's name and see its input links drawn as a tree. This is the best tool in existence for understanding an unfamiliar database.

## The services built alongside

The same build produces standalone service JARs:

| Service | Location under the source tree | Page |
| --- | --- | --- |
| RDB archive engine | `services/archive-engine/target/` | [Archiving](../toolbox/archiving.md#phoebus-rdb-archive-engine) |
| Alarm server | `services/alarm-server/target/` | [Alarm system](alarm-system.md) |
| Alarm logger | `services/alarm-logger/target/` | [Alarm system](alarm-system.md) |
| Alarm config logger | `services/alarm-config-logger/target/` | [Alarm system](alarm-system.md) |
| Save & restore | `services/save-and-restore/target/` | [Save & restore](save-and-restore.md) |
| Scan server | `services/scan-server/target/` | [Scanning](../toolbox/scanning-and-automation.md#phoebus-scan-server) |

Each runs as `java -jar <service>.jar -help` and is configured by a properties file. **The hard part of deploying them is their infrastructure** — Kafka, Elasticsearch, a relational database — not the services themselves.

## Deploying to consoles

For more than one machine:

- **Distribute the built product**, don't build on each console. A tarball, a package, or a container.
- **One shared `settings.ini`**, deployed by configuration management. Divergent client settings produce "it works on my machine" reports that take hours to unravel.
- **Displays on a shared, read-only path** — NFS, or a web server that Phoebus can read `.bob` files over HTTP from. Keep the display files in git and deploy from it.
- **A launcher script** that sets `JAVA_HOME`, the settings file, and the display root, so operators start it from a desktop icon.
- **Consider [DBWR](dbwr.md)** for anyone who only needs to look: no install, and the same `.bob` files.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| Missing-artefact errors early in the build | The `dependencies/pom.xml` step was skipped |
| `NoClassDefFoundError: javafx/...` at startup | [JavaFX](jdk.md#javafx) not available to your JDK |
| `Unsupported class file major version` | JDK too old for the current source. Check the README's minimum. |
| Builds, but shows a blank window | Graphics/driver issue in a VM. Try software rendering: `-Dprism.order=sw` |
| No PVs connect, but `caget` works in the same shell | Phoebus preferences overriding the environment — check `settings.ini`, particularly `auto_addr_list` |
| Bizarre, inconsistent Maven failures | Corrupted cache. `rm -rf ~/.m2/repository` and rebuild. |
| Slow, then times out fetching dependencies | Proxy needed — configure it in `~/.m2/settings.xml` |

## Alternative: PyDM

If the JDK/JavaFX/Maven chain is more than you want today:

```bash
pip install pydm
pydm --pv DEMO:Temperature
```

[PyDM](../toolbox/operator-interfaces.md#pydm) gets you a working screen in about a minute. It doesn't give you the alarm tree, save/restore or Olog clients — but for learning, and for Python-centric teams, it's a legitimate primary choice rather than a consolation prize.

## Next

→ [Archiver Appliance](archiver-appliance.md), or [the alarm system](alarm-system.md).
