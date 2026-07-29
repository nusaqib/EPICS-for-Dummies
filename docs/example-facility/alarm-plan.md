# Alarm Plan

Nine thousand alarm-configured PVs, and a target of fewer than ten annunciated alarms per hour. This chapter is about how those two numbers coexist.

Tool background: [Toolbox → Alarms](../toolbox/alarms.md).

## The governing principle

**Every alarm must require a specific operator action.**

If the answer to "what should the operator do?" is "nothing", or "mention it tomorrow", it is not an alarm. It is a status indicator, a report, or a maintenance ticket.

This test alone eliminates most candidate alarms. Of 415 000 PVs, HLS alarm-configures 9 000 — about 2%. The other 98% have alarm limits on their *records* (so screens colour correctly and the [archiver](archiving-plan.md) records severity) but do not annunciate.

That distinction is the heart of alarm design: **record-level severity is free and universal; annunciation is scarce and must be earned.**

## Three configurations, three audiences

| Configuration | Alarms | Audience | Annunciation |
| --- | --- | --- | --- |
| `Accelerator` | ~6 000 | Control room operators | Visual + audible + on-call paging |
| `Beamlines` | ~2 500 | Beamline staff, per beamline | Visual on that beamline; email |
| `Controls` | ~500 | Controls team | Visual + email; paging for service-down |

Separate Kafka topics, separate [alarm server](../build-install/alarm-system.md) instances, separate trees. Because a combined tree pages the controls team about a vacuum excursion and the operators about a full disk, and both groups then learn to ignore it.

## The Accelerator hierarchy

Three levels of tree depth. Severity propagates upward, so the top level says *where* and drilling down says *what*.

```text
Accelerator
├── Storage Ring
│   ├── Magnets            (20 cells → per-cell summary → individual supplies)
│   ├── Vacuum             (20 cells → per-cell summary → gauges, pumps, valves)
│   ├── RF                 (cavities, SSAs, harmonic cavities, LLRF)
│   ├── Diagnostics        (BPMs, DCCT, loss monitors, feedback)
│   ├── Insertion Devices  (15 IDs)
│   └── Orbit Feedback
├── Injector
│   ├── Gun & Linac
│   ├── Booster
│   └── Transfer Lines
├── Front Ends            (20)
├── Utilities
│   ├── Water             (4 circuits)
│   ├── HVAC
│   ├── Cryogenics
│   └── Electrical
└── Protection Systems    (read-only status from MPS / PPS / radiation)
```

