# Access Security

EPICS Base has a built-in mechanism for restricting who may write to which PVs, from where. It is genuinely useful and it is not a security boundary. Both halves of that sentence matter.

Reference: [Access Security](https://docs.epics-controls.org/en/latest/appdevguide/accessSecurity.html) in the Application Developer's Guide.

## What it can do

An IOC loads an **access configuration file** (`.acf`) defining:

- **UAG** — User Access Groups: lists of user names.
- **HAG** — Host Access Groups: lists of host names.
- **ASG** — Access Security Groups: named rule sets, referenced by each record's `ASG` field.
- **Rules** — for each ASG, at each *access level*, which UAG/HAG combinations get `NONE`, `READ`, or `WRITE`.

```text
UAG(operators)  { opr, physicist1, physicist2 }
UAG(experts)    { rfexpert, magnetexpert }

HAG(controlroom) { console1, console2, console3 }
HAG(office)      { desk-pc-1, desk-pc-2 }

# Default for records with no ASG field: anyone may read, nobody may write
ASG(DEFAULT) {
    RULE(1, READ)
    RULE(1, WRITE) { UAG(operators) HAG(controlroom) }
}

# RF cavity tuning: experts only, control room only
ASG(RFEXPERT) {
    RULE(1, READ)
    RULE(1, WRITE) { UAG(experts) HAG(controlroom) }
}

# Machine-state-dependent: writable only when the beam permit is off
ASG(BEAMOFFONLY) {
    INPA("HLS-CF-MPS-01:BeamPermit-Sts")
    RULE(1, READ)
    RULE(1, WRITE) { UAG(operators) HAG(controlroom) CALC("A=0") }
}
```

Then in the database:

```text
record(ao, "SR-C05-RF-CAV-01:Tune-SP") {
    field(ASG, "RFEXPERT")
    # ...
}
```

Loaded at startup with `asSetFilename("/opt/epics/config/facility.acf")` before `iocInit`, and reloadable at runtime with `asInit` — so a rule change doesn't require an IOC restart. `asdbdump`, `asphag`, `aspuag` and `asfSetFilename` on the IOC shell let you inspect what's in force.

### The `CALC` clause is the interesting part

A rule can depend on the live value of a PV. That gives you *state-dependent* permissions with no client cooperation required:

- Magnet setpoints writable only when the beam permit is off.
- Beamline optics writable only when that beamline's shutter is closed.
- Insertion device gap writable only in a defined machine mode.

This is enforced inside the IOC, on every write, regardless of which client is asking. It is the most valuable feature on this page — and note that it protects against *mistakes*, which is what actually happens, far more often than malice.

## What it cannot do

!!! danger "The user name is self-declared"
    A Channel Access client sends whatever user name it likes. There is no password, no token, no certificate, no challenge. `caput` from a machine you control, with `USER` set to `opr`, satisfies `UAG(operators)`.

    Host-based rules are marginally stronger — the client's address is harder to fake casually — but IP spoofing and DNS games are not exotic.

So access security is:

- ✅ **Excellent** against accident: the wrong script, the wrong window, the wrong day, the well-meaning physicist with a typo.
- ✅ **Excellent** as an interlock on machine state, via `CALC`.
- ❌ **Not** protection against a determined person with network access.
- ❌ **Not** a substitute for network segmentation.
- ❌ **Not** auditable in the sense a security team means. `caPutLog` records the *claimed* identity.

**Channel Access is unencrypted and unauthenticated.** That is a property of a protocol designed for a private control network in 1990, and the architectural response is to keep that assumption true: segment the network, and let everything outside the controls zone reach it only through a read-only [gateway](../toolbox/gateways.md). Topology is the boundary you can actually rely on. See [Networking](networking.md).

Community work on TLS-protected, authenticated PVA has been ongoing; consult the current Base/PVXS release notes for its state rather than this page.

## Layering, in the order you should think about it

Defence for a controls system, from strongest to weakest:

| Layer | Mechanism | Strength |
| --- | --- | --- |
| 1 | **Physical / VLAN segmentation** — office cannot route to the IOC network at all | Strong |
| 2 | **Read-only gateway** as the only crossing | Strong; independent of client claims |
| 3 | **Host-based ASG rules** — writes only from named consoles | Moderate |
| 4 | **`CALC` state rules** — writes only when the machine allows it | Strong *for its purpose* (state, not identity) |
| 5 | **`DRVL`/`DRVH` drive limits** on every output record | Strong, local, unbypassable; costs nothing |
| 6 | **User-based ASG rules** | Weak against intent, good against accident |
| 7 | **[caPutLog](../toolbox/logbooks.md#caputlog)** — record every write with claimed identity, host, old and new value | Not prevention; essential for reconstruction |

Layer 5 deserves more attention than it gets. `DRVL`/`DRVH` on an `ao` record clamps every write inside the IOC. No client can exceed it, no gateway configuration can weaken it, and it costs one line in a `.db` file. It is the cheapest genuine protection in EPICS and it is routinely left unset.

## Practical patterns

**Default deny for writes, allow all reads.** Reading is almost never the risk, and a read-restricted control system defeats the archiving, alarm, and diagnostic tooling that keeps it alive. Restrict writes; publish reads.

**Group by consequence, not by subsystem.** `ASG(RFEXPERT)` and `ASG(MAGNETEXPERT)` scale badly — you end up with forty groups nobody can reason about. Grouping by *what happens if this is wrong* — `ASG(BEAM_AFFECTING)`, `ASG(EXPERT_ONLY)`, `ASG(READONLY)`, `ASG(OPERATOR)` — stays comprehensible and maps onto how operations actually thinks.

**Put the `.acf` under version control and deploy it centrally.** One file, one owner, distributed to every IOC by configuration management. Per-IOC hand-edited copies diverge, and then the answer to "who can write to this?" is "it depends which IOC, and nobody knows".

**Make the rules visible to operators.** Phoebus widgets grey out when a client lacks write access, because CA reports access rights per channel. That feedback loop is worth a lot: an operator who can see that a control is locked doesn't spend ten minutes wondering why their `caput` had no effect.

**Log every write.** [caPutLog](../toolbox/logbooks.md#caputlog) is not access control, but "which of us changed this at 14:03, and what was it before?" is one of the most frequently asked questions in a control room. Have the answer.

## What to tell your IT security team

They will ask. Honest answers:

- Channel Access has no authentication, authorisation-by-identity, or encryption. It predates the threat model they are used to and was designed for an isolated network.
- The control system's security posture is **network isolation plus physical access control**, not protocol security.
- There is a documented boundary — one read-only gateway — and everything outside the controls network crosses it, in one direction.
- Safety functions do not depend on EPICS at all. Personnel and machine protection are in certified PLCs and hard-wired logic; EPICS displays their state and cannot influence it. See [Machine Protection](../example-facility/machine-protection.md).
- Writes are logged with claimed identity, source host, and old/new value.
- Remote access is via jump host and read-only gateway, never a route into the controls VLAN.

That is a defensible position, honestly stated. Claiming that ASG rules are authentication is not, and it will fail the first time anyone tests it.

## Next

→ [Scaling & Availability](scaling-and-ha.md) — what breaks as the facility grows.
