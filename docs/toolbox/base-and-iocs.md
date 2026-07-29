# EPICS Base and IOC Tools

Base is the only mandatory component. Everything else in [the Toolbox](index.md) is optional.

## EPICS Base

**What it is:** the core. Build system, C/C++ libraries, both network protocols, the standard record types, the process database engine, access security, and the command-line tools.

| | |
| --- | --- |
| Source | [github.com/epics-base/epics-base](https://github.com/epics-base/epics-base) |
| Releases & downloads | [epics-controls.org/resources-and-support/base](https://epics-controls.org/resources-and-support/base/) |
| Documentation | [docs.epics-controls.org](https://docs.epics-controls.org) |
| App Developer's Guide | [AppDevGuide](https://docs.epics-controls.org/en/latest/appdevguide/AppDevGuide.html) |
| Install how-to | [Getting started — installation](https://docs.epics-controls.org/en/latest/getting-started/installation-linux.html) |
| This guide | [Build EPICS Base](../build-install/epics-base.md) |

**Current series is 7.0.x**, which merged the former EPICS V4 work (PV Access, PVXS's predecessors, normative types) into Base. Base 3.15 and 3.14 are still found in production and are effectively frozen; new work should target 7.

**What ships inside:**

| Component | Purpose |
| --- | --- |
| `libca`, `libCom`, `libdbCore`, `libdbRecStd` | Channel Access client/server, OS abstraction, database engine, standard records |
| `pvAccess`, `pvData`, `pvDatabase`, `normativeTypes` | The PVA stack, bundled as submodules |
| ~25 standard record types | `ai`, `ao`, `bi`, `bo`, `mbbi`, `mbbo`, `calc`, `calcout`, `waveform`, `sub`, `seq`, `fanout`, `compress`, `histogram`, … |
| `softIoc`, `softIocPVA` | Ready-made IOC executables that load your `.db` and serve it. The fastest path to a working PV. |
| `caget`, `caput`, `camonitor`, `cainfo`, `caRepeater` | CA command-line tools |
| `pvget`, `pvput`, `pvmonitor`, `pvinfo`, `pvlist`, `pvcall` | PVA command-line tools |
| `makeBaseApp.pl` | Generates an IOC application skeleton |
| `msi` | Macro substitution and include — expands templates |
| `dbdExpand.pl`, `registerRecordDeviceDriver.pl`, and friends | Build-time code generators (this is why Perl is required) |
| `EpicsHostArch` | Prints your `EPICS_HOST_ARCH` value |

**Supported platforms:** Linux (x86_64, ARM, others), macOS, Windows (MinGW and Visual Studio), RTEMS, VxWorks. Cross-compilation for embedded and RTOS targets is a first-class feature of the build system, not an afterthought — one source tree, many `EPICS_HOST_ARCH`/`CROSS_COMPILER_TARGET_ARCHS` outputs.

### `softIoc`: the underrated tool

```bash
softIoc -d mydatabase.db      # serve a database, drop to the epics> prompt
softIoc -m P=TEST: -d my.db   # with macros
softIocPVA -d mydatabase.db   # same, plus a PVA server
```

No application to build, no `st.cmd`, no directory structure. For learning, for testing, for simulation, and for a surprising number of real production soft IOCs, this is all you need. See [Your First IOC](../build-install/first-ioc.md).

### The IOC shell

Every IOC gives you an `epics>` prompt. The commands you'll use constantly:

| Command | Purpose |
| --- | --- |
| `dbl` | List all records |
| `dbl "" ".*Current.*"` | List matching records |
| `dbpr <rec> <level>` | Print a record's fields, levels 0–4 |
| `dbtr <rec>` | Test-process a record |
| `dbgf` / `dbpf` | Get/put a field directly, bypassing the network |
| `casr <level>` | Channel Access server report: clients, channels, queues |
| `dbior <drv> <level>` | Driver I/O report |
| `dbLockShowLocked` | Show lock sets |
| `asdbdump` | Dump loaded [access security](../architecture/access-security.md) rules |
| `epicsThreadShowAll` | Every thread, its priority, and its state |
| `iocInit` | Bring the IOC up — the last line of `st.cmd` |
| `help` | Every registered command |

Full list: [Cheat Sheet](../reference/cheatsheet.md).

## Getting Base without compiling

| Method | Command / link | Notes |
| --- | --- | --- |
| conda-forge | `conda install -c conda-forge epics-base` | Fast; popular with Python-centric users. Also `epicscorelibs` for pip-installable Python bindings. |
| Debian/Ubuntu | `apt install epics-dev` — [epicsdeb](https://github.com/epicsdeb) | Community packaging of Base and many modules. |
| Containers | [epics-containers](deployment-and-operations.md#epics-containers) | Base images with modules pre-built. |
| Training VM | [SNS training VMs](../reference/training.md) | Everything pre-installed, including services. |
| Homebrew (macOS) | Community formulae | Varies; check current availability. |

## IOC application structure

`makeBaseApp.pl` generates the conventional tree:

```bash
mkdir myioc && cd myioc
makeBaseApp.pl -t ioc myioc
makeBaseApp.pl -i -t ioc myioc     # add the boot directory
make
```

```text
myioc/
├── configure/
│   ├── RELEASE        ← paths to EPICS_BASE and every support module
│   └── CONFIG_SITE    ← site build options
├── myiocApp/
│   ├── Db/            ← your .db, .template, .substitutions
│   └── src/           ← C/C++ source, and the "DBD includes" list
├── iocBoot/
│   └── iocmyioc/
│       ├── st.cmd     ← the startup script
│       └── envPaths   ← generated environment for st.cmd
├── bin/$EPICS_HOST_ARCH/       ← the built IOC executable
├── db/  dbd/  include/  lib/   ← installed artefacts
└── Makefile
```

`configure/RELEASE` is where most beginner build failures live: it must name every support module's install path, and a module missing there produces "record type not found" or a link error rather than anything helpful.

## Tools that come with or beside Base

### VDCT

**Visual Database Configuration Tool** — a graphical `.db` editor that draws records as boxes and links as wires. Java, from Cosylab, and old.

- [github.com/epics-extensions/VisualDCT](https://github.com/epics-extensions/VisualDCT)

Worth knowing about for one reason: reading somebody else's dense database is much easier as a diagram than as text. It parses existing `.db` and `.dbd` files, preserves comments and record order on save, and stores its layout as comments so a VDCT-edited file remains hand-editable. Nobody starts new work in it; plenty of people open it to understand a legacy IOC.

### StripTool

Real-time strip chart for CA. Ancient Motif application, still installed everywhere, still occasionally the fastest way to watch four signals for thirty seconds.

- [github.com/epics-extensions/StripTool](https://github.com/epics-extensions/StripTool)

Modern equivalents: Phoebus Data Browser, PyDM's time plot.

### ci-scripts

The community's shared CI harness for building EPICS modules on GitHub Actions, GitLab CI, AppVeyor and Travis, with dependency handling and cross-platform matrices.

- [github.com/epics-base/ci-scripts](https://github.com/epics-base/ci-scripts)

If you maintain a module, use this rather than writing workflows from scratch — it handles the "build against Base 3.15, 7.0, and master, on Linux, Windows and macOS" matrix that you would otherwise get wrong.

### ADL/OPI converters

Migrating displays between toolkits is a recurring facility chore. Converters exist in both directions between MEDM `.adl`, EDM `.edl`, Phoebus `.bob`/`.opi`, and caQtDM `.ui` — Phoebus ships importers for `.adl`, `.edl` and legacy `.opi`. Results always need manual cleanup; treat conversion as a head start, not a migration.

## Next

→ [Soft Support Modules](soft-support-modules.md) — the modules almost every IOC loads.
