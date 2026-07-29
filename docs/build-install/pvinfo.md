# Install PV Info

A web front end to [ChannelFinder](channelfinder-recsync.md): search PVs by name or by metadata, and cross-link to every other service that knows about them.

Overview: [Toolbox → PV Info](../toolbox/web-interfaces.md#pv-info).

| | |
| --- | --- |
| Source | [github.com/ChannelFinder/pvinfo](https://github.com/ChannelFinder/pvinfo) |

## Prerequisites

- **[ChannelFinder running and populated](channelfinder-recsync.md)** — PV Info is a view over it, so with an empty ChannelFinder there is nothing to see
- The other services you want to link to: [archiver](archiver-appliance.md), [alarm system](alarm-system.md), [save & restore](save-and-restore.md), [Olog](olog.md)

## Install

Follow the repository's README — it's a web application, and the deployment method (container image, Node/npm build, or servlet container) depends on the current version. Check there rather than trusting a snapshot in this guide.

## Configure the links

The configuration that matters is the set of **service URLs**: ChannelFinder, the archiver's retrieval endpoint, the alarm logger, save & restore, and Olog.

Those links are the whole point. Given a PV name, PV Info can then show:

| Question | Answered from |
| --- | --- |
| What is this PV, and what type? | ChannelFinder |
| Which IOC serves it, on which host? | ChannelFinder (via [recsync](channelfinder-recsync.md)) |
| What subsystem, area, criticality? | ChannelFinder properties |
| What does its history look like? | Archiver |
| Is it alarmed, and how often does it trip? | Alarm logger |
| Which save sets include it? | Save & restore |
| Has anyone written about it? | Olog |

"What is this PV and what's going on with it?" is asked dozens of times a day at a facility. Answering it in one page instead of five tools is a real productivity gain, and it's the reason to deploy this rather than just using ChannelFinder's REST API.

## Search patterns worth knowing

```text
SR-C05-*                  everything in cell 5
*-DI-BPM-*:X-Mon          every horizontal BPM reading
subsystem=vacuum          every vacuum PV, however named
iocName=SR-C05-VA-IOC-01  everything on one IOC
recordType=motor          every motor axis in the facility
```

The last three only work if you [populated properties deliberately](channelfinder-recsync.md#attaching-your-own-metadata) with `info()` tags in your databases. This is where that investment shows up.

## Deploy it safely

Same posture as the other [web interfaces](../toolbox/web-interfaces.md): TLS and authentication at a reverse proxy, and read-only. PV Info is inherently a read-only tool, which makes it the safest thing in this section to expose to a wider audience — and a good candidate for the facility's general-purpose "what is this?" page.

## Verify

1. Search for a PV you know is in ChannelFinder.
2. Confirm the IOC name and host are correct.
3. Follow the archive link and see history.
4. Search by one of your own properties (`subsystem=vacuum`).
5. Search for a PV that doesn't exist, and confirm the failure is clear rather than an empty page that looks like a broken service.

## Next

→ [Gateways](gateways.md)
