
## Pre-requisites
- JDK/JRE (JAVA_HOME needs to be defined)

## Configure & Install
- Download tomcat from [Tomcat download](https://tomcat.apache.org/download-90.cgi)

```
tar zxvf apache-tomcat-x.x.x.tar.gz/
cd apache-tomcat-x.x.x/
cd bin/
```

- Start the tomcat server by running `./startup.sh`

- Open web browser and type http://localhost:8080 and you'll see the Apache Tomcat page.

- Shutdown the tomcat server by running `bin/shutdown.sh` when needed.

## Miscellaneous

- To open `Manager App` to see/start/stop applications, edit conf/tomcat-users.xml and uncomment the following line. Change password according to your choice.

```
<user username="admin" password="tomcat" roles="manager-gui"/>
```