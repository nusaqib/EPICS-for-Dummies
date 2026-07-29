# EPICS for Dummies

> **EPICS** → **E**xperimental **P**hysics and **I**ndustrial **C**ontrol **S**ystem

A documentation-only guide to the EPICS ecosystem: **what every tool is, why it exists, where to get it, and how a real facility wires them together.**

If you already know EPICS, [the official intro](https://docs.epics-controls.org/en/latest/guides/EPICS_Intro.html) is probably where you want to be. If you read that page and thought *"okay, but what do I actually install, and in what order?"* — you're in the right place.

📖 **Read it as a website:** <https://nusaqib.github.io/EPICS-for-Dummies/>

---

## What this is

EPICS is not one program. It is a collaboration-maintained *ecosystem* of a couple of hundred separately released pieces — a core library, dozens of device-support modules, half a dozen GUI toolkits, several archivers, alarm servers, directory services, gateways, and client libraries in six languages. Nobody hands you the list. Every facility rediscovers it.

This repo is that list, organised so you can find your way:

| If you… | Go to |
| --- | --- |
| have never heard of a "process variable" | [Start Here](docs/start-here/index.md) |
| want to understand how the pieces fit | [Architecture](docs/architecture/index.md) |
| are looking for *the tool that does X* | [The Toolbox](docs/toolbox/index.md) — the catalogue |
| need to get software running on a box | [Build & Install](docs/build-install/index.md) |
| want to see a whole facility designed end-to-end | [Example Facility](docs/example-facility/index.md) |
| need a command, a record field, an env var | [Reference](docs/reference/cheatsheet.md) |

There is **no code in this repository** — no install scripts, no IOC templates. Everything here points at upstream projects maintained by people who know their own software better than a shell script in a beginner's guide ever will. Commands appear inline in the how-to pages so you can read them before you run them.

## The worked example

Abstract architecture diagrams only get you so far. So this guide designs a complete, fictional facility and shows every decision:

**🔬 The Helios Light Source (HLS)** — a hypothetical 3 GeV, 4th-generation synchrotron light source with a linac, a booster, a 528 m storage ring, and 20 beamlines.

The [Example Facility](docs/example-facility/index.md) section works through its [machine parameters](docs/example-facility/machine-parameters.md), [PV naming convention](docs/example-facility/naming-convention.md), [~330 IOCs](docs/example-facility/ioc-inventory.md), [network segmentation](docs/example-facility/network-design.md), [service deployment](docs/example-facility/services-deployment.md), [archiver sizing arithmetic](docs/example-facility/archiving-plan.md), [alarm hierarchy](docs/example-facility/alarm-plan.md), [machine protection boundaries](docs/example-facility/machine-protection.md), and a [beamline](docs/example-facility/beamline.md) — then closes with [operations scenarios](docs/example-facility/operations-scenarios.md) and a [laptop-scale simulation](docs/example-facility/build-a-mini-hls.md) of the whole thing.

HLS is invented. Its numbers are plausible and internally consistent, in the spirit of published 4th-generation light source design reports, but it is a teaching device — not a design you should build.

## Reading order for a total beginner

1. [What is EPICS?](docs/start-here/what-is-epics.md) — the 10-minute version
2. [Core Concepts](docs/start-here/core-concepts.md) — PVs, records, IOCs, CA/PVA
3. [Build EPICS Base](docs/build-install/epics-base.md) → [Your First IOC](docs/build-install/first-ioc.md)
4. [Command Cheat Sheet](docs/reference/cheatsheet.md) — poke at it with `caget`/`caput`/`camonitor`
5. [Architecture Overview](docs/architecture/index.md) — now the layer model will mean something
6. [The Toolbox](docs/toolbox/index.md) — browse; you don't need it all
7. [Example Facility](docs/example-facility/index.md) — see it assembled at scale

Or skip straight to a [prebuilt training VM](docs/reference/training.md) if you'd rather click than compile.

## Contributing

Corrections, dead links, and "you forgot tool X" are all welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). A monthly CI job checks every external link in this repo, but link rot outruns automation.

## Licence

[MIT](LICENSE). The linked projects carry their own licences; check them before you deploy anything.

## A disclaimer worth reading

This guide is written by someone learning EPICS, not by the EPICS core developers. It is a map, not an authority. Where this repo and [docs.epics-controls.org](https://docs.epics-controls.org) disagree, **the official documentation is right and this is out of date.** Nothing here is safety-related guidance: EPICS is a control and monitoring system, not a safety system, and no page in this repo should be used to design a personnel-protection or machine-protection interlock. See [Machine Protection](docs/example-facility/machine-protection.md) for why that line matters.
