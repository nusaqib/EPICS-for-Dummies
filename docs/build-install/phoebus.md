- [How To build and install Phoebus](#how-to-build-and-install-phoebus)
  - [Pre-requisites](#pre-requisites)
      - [Building Phoebus:](#building-phoebus)
      - [Other](#other)
  - [Build \& Install](#build--install)
  - [Run Phoebus](#run-phoebus)


# How To build and install Phoebus

[Phoebus installation - Github](https://github.com/ControlSystemStudio/phoebus)

## Pre-requisites
#### Building Phoebus:
- JDK 11 or late
- maven 3.x or ant

We'll build with maven.

#### Other
- git

Hopefully [requirements](../../scripts/Phoebus/install_requirements.sh) should install these on Debian and Red-Hat distributions.

## Build & Install
We'll be installing Phoebus in ${HOME} directory.

- Clone the source code of Phoebus
~~~bash
git clone https://github.com/ControlSystemStudio/phoebus.git
~~~

- Obtaining external dependencies

```bash
mvn clean verify -f dependencies/pom.xml
```

- Define Environment variables
    - JAVA_HOME variable should point to JDK installation directory. In my case:
```bash
export JAVA_HOME = /usr/lib/jvm/<java-1.xxxx>
```

- Build with maven
```bash
mvn clean install
```
Congratulations if you saw *BUILD SUCCESS* at your terminal.

Building phoebus also builds the following services:
- RDB Archiver System
- Alarm Server
- Alarm Logger
- Alarm Config Logger
- Save and Restore
- Scan Server

## Run Phoebus
```bash
cd phoebus-product/target
java -jar product-*-SNAPSHOT.jar
```