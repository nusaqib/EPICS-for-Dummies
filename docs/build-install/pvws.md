# How To build and install PVWS (PV Web Socket)

- [PV Web Socket - GitHub](https://github.com/ornl-epics/pvws)

## Pre-requisites

- Maven
- Tomcat
    - See [Tomcat installation and configuration](./Tomcat.md)

## Build & Install

- Clone the source code of EPICS base
~~~bash
git clone https://github.com/ornl-epics/pvws.git
~~~

- Build
~~~bash
mvn clean package
~~~

Upon `BUILD SUCCESS` The deployable file will be in `target/pvws.war`. Place `pvws.war` in `$CATALINA_HOME/webapps`

PVWS can now be accessed at http://localhost:8080/pvws
