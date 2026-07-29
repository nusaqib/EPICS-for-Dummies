# Linux Prerequisites

EPICS development happens on Linux. Not exclusively — Base builds on Windows and macOS, and IOCs run on RTEMS and VxWorks — but every facility's servers, every module's CI, and every piece of advice you'll get on the mailing list assumes Linux.

If you're coming from a physics or engineering background and the shell is unfamiliar territory, this page is the minimum set. The SNS training course also has a good [Linux for EPICS](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/00%20Linux.pdf) primer.

## Which distribution

| Distribution | Why you'd choose it |
| --- | --- |
| **Debian** / **Ubuntu LTS** | Easiest for learning. `apt` has everything, and [epicsdeb](../toolbox/deployment-and-operations.md#distribution-packages) packages Base and many modules. Most tutorials assume this. |
| **RHEL** / **Rocky** / **AlmaLinux** | What facility servers actually run, for the ten-year support horizon. Fewer prebuilt EPICS packages; you build from source. |
| **openSUSE**, **Arch**, anything else | Works fine. You'll translate package names yourself. |

For learning, use a VM or container rather than your main desktop — you'll be putting things in `/opt` and editing environment files, and being able to throw it away is worth a lot. Or skip building entirely and use a [prebuilt training VM](../reference/training.md).

## Packages you need before building anything

=== "Debian / Ubuntu"

    ```bash
    sudo apt update
    sudo apt install -y build-essential perl git libreadline-dev
    ```

    For the Java-based tools ([Phoebus](../build-install/phoebus.md), the archiver, the services):

    ```bash
    sudo apt install -y openjdk-21-jdk maven
    ```

    For Python client work:

    ```bash
    sudo apt install -y python3-pip python3-venv
    ```

=== "RHEL / Rocky / Alma"

    ```bash
    sudo dnf groupinstall -y "Development Tools"
    sudo dnf install -y perl git readline-devel
    sudo dnf install -y java-21-openjdk-devel maven
    sudo dnf install -y python3-pip
    ```

=== "What each one is for"

    | Package | Why |
    | --- | --- |
    | `make` | EPICS Base has its own build system layered on GNU Make. Non-GNU make will not work. |
    | `gcc` / `g++` | Base is C and C++. |
    | `perl` | The EPICS build system and its code generators are Perl. Not optional. |
    | `readline` | Gives the `epics>` IOC shell history and line editing. Technically optional; you will regret skipping it within ten minutes. |
    | `git` | Everything is on GitHub. |
    | JDK 17+ | Phoebus and all the Java services. Check each project's README for its minimum. |
    | Maven | Builds the Java projects. |

## The four environment variables that matter

More than half of "EPICS doesn't work" is an environment problem. These are the ones you'll set:

```bash
export EPICS_BASE=${HOME}/EPICS/base
export EPICS_HOST_ARCH=$(${EPICS_BASE}/startup/EpicsHostArch)
export PATH=${EPICS_BASE}/bin/${EPICS_HOST_ARCH}:${PATH}
```

| Variable | Meaning |
| --- | --- |
| `EPICS_BASE` | Where Base is installed. Module Makefiles read it from `configure/RELEASE`, but tools and scripts want it in the environment. |
| `EPICS_HOST_ARCH` | Your platform triple, e.g. `linux-x86_64`. Base builds everything into architecture-specific directories, so this is how tools find binaries. Compute it with the provided script rather than guessing. |
| `PATH` | So `caget`, `softIoc`, `makeBaseApp.pl` are runnable. |
| `EPICS_CA_ADDR_LIST` | Which hosts/subnets to search for PVs. Unset means "broadcast on all local interfaces", which is right on a flat lab network and wrong the moment routers are involved. See [environment variables](../reference/environment-variables.md) and [networking](../architecture/networking.md). |

!!! warning "`export` only lasts for that shell"
    A new terminal, an ssh session, or a `sudo -i` starts fresh. Put the three lines above in `~/.bashrc` (interactive shells) or `~/.profile` (login shells), then `source` the file. If `caget` works in one terminal and not another, this is why — every single time.

Facilities usually replace all of this with a site setup script (`source /opt/epics/setup.sh`) or environment modules (`module load epics/7.0.9`). Ask what yours does before inventing your own.

## Shell skills you'll actually use

Not a Linux course — just the specific things EPICS work demands.

**Reading a build failure.** EPICS build output is verbose and the real error is rarely the last line. Capture it and search:

```bash
make 2>&1 | tee /tmp/build.log
grep -n -i -m5 -E "error|no such file" /tmp/build.log
```

**Finding what a module installed.** After a `make install`, headers land in `include/`, libraries in `lib/$EPICS_HOST_ARCH/`, DBDs and templates in `dbd/` and `db/`. When a `.db` file says "record type not found", the DBD didn't get installed or isn't loaded.

**Checking whether an IOC is actually listening.**

```bash
ss -lunp | grep -E '5064|5065|5075|5076'   # CA and PVA ports
ps aux | grep -i ioc
```

**Watching a process's console.** IOCs run under [procServ](../toolbox/deployment-and-operations.md#procserv) or `systemd` in production. `telnet localhost 20001` gets you the `epics>` prompt of a procServ-managed IOC. `Ctrl-]` then `quit` detaches without killing it — **`Ctrl-C` in a procServ session will stop the IOC**, and on a live machine that is a very bad afternoon.

**tmux or screen.** You will want several terminals on a remote machine: IOC console, `camonitor`, editor. Learn one multiplexer.

## File locations you'll see

There is no EPICS filesystem standard, but the conventions cluster:

```text
$HOME/EPICS/base            # a learner's Base build
/opt/epics/base-7.0.9       # a facility's versioned Base
/opt/epics/modules/asyn/    # site-installed support modules
/opt/epics/ioc/<iocname>/   # a deployed IOC application
  ├── st.cmd                #   startup script
  ├── db/                   #   loaded databases
  ├── autosave/             #   autosave .sav files (must be writable!)
  └── iocBoot/
/var/log/ioc/<iocname>.log  # procServ logs
```

Two operational notes hidden in that tree: the autosave directory must be writable by the IOC's user or restore silently does nothing, and an IOC's working directory matters because relative paths in `st.cmd` resolve against it.

## Networking, briefly

EPICS discovers PVs by **UDP broadcast** on port 5064 (CA) and 5076 (PVA), then opens **TCP** connections to whichever IOC answers. Consequences you will meet:

- A host firewall that blocks inbound UDP breaks discovery, and it looks exactly like "the PV doesn't exist".
- Broadcasts don't cross routers. On any network more complex than a single switch, set `EPICS_CA_ADDR_LIST` explicitly and set `EPICS_CA_AUTO_ADDR_LIST=NO`.
- VPNs and Docker's default bridge network both break broadcast discovery in interesting ways. Containers usually need host networking, or explicit address lists in both directions.

Full treatment in [Networking](../architecture/networking.md).

## Next

→ [Build EPICS Base](../build-install/epics-base.md)