Level-1 branches map exactly onto the [level-2 synoptic screens](operator-interfaces.md#level-2--subsystem-synoptics), so an alarm at `Storage Ring / Vacuum` and the vacuum synoptic are the same mental object. That correspondence is deliberate and it is what makes the tree navigable under stress.

## Designing for the flood

A beam dump sets thousands of records into `MAJOR` within a second. If the display shows all of them, the operator cannot find the cause, and the alarm system has actively made the situation worse.

Four mechanisms, applied deliberately:

### 1. Hierarchy

The top level says `STORAGE RING — MAJOR`. One line. Drilling down narrows it. An operator's first action is always "which subsystem", never "read four thousand rows".

### 2. Delays on consequential alarms

| Alarm class | Delay | Reasoning |
| --- | --- | --- |
| Beam permit lost, RF trip, MPS trip | **0 s** | These are causes. They must appear first and alone. |
| Beam current low, lifetime low | 5 s | Consequences of a dump. Delayed so the cause is visible first. |
| Orbit RMS high, feedback fault | 5 s | Consequence |
| Vacuum pressure high | 5 s | Real, but not instantaneous |
| Individual magnet supply off | 10 s | A dump turns many things off |
| Temperature and flow alarms | 30 s | Thermal time constants are minutes; a 30 s excursion is noise |
| IOC heartbeat lost | 30 s | Survives a restart without annunciating |

**The 0 s / 5 s split is the single most effective anti-flood measure available.** For the five seconds after a dump, the operator sees only the small set of PVs that can *cause* one. That is the first-out indication, achieved with a configuration field rather than special hardware.

### 3. Suppression by machine state

Alarms are enabled per [machine mode](machine-parameters.md#operating-modes):

| Mode | Suppressed |
| --- | --- |
| Beam off / access | Beam current, lifetime, orbit, injection efficiency, ID gap |
| Injector only | All storage ring beam-related alarms |
| Shutdown | Nearly everything except utilities, cryogenics and protection-system status |
| Machine study | Orbit and stability alarms (physicists are deliberately perturbing them) |

Without this, "beam off" generates thousands of alarms about the absence of beam, every single time, and the alarm system is trained into irrelevance during exactly the periods when maintenance faults matter most.

### 4. Hysteresis and counts

`HYST` on every analog record with an alarm limit, so a value oscillating across a threshold produces one alarm rather than a storm from a single physical condition. Count-based alarming for intermittent faults: alarm if it happens five times in ten minutes, not on each occurrence.

## The guidance text

Every one of the 9 000 alarms carries guidance and a display link. This is tedious and it is the majority of the real work of deploying an alarm system.

```xml
<pv name="SR-C05-VA-IP-03:Pressure-Mon">
  <description>Cell 5 ion pump 3 pressure</description>
  <latching>true</latching>
  <annunciating>true</annunciating>
  <delay>5</delay>
  <guidance>
    <title>What this means</title>
    <details>Pressure at cell 5 ion pump 3 above 1e-8 mbar (MINOR)
or 1e-7 mbar (MAJOR).

Check the neighbouring gauges on the vacuum synoptic first:
- Whole-cell rise      → suspect a leak or a failed pump
- Single gauge only    → suspect the gauge or its controller
- Rising with beam     → beam-induced desorption, may settle

The sector valves will close automatically on a large rise. That
is the PLC interlock and it does not need your intervention.

Above 1e-7 mbar, call the vacuum on-call (see the rota).</details>
  </guidance>
  <display>
    <title>Cell 5 vacuum</title>
    <details>/displays/sr/vacuum_cell.bob?CELL=05</details>
  </display>
</pv>
```

Note what the guidance does: it tells the operator what to look at, how to distinguish the two likely causes, **what the automatic systems will do without them**, and when to escalate. An operator reading that at 03:00 is equipped. A red rectangle is not.

The line about the PLC closing the valves matters especially — it prevents an operator from taking an unnecessary action, and it reinforces [where the protection boundary is](machine-protection.md).

## The Controls configuration

The controls team's own alarms, deliberately separate:

| Alarm | Delay | Severity |
| --- | --- | --- |
| IOC heartbeat lost | 30 s | MAJOR |
| IOC uptime reset (restarted) | 0 s | MINOR |
| IOC CPU sustained > 80% | 5 min | MINOR |
| IOC scan task overrun | 1 min | MAJOR |
| Archiver appliance down | 1 min | MAJOR |
| Archiver disconnected-PV count rising | 10 min | MINOR |
| Archiver ingest rate zero | 5 min | MAJOR |
| Archiver storage tier > 85% | 1 h | MINOR |
| Gateway down | 30 s | MAJOR |
| Alarm system: **alarm rate zero for 30 min** | 30 min | MAJOR |
| Kafka broker down | 1 min | MAJOR |
| Elasticsearch cluster not green | 5 min | MINOR |
| NTP offset > 100 ms | 5 min | MAJOR |

Two entries here are unusual and both are important:

**"Alarm rate zero" alarms on silence.** A dead alarm system looks exactly like a quiet machine, and everyone continues to believe they are being watched over.

**NTP offset is MAJOR, not a housekeeping item.** [Timestamps come from IOCs](../toolbox/timing-systems.md), so a drifted clock corrupts the archive and makes causality analysis wrong. It's a data-integrity incident.

## Annunciation and escalation

| Channel | Used for |
| --- | --- |
| Visual — always-on alarm panel on the control room wall | Everything in `Accelerator` |
| Audible — Phoebus annunciator | MAJOR only, and only above the beam-affecting subtrees |
| Email | Subsystem experts, per-subtree, MINOR and above |
| Paging / SMS to on-call rota | MAJOR in the beam-affecting subtrees, or any `Controls` service-down |
| Chat integration | A Kafka consumer posting into the operations channel |

Audible annunciation is restricted to MAJOR in beam-affecting subtrees for one reason: **an annunciator that sounds too often gets muted within a week**, and the mute is permanent. Rate discipline, not volume, is what makes audible alarms work.

Paging goes to a **rota with an escalation path**, never to an individual. The most reliable failure mode of on-call systems is paging someone who is on holiday.

## Keeping it good

**Monthly alarm review.** The [alarm logger](../toolbox/alarms.md#alarm-logger) provides the data; rank alarms by frequency and take the top ten. Each is one of:

1. A real recurring fault worth fixing in hardware;
2. A threshold set wrong;
3. An alarm that should not exist.

**This single practice does more for alarm quality than any amount of initial configuration.** It's also the practice most likely to be dropped when the facility gets busy, and dropping it is how a good alarm system becomes a bad one over about eighteen months.

**Track the rate against the target.** Average annunciated alarms per hour, plotted weekly. Published guidance (IEC 62682, ISA-18.2) puts a sustainable operator load around ten per hour; HLS targets under ten with bursts tolerated. When the trend crosses it, the review becomes urgent rather than routine.

**Configuration in git, imported into Kafka.** The XML is the reviewable source; the [config logger](../toolbox/alarms.md#alarm-config-logger) provides an independent audit trail of what actually changed and when.

## The line that isn't crossed

!!! danger "None of this is protection"
    Every alarm here tells a human something. Nothing here *acts*.

    The machine protection and personnel protection systems are separate, certified, and outside EPICS entirely. The `Protection Systems` branch of the alarm tree contains **read-only status** — it tells the operator that a protection system has acted, and it has no ability to cause or prevent that action.

    See [Machine Protection](machine-protection.md).

## Next

→ [Machine Protection](machine-protection.md)
