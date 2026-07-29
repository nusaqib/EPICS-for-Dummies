# IOC and PV Inventory

330 IOCs and 415 000 process variables. This chapter shows where they come from and why the boundaries are drawn where they are.

## The granularity decision

The recurring argument, decided here: **one IOC per device group or per crate**, biased fine-grained.

| | Fine-grained (chosen) | Coarse-grained |
| --- | --- | --- |
| Failure domain | One device group | A whole subsystem |
| Restart cost | Seconds, one device group offline | Disruptive, subsystem-wide |
| Ownership | Obvious | Shared, therefore nobody's |
| Cross-device logic | CA links — asynchronous, can disconnect | DB links — synchronous, guaranteed ordering |
| Process count | 330 to deploy and monitor | ~30 |
| Database size | Small, comprehensible | Large; wide [lock sets](../architecture/process-database.md#lock-sets-the-thing-that-eventually-bites-you) |

**The rule applied: draw IOC boundaries where you are willing to lose everything inside them at once.**

Fine-grained is only affordable because deployment is [containerised](../build-install/containers.md) — 330 processes is an inventory problem, and inventory problems are solved by tooling. In 2005 this decision would have gone the other way, and many operating facilities still live with coarse IOCs decided under exactly that constraint.

**Where fine-grained was overridden:** records that must interlock reliably live in one IOC. Cell 5's vacuum gauges, its ion pumps and its valve-status readbacks are one IOC, because the summary logic that drives the cell's vacuum-OK indication must be synchronous and must not depend on a CA link staying connected. Splitting them per-device would have been dogma winning over engineering.

## IOC inventory

### Accelerator — 210 IOCs

| Group | Count | Scope of one IOC |
| --- | --- | --- |
| Linac and gun | 12 | Gun, 2 modulators, 3 RF, 2 magnet, 2 vacuum, 2 diagnostics |
| LTB transfer line | 4 | Magnets, vacuum, diagnostics, screens |
| Booster | 20 | 4 magnet PS, 2 RF, 4 vacuum, 6 diagnostics, 2 kickers, 2 timing |
| BTS transfer line | 4 | As LTB |
| SR magnet supplies | 40 | Two per cell — one for quads/sextupoles, one for correctors |
| SR vacuum | 20 | One per cell: gauges, ion pumps, turbos, valve status |
| SR diagnostics | 26 | One BPM/loss IOC per cell (20), plus 6 central (DCCT, tune, streak, bunch-by-bunch) |
| SR RF | 6 | 2 cavity/LLRF, 2 SSA, 1 harmonic cavities, 1 supervisory |
| Insertion devices | 15 | One per ID: motion, cryogenics, feed-forward |
| Front ends | 20 | One per beamline front end: slits, XBPM, shutter status, vacuum |
| Timing | 4 | EVG, event distribution, timestamp diagnostics |
| Fast orbit feedback | 4 | Configuration and diagnostics interface to the FPGA system |
| MPS / PPS / radiation interface | 6 | **Read-only** status from the protection systems |
| Cryogenics and utilities | 14 | Water circuits, HVAC, LN₂, He plant — mostly OPC UA to PLCs |
| Machine-wide soft IOCs | 15 | Orbit aggregation, unit conversion, mode logic, summaries, physics support |
| **Subtotal** | **210** | |

### Beamlines — 100 IOCs

Five per beamline, at full build-out (20 beamlines):

| Per-beamline IOC | Scope |
| --- | --- |
| Optics motion | Monochromator, mirrors, slits — [motor](../toolbox/motion.md) plus pseudo-motors |
| Optics services | Beamline vacuum, cooling, filters, attenuators |
| End-station motion | Sample stages, diffractometer, positioners |
| Detector | [areaDetector](../toolbox/detectors-and-imaging.md) — one per primary detector |
| Sample environment | Cryostreams, furnaces, gas rigs, whatever the science needs |

### Central and infrastructure — 20 IOCs

| Group | Count | Scope |
| --- | --- | --- |
| Network and PDU monitoring | 4 | [SNMP](../toolbox/soft-support-modules.md#other-soft-modules-worth-knowing) to switches, PDUs |
| UPS monitoring | 2 | |
| Environmental | 2 | Rack and gallery temperature, humidity |
| Facility summary / aggregation | 6 | Machine mode, facility-wide summaries, [status for beamlines](network-design.md) |
| Site and weather | 1 | Yes, really — ground temperature correlates with orbit drift |
| Test stands | 5 | Magnet, RF, vacuum and detector test stands, plus a full simulation IOC set |
| **Subtotal** | **20** | |

### **Total: 330 IOCs**

## PV inventory

### Accelerator — 265 000 PVs

| Subsystem | Devices | PVs each | Total |
| --- | --- | --- | --- |
| Magnet power supplies | ≈900 supplies | ≈80 | 71 000 |
| Vacuum | 600 devices | ≈40 | 24 000 |
| Diagnostics | 180 BPMs @150, 120 BLMs @30, other | — | 40 600 |
| RF | — | — | 12 000 |
| Insertion devices | 15 | ≈800 | 12 000 |
| Front ends | 20 | ≈400 | 8 000 |
| Timing | 60 EVRs + EVG | — | 6 000 |
| Fast orbit feedback | — | — | 8 000 |
| MPS / PPS / radiation status | — | — | 12 000 |
| Cryogenics and utilities | — | — | 25 000 |
| Linac, booster, transfer lines | — | — | 30 000 |
| IOC health and soft/aggregation PVs | 210 IOCs | — | 16 400 |
| **Subtotal** | | | **265 000** |

### Beamlines — 130 000 PVs

20 beamlines × ≈6 500 PVs each. A detector IOC alone contributes 2 000–4 000 (areaDetector's plugin chain is PV-rich), motion another 1 500, and the rest is optics, vacuum and sample environment. See [the beamline chapter](beamline.md).

### Central and infrastructure — 20 000 PVs

Network gear, PDUs, UPSs, environmental, facility summaries, gateway statistics, test stands.

### **Total: 415 000 PVs**

## What the numbers imply

**Magnet supplies are the largest single block.** 71 000 PVs, 17% of the facility, from ≈900 devices. That is what "80 PVs per power supply" looks like at scale — setpoint, readback, limits, status bits, interlock reflections, temperatures, firmware version, statistics. The lesson: a per-device PV count you consider reasonable, multiplied by device count, is the number that determines your archiver sizing and your naming budget. Decide it deliberately.

**Two hundred and ten accelerator IOCs need generated configuration.** Nobody hand-writes 40 magnet IOCs. Each is instantiated from a [template plus substitutions](../architecture/process-database.md#templates-and-substitutions) generated from the device database, and its [`st.cmd` is generated by ibek](../toolbox/deployment-and-operations.md#ibek) from a YAML description. The per-cell IOCs differ only in their cell number and their device list.

**Sixteen thousand IOC-health PVs justify their own tooling.** 210 IOCs × ~60 [iocStats](../toolbox/soft-support-modules.md#iocstats--deviocstats) PVs is not noise — it's the data behind [the control-system health dashboard](../toolbox/observability.md), and it gets its own branch in the [alarm tree](alarm-plan.md).

## Host allocation

330 IOCs do not mean 330 machines.

| Tier | Hosts | What runs there |
| --- | --- | --- |
| **Accelerator IOC servers** | 12 | Most of the 210 accelerator IOCs, as containers with host networking |
| **Embedded / crate controllers** | ~35 | MTCA and VME controllers for diagnostics, timing and fast systems — where hardware forces locality |
| **Beamline IOC servers** | 20 | One per beamline, hosting its 5 IOCs |
| **Detector servers** | 20 | One per beamline, on the [detector network](network-design.md), sized for data rate |
| **Central services** | See [service deployment](services-deployment.md) | |

Soft IOCs are packed onto shared servers; hard IOCs live where the hardware is. The split follows a simple rule: **an IOC runs as close to its hardware as the bus requires, and no closer.** A serial device reached through a serial-to-Ethernet converter needs no locality at all, which is why most HLS IOCs are soft IOCs in a rack room.

## Naming IOCs

Distinct from [PV naming](naming-convention.md), and it matters because the IOC name appears in iocStats PVs, ChannelFinder properties, log files, container names and procServ ports.

```text
<sec>-<area>-<class>-ioc-<nn>

sr-c05-va-ioc-01        cell 5 vacuum
sr-c05-ps-ioc-01        cell 5 quad/sextupole supplies
sr-c05-ps-ioc-02        cell 5 correctors
sr-s07-id-ioc-01        straight 7 insertion device
bl07-op-ioc-01          beamline 7 optics motion
hls-cf-sum-ioc-01       facility summaries
```

Lower case, because these are hostnames, container names and log filenames. Console ports are allocated systematically from a documented table — ad-hoc [procServ](../toolbox/deployment-and-operations.md#procserv) ports collide eventually, and the collision appears as an IOC that mysteriously won't start.

## Keeping the inventory honest

**Generated, not maintained.** [recsync](../toolbox/directory-services.md#recsync) reports every IOC's record list into [ChannelFinder](../toolbox/directory-services.md); iocStats reports its health. The inventory *is* a ChannelFinder query, so it cannot drift from reality.

A hand-maintained IOC list is wrong within a month, and its wrongness is invisible — which is worse than having no list, because people trust it.

## Next

→ [Network Design](network-design.md)
