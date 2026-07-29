# Install PVWS (PV Web Socket)

The WebSocket bridge that lets browsers read PVs. Foundation for [DBWR](dbwr.md) and for any custom web dashboard.

Overview: [Toolbox → PVWS](../toolbox/web-interfaces.md#pvws-pv-web-socket).

| | |
| --- | --- |
| Source | [github.com/ornl-epics/pvws](https://github.com/ornl-epics/pvws) |
| Origin | ORNL |

## Prerequisites

- [JDK](jdk.md) and Maven
- [Tomcat](tomcat.md)
- Network reachability from the Tomcat host to your IOCs — **this is the part that catches people out**, see below

## Build

```bash
git clone https://github.com/ornl-epics/pvws.git
cd pvws
mvn clean package
```

`BUILD SUCCESS` leaves the deployable at `target/pvws.war`.

## Deploy

```bash
cp target/pvws.war $CATALINA_HOME/webapps/
tail -f $CATALINA_HOME/logs/catalina.out     # watch it deploy
```

Then <http://localhost:8080/pvws> — the bundled demo page lets you subscribe to a PV name and watch values arrive.

## Configure EPICS access

PVWS is a Channel Access and PV Access **client**, so it needs the same environment any client needs. This is the single most common reason a fresh PVWS shows nothing.

Set the EPICS variables for the Tomcat process — in `$CATALINA_HOME/bin/setenv.sh`:

```bash
export EPICS_CA_ADDR_LIST="10.1.5.255 10.1.6.255"
export EPICS_CA_AUTO_ADDR_LIST=NO
export EPICS_CA_MAX_ARRAY_BYTES=10000000
export EPICS_PVA_ADDR_LIST="10.1.5.255 10.1.6.255"
export EPICS_PVA_AUTO_ADDR_LIST=NO
```

Restart Tomcat after changing it. Verify with a PV you know exists — if `caget` works from a shell on that host but PVWS doesn't see the PV, the variables aren't reaching the Tomcat process. See [Networking](../architecture/networking.md).

Other configurable items, per the project's README, include the maximum array size and the maximum number of PVs per session — both worth setting deliberately rather than discovering.

## Use it

```javascript
const ws = new WebSocket("wss://pvws.example.org/pvws/pv");

ws.onopen = () => ws.send(JSON.stringify({
    type: "subscribe",
    pvs: ["SR-CF-DI-DCCT-01:Current-Mon", "SR-CF-RF-CAV-01:Volt-Mon"]
}));

ws.onmessage = (event) => {
    const msg = JSON.parse(event.data);
    // msg.pv, msg.value, msg.severity, msg.seconds, msg.units, ...
    console.log(msg.pv, msg.value, msg.severity);
};
```

The message protocol is documented in the repository. Note that the first message for a PV carries its metadata (units, precision, limits, enum labels) and subsequent messages carry values — so cache the metadata rather than expecting it every time.

**Always display severity.** A dashboard showing a number with no indication that it's `INVALID` will eventually mislead somebody about the state of the machine.

## Deploy it safely

This is the component most likely to end up reachable from outside the controls network, so the boundary matters more here than anywhere else in this section.

```text
Browser ──HTTPS/WSS──> nginx (TLS + SSO) ──> Tomcat/PVWS ──CA──> read-only gateway ──> IOCs
```

- **Behind a [read-only gateway](gateways.md), always.** Everything the browser can reach, PVWS can reach. Making "read-only" a topological fact rather than a configuration setting is the whole point.
- **TLS and authentication at the reverse proxy.** PVWS is not an identity system.
- **Watch the PV count.** One PVWS holding tens of thousands of channels for a handful of dashboards is a common accident — usually a page subscribing to everything and rendering a fraction.
- **Set array limits consistently** at the client, PVWS, the gateway and the IOC. A mismatch silently truncates arrays and looks like data corruption.

## Verify

1. Subscribe to a PV from the demo page and change it with `caput`.
2. Confirm the value and the severity both update.
3. Stop the IOC — the browser should see a disconnect, not a frozen value.
4. Check `catalina.out` for CA connection warnings.

Step 3 matters: a web dashboard that keeps showing the last value after the IOC dies is worse than one that shows nothing.

## Next

→ [DBWR](dbwr.md), which turns PVWS into a full display runtime.
