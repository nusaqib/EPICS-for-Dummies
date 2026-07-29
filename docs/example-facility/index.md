# The Helios Light Source

A hypothetical 3 GeV, 4th-generation synchrotron light source, with its EPICS control system designed end to end.

!!! warning "Helios is fictional"
    HLS does not exist. Its parameters are plausible and internally consistent — chosen in the spirit of published 4th-generation light source design reports — but every number here is a teaching device.

    **Do not treat any value on these pages as a design value**, and do not treat any page here as safety guidance. Where these pages discuss machine or personnel protection, the point being made is [where EPICS stops](machine-protection.md).

## Why invent a facility

"You need a naming convention" teaches nothing. Watching a naming convention get *chosen* — with the 60-character Channel Access limit pressing on it, with third-party modules appending suffixes you don't control, with a compromise for the machine protection system — teaches a lot.

So this section takes every architectural claim made elsewhere in this guide and forces it to survive contact with a concrete machine: 415 000 process variables, 330 IOCs, twenty beamlines, and an operations team who will be woken at 03:00 by whatever you get wrong.

## The machine, in one table

| | |
| --- | --- |
| Type | 4th-generation storage ring light source |
| Energy | 3.0 GeV |
| Circumference | 528 m |
| Lattice | 20 × seven-bend achromat (MBA) |
| Horizontal emittance | 100 pm·rad |
| Stored current | 500 mA, top-up every ~120 s |
| RF | 500 MHz, two main cavities, passive 3rd-harmonic bunch lengthening |
| Injector | 150 MeV linac → 3 GeV booster (concentric, same tunnel) |
| Insertion devices | 15 |
| Beamlines | 20 (15 ID, 5 bending magnet) at full build-out |

Full parameter set: [Machine Parameters](machine-parameters.md).

## The control system, in one table

| | |
| --- | --- |
| Process variables | ≈ 415 000 |
| IOCs | ≈ 330 |
| Network zones | 6 |
| Archived PVs | ≈ 290 000, ≈ 24 TB/year at full resolution |
| Alarm-configured PVs | ≈ 9 000, target < 10 annunciated alarms/hour |
| EPICS Base | 7.0.x, both CA and PVA served |
| IOC deployment | Container images, Kubernetes with host networking |
| Screens | Phoebus, with DBWR for browser access |

## The chapters

Read in order the first time — each builds on the last.

| Chapter | The question it answers |
| --- | --- |
| **[Machine Parameters](machine-parameters.md)** | What is this machine, physically? |
| **[Subsystems](subsystems.md)** | What has to be controlled, and how fast? |
| **[Naming Convention](naming-convention.md)** | What is every PV called, and why that scheme? |
| **[IOC Inventory](ioc-inventory.md)** | 330 IOCs — which, where, and why drawn that way? |
| **[Network Design](network-design.md)** | Six zones, five gateways: what crosses which boundary? |
| **[Service Deployment](services-deployment.md)** | Where do the archiver, alarms and directory actually run? |
| **[Operator Interfaces](operator-interfaces.md)** | What does an operator actually look at? |
| **[Archiving Plan](archiving-plan.md)** | Where does 24 TB/year come from, term by term? |
| **[Alarm Plan](alarm-plan.md)** | How do 9 000 alarms stay under ten per hour? |
| **[Machine Protection](machine-protection.md)** | Where does EPICS stop, and why is that line absolute? |
| **[A Beamline](beamline.md)** | BL07 in full: optics, detector, data, and its own IOCs |
| **[Operations Scenarios](operations-scenarios.md)** | Startup, a 03:00 beam dump, a maintenance day |
| **[Build a Mini-HLS](build-a-mini-hls.md)** | Run a shrunken version of all of it on your laptop |

## The design decisions, summarised

If you read nothing else, these are the choices the chapters argue for:

**Location first in the PV name.** `SR-C05-PS-QF-01:Current-RB` — section, then area, then device class. Because "everything in cell 5" is the most common operational query, and because gateway rules, archiver policies, alarm hierarchy and access-security groups are all written as name patterns. [Why](../architecture/naming-conventions.md#why-location-comes-first)

**Fine-grained IOCs.** One per device group or crate, ~330 of them, not 20 large ones. Failure domains stay small and restarts stay cheap, which is affordable only because deployment is containerised. [Why](ioc-inventory.md#the-granularity-decision)

**Six network zones, and the office boundary is read-only by topology.** Not by configuration, and not by access-security rules — by there being no path that can carry a write. [Why](network-design.md)

**Monitor-based archiving with deliberate deadbands, set when records are created.** Because `ADEL` lives in the IOC, and retrofitting it across a facility is much harder than thinking about it up front. [Why](archiving-plan.md#the-decision-that-dominates-everything)

**A three-level alarm hierarchy with delays on consequential alarms.** So a beam dump produces one alarm at the top and a findable first cause underneath, instead of four thousand simultaneous red rectangles. [Why](alarm-plan.md#designing-for-the-flood)

**Protection systems are outside EPICS entirely.** Certified PLCs and hard-wired logic; EPICS reads their status and cannot influence it. [Why](machine-protection.md)

**Detector data never crosses Channel Access.** Its own network, its own path to storage. EPICS controls the detector and supplies the metadata. [Why](beamline.md#the-data-path)

## Next

→ [Machine Parameters](machine-parameters.md)
