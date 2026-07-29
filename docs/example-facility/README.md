# Example Facility — The Helios Light Source

> This file is the overview for people browsing this folder on GitHub. The same material is the site's landing page in [`index.md`](index.md); if you're reading the built site, start there.

A hypothetical 3 GeV, 4th-generation synchrotron light source, with its EPICS control system designed end to end.

## Why a fictional facility

"You need a naming convention" teaches nothing. Watching one get *chosen* — with the 60-character Channel Access limit pressing on it, with areaDetector appending suffixes you don't control, with a compromise forced by the machine protection system — teaches a lot.

So this section takes every architectural claim made elsewhere in the guide and forces it to survive contact with a concrete machine: 415 000 process variables, 330 IOCs, twenty beamlines, and an operations team who will be woken at 03:00 by whatever you got wrong.

> [!WARNING]
> **Helios does not exist.** Its parameters are plausible and internally consistent — chosen in the spirit of published 4th-generation light source design reports — but every number here is a teaching device.
>
> Do not treat any value on these pages as a design value, and do not treat any page here as safety guidance. Where these pages discuss machine or personnel protection, the point being made is [where EPICS stops](machine-protection.md).

## The machine

| | |
| --- | --- |
| Type | 4th-generation storage ring light source |
| Energy | 3.0 GeV |
| Circumference | 528 m |
| Lattice | 20 × seven-bend achromat (MBA) |
| Horizontal emittance | 100 pm·rad |
| Stored current | 500 mA, top-up every ~120 s |
| RF | 500 MHz, two main cavities, passive 3rd-harmonic bunch lengthening |
| Injector | 150 MeV linac → 3 GeV booster, concentric in the same tunnel |
| Insertion devices | 15 |
| Beamlines | 20 (15 ID, 5 bending magnet) at full build-out |

## The control system

| | |
| --- | --- |
| Process variables | ≈ 415 000 |
| IOCs | ≈ 330 |
| Network zones | 6, joined by 4 gateways |
| Archived PVs | ≈ 290 000, ≈ 24 TB/year at full resolution |
| Alarm-configured PVs | ≈ 9 000, target < 10 annunciated alarms/hour |
| EPICS Base | 7.0.x, serving both CA and PVA |
| IOC deployment | Container images, Kubernetes with host networking |
| Screens | Phoebus, with DBWR for browser access |

## The chapters

Read in order the first time — each builds on the last.

| # | Chapter | The question it answers |
| --- | --- | --- |
| — | [`index.md`](index.md) | Site landing page for this section |
| 1 | [`machine-parameters.md`](machine-parameters.md) | What is this machine, physically? |
| 2 | [`subsystems.md`](subsystems.md) | What has to be controlled, how fast, and **which layer owns it**? |
| 3 | [`naming-convention.md`](naming-convention.md) | What is every PV called, and why that scheme? |
| 4 | [`ioc-inventory.md`](ioc-inventory.md) | 330 IOCs and 415 000 PVs — which, where, and why drawn that way? |
| 5 | [`network-design.md`](network-design.md) | Six zones, four gateways: what crosses which boundary? |
| 6 | [`services-deployment.md`](services-deployment.md) | Where do the archiver, alarms and directory run — and what breaks when each dies? |
| 7 | [`operator-interfaces.md`](operator-interfaces.md) | What does an operator actually look at? |
| 8 | [`archiving-plan.md`](archiving-plan.md) | Where does 24 TB/year come from, term by term? |
| 9 | [`alarm-plan.md`](alarm-plan.md) | How do 9 000 alarms stay under ten per hour? |
| 10 | [`machine-protection.md`](machine-protection.md) | Where does EPICS stop, and why is that line absolute? |
| 11 | [`beamline.md`](beamline.md) | BL07 in full: optics, detector, data path, its own IOCs |
| 12 | [`operations-scenarios.md`](operations-scenarios.md) | Startup, a 03:00 beam dump, an IOC dying, a maintenance day |
| 13 | [`build-a-mini-hls.md`](build-a-mini-hls.md) | Run a shrunken version of all of it on your laptop |

## The design decisions, summarised

If you read nothing else in this folder, these are the choices the chapters argue for:

**Location first in the PV name.** `SR-C05-PS-QF-01:Current-RB` — section, then area, then device class. Because "everything in cell 5" is the most common operational query, and because gateway rules, archiver policies, alarm hierarchy and access-security groups are *all* written as name patterns. Your name structure is your policy structure. → [naming-convention.md](naming-convention.md)

**Fine-grained IOCs.** One per device group or crate — 330 of them, not 20 large ones. Failure domains stay small and restarts stay cheap, which is only affordable because deployment is containerised. Draw IOC boundaries where you are willing to lose everything inside them at once. → [ioc-inventory.md](ioc-inventory.md)

**The office boundary is read-only by topology.** Not by configuration, not by access-security rules — by there being no path that can carry a write. Channel Access has no authentication, so a self-declared user name is not a boundary; a gateway that cannot forward a write is. → [network-design.md](network-design.md)

**Monitor-based archiving with deadbands set when records are created.** `ADEL` lives in the IOC, so you cannot fix a badly-behaved archived PV from the archiver side. This one choice is the difference between 24 TB/year and 116 TB/year. → [archiving-plan.md](archiving-plan.md)

**A three-level alarm hierarchy with delays separating causes from consequences.** Causes at 0 s, consequences at 5 s. A beam dump then produces two alarms and a findable first cause, instead of four thousand simultaneous red rectangles. → [alarm-plan.md](alarm-plan.md)

**Protection systems are outside EPICS entirely.** Certified PLCs and hard-wired logic; EPICS reads their status and cannot influence it. The line is drawn on a principle, not case by case, because any process that evaluates exceptions individually will eventually approve one. → [machine-protection.md](machine-protection.md)

**Detector data never crosses Channel Access.** Its own network, its own path to storage. EPICS controls the detector and supplies the metadata that travels with the frames. → [beamline.md](beamline.md)

## Keeping this section consistent

The numbers here are cross-referenced between chapters: device counts in [`machine-parameters.md`](machine-parameters.md) drive the PV and IOC counts in [`ioc-inventory.md`](ioc-inventory.md), which drive the storage arithmetic in [`archiving-plan.md`](archiving-plan.md) and the zone sizing in [`network-design.md`](network-design.md).

If you change a number on one page, grep for it and fix the others — see the ground rules in [`CONTRIBUTING.md`](../../CONTRIBUTING.md).
