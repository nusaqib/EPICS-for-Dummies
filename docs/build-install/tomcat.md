# Apache Tomcat

The servlet container that hosts the WAR-file services: [PVWS](pvws.md), [DBWR](dbwr.md), and the [Archiver Appliance](archiver-appliance.md).

Upstream: [tomcat.apache.org](https://tomcat.apache.org/)

## Prerequisites

- A [JDK](jdk.md) with `JAVA_HOME` set.

Check which Tomcat major version each service wants before choosing — the Archiver Appliance in particular has specific requirements, so read its documentation rather than defaulting to the newest release.

## Install

Two routes.

=== "Tarball (recommended for learning)"

    Download the current release of your chosen major version from the [Tomcat download pages](https://tomcat.apache.org/), then:

    ```bash
    cd /opt
    sudo tar zxvf ~/Downloads/apache-tomcat-*.tar.gz
    sudo ln -s /opt/apache-tomcat-* /opt/tomcat
    export CATALINA_HOME=/opt/tomcat
    ```

    Everything is under one directory, which makes it obvious what belongs to Tomcat and trivial to remove.

=== "Distribution package"

    ```bash
    sudo apt install tomcat10        # Debian/Ubuntu; name varies by release
    ```

    You get systemd integration and security defaults, at the cost of a layout spread across `/etc`, `/var/lib` and `/usr/share`, which the service documentation you're following probably doesn't assume.

## Start and stop

```bash
$CATALINA_HOME/bin/startup.sh      # start
$CATALINA_HOME/bin/shutdown.sh     # stop
tail -f $CATALINA_HOME/logs/catalina.out
```

Then open <http://localhost:8080> — the Tomcat welcome page means it's working.

**`catalina.out` is where deployment failures appear.** A WAR that doesn't work almost always logged the reason there, and reading it first will save you a lot of guessing.

## Deploy a WAR

```bash
cp pvws.war $CATALINA_HOME/webapps/
```

Tomcat auto-deploys: it unpacks `pvws.war` into `webapps/pvws/` and serves it at `/pvws`. **The WAR filename becomes the URL path**, so renaming the file changes the URL — which matters when a service's own documentation gives absolute paths.

Undeploy by removing both the `.war` and its unpacked directory.

## The Manager app

Useful for start/stop/reload without touching the filesystem. Edit `conf/tomcat-users.xml`:

```xml
<role rolename="manager-gui"/>
<user username="admin" password="CHANGE-THIS" roles="manager-gui"/>
```

Restart, then <http://localhost:8080/manager/html>.

!!! danger "Never leave the default credentials"
    A Tomcat Manager reachable with `admin`/`tomcat` is remote code execution as the Tomcat user — deploy a WAR, run anything. Internet-facing Tomcats with default credentials are compromised within hours by automated scanning.

    On any machine that isn't your laptop: use a strong password, restrict the Manager to localhost (`conf/Catalina/localhost/manager.xml` with a `RemoteAddrValve`), or don't enable it at all.

## Configuration you'll touch

| File | Purpose |
| --- | --- |
| `conf/server.xml` | Ports (8080 HTTP, 8443 HTTPS, 8005 shutdown), connectors, TLS |
| `conf/tomcat-users.xml` | Manager credentials |
| `conf/context.xml` | JNDI resources — database connection pools for the services |
| `bin/setenv.sh` | `JAVA_OPTS` for heap size and system properties. Create it; it isn't there by default. |
| `logs/catalina.out` | Where you look when something doesn't work |

Heap size, in `bin/setenv.sh` — the default is too small for the Archiver Appliance and for a PVWS holding many channels:

```bash
export JAVA_OPTS="-Xms1g -Xmx4g"
```

Service-specific system properties also go here, which is how the Archiver Appliance is configured.

## Running it properly

For anything beyond a laptop:

**Don't run Tomcat as root.** Create a dedicated user, `chown` the installation to it. If Tomcat must bind port 80/443, use a reverse proxy rather than root or `setcap`.

**Put nginx or Apache in front.** TLS termination, authentication (SSO/OIDC), rate limiting, and static-file serving all belong there, not in Tomcat. This is also where you enforce the read-only, authenticated boundary that the [web interfaces](../toolbox/web-interfaces.md) assume.

**Manage it with systemd.** A unit file with `Type=forking` pointing at `startup.sh`/`shutdown.sh`, or `Type=simple` with `catalina.sh run`, so it starts at boot and restarts on failure.

**Set the heap deliberately** and monitor it. An OOM-killed Tomcat takes every service on it down at once.

**One Tomcat per service, or one for all?** For a facility, separate instances (or containers) per service: independent restarts, independent heap tuning, and one service's memory leak doesn't take down the others. For learning, one Tomcat with several WARs is much less work.

## Next

→ [PVWS](pvws.md), [DBWR](dbwr.md), or the [Archiver Appliance](archiver-appliance.md).
