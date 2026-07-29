# Scanning and Automation

Making a sequence of things happen without a human doing each step. Four layers, and the choice of layer matters more than the choice of tool within it.

| Layer | Runs in | Survives | Use for |
| --- | --- | --- | --- |
| **[Sequencer (SNL)](#sequencer-snl)** | The IOC | Network loss, client crashes, everything short of IOC death | Machine sequences, startup/shutdown, state machines that must not stop |
| **[sscan](#sscan)** | The IOC | Same | Multi-dimensional scans with in-IOC data collection |
| **[Scan server](#phoebus-scan-server)** | A service | Client crashes; not its own | Experiment procedures with operator oversight |
| **[Bluesky](scientific-data.md#bluesky)** | A Python session | Nothing | Experiments, where flexibility beats robustness |

The rule: **the more the machine depends on it, the deeper it should live.** A magnet ramp sequence belongs in the IOC. A user's diffraction scan belongs in Python.

## Sequencer (SNL)

**State machines inside the IOC, in a C-like language.**

| | |
| --- | --- |
| Documentation | [State Notation Language and Sequencer manual](https://www-csr.bessy.de/control/SoftDist/sequencer/) |
| Mirror | [mdavidsaver.github.io/sequencer-mirror](https://mdavidsaver.github.io/sequencer-mirror/) |
| Training | [Sequencer](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/14%20Sequencer.pdf) · [lab](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/14l%20SequencerLab.pdf) (USPAS) |

**State Notation Language** (SNL) is compiled by `snc` into C, built into your IOC, and runs as a thread inside it. PVs are ordinary variables, `assign`ed to channels and `monitor`ed:

```c
program magnetRamp

double current_sp;
assign current_sp to "SR-C05-PS-QF-01:Current-SP";

double current_rb;
assign current_rb to "SR-C05-PS-QF-01:Current-RB";
monitor current_rb;

short permit;
assign permit to "HLS-CF-MPS-01:BeamPermit-Sts";
monitor permit;

double target = 102.5;

ss ramp {
    state idle {
        when (permit == 0) {
            printf("Permit off, starting ramp\n");
        } state ramping
    }
    state ramping {
        when (current_rb < target - 0.1) {
            current_sp = current_rb + 1.0;    /* 1 A per step */
            pvPut(current_sp);
        } state ramping

        when (delay(30.0)) {
            printf("Ramp timed out\n");
        } state faulted

        when (current_rb >= target - 0.1) {
        } state atField

        when (permit != 0) {
        } state faulted
    }
    state atField { when (permit != 0) {} state faulted }
    state faulted { when (delay(5.0)) {} state idle }
}
```

**Why it's the right tool for machine sequences:**

- It runs in the IOC. A network partition, a rebooted workstation, or a crashed GUI does not interrupt it.
- Timeouts and error transitions are *first-class syntax* (`when (delay(30.0))`), which is exactly what sequence logic is mostly made of.
- The state machine is explicit and reviewable, rather than implicit in the control flow of a script.
- It's been running production accelerator sequences for thirty years.

**Costs:** a compile step in your IOC build; a language most people learn only for this; and debugging is via `seqShow`/`seqChanShow` on the IOC console rather than a debugger. Also, `+r` (reentrant) and safe-mode semantics around variable sharing catch people out — read the manual section on that before writing anything with multiple state sets.

Typical uses: magnet cycling and degaussing, RF conditioning and startup, injection sequences, insertion device gap/taper coordination, cryogenic and vacuum pump-down sequences, automatic recovery after a trip.

## sscan

**Scanning inside the IOC.**

| | |
| --- | --- |
| Source | [github.com/epics-modules/sscan](https://github.com/epics-modules/sscan) |
| Part of | [synApps](deployment-and-operations.md#synapps) |

The `sscan` record implements a scan: up to four **positioners**, up to seventy **detectors**, up to four **triggers**, with `NPTS` points, and the collected data held in the record's arrays. Scan records can be nested for multi-dimensional scans, and `saveData` writes the results to files.

Why do it in the IOC rather than a client:

- **Speed.** No network round trip per point. A 1 000-point scan is not 1 000 client-server exchanges.
- **Robustness.** The scan finishes even if the workstation that started it goes away.
- **Correlation.** Positions and detector values are captured together, at the same moment, in the IOC.

Why not: expressing a complex, conditional, adaptive experiment in `sscan` records is painful, and that's precisely what [Bluesky](scientific-data.md#bluesky) is good at. Long-standing practice at APS-family beamlines, and still the right choice for straightforward scans where reliability matters more than expressiveness.

## Phoebus Scan Server

| | |
| --- | --- |
| Documentation | [Scan server](https://control-system-studio.readthedocs.io/en/latest/services/scan-server/doc/index.html) |
| Client | The Scan application in [Phoebus](operator-interfaces.md#phoebus) |

A service that executes scans described as XML or built in the Phoebus scan editor. Commands include `set`, `wait`, `loop`, `log`, `parallel`, `sequence`, `if`, `script`, and `include` — so a scan is a structured, reviewable, restartable document rather than a program.

Features that matter operationally: scans queue, so submitting work while another scan runs is normal; scans can be paused, resumed and aborted from the UI; progress is visible; and a scan's data is logged as it goes. The queue plus the visibility is the appeal — a control room can see what automation is running and stop it, which is not true of a script in somebody's terminal.

**Good middle ground**: more robust and more visible than a client script, more flexible than `sscan`, less capable than Bluesky.

## pyDevice

**Python inside record processing.**

| | |
| --- | --- |
| Source | [github.com/klemenv/pyDevice](https://github.com/klemenv/pyDevice) |
| Training | [Python IOC pyDevice](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/23%20Python%20IOC_pydevice.pdf) (USPAS) |

Lets a record's processing call a Python function, embedding an interpreter in the IOC. Excellent for calculations too awkward for a `calc` expression, for talking to a device with a Python-only SDK, and for gluing something together quickly.

Use with judgement: you have put a garbage-collected interpreter with a global lock inside a real-time-ish control process. Fine for slow, non-critical logic; a poor choice in a fast scan path or anything the machine depends on.

Related: [luaEpics](https://github.com/epics-modules/lua) does the same with Lua, which is lighter-weight and embeds more naturally, and gives you a scriptable IOC shell as a side benefit.

## Other automation tools

| Tool | Purpose |
| --- | --- |
| **[sseq](https://github.com/epics-modules/sseq)** | Sequenced output records: write ten values, with delays and conditions, driven by one trigger. Declarative sequencing without SNL. |
| **`seq` record** (Base) | Up to sixteen values to sixteen links with delays. The simplest sequencing available. |
| **`calcout` with `ODLY`** | Delayed conditional output. Two records like this replace a surprising number of scripts. |
| **[caputRecorder](https://github.com/epics-modules/caputRecorder)** | Records what an operator does as replayable Python. Good for capturing a procedure someone performs by hand and turning it into automation. |
| **[Bluesky](scientific-data.md#bluesky)** | Experiment orchestration. The right answer for beamline science. |
| **Plain scripts + cron** | Legitimate for periodic housekeeping: nightly reports, log rotation, health checks. Not for anything the machine depends on. |

## Choosing, concretely

| Task | Where it belongs |
| --- | --- |
| Ramp magnets to a machine mode, correctly, every time | **SNL sequencer** — must survive everything |
| Recover automatically from an RF trip | **SNL sequencer** |
| Insertion device gap tracking monochromator energy | **IOC**: `calc`/`transform` records or a sequencer, never a client |
| Cycle a magnet to remove hysteresis | **SNL sequencer** |
| A 2D beamline scan producing a map | **Bluesky** or **sscan**, depending on the facility's ecosystem |
| An operator-supervised alignment procedure | **Scan server** |
| Nightly archive health report | **Script + cron** |
| Adaptive optimisation of machine parameters | **[Optimisation framework](physics-and-optimization.md)** driving PVs from Python |
| An interlock | **[Not any of these.](../example-facility/machine-protection.md)** Hardware. |

## Guidance

**Automation that the machine depends on belongs in the IOC.** If it stops when a laptop closes, it isn't automation, it's a person with extra steps. This is the single most important point on this page and the one most often ignored, because a Python script is so much quicker to write than an SNL program.

**Make every automated action visible.** A PV showing what the sequence is doing, its current state, and its last error. Automation an operator cannot see is automation they will fight.

**Give an operator a way to stop it.** An abort PV, honoured promptly, in every sequence. And an interlock ensuring that stopping it leaves the machine in a safe state rather than half-configured.

**Design the failure paths first.** The happy path is the easy 10%. What happens when a device doesn't respond, a limit is hit, the permit drops mid-sequence, or the sequence is aborted at step 7 of 12? SNL's `when (delay(...))` syntax exists because everyone eventually learns that this is most of the work.

**Log what automation did.** To [caPutLog](logbooks.md#caputlog) automatically, and to the [logbook](logbooks.md) with intent where it matters. "The magnets changed at 03:00 and nobody was there" should have an answer.

## Next

→ [Simulation & Testing](simulation-and-testing.md)
