# EPICS for Dummies

> **EPICS** → **E**xperimental **P**hysics and **I**ndustrial **C**ontrol **S**ystem

Welcome. This site is a map of the EPICS ecosystem for people who are new to it — what every tool is, why it exists, where to get it, and how a real facility wires them together.

If you're already comfortable with EPICS, you want [docs.epics-controls.org](https://docs.epics-controls.org). If you read the [official introduction](https://docs.epics-controls.org/en/latest/guides/EPICS_Intro.html) and thought *"fine, but what do I actually install, and in what order?"* — keep reading.

## The problem this site solves

EPICS is not a program you install. It's a collaboration-maintained ecosystem of a couple of hundred separately released pieces: a core library, dozens of device-support modules, half a dozen GUI toolkits, several archivers, alarm servers, directory services, gateways, and client libraries in six languages. They are hosted across at least eight GitHub organisations, three GitLab instances, a SourceForge project, and a handful of institutional web servers.

Nobody hands you the list. Every new facility, and every new hire, rediscovers it.

<div class="grid cards" markdown>

- 🚀 **[Start Here](start-here/index.md)**

    Never heard of a process variable? Begin with concepts, a glossary, and a suggested learning path.

- 🗺️ **[Architecture](architecture/index.md)**

    The layer model, the process database, CA vs PVA, naming conventions, networking, access security.

- 🧰 **[The Toolbox](toolbox/index.md)**

    The catalogue. Twenty-two categories, every significant tool, with links that resolve.

- 🔨 **[Build & Install](build-install/index.md)**

    Practical how-tos: Base, your first IOC, Phoebus, the archiver, alarms, the web stack, containers.

- 🔬 **[Example Facility](example-facility/index.md)**

    The Helios Light Source — a complete hypothetical synchrotron, designed end to end.

- 📚 **[Reference](reference/cheatsheet.md)**

    Commands, environment variables, record types, an error-message index, training material, community.

</div>

## The worked example: Helios Light Source

Layer diagrams only teach so much. This guide therefore invents a facility and designs the whole control system for it:

**Helios Light Source (HLS)** — 3 GeV, 4th-generation storage ring, 528 m circumference, 100 pm·rad emittance, 500 mA in top-up mode, 20 beamlines, ~330 IOCs, ~415 000 process variables.

Every chapter shows the reasoning, not just the answer: why the [naming convention](example-facility/naming-convention.md) puts the area code second, how the [archiver storage estimate](example-facility/archiving-plan.md) arrives at 24 TB/year, where the [machine protection system](example-facility/machine-protection.md) stops and EPICS begins, and what actually happens during a [beam dump at 03:00](example-facility/operations-scenarios.md).

Then [Build a Mini-HLS](example-facility/build-a-mini-hls.md) shrinks the whole thing onto a laptop with soft IOCs, so you can watch it work.

!!! warning "HLS is fictional"
    Its parameters are plausible and internally consistent — chosen in the spirit of published 4th-generation light source design reports — but Helios is a teaching device. Do not treat any number here as a design value, and do not treat any page here as safety guidance.

## Suggested path for a beginner

1. [What is EPICS?](start-here/what-is-epics.md) — the 10-minute version
2. [Core Concepts](start-here/core-concepts.md) — PVs, records, IOCs, CA and PVA
3. [Build EPICS Base](build-install/epics-base.md), then [Your First IOC](build-install/first-ioc.md)
4. [Command Cheat Sheet](reference/cheatsheet.md) — poke at your IOC with `caget`, `caput`, `camonitor`
5. [Talk to a Real Device](build-install/talk-to-a-device.md) — one instrument, end to end, including what breaks
6. [Architecture Overview](architecture/index.md) — the layer model will now mean something
7. [The Toolbox](toolbox/index.md) — browse it; you will not need all of it
8. [Example Facility](example-facility/index.md) — watch it assemble at scale

In a hurry, or allergic to compilers? Use a [prebuilt training VM](reference/training.md) with the whole stack already running.

## How this site is maintained

Documentation only — no scripts, no templates, no code. Where upstream documents something, this site links to upstream rather than paraphrasing it, because paraphrases go stale silently. External links are checked monthly in CI. Corrections are welcome via [GitHub](https://github.com/nusaqib/EPICS-for-Dummies).

!!! note "This is a learner's map, not an authority"
    Where this site and the [official EPICS documentation](https://docs.epics-controls.org) disagree, the official documentation is right and this site is out of date.
