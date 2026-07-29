# Accuracy and Known Uncertainties

This guide was written by someone learning EPICS. It reads confidently because prose that hedges every sentence is unreadable — but **confidence is not accuracy**, and you are entitled to know which parts are solid and which are a learner's best understanding.

This page is the honest version of that. It also exists to make review *tractable*: "please check these specific claims" is a request an expert can act on in twenty minutes, whereas "please review 79 pages" is a request nobody accepts.

## The general disclaimer

Where this guide and the [official EPICS documentation](https://docs.epics-controls.org) disagree, **the official documentation is right and this guide is out of date.** Same for any project's own README. Please [tell us](https://github.com/nusaqib/EPICS-for-Dummies/issues) when you find such a case — that's the most useful contribution available.

## Confidence, by category

| Category | Confidence | Why |
| --- | --- | --- |
| **Core concepts** — PVs, records, links, scanning, alarm severity | High | Stable for decades, and cross-checked against the Application Developer's Guide |
| **What each tool is for** | High | Taken from each project's own documentation |
| **Links and where things live** | High | Every external URL was verified, and a monthly CI job re-checks them |
| **Command syntax** | High | Standard tooling, stable across versions |
| **Architectural reasoning** — why gateways, why hierarchy, why deadbands | Medium-high | Widely-held practice, but the *emphasis* is a judgement call |
| **Version-specific claims** — minimum JDKs, Base behaviour, supported Tomcat | **Low** | These move, and this guide will lag. Always check upstream. |
| **Operational advice** — what to monitor, how to deploy | Medium | Genuine practice varies enormously between facilities |
| **Numbers in the Helios chapters** | Not applicable | [Deliberately invented](../example-facility/index.md), plausible, and not design values |
| **Anything safety-related** | **Out of scope by policy** | This guide states where the boundary is and refuses to go past it. See [Machine Protection](../example-facility/machine-protection.md). |

## Specific claims worth an expert's eye

If you know EPICS well and have twenty minutes, these are the highest-value things to check. Each is a claim I'd want a second opinion on, with the page it appears on.

| Page | Claim to check |
| --- | --- |
| [Scaling & Availability](../architecture/scaling-and-ha.md#redundancy-whats-actually-possible) | That there is no general IOC failover, that redundant-IOC support is not the modern mainstream answer, and that fast-restart-plus-autosave is what facilities actually rely on |
| [Protocols](../architecture/protocols.md#configuration-that-matters) | The description of modern Base auto-sizing array buffers, and whether `EPICS_CA_MAX_ARRAY_BYTES` still needs setting in practice |
| [Protocols](../architecture/protocols.md#security-posture-stated-plainly) | The current state of authenticated / TLS-protected PVA — deliberately vague here, and it may now be more definite |
| [Timing Systems](../toolbox/timing-systems.md#timestamps-in-the-record-layer) | The `TSE` semantics table, especially `-2` / `TSEL` behaviour |
| [Timing Systems](../toolbox/timing-systems.md#beam-synchronous-acquisition) | Whether the beam-synchronous acquisition description is fair, and whether a community-generic solution now exists |
| [Process Database](../architecture/process-database.md#lock-sets-the-thing-that-eventually-bites-you) | The lock-set explanation, and whether inserting a `CA` link is still the standard remedy |
| [Deployment & Operations](../toolbox/deployment-and-operations.md) | Whether epics-containers and e3 are characterised fairly, and whether the "choosing an approach" table matches real practice |
| [Save & Restore](../build-install/save-and-restore.md) | The backing store for the current Phoebus save-and-restore release — this changed across versions and the page hedges |
| [Alarms](../toolbox/alarms.md#why-kafka) | The claim that the alarm server holds no durable state and rebuilds from Kafka in seconds |
| [Access Security](../architecture/access-security.md) | The `CALC` clause description and the `asInit` runtime-reload claim |
| [Client Libraries](../toolbox/client-libraries.md#python) | Whether the "which Python library?" recommendation is the consensus one |
| Any page | **Every version number.** Base 7.0.x, JDK minimums, Tomcat versions, Elasticsearch requirements. |

## Where this guide is deliberately opinionated

Not errors — choices. Reasonable people disagree, and you should know these are positions rather than facts:

- **Fine-grained IOCs** over few large ones. Stated as a recommendation with the counter-argument given, but plenty of working facilities went the other way for good reasons.
- **Phoebus as the default GUI.** PyDM and caQtDM are treated as strong alternatives, but the recommendation is a judgement.
- **"Prefer no code"** — a StreamDevice protocol over C, a `calc` record over a Python script. A genuine bias, stated as such.
- **"Logic the machine depends on belongs in the IOC."** This guide repeats it firmly because the failure mode is severe, but the boundary is genuinely blurry in practice.
- **Monitor-based archiving with deadbands** as the default. Scan-based archiving has legitimate uses this guide underplays.
- **Alarm philosophy** drawn from the process-industry standards. Accelerator practice varies.

## Where it is deliberately silent

- **How your facility does anything.** The most important knowledge is local and unwritten. [Your First Week at a Facility](../start-here/first-week-at-a-facility.md) is a list of questions rather than answers, on purpose.
- **Designing protection systems.** Not from caution about liability — because it requires certified engineering practice that a beginner's guide has no business summarising.
- **Choosing between EPICS and TANGO.** Mentioned, not adjudicated.
- **Anything requiring hardware to verify.** Where a claim couldn't be tested, it's marked with a `!!! warning`.

## How to help

**The single most valuable thing:** if you know EPICS well, read one page in your area of expertise and file what's wrong. One page, one area. That's a much smaller ask than it sounds and it's how a guide like this becomes trustworthy.

- Wrong fact, dead link, stale version → [dead link or factual error](https://github.com/nusaqib/EPICS-for-Dummies/issues/new?template=dead-link-or-error.yml)
- A page assumed knowledge you didn't have → [a page confused me](https://github.com/nusaqib/EPICS-for-Dummies/issues/new?template=confusing-page.yml)
- Something missing from the catalogue → [you forgot tool X](https://github.com/nusaqib/EPICS-for-Dummies/issues/new?template=missing-tool.yml)

Corrections don't need to be polite about it. A guide that misleads beginners is worse than no guide, and "this whole section is wrong because…" is exactly the issue worth opening.

## For readers deciding whether to trust this

A reasonable way to use this guide:

1. **Use it as a map** — to learn what exists, what things are called, and roughly how they relate.
2. **Verify before you depend on it** — check the project's own documentation before installing, and the Application Developer's Guide before designing.
3. **Treat version numbers as hints**, never as requirements.
4. **Treat the Helios chapters as a worked exercise**, not a reference design.
5. **Ignore it entirely on anything safety-related** and talk to your facility's safety authority.

That's not false modesty. It's the correct way to use any secondary source.
