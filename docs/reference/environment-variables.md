# Environment Variables

More than half of "EPICS doesn't work" is an environment problem. Authoritative list: [Channel Access Reference Manual](https://epics.anl.gov/base/R3-14/8-docs/CAref.html) and the [Application Developer's Guide](https://docs.epics-controls.org/en/latest/appdevguide/AppDevGuide.html).

## Build and installation

| Variable | Purpose |
| --- | --- |
| `EPICS_BASE` | Where Base is installed. Tools and scripts read it from the environment; module Makefiles read it from `configure/RELEASE`. |
| `EPICS_HOST_ARCH` | Your platform triple, e.g. `linux-x86_64`. Base installs into architecture-specific directories, so this is how binaries are found. Compute it with `$EPICS_BASE/startup/EpicsHostArch`, don't guess. |
| `PATH` | Must include `$EPICS_BASE/bin/$EPICS_HOST_ARCH` |
| `LD_LIBRARY_PATH` | Sometimes needed for `$EPICS_BASE/lib/$EPICS_HOST_ARCH`, depending on how things were built |

## Channel Access: client side

| Variable | Default | Notes |
| --- | --- | --- |
| `EPICS_CA_ADDR_LIST` | *(empty)* | Space-separated addresses to send name searches to: subnet broadcast addresses, unicast hosts, or `host:port`. **Set this on any routed network.** |
| `EPICS_CA_AUTO_ADDR_LIST` | `YES` | `YES` also broadcasts on every local interface. Set `NO` when your list is deliberate, otherwise behaviour depends on which interfaces the host happens to have. |
| `EPICS_CA_CONN_TMO` | `30.0` | Seconds before a quiet connection is declared dead |
| `EPICS_CA_BEACON_PERIOD` | `15.0` | Expected server beacon interval |
| `EPICS_CA_MAX_ARRAY_BYTES` | see note | Historic cause of truncated arrays. Modern Base sizes buffers dynamically, but old clients, old IOCs and [gateways](../toolbox/gateways.md) may still need it raised — **on every hop**. |
| `EPICS_CA_MAX_SEARCH_PERIOD` | `300` | Cap on the search retry backoff |
| `EPICS_CA_SERVER_PORT` | `5064` | Changing it creates an isolated EPICS "universe" |
| `EPICS_CA_REPEATER_PORT` | `5065` | Where `caRepeater` listens |
| `EPICS_CA_NAME_SERVERS` | *(empty)* | Unicast TCP name servers, as an alternative to broadcast search |
| `EPICS_CA_AUTO_ARRAY_BYTES` | `YES` | Let the client size array buffers automatically |

## Channel Access: server side

The ones that matter on multi-homed IOC hosts, which is most of them at a facility.

| Variable | Notes |
| --- | --- |
| `EPICS_CAS_INTF_ADDR_LIST` | Which interfaces the CA server listens on. **Without this, an IOC may serve on the management network and not the controls network** — reachable from some places and not others, with no obvious pattern. |
| `EPICS_CAS_BEACON_ADDR_LIST` | Where beacons are sent. Clients that don't get beacons reconnect slowly after an IOC restart. |
| `EPICS_CAS_IGNORE_ADDR_LIST` | Addresses whose searches are ignored |
| `EPICS_CAS_AUTO_BEACON_ADDR_LIST` | Automatic beacon addresses |
| `EPICS_CAS_SERVER_PORT` | Server port, if not 5064 |
| `EPICS_CA_SERVER_PORT` | Also read by servers when the `CAS_` variant is unset |

## PV Access

| Variable | Notes |
| --- | --- |
| `EPICS_PVA_ADDR_LIST` | Client search addresses |
| `EPICS_PVA_AUTO_ADDR_LIST` | As the CA equivalent |
| `EPICS_PVA_SERVER_PORT` | Default `5075` (TCP) |
| `EPICS_PVA_BROADCAST_PORT` | Default `5076` (UDP search and beacons) |
| `EPICS_PVA_CONN_TMO` | Connection timeout |
| `EPICS_PVAS_INTF_ADDR_LIST` | Server-side interface list |
| `EPICS_PVAS_BEACON_ADDR_LIST` | Server-side beacon addresses |
| `EPICS_PVA_NAME_SERVERS` | Unicast name servers |

## IOC behaviour

| Variable | Notes |
| --- | --- |
| `EPICS_IOC_LOG_INET` / `EPICS_IOC_LOG_PORT` | Host and port of an `iocLogServer` to send `errlog` messages to |
| `EPICS_IOC_LOG_FILE_NAME` / `_LIMIT` | Log file and size limit |
| `EPICS_TIMEZONE` | Timezone for timestamp formatting. **Run infrastructure in UTC.** |
| `EPICS_TS_NTP_INET` | NTP server for timestamp support on some targets |
| `IOCSH_PS1` | The IOC shell prompt |
| `IOCSH_HISTSIZE` | Shell history length |

## Common configurations

=== "A flat lab network"

    ```bash
    export EPICS_BASE=${HOME}/EPICS/base
    export EPICS_HOST_ARCH=$(${EPICS_BASE}/startup/EpicsHostArch)
    export PATH=${EPICS_BASE}/bin/${EPICS_HOST_ARCH}:${PATH}
    ```

    Nothing else. Broadcast discovery works on a single subnet, which is why every tutorial omits this topic.

=== "A routed facility network"

    ```bash
    export EPICS_CA_AUTO_ADDR_LIST=NO
    export EPICS_CA_ADDR_LIST="10.10.1.255 10.10.2.255 10.30.1.255"
    export EPICS_PVA_AUTO_ADDR_LIST=NO
    export EPICS_PVA_ADDR_LIST="10.10.1.255 10.10.2.255 10.30.1.255"
    ```

    Distributed by a per-zone site script, never set per user. See [network design](../example-facility/network-design.md#client-configuration).

=== "Behind a gateway only"

    ```bash
    export EPICS_CA_AUTO_ADDR_LIST=NO
    export EPICS_CA_ADDR_LIST="10.50.1.10"       # the gateway, and nothing else
    export EPICS_CA_MAX_ARRAY_BYTES=10000000
    ```

    A one-address list is the point: this client's entire view of the facility is what the gateway chooses to show it.

=== "A multi-homed IOC host"

    ```bash
    export EPICS_CAS_INTF_ADDR_LIST="10.10.1.42"          # controls interface only
    export EPICS_CAS_BEACON_ADDR_LIST="10.10.1.255 10.30.1.255"
    export EPICS_PVAS_INTF_ADDR_LIST="10.10.1.42"
    ```

=== "An isolated test system"

    ```bash
    export EPICS_CA_SERVER_PORT=5164
    export EPICS_CA_REPEATER_PORT=5165
    export EPICS_PVA_SERVER_PORT=5175
    export EPICS_PVA_BROADCAST_PORT=5176
    ```

    A complete second universe on the same wire. Genuinely useful, and a memorable way to make PVs invisible if you forget you did it.

=== "A container"

    ```bash
    # IOC container: host networking, because broadcast discovery
    # does not survive NAT
    docker run --network host ...

    # Client container: bridge is fine with an explicit unicast list
    docker run -e EPICS_CA_AUTO_ADDR_LIST=NO \
               -e EPICS_CA_ADDR_LIST="10.10.1.42 10.10.1.43" ...
    ```

    See [Containers](../build-install/containers.md).

## Where these should live

| Scope | Where |
| --- | --- |
| Learning | `~/.bashrc` or `~/.profile` |
| A facility | One site script per network zone (`/etc/profile.d/epics.sh`), or environment modules, deployed by configuration management |
| An IOC | `st.cmd`, or the systemd unit / container environment |
| A Java service | Its properties file *and* the process environment — [Phoebus preferences can override the environment](../build-install/phoebus.md#point-it-at-your-pvs), which is a confusing failure |
| Tomcat-hosted services | `$CATALINA_HOME/bin/setenv.sh` — [the usual reason a fresh PVWS shows nothing](../build-install/pvws.md#configure-epics-access) |

!!! warning "Per-user environment archaeology is a facility-scale hazard"
    When every user's `.bashrc` differs, "it works on my machine" becomes unanswerable. One script per zone, owned centrally, is the only arrangement that stays correct.

## Debugging environment problems

```bash
env | grep EPICS                    # what is actually set, in THIS shell
cainfo PV                           # which server answered? from which address?
caget -w 2 PV                       # short timeout, so failure is quick

# Does it work with an explicit address? If yes, your address list is the problem.
EPICS_CA_AUTO_ADDR_LIST=NO EPICS_CA_ADDR_LIST=10.10.1.42 caget PV
```

That last line is the single most useful diagnostic on this page. If a PV is unreachable normally and reachable with an explicit address, the problem is discovery, not the IOC.

More: [Troubleshooting](troubleshooting.md) and [Networking](../architecture/networking.md).
