# Operations Scenarios

Four scenarios showing the control system in use. Design decisions from the earlier chapters either pay off here or don't.

## 1. Morning startup after a maintenance day

**07:00. Tunnel access ended at 06:00. Beam is expected for users at 09:00.**

| Time | Action | Control system involvement |
| --- | --- | --- |
| 06:00 | Tunnel searched and secured | **PPS.** `HLS-CF-PPS-01:TunnelSearch-Sts` goes to `SECURED`. EPICS observes; it cannot influence. |
| 06:15 | Machine mode → `Injector only` | `HLS-CF-MODE-01:Mode-SP`. Changes which [alarms are enabled](alarm-plan.md#3-suppression-by-machine-state) and which [ASGs](operator-interfaces.md#access-control-in-practice) are writable. |
| 06:20 | Restore the golden configuration | [Save & restore](../toolbox/save-and-restore.md): restore `Accelerator/UserOperation-Golden` into the machine. **Compare first**, restore second. |
| 06:25 | Review the diff | 23 PVs differ from the golden set. Eighteen are expected (yesterday's vacuum work). Five are not — an operator investigates before proceeding. |
| 06:30 | Cycle the magnets | [SNL sequencer](../toolbox/scanning-and-automation.md#sequencer-snl) programs, one per supply group, ramping up and down to remove hysteresis. Runs in the IOCs; survives anything short of IOC death. |
| 06:45 | RF conditioning and cavity tune | Sequencer; ~15 minutes |
| 07:00 | Linac and booster on, first beam to the booster | Injector IOCs; [timing system](../toolbox/timing-systems.md) events |
| 07:20 | Inject into the ring | Injection sequencer. Injection efficiency PV watched closely. |
| 07:40 | Ramp to 500 mA | Top-up sequencer, repeated injections |
| 08:00 | Orbit correction, then orbit feedback on | Physics application measures and corrects; then the [FPGA loop](subsystems.md#fast-orbit-feedback) is enabled via its IOC interface |
| 08:20 | Insertion device gaps to their user settings | Per-ID IOCs; feed-forward tables compensate the tune shift |
| 08:30 | Machine mode → `User operation` | Alarm suppression lifts; beam-affecting ASGs lock |
| 08:40 | Take a snapshot | "Start of user run, 500 mA, all IDs closed" |
| 08:45 | Front-end shutters enabled | **PPS.** Beamlines request; the PPS decides. |
| 09:00 | Users have beam | |

**What made this work:**

The **compare-then-restore** step at 06:25. The 23-PV diff is the single most valuable thirty seconds of the morning: it turns "the machine feels different today" into a specific list. Without it, the five unexpected differences would be discovered as a beam behaviour anomaly at 08:00, with a queue of users forming.

The **sequencers in IOCs**. Magnet cycling and RF conditioning take an hour of unattended, error-prone, multi-step work. Running in the IOCs, they complete whether or not anyone's workstation stays up, and they have defined failure transitions.

The **mode PV gating alarms and permissions**. During `Injector only`, thousands of ring-beam alarms are suppressed and beam-affecting setpoints are writable. At 08:30 both flip. One PV, two policies, no human discipline required.

## 2. Beam dump at 03:14

**Unattended shift. 500 mA, all beamlines running. Beam lost.**

### What the operator sees, in order

```text
03:14:07.412   MAJOR   Storage Ring / RF          SR-CF-RF-CAV-01:Fault-Sts
03:14:07.418   MAJOR   Protection Systems         HLS-CF-MPS-01:BeamPermit-Sts
```

Two alarms. Then, five seconds later, the consequences:

```text
03:14:12       MAJOR   Storage Ring / Diagnostics  Beam current low
03:14:12       MAJOR   Storage Ring / Orbit FB     Feedback fault
03:14:12       MINOR   Front Ends                  20 × shutter closed
03:14:17       MINOR   Storage Ring / Magnets      Various supplies off
```

**That ordering is the [alarm plan](alarm-plan.md#2-delays-on-consequential-alarms) working.** For five seconds the operator sees only the small set of PVs that can *cause* a dump. The RF cavity fault is unambiguous, and it arrived six milliseconds before the permit dropped.

Without the 0 s / 5 s delay split, roughly four thousand alarms would have arrived in the same second and the cause would be one line among them.

### Diagnosis, in about ten minutes

| Step | Tool | Finding |
| --- | --- | --- |
| Confirm the first cause | `HLS-CF-MPS-01:FirstFault-Sts` — recorded by the [MPS](machine-protection.md) in its own time base | RF cavity 1 arc interlock |
| Read the guidance | The alarm's `<guidance>` text | Names the likely causes, what the automatic systems already did, and the on-call rota |
| Open the right screen | The alarm's `<display>` link | RF cavity 1 detail screen, one click |
| Look at the seconds before | [Phoebus Data Browser](operator-interfaces.md#the-screen-hierarchy) over the [archiver](archiving-plan.md) | Reflected power rising over ~40 s before the trip |
| Look at the days before | Same, zoomed out | The same rise has occurred, smaller, three times in a week — each time recovering |
| Check who changed what | The "recent writes" panel, from [caPutLog](../toolbox/logbooks.md#caputlog) | Nothing touched RF in 18 hours |
| Rule out utilities | Archived water and HVAC data on the same axis | Cooling water temperature normal |
| Log it | [Olog](../toolbox/logbooks.md#olog), with the plot attached from the Data Browser in two clicks | |
| Escalate | RF on-call, per the guidance text | |

**What made this work:**

**`FirstFault` from the protection system.** Only the MPS has a trustworthy view of ordering at millisecond resolution. EPICS asking "which alarm has the earliest timestamp?" would be answering from IOC clocks, which is why [NTP offset is a MAJOR alarm](alarm-plan.md#the-controls-configuration) and why this PV exists.

**Archiving everything, forever.** The three previous smaller events are the actual finding — a degrading component, not a one-off. They exist because reflected power is archived with a sensible deadband and never decimated away. [Retroactive archiving is impossible](archiving-plan.md).

**Cross-subsystem correlation on one time base.** Ruling out cooling water took thirty seconds because it's in the same archive on the same clock. In facilities where utilities data lives in a separate BMS with its own timestamps, that's a morning's work.

**Guidance text.** The operator is not an RF expert at 03:14. The guidance told them what to check, that the shutters had closed automatically, and who to call.

## 3. An IOC dies quietly

**14:22. `sr-c08-va-ioc-01` stops responding.**

```text
14:22:31   (nothing — 30 s delay)
14:23:01   MAJOR   Controls / IOC Health   sr-c08-va-ioc-01 heartbeat lost
```

What happens, and doesn't:

- **The beam continues.** Cell 8's vacuum hardware keeps doing exactly what it was last told. Ion pumps pump; gauges measure; the [PLC valve interlocks](subsystems.md#vacuum) are entirely unaffected because they were never in EPICS. What is lost is *observation*, not control of the physical process.
- **Kubernetes restarts the container** within a minute. [autosave](../toolbox/soft-support-modules.md#autosave) restores the settings; `PINI` pushes them; clients reconnect automatically.
- **The archive has a one-minute gap** for cell 8 vacuum. Recorded, visible, not fixable.
- The 30-second delay on the heartbeat alarm means a *clean* restart wouldn't have annunciated at all — only an IOC that stays down does.

**The important line in this scenario is the first one.** An IOC dying does not stop the machine, because hardware holds its state and protection lives elsewhere. That reframes the availability requirement from "never fail" to "**fail visibly and recover fast**" — which is achievable, and is why [there is no IOC failover in EPICS](../architecture/scaling-and-ha.md#redundancy-whats-actually-possible) and why nobody needs it.

The failure that would have been *dangerous* is the one that didn't happen: an IOC down for three weeks with nobody noticing. The heartbeat alarm exists for that, and it costs one module on every IOC.

## 4. Maintenance day

**08:00. Eight hours of tunnel access. Twelve work packages.**

| Time | Activity | Control system |
| --- | --- | --- |
| 07:00 | Beam off, mode → `Beam off / access` | Alarm suppression for beam-related alarms; beam-affecting ASGs become writable |
| 07:15 | **Snapshot before anything** | `Accelerator/PreMaintenance-<date>`. The reference for reverting. |
| 07:30 | Tunnel search, access granted | **PPS** |
| 08:00–15:00 | Twelve work packages proceed | |
| — | Replace an ion pump in cell 12 | `sr-c12-va-ioc-01` reconfigured, redeployed from git, restarted. New PV appears in [ChannelFinder](../toolbox/directory-services.md) via recsync, and is **archived automatically** because its record carries `info(recceiver:archive, "monitor")`. |
| — | Firmware upgrade on 20 corrector supplies | Version PVs confirm afterwards. `-Ver` PVs exist for exactly this. |
| — | Deploy an alarm configuration change | XML in git → review → import. [Config logger](../toolbox/alarms.md#alarm-config-logger) records who and when. |
| — | Add a new beamline sample environment IOC | Container built in CI, deployed, [PVs registered](../toolbox/directory-services.md#recsync), screens generated by [PVI](../toolbox/deployment-and-operations.md#pvi) |
| — | Archiver `arch-02` storage expansion | Ingest pauses ~10 min. A known, logged gap. |
| 15:00 | Access ends, tunnel searched | **PPS** |
| 15:15 | **Compare against the pre-maintenance snapshot** | 41 PVs differ. Each is matched against a work package. |
| 15:30 | Two unexplained differences | Both traced via [caPutLog](../toolbox/logbooks.md#caputlog) to a technician's test writes. Reverted. |
| 15:45 | Startup sequence begins | As scenario 1 |
| 18:00 | Beam for users | |

**What made this work:**

**The 15:15 comparison.** Forty-one differences, thirty-nine expected, two not. Those two would otherwise have been discovered as beam behaviour anomalies over the following days, with no way to connect them to the maintenance day. Snapshot-and-diff turns a week of confusion into fifteen minutes.

**Automatic archiving of the new PV.** Nobody remembered to add the new ion pump's PVs to the archiver, and it didn't matter, because [archiving is configured by query](archiving-plan.md#configuration-by-query) over metadata declared in the database. The alternative — a human step that's occasionally forgotten — produces gaps discovered years later.

**Everything from git.** Twelve work packages, several IOC changes, an alarm configuration change, all deployed from version control with CI. And a drift-detection job afterwards confirming that what's running matches what's committed — because ["it's all in git" is a claim about the repository, not about the servers](services-deployment.md#what-gets-protected).

**caPutLog answering the awkward question.** Two unexplained setpoints, traced to a person and a time in about a minute. Without it, the answer is "nobody knows", and the two values either get reverted on a guess or left in place.

## The pattern across all four

Reading these back, the same handful of decisions keep doing the work:

| Decision | Where it paid off |
| --- | --- |
| Snapshot and **compare** before and after everything | Scenarios 1 and 4 — the highest-value thirty seconds in each |
| Alarm delays separating causes from consequences | Scenario 2 — two alarms instead of four thousand |
| Archive everything, forever, with sensible deadbands | Scenario 2 — the three prior events were the actual finding |
| Guidance text on every alarm | Scenario 2 — an operator who isn't an RF expert, at 03:14 |
| Protection systems outside EPICS | Scenarios 1, 3, 4 — safe failure, unaffected by IOC state |
| iocStats heartbeats on everything | Scenario 3 — the failure that gets noticed |
| Archiving configured by query | Scenario 4 — the step nobody had to remember |
| Everything from git, with drift detection | Scenario 4 |
| caPutLog | Scenarios 2 and 4 — "who changed this?" |

None of these is exotic, and none is expensive. They are all decided *before* first beam, and they are all much harder to retrofit than to install.

## Next

→ [Build a Mini-HLS](build-a-mini-hls.md) — run a shrunken version of all of this on your laptop.
