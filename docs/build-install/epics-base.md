# Build and Install EPICS Base

The foundation. Everything else needs this.

**Upstream instructions:** [Installation on Linux / macOS / Windows](https://docs.epics-controls.org/projects/how-tos/en/latest/getting-started/installation.html) — the authoritative version. This page covers the same ground with the things that trip people up.

## Prerequisites

| Need | Why |
| --- | --- |
| GNU `make` | The EPICS build system requires GNU Make specifically |
| `gcc` / `g++` | Base is C and C++ |
| `perl` | The build system's code generators are Perl. Not optional. |
| `readline` dev headers | Gives the `epics>` prompt history and editing |
| `git` | To clone the source |

=== "Debian / Ubuntu"

    ```bash
    sudo apt update
    sudo apt install -y build-essential perl git libreadline-dev
    ```

=== "RHEL / Rocky / Alma"

    ```bash
    sudo dnf groupinstall -y "Development Tools"
    sudo dnf install -y perl git readline-devel
    ```

## Build

Installing into `${HOME}/EPICS/base`, which is the convention most tutorials assume.

```bash
mkdir -p ${HOME}/EPICS
cd ${HOME}/EPICS
git clone --recursive https://github.com/epics-base/epics-base.git base
cd base
```

`--recursive` matters: the PVA components (`pvData`, `pvAccess`, `pvDatabase`, `normativeTypes`, `pva2pva`) are git submodules. Without it you get a Base that builds but has no PV Access, and the failure appears much later as a missing `softIocPVA`.

Building a specific release rather than the development tip:

```bash
git tag -l 'R7*' | sort -V | tail -5     # see what's available
git checkout R7.0.9                       # or whichever
git submodule update --init --recursive   # re-sync submodules to the tag
```

For anything you intend to keep, use a release tag. The `main` branch is the developers' working branch — usually fine, occasionally not.

Then build:

```bash
make -j$(nproc)
```

Ten to thirty minutes depending on the machine. `-j` parallelises it; if a parallel build fails confusingly, retry with plain `make` before believing the error.

Success looks like a build that ends without an error, and:

```bash
ls bin/*/                # softIoc, caget, caput, camonitor, ...
```

## Set up your environment

```bash
export EPICS_BASE=${HOME}/EPICS/base
export EPICS_HOST_ARCH=$(${EPICS_BASE}/startup/EpicsHostArch)
export PATH=${EPICS_BASE}/bin/${EPICS_HOST_ARCH}:${PATH}
```

Base also ships setup scripts that do this for you — `${EPICS_BASE}/startup/setup_profile.sh` and friends — worth looking at, since they handle more cases than three hand-written lines.

!!! warning "This lasts only for the current shell"
    New terminal, new ssh session, `sudo -i` — all start fresh. Put the three lines in `~/.bashrc` (interactive shells) or `~/.profile` (login shells), then `source` it.

    **If `caget` works in one terminal and not another, this is why.** Every time.

Check it:

```bash
echo $EPICS_HOST_ARCH        # e.g. linux-x86_64
which softIoc caget          # both should resolve
```

## Test it

```bash
softIoc
```

You should get:

```text
Starting iocInit
############################################################################
## EPICS R7.0.x
## Rev. ...
############################################################################
iocRun: All initialization complete
epics>
```

At the prompt:

```text
epics> dbl                  # no records yet — correct
epics> help                 # every registered command
epics> exit
```

Then the PVA server:

```bash
softIocPVA
```

If `softIocPVA` is missing, the submodules weren't cloned. Fix with `git submodule update --init --recursive` and rebuild.

### Prove it end to end

Two terminals. In the first:

```bash
cat > /tmp/test.db <<'EOF'
record(ai, "TEST:Temperature") {
    field(DESC, "A number I can change")
    field(EGU,  "degC")
    field(PREC, "2")
    field(HIGH, "30")   field(HSV,  "MINOR")
    field(HIHI, "40")   field(HHSV, "MAJOR")
}
EOF
softIoc -d /tmp/test.db
```

In the second (with the environment set):

```bash
caget TEST:Temperature          # 0
caput TEST:Temperature 35       # write
caget -a TEST:Temperature       # value, timestamp, and MINOR severity
camonitor TEST:Temperature &    # subscribe
caput TEST:Temperature 45       # watch the monitor fire, severity MAJOR
```

That's a complete EPICS system: a server owning a record, a client reading it over the network, alarm limits working. Everything else in this guide is scale and convenience on top of exactly this.

## Building for other targets

Cross-compilation is a first-class feature. In `configure/CONFIG_SITE`:

```make
CROSS_COMPILER_TARGET_ARCHS = linux-arm RTEMS-beatnik
```

Each target needs its own toolchain and, for RTEMS/VxWorks, its own configuration in `configure/os/`. Not a beginner activity, but worth knowing it's designed in rather than bolted on.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| `perl: not found`, or a build failure in a `.pl` script | Perl missing. It's a hard requirement, not an optional nicety. |
| `readline.h: No such file` | Install `libreadline-dev` / `readline-devel`, then rebuild. |
| No `softIocPVA` after a successful build | Submodules not cloned. `git submodule update --init --recursive`. |
| `caget: command not found` | `PATH` not set, or set in a different shell. |
| `EPICS_HOST_ARCH` empty | The `EpicsHostArch` script path is wrong, i.e. `EPICS_BASE` is wrong. |
| Confusing parallel build failure | Retry without `-j`; the real error is usually then legible. |
| Built fine, `caget` times out from another machine | Not a build problem — [networking](../architecture/networking.md). Firewall or address list. |
| `Channel connect timed out` on the same machine | Check the record name with `dbl` on the IOC. A typo looks exactly like a network fault. |

More: [Troubleshooting](../reference/troubleshooting.md).

## Alternatives to building

| Route | Command |
| --- | --- |
| conda | `conda install -c conda-forge epics-base` |
| Debian/Ubuntu | `apt install epics-dev` ([epicsdeb](../toolbox/deployment-and-operations.md#distribution-packages)) |
| Containers | [epics-containers](containers.md) |
| Prebuilt VM | [Training resources](../reference/training.md) |

## Next

→ [Your First IOC](first-ioc.md)
