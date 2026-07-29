# Install DBWR (Display Builder Web Runtime)

Renders your existing [Phoebus](phoebus.md) Display Builder files in a browser. No client install, works on phones, and — crucially — **the same `.bob` files** as the control room.

Overview: [Toolbox → DBWR](../toolbox/web-interfaces.md#dbwr-display-builder-web-runtime).

| | |
| --- | --- |
| Source | [github.com/ornl-epics/dbwr](https://github.com/ornl-epics/dbwr) |
| Origin | ORNL (Kay Kasemir) |
| Training | [Display Web Runtime](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/06%20Display%20Web%20Runtime.pdf) (USPAS) |

## Prerequisites

- [JDK](jdk.md) and Maven
- [Tomcat](tomcat.md)
- **[PVWS](pvws.md) deployed and working** — DBWR gets its live data through PVWS, so verify PVWS first. Debugging DBWR before PVWS works is debugging two things at once.
- Somewhere for it to read `.bob` files from: a filesystem path, or an HTTP URL

## Build

```bash
git clone https://github.com/ornl-epics/dbwr.git
cd dbwr
mvn clean package
```

`BUILD SUCCESS` leaves `target/dbwr.war`.

## Deploy

```bash
cp target/dbwr.war $CATALINA_HOME/webapps/
tail -f $CATALINA_HOME/logs/catalina.out
```

Then <http://localhost:8080/dbwr>.

## Configure

DBWR needs two things: where PVWS is, and where the display files are. Both are set in its configuration as described in the repository's README — check there for the current property names, since these have moved between releases.

The essentials:

| Setting | Purpose |
| --- | --- |
| PVWS URL | Where to get live data. Must be reachable **from the browser**, not just from Tomcat — this is a common misconfiguration. |
| Display file root | A filesystem path or base URL under which `.bob` files are found |
| Default display | What loads at the bare URL |

Opening a specific display, with macros:

```text
http://dbwr.example.org:8080/dbwr/view.html?display=/sr/vacuum_cell.bob&CELL=05
```

Macro arguments in the query string work the same way as they do in Phoebus, which means a single templated display serves twenty cells from twenty URLs.

## Serving displays over HTTP

Keeping display files in git and serving them from a web server (or fetching them from a GitLab/GitHub raw URL) is worth doing:

- One source of truth shared by Phoebus and DBWR.
- Version history for screens, which are configuration and deserve it.
- No filesystem coupling between the DBWR host and your display repository.

Phoebus itself can open `.bob` files over HTTP too, so both runtimes read from exactly the same place.

## Verify

1. Open a simple display you built in Phoebus. Widgets should render and values should update.
2. Change a PV with `caput` and confirm the browser updates.
3. Stop the IOC and confirm widgets show disconnected — not a frozen last value.
4. Open it on a phone on the same network.
5. Try one of your **complex** displays. Note what doesn't work; see below.

## Known limitations

DBWR supports most widgets and their key features, not all of them. Complex scripted displays, unusual widget properties, and embedded custom rules may not translate.

The practical approach: **test the specific displays you care about**, and where something doesn't render, either simplify that display or make a separate web-oriented version. Don't assume parity, and don't discover the gap when someone is relying on it remotely.

## Deploy it safely

Same posture as [PVWS](pvws.md#deploy-it-safely), because DBWR's reach is PVWS's reach:

```text
Browser ──HTTPS──> nginx (TLS + SSO) ──> DBWR + PVWS ──> read-only gateway ──> IOCs
```

- Read-only gateway between the web tier and the controls network. Always.
- TLS and authentication at the reverse proxy.
- Remember that a display's *appearance* of being read-only is not a control. The gateway is the control.

## Why this is worth the effort

Most facilities end up needing some web view of the machine, and the usual outcome is a second, parallel set of screens that diverges from the control room's within a year.

DBWR removes that failure mode: one set of `.bob` files, maintained once, rendered in both places. The on-call engineer at home sees exactly what the operator sees. That property is worth more than the feature list suggests.

## Next

→ [PV Info](pvinfo.md), or [Gateways](gateways.md) to build the boundary these services assume.
