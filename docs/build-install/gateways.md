# Install Gateways

A gateway is how PVs cross a network boundary safely. It collapses connection fan-out and — more importantly — it is the only *reliable* write boundary EPICS has.

Overview and the reasoning: [Toolbox → Gateways](../toolbox/gateways.md).

## CA Gateway

| | |
| --- | --- |
| Source | [github.com/epics-extensions/ca-gateway](https://github.com/epics-extensions/ca-gateway) |

### Build

Needs EPICS Base and the `pcas` (portable Channel Access server) module:

```bash
cd ${HOME}/EPICS
git clone https://github.com/epics-modules/pcas.git
cd pcas
# edit configure/RELEASE to point EPICS_BASE at your Base
make

cd ${HOME}/EPICS
git clone https://github.com/epics-extensions/ca-gateway.git
cd ca-gateway
# edit configure/RELEASE for EPICS_BASE and PCAS
make
```

### Configure

Two files. **`pvlist`** decides what passes and how:

```text
EVALUATION ORDER ALLOW, DENY

# Storage ring: readable by everyone downstream, writable by no one
SR-.*                 ALLOW    RO

# Machine status the beamlines need
HLS-CF-DI-.*          ALLOW    RO
HLS-CF-MPS-.*:.*-Sts  ALLOW    RO

# Nothing else crosses this boundary
.*                    DENY
```

Patterns are regular expressions, matched in file order under the stated evaluation order. `RO` forces read-only regardless of anything the client claims. `RW <group>` permits writes subject to a group defined in the second file.

**`access`** defines those groups, using the same syntax as an IOC's [`.acf`](../architecture/access-security.md):

```text
HAG(beamline7) { bl07-ws1, bl07-ws2 }

ASG(BL7WRITE) {
    RULE(1, READ)
    RULE(1, WRITE) { HAG(beamline7) }
}
```

`pvlist` also supports **name aliasing** by regex substitution, which is occasionally invaluable during a facility rename: old names keep working through the gateway while IOCs serve new ones.

### Run

```bash
gateway -sport 5064 -cport 5064 \
        -pvlist /etc/cagateway/pvlist \
        -access /etc/cagateway/access \
        -log /var/log/cagateway/gateway.log \
        -prefix HLS-CF-GW-01 \
        -server
```

The two sides matter and are easy to get backwards:

- **`-cport` / `-cip`** — the *client* side: which network the gateway searches for PVs on (i.e. toward the IOCs).
- **`-sport` / `-sip`** — the *server* side: which network the gateway serves PVs on (i.e. toward the clients).

On a two-interface host, bind each explicitly. Getting them the wrong way round produces a gateway that finds nothing, or — worse — one that serves the controls network to itself.

`-prefix` gives the gateway's own statistics PVs a name. **Archive and alarm on those**: connected channels, client count, CPU. A saturated gateway degrades everything behind it, and it presents as "the whole control system got slow".

Run it under systemd or [procServ](../toolbox/deployment-and-operations.md#procserv), and rotate its log.

## p4p PVA Gateway

| | |
| --- | --- |
| Documentation | [epics-base.github.io/p4p/gw.html](https://epics-base.github.io/p4p/gw.html) |

The modern PVA gateway, and it can bridge **CA upstream to PVA downstream** — so PVA clients reach CA-only IOCs.

```bash
pip install p4p
python -m p4p.gw /etc/pvagw/gateway.conf
```

Configuration is JSON: the upstream and downstream interfaces, and access-control rules per client group. Consult the documentation for the current schema; the concepts map directly onto the CA gateway's (read-only, pattern matching, per-group rules).

For new PVA deployments, use this rather than [pva2pva](https://github.com/epics-base/pva2pva).

## Deployment patterns

The four standard ones, with reasoning, are in the [toolbox page](../toolbox/gateways.md#deployment-patterns). In brief:

| Pattern | `pvlist` shape |
| --- | --- |
| Read-only export to the office | `.* ALLOW RO`, with explicit denials |
| Accelerator → beamlines | A **curated** prefix list, read-only — not `.*` |
| Load reduction in front of busy IOCs | `.* ALLOW RO` within one zone, no policy purpose |
| Production → development, read-only | `.* ALLOW RO`, so test code can't touch the machine |

## Verify

1. From a client on the downstream network, `caget` a PV that should pass. It should work.
2. `caput` to it. It should **fail** with an access-rights error. Test this deliberately — a gateway you believe is read-only and isn't is worse than no gateway.
3. `caget` a PV that should be denied. It should time out.
4. `cainfo <pv>` from downstream — the reported server should be the *gateway*, not the IOC. If it's the IOC, your client is reaching the controls network directly and the gateway isn't a boundary at all.
5. Check the gateway's statistics PVs.
6. Test a large waveform. Array size limits must agree at the client, the gateway and the IOC; a mismatch truncates silently.

Step 4 is the one people skip, and it's the one that reveals a boundary that only exists on paper.

## Operating it

**Version-control `pvlist` and `access`.** They are security configuration. Reviewed, deployed by configuration management, never edited in place on the server.

**Monitor it.** Statistics PVs, CPU, connection count — archived and alarmed.

**Review the rules when the network changes.** A gateway makes PVs available to everything on its downstream network. If that network is later connected to something else, your boundary moved and nobody updated the gateway.

**Don't chain deeply.** One hop between zones, two if you must. Three means somebody should redraw the network diagram.

## Worked example

The [Helios network design](../example-facility/network-design.md) shows a complete gateway topology for a facility: which zones exist, which gateways connect them, what each one exports, and why.

## Next

→ [Containers](containers.md), the modern alternative to all of this hand-assembly.
