# Deployment and Operations

How you get from "an IOC works on my machine" to "300 IOCs run reliably and anyone can rebuild any of them". This is the most site-specific area in EPICS, and historically the least standardised — every facility built its own answer. That's changing.

## The problem

EPICS has no package manager, no dependency resolver, and no deployment standard. What it has instead:

- Base at some version, plus 5–30 support modules at their own versions, mutually compatible only by testing.
- `configure/RELEASE` files naming absolute paths to every module.
- A per-IOC `st.cmd` combining paths, macros, and startup order.
- Anywhere from one to several thousand IOCs, across Linux servers, embedded boards, and RTOS targets.

Which produces the recognisable failure state: nobody is sure what version is running where, nobody can rebuild a five-year-old IOC, and one server's `/opt/epics` has accumulated modifications nobody documented.

## procServ

**Give an IOC a supervisor and a console.**

| | |
| --- | --- |
| Source | [github.com/ralphlange/procServ](https://github.com/ralphlange/procServ) |
| Author | Ralph Lange |

Runs a process in the background, exposes its console on a telnet port, restarts it if it dies, and logs everything.

```bash
procServ -n "vac-sr-c05" -L /var/log/ioc/vac-sr-c05.log \
         --allow --autorestart 20105 /opt/epics/ioc/vac-sr-c05/st.cmd
```

```bash
telnet localhost 20105     # you now have the epics> prompt
# Ctrl-] then "quit" to detach WITHOUT killing the IOC
```

!!! danger "Ctrl-C in a procServ session stops the IOC"
    Detach with `Ctrl-]` then `quit`. `Ctrl-C` sends an interrupt to the IOC process. On a live machine, this is a memorable mistake.

Why it's near-universal: an IOC's console is where you run `dbpr`, `casr` and `dbl` — the diagnostics that matter — and a bare `systemd` service gives you no way in. Many sites now run procServ *under* systemd, getting boot-time startup from one and console access from the other.

Companion: `procServControl` and the `caproto`/`procServ` PV interfaces let you restart IOCs from a screen, which is either convenient or terrifying depending on your access controls.

## epics-containers

**The most significant recent change in how EPICS gets deployed.**

| | |
| --- | --- |
| Documentation | [epics-containers.github.io](https://epics-containers.github.io/) |
| Source | [github.com/epics-containers](https://github.com/epics-containers) |
| Origin | Diamond Light Source, with growing multi-facility adoption |

The proposition: an IOC is a container image. Its Base version, its modules, its libraries and its `st.cmd` are all inside, versioned together, built in CI, and deployed to Kubernetes (or podman/docker on a plain host).

What that solves:

- **Reproducibility.** An image tag *is* the complete definition. Rebuilding a two-year-old IOC exactly is `docker pull`.
- **No dependency hell.** Two IOCs needing different asyn versions coexist without argument.
- **Deployment is orchestration.** Kubernetes handles restart, scheduling, health checks, rolling updates and inventory. Three hundred IOCs become a manageable inventory rather than three hundred servers with histories.
- **Development matches production.** The image you tested is the image that runs.

What it costs: a container registry, a Kubernetes cluster (or a decision not to use one), and a genuinely new operating model for a team used to `ssh` and `make`. The networking caveat matters — IOC containers need **host networking** for CA/PVA broadcast discovery to work; see [Networking](../architecture/networking.md#containers-vms-and-clouds).

The ecosystem includes:

### ibek

**IOC Builder for EPICS and Kubernetes** — [github.com/epics-containers/ibek](https://github.com/epics-containers/ibek)

Generates `st.cmd` and databases from a YAML description of what the IOC contains:

```yaml
ioc_name: bl07-mo-ioc-01
description: BL07 sample stage motion
entities:
  - type: epics.EpicsCaMaxArrayBytes
    max_bytes: 6000000
  - type: pmac.Geobrick
    P: BL07-MO-BRICK-01
    PORT: BRICK1
    IP: 172.23.7.10
  - type: pmac.dls_pmac_asyn_motor
    Controller: BRICK1
    P: BL07-MO-STAGE-01
    M: ":X"
    ADDR: 1
    DESC: Sample X
```

The support modules ship YAML *definitions* describing what they can instantiate, and `ibek` composes them. The point is that the IOC's definition becomes a reviewable, validated, diffable document rather than a shell script — and generating it means it can also generate screens and documentation from the same source.

### PVI

**Process Variable Interface** — [github.com/epics-containers/pvi](https://github.com/epics-containers/pvi)

Describes a device's PV interface once, then generates the database template, the operator screen, the documentation, and the [ophyd](scientific-data.md#ophyd-and-ophyd-async) device class from it. Attacks the duplication problem directly: the same device structure otherwise gets written out by hand in four places and drifts in all four.

## e3 (ESS EPICS Environment)

| | |
| --- | --- |
| Documentation | [e3pages.readthedocs.io](https://e3pages.readthedocs.io/en/latest/) |
| Source | [github.com/icshwi/e3](https://github.com/icshwi/e3) |
| Origin | European Spallation Source |

A different, equally coherent answer, descended from PSI's approach: build every module as a **loadable module** with its version in its name, and load them into a generic IOC executable at runtime.

```text
require asyn,4.42.0
require StreamDevice,2.8.20
iocshLoad("$(StreamDevice_DIR)/myDevice.iocsh", "P=SR-C05-VA")
```

No per-IOC compilation. No `configure/RELEASE`. Multiple versions of a module installed side by side, and an IOC declares which it wants. `iocsh` snippets shipped by modules replace hand-written `st.cmd` fragments.

Very effective, and adopted beyond ESS. The trade-off against containers: e3 is a lighter operational change (no Kubernetes) and keeps a shared environment on the host, so IOCs are not as fully isolated.

## synApps

| | |
| --- | --- |
| Home | [github.com/EPICS-synApps](https://github.com/EPICS-synApps) |
| Origin | APS / BCDA |

A **curated, mutually tested collection** of support modules — asyn, autosave, calc, motor, sscan, busy, std, stream, areaDetector, iocStats, and dozens more — released together as a set with known-compatible versions.

The problem it solves is real and boring: "which version of motor works with which version of asyn and which version of Base?" has no general answer, and synApps provides *an* answer, tested. For anyone building a beamline IOC from scratch, starting from synApps saves days of version archaeology.

## Distribution packages

| Route | Notes |
| --- | --- |
| **[epicsdeb](https://github.com/epicsdeb)** | Debian/Ubuntu packages of Base and many modules. `apt install epics-dev`. Convenient; module coverage is partial and lags upstream. |
| **conda-forge** | `conda install -c conda-forge epics-base`. Strong for Python-centric work; `epicscorelibs` makes pip-installable Python bindings possible. |
| **PSI / facility repositories** | Several facilities publish their module builds. Useful, and usually assumes their conventions. |
| **Homebrew** | Community formulae for macOS. Varies. |

Good for learning, for client machines, and for soft IOCs with modest dependencies. Less good for production IOCs needing a specific module set, where you want the version pinned by *you* rather than by a distribution's release cycle.

## Configuration management

The traditional answer, and still what most facilities run:

| Tool | Use |
| --- | --- |
| **Ansible** | Most common in the EPICS community. Agentless, readable, good for "install these modules, deploy these IOCs, write these config files". |
| **Puppet / Salt / Chef** | All in use somewhere. |
| **git + a deploy script** | Entirely respectable at small scale, provided the script is in git too. |

Whatever the tool, the requirements are the same:

1. Any IOC host can be rebuilt from scratch without tribal knowledge.
2. Every configuration file — including `.acf`, gateway `pvlist`, archiver policies, alarm configuration — comes from version control.
3. What is deployed can be *verified* against what is in git, and drift is detected rather than assumed absent.

Point 3 is the one that's usually missing. "It's all in git" is a claim about the repository, not about the servers.

## Standardising a site

If you're building this from nothing, the decisions that matter:

**Where does software live?** `/opt/epics/base-7.0.9`, `/opt/epics/modules/<name>/<version>`, `/opt/epics/ioc/<iocname>`. Versioned paths, never a bare `base` symlink that someone repoints on a Tuesday.

**How is the environment set?** One site script or environment module. Never per-user `.bashrc` archaeology.

**How are IOCs started?** systemd + procServ, or Kubernetes. Pick one and apply it everywhere; a facility with three mechanisms has three mechanisms to debug at 03:00.

**What's the naming scheme for IOCs?** Related to but distinct from [PV naming](../architecture/naming-conventions.md). The IOC name appears in [iocStats](soft-support-modules.md#iocstats-and-deviocstats) PVs, [ChannelFinder](directory-services.md) properties, log files, and procServ ports, so make it systematic — including a port-allocation scheme, because ad-hoc procServ ports collide eventually.

**Who may deploy?** And is there a change window for IOCs serving operating subsystems? This is a policy question that will be answered by default if you don't answer it deliberately.

**How is a rollback done?** If the answer isn't obvious and fast, deployments will be feared and therefore batched, which makes each one riskier. Container tags and e3 versioning both make rollback trivial, which is a large part of their value.

## Operational practices

**Every IOC runs [iocStats](soft-support-modules.md#iocstats-and-deviocstats).** Alarmed on heartbeat loss and uptime reset. Non-negotiable at any scale above a handful.

**Every IOC's console is reachable.** procServ port or `kubectl exec`, documented, with the port allocation in a table somebody maintains.

**Every IOC's logs go somewhere central.** See [Logbooks](logbooks.md#ioc-and-infrastructure-logging).

**Every IOC's [autosave](soft-support-modules.md#autosave) directory is writable and backed up.** Check after every deployment; a read-only autosave directory fails silently.

**Restarts are boring.** Autosave configured, `PINI` set where needed, hardware holding state across the gap. If restarting an IOC is frightening, it will be avoided and problems will accumulate.

**An inventory exists.** Which IOCs, on which hosts, serving which subsystems, at which versions, with which console ports. Generated from reality ([recsync](directory-services.md#recsync) + iocStats) rather than maintained by hand.

## Choosing an approach

| Situation | Suggestion |
| --- | --- |
| Learning, or one test stand | Build Base and modules by hand, `softIoc` or a simple app, start it with procServ. Understand the machinery before automating it. |
| One beamline, small team | [synApps](#synapps) + Ansible + procServ. Boring, well-trodden, entirely adequate. |
| A facility, greenfield | Seriously evaluate [epics-containers](#epics-containers). It is where the community's effort is going, and it solves the reproducibility problem properly. |
| A facility with an established `/opt/epics` and hundreds of IOCs | [e3](#e3-ess-epics-environment)-style versioned modules is a smaller step than containerisation, and gets you most of the reproducibility benefit. |
| Your facility already has a standard | **Use it.** Being the one person with a different deployment model means being the only person who can fix your IOCs. |

## Next

→ [Observability](observability.md)
