# How To build and install DBWR (Display Builder Web Runtime)

- [Display Builder Web Runtime - GitHub](https://github.com/ornl-epics/dbwr)

## Pre-requisites

- Maven
- Tomcat
    - See [Tomcat installation and configuration](./Tomcat.md)

## Build & Install

- Clone the source code of EPICS base
~~~bash
git clone https://github.com/ornl-epics/dbwr.git
~~~

- Build
~~~bash
mvn clean package
~~~

Upon `BUILD SUCCESS`, the deployable file will be in `target/dbwr.war`. Place `dbwr.war` in `$CATALINA_HOME/webapps`

PVWS can now be accessed at http://localhost:8080/dbwr