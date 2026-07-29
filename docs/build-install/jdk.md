# Java (JDK)

Every Java tool in the EPICS ecosystem needs a JDK: [Phoebus](phoebus.md), the [archive engine](../toolbox/archiving.md#phoebus-rdb-archive-engine), the [alarm services](alarm-system.md), [save & restore](save-and-restore.md), [ChannelFinder](channelfinder-recsync.md), [Olog](olog.md), [PVWS](pvws.md), [DBWR](dbwr.md), and the [Archiver Appliance](archiver-appliance.md).

## Which version

!!! warning "Check the project, don't trust this page"
    Java requirements move, and different tools in the ecosystem move at different times. **Read the README of the specific project you're building.** Phoebus in particular has raised its minimum several times, and building with too old a JDK produces confusing Maven errors rather than a clear message.

As a general guide: a recent LTS release (17 or 21) satisfies most of the ecosystem. Phoebus's Display Builder needs JavaFX, which some JDK distributions bundle and others don't — see below.

## Install

=== "Debian / Ubuntu"

    ```bash
    sudo apt update
    sudo apt install -y openjdk-21-jdk maven
    ```

    To see what's available:

    ```bash
    apt-cache search openjdk | grep jdk
    ```

=== "RHEL / Rocky / Alma"

    ```bash
    sudo dnf install -y java-21-openjdk-devel maven
    ```

=== "Manual (any distro)"

    Download a build from [Adoptium](https://adoptium.net/) (Eclipse Temurin), [Azul Zulu](https://www.azul.com/downloads/), or [Oracle](https://www.oracle.com/java/technologies/downloads/), unpack it into `/opt`, and set `JAVA_HOME` accordingly.

    Azul Zulu offers builds **with JavaFX included**, which is the simplest route for Phoebus.

## Set JAVA_HOME

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64      # Debian/Ubuntu
# export JAVA_HOME=/usr/lib/jvm/java-21-openjdk           # RHEL family
export PATH=${JAVA_HOME}/bin:${PATH}
```

!!! danger "No spaces around the `=`"
    `export JAVA_HOME = /path` is not valid shell. Bash reads it as the command `export` with three arguments, `JAVA_HOME` ends up unset, and Maven then produces an error mentioning neither `export` nor `JAVA_HOME`.

Find the real path on your machine:

```bash
readlink -f $(which java) | sed 's|/bin/java||'
```

Verify:

```bash
java -version
javac -version        # must work too — a JRE alone cannot build
mvn -version          # should report the JDK it found
echo $JAVA_HOME
```

Put the exports in `~/.bashrc` or `~/.profile`, as with [the EPICS variables](epics-base.md#set-up-your-environment).

## Multiple JDKs

Common, because different tools want different versions.

=== "Debian / Ubuntu"

    ```bash
    sudo update-alternatives --config java
    sudo update-alternatives --config javac
    ```

=== "RHEL family"

    ```bash
    sudo alternatives --config java
    ```

=== "Per-project, without changing the system"

    ```bash
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 mvn clean install
    ```

    Or use [SDKMAN!](https://sdkman.io/) to switch per shell — cleaner than fighting `alternatives` when you genuinely need three JDKs.

## JavaFX

Phoebus's UI is JavaFX, which was removed from the JDK after Java 10 and is now a separate project ([OpenJFX](https://openjfx.io/)).

Three ways to satisfy it:

1. **A JDK that bundles it** — Azul Zulu "JDK FX" builds. Simplest.
2. **Maven pulls it in** — Phoebus's build fetches the JavaFX artefacts it needs, which works if your build has network access.
3. **A distribution package** — `openjfx` on Debian/Ubuntu. Version-matching with your JDK can be fiddly.

Symptom of getting this wrong: the build succeeds and the application fails at startup with a missing `javafx.*` class. Not subtle, but confusing if you don't know JavaFX is separable from the JDK.

## Maven

Most of the ecosystem builds with Maven.

```bash
mvn -version
```

Worth knowing:

- Maven caches dependencies in `~/.m2/repository`. First builds download a lot; later builds are much faster.
- A corrupted cache produces bizarre errors. `rm -rf ~/.m2/repository` and rebuild is the standard remedy, at the cost of a re-download.
- `mvn clean install -o` builds offline once the cache is warm — useful on a controls network with no internet access, and a good reason to warm the cache deliberately before you need it.
- Behind a proxy, configure it in `~/.m2/settings.xml`, not in environment variables.

## Next

→ [Phoebus](phoebus.md), or [Tomcat](tomcat.md) if you're heading for the web services.
