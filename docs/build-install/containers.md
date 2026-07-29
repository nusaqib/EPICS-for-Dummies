# Containers

The modern alternative to everything else in this section. Instead of building Base and modules on each host, you consume or build **images** in which an IOC's Base version, modules, libraries and startup script are versioned together.

Overview and the trade-offs: [Toolbox → epics-containers](../toolbox/deployment-and-operations.md#epics-containers).

| | |
| --- | --- |
| Documentation | [epics-containers.github.io](https://epics-containers.github.io/) |
| Source | [github.com/epics-containers](https://github.com/epics-containers) |
| Origin | Diamond Light Source; multi-facility adoption |

!!! tip "Start with the upstream tutorials"
    epics-containers has a genuinely good tutorial sequence that takes you from `docker run` to a Kubernetes-deployed IOC. Follow that rather than a summary here — this page exists to tell you what you're getting into and what the EPICS-specific pitfalls are.

## Why bother

| Problem | What containers do about it |
| --- | --- |
| "Which module versions is this IOC built against?" | The image tag is the complete answer |
| "Can we rebuild the IOC from three years ago?" | `docker pull` |
| Two IOCs need different asyn versions | They're different images. No conflict exists. |
| 300 IOCs to deploy and track | Kubernetes handles restart, scheduling, health, inventory |
| "It works on my machine" | The image you tested is the image that runs |
| A support module upgrade breaks four IOCs | Upgrade one image at a time; roll back by tag |

The reproducibility argument is the strong one. A traditional `/opt/epics` accumulates undocumented modifications, and nobody can reconstruct what an IOC was built against. An image tag cannot drift.

## The critical EPICS-specific caveat

!!! danger "IOC containers need host networking"
    Channel Access and PV Access discovery uses **UDP broadcast**. Docker's default bridge network does NAT, which means:

    - outbound searches from a container work;
    - **inbound searches and beacons do not reach it.**

    An IOC in a default-bridge container is effectively invisible on the network — it starts cleanly, logs nothing wrong, and no client can find it.

    ```bash
    docker run --network host ...          # IOC containers
    ```

    In Kubernetes, `hostNetwork: true` on IOC pods. This is what epics-containers does, and it's why IOC pods are scheduled deliberately rather than freely.

Clients in containers are easier: they can use bridge networking with an explicit `EPICS_CA_ADDR_LIST` of unicast IOC or gateway addresses, since only the outbound direction matters. See [Networking](../architecture/networking.md#containers-vms-and-clouds).

## The pieces

### Container images

epics-containers publishes layered base images — an EPICS Base layer, then support-module layers, then your IOC. Building an IOC image means writing a short Dockerfile that starts from a suitable base and adds your `st.cmd` and databases.

Two build stages is the usual pattern: a *developer* image with compilers and sources, and a slim *runtime* image containing only what the IOC needs. The runtime image is what you deploy.

### ibek

**IOC Builder for EPICS and Kubernetes** — [github.com/epics-containers/ibek](https://github.com/epics-containers/ibek)

Generates `st.cmd` and databases from a YAML description:

```yaml
ioc_name: bl07-mo-ioc-01
description: BL07 sample stage motion
entities:
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

Support modules ship YAML *definitions* of what they can instantiate; `ibek` composes them and validates against those schemas. The gain: an IOC's definition becomes a reviewable, diffable, **validated** document instead of a shell script, and typos are caught at build time rather than at `iocInit`.

### PVI

**Process Variable Interface** — [github.com/epics-containers/pvi](https://github.com/epics-containers/pvi)

Describes a device's PV interface once, then generates the database template, the [operator screen](../toolbox/operator-interfaces.md), the documentation, and the [ophyd](../toolbox/scientific-data.md#ophyd-and-ophyd-async) device class. Attacks the duplication that otherwise has you writing the same device structure by hand in four places, and drifting in all four.

## What it costs

Be honest with yourself about this before committing a facility to it:

- **A container registry**, with retention and access control.
- **Kubernetes**, or a deliberate decision to use plain podman/docker on hosts. Kubernetes is where the deployment benefits are, and it is a substantial operational skill in itself.
- **A new mental model** for a team used to `ssh` and `make`. Getting to a running IOC involves more indirection, and debugging spans more layers.
- **Host networking**, which removes some of Kubernetes' network isolation for exactly the pods you most want to schedule freely.
- **Buy-in.** A half-adopted container strategy — some IOCs containerised, some not — means maintaining two deployment models, which is worse than either alone.

## Simpler container use, without Kubernetes

You don't have to take the whole thing. Useful intermediate points:

```bash
# A development environment with Base and modules already built
docker run -it --network host ghcr.io/epics-containers/<image>:<tag> bash

# Run an IOC from an image on a plain host, managed by systemd + podman
podman run --network host --name vac-sr-c05 <image>:<tag>
```

Container images as a **build and distribution** mechanism, with plain systemd running them on ordinary hosts, gets you most of the reproducibility benefit with none of the Kubernetes learning curve. Several facilities sit exactly here, deliberately.

## For learning EPICS

Containers are excellent for getting a working environment fast:

- Base and common modules already built — no [build chapter](epics-base.md) required.
- Throw it away and start again freely.
- Reproduce someone else's problem exactly.

They're less good as a *first* exposure, because you learn the container tooling instead of the EPICS build system, and you'll need the latter eventually. Suggested order: build Base by hand once, write [your first IOC](first-ioc.md), then use containers freely.

## Verify a containerised IOC

1. `docker run --network host` your IOC image.
2. `caget` one of its PVs **from another host**. This is the test that matters — inside the container it will work even when networking is misconfigured.
3. `cainfo <pv>` and check the reported server address is the host's, not a container-internal address.
4. Restart the container and confirm [autosave](../toolbox/soft-support-modules.md#autosave) restored settings — which requires the autosave directory to be a **persistent volume**, not container-local storage. A containerised IOC whose autosave files vanish on restart is a common and quiet mistake.
5. Confirm you can get to the IOC shell (`docker attach`, `kubectl exec`) for `dbpr` and `casr`.

Points 4 and 5 are the two that catch people moving IOCs into containers: persistent state and console access both need deliberate arrangement, and both are things the traditional deployment gave you for free.

## Next

→ [The Example Facility](../example-facility/index.md) — all of this assembled for a whole synchrotron.
