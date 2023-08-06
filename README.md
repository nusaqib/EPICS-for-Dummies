- [EPICS for Dummies](#epics-for-dummies)
  - [Introduction](#introduction)
  - [Off-the-shelf EPICS control system](#off-the-shelf-epics-control-system)
  - [How To - Build \& Install](#how-to---build--install)
    - [EPICS Base](#epics-base)
    - [Phoebus](#phoebus)
    - [Archiver System](#archiver-system)
    - [Alarm System](#alarm-system)
    - [Channel Finder](#channel-finder)
    - [Phoebus Olog](#phoebus-olog)
    - [PV Web Socket](#pv-web-socket)
    - [Display Builder Web Runtime](#display-builder-web-runtime)
    - [Save-and-restore](#save-and-restore)
    - [Gateway](#gateway)
    - [Soft Modules](#soft-modules)
    - [Hard Modules](#hard-modules)
  - [Tutorials](#tutorials)
  - [Trainings](#trainings)
  - [References](#references)

# EPICS for Dummies

EPICS --> Experimental Physics and Industrial Control System

Are you familiar with EPICS a little bit? Keep reading : [What is EPICS](https://docs.epics-controls.org/en/latest/guides/EPICS_Intro.html)

If you wanna learn EPICS but couldn't understand what is the above line, you're at the right place.

This guide is intended to be a one-stop for an EPICS beginner (including myself) to build and run a complete EPICS infrastructure. At the time of writing, there are lots of components, tools and applications that together build an amazing control system framework that can operate today's most complex machines like Particle Accelerators, Telescopes, Fusion experiments and a lot more (including a small setup at your lap consisting of a single commercial-off-the-shelf equipment).

## Introduction
As someone new to EPICS, one may be coming from a non-software background (like me), and that's perfectly fine. EPICS is designed to be accessible to individuals coming from a wide range of domains like physics, engineering etc. There are lots of components to a complete EPICS control system in production at various research facilities all over the world. This is sometimes overwhelming to a newcomer, hence this guide is intended to provide introduction to EPICS infrastructure, all at one place. Links are provided for further readings from the official repositories and/or other sources.

Initially, intension is to build, configure and run the following (even I don't know how do to this all at the time of writing). We'll be doing this for a test environment as production environment requires expertise which I don't have (hoping one day I'll have that). This list will keep incrementing hopefully to incorporate everything related to EPICS for a beginner.

1. [EPICS base](https://epics-controls.org/resources-and-support/base): "*Lets touch base with EPICS*". EPICS base is the set of core software, i.e. the components of EPICS without which EPICS would not function. EPICS base allows an arbitrary number of target systems, IOCs (input/output controllers), and host systems, OPIs (operator interfaces) of various types.

2. [Phoebus](https://github.com/ControlSystemStudio/phoebus): Phoebus is a framework and a collections of tools to monitor and operate large scale control systems, such as the ones in the particle accelerator community.There is a history of user interface tools in EPICS from MEDM(199x), EDM(200x), CS-Studio(201x) and now Phoebus(202x). Phoebus is an update of the Control System Studio toolset that removes dependencies on Eclipse RCP and SWT.

3. Data Archiver: "*It's strange to have a control system without archiver but it's not strange to have a wife with a perfect archiver system that can retreive mistakes with timestamps from past in matter of seconds*". Data archiving is an essential part of any control system. We will look at the following two implementations of EPICS archivers:
    - [Phoebus RDB Archive Engine Service](https://control-system-studio.readthedocs.io/en/latest/services/archive-engine/doc/index.html)
    - [The EPICS Archiver Appliance](https://slacmshankar.github.io/epicsarchiver_docs/index.html)

4. [Alarm System](https://control-system-studio.readthedocs.io/en/latest/app/alarm/ui/doc/index.html): "*Press Acknowledge all and Reset all, they said...everything will become good, they said*". Alarm system assists operators as they monitor and control the complex systems, and alert them to abnormal situations. The alarm system monitors the alarm state for a configurable list of PVs. When the alarm severity of any PV changes from OK to for example MAJOR, the alarm system changes to that same alarm severity. It consists of three services:
    - [Alarm Server](https://control-system-studio.readthedocs.io/en/latest/services/alarm-server/doc/index.html)
    - [Alarm Logger](https://control-system-studio.readthedocs.io/en/latest/services/alarm-logger/doc/index.html)
    - [Alarm Config Logger](https://control-system-studio.readthedocs.io/en/latest/services/alarm-config-logger/doc/index.html)

5. [Channel Finder](https://channelfinder.github.io/): "*It's always compelling to see how easily everyone agrees on one naming convention*". ChannelFinder is a directory service for EPICS channels. It consists of a few projects:

    - [The Web Service](https://github.com/ChannelFinder/ChannelFinderService): It is implemented as a REST style web service.
    - Client libraries: There are currently [Java](https://github.com/ChannelFinder/javaCFClient) and [python](https://github.com/ChannelFinder/pyCFClient) client libraries available.
    - [Recsync](https://github.com/ChannelFinder/recsync): An EPICS module which enables IOCs to report its list of records to ChannelFinder. The record synchronizer project includes two parts. A client (RecCaster) which runing as part of an EPICS IOC, and a server (RecCeiver) which is a stand alone daemon. Together they work to ensure the the server(s) have a complete list of all records currently provided by the client IOCs.

6. [Phoebus Olog](https://github.com/Olog/phoebus-olog): *Oh look! Wer're logging sensitive information....Don't worry! Nobody will see it* [(geek-and-poke)](https://geek-and-poke.com/geekandpoke/2021/3/16/simply-explained). This is an online logbook for EPICS as logging is also an essential part of an operational facility.

7. [PV Web Socket](https://github.com/ornl-epics/pvws): Web socket for EPICS Process Variables. Used in [Display Builder Web Runtime](https://github.com/ornl-epics/dbwr) and [PV info](https://github.com/ChannelFinder/pvinfo).

8. [Display Builder Web Runtime](https://github.com/ornl-epics/dbwr): This web runtime provides convenient remote access to Phoebus Display Builder OPIs.
    - Use any web browser with zero client-side installation, including smart phones
    - Supports most widgets and their key features

9.  [PV info](https://github.com/ChannelFinder/pvinfo): Web interface to the EPICS Channel Finder database. This interface allows users to query for PVs by wildcard name searches as well as querying by PV meta-data such as IOC name, record type, etc. Also, integrates with almost all essential high-level applications.

10.  [Save-and-restore](https://control-system-studio.readthedocs.io/en/latest/services/save-and-restore/doc/index.html): The save-and-restore service implements service as a collection of REST endpoints. These can be used by clients to manage configurations (aka save sets) and snapshots, to compare snapshots and to restore PV values from snapshots.

11. Gateway: An EPICS gateway helps to reduce the resource load on the server-facing side, and to apply access control restrictions to requests from the client facing side. Following are the EPICS Gateways:
    - [Channel Access PV Gateway](https://github.com/epics-extensions/ca-gateway)
    - [pva2pva PV Access Gateway](https://github.com/epics-base/pva2pva)
    - [PVA Gateway PV Access Gateway](https://mdavidsaver.github.io/p4p/gw.html)


The above components build a reasonably great distributed control system consisting of all essential services required. Now it's time to enhance [EPICS base](https://epics-controls.org/resources-and-support/base) capabilities using [EPICS IOC Support Modules](https://epics-controls.org/resources-and-support/modules). As more device and record support software was written at various EPICS sites to interface to different kinds of hardware, it became obvious that these modules could not all be managed and distributed centrally as part of Base. Since then many of the support layers have been removed from Base and are now maintained separately. Source code for many modules can be found in the [Github epics-modules](https://github.com/epics-modules) project. Depending on the purpose of the modules they are categorized here as:
    
- [Soft Support](https://epics-controls.org/resources-and-support/modules/soft-support): A Soft Support module may contain a new record type, software-only device support, or some other software that runs in the IOC but which is not readily identified with a particular piece of hardware. We'll look at the following soft support modules:
    - [Autosave](https://github.com/epics-modules/autosave/blob/master/docs/autoSaveRestore.md): Automatically saves the values of EPICS process variables (PVs) to files on a server, and restores those values when the IOC (Input-Output Controller — the business end of EPICS) is rebooted.
    - [Sequencer](https://mdavidsaver.github.io/sequencer-mirror): Provides implementation of a finite state machine.
    - [caPutLog](https://github.com/epics-modules/caPutLog/blob/master/docs/index.rst): Provides logging for Channel Access put operations.
    - [iocStats](https://github.com/epics-modules/iocStats): Provides support for records that show the health and status of an IOC, plus a few IOC control records.
    - [Asyn]()
    - [StreamDevice]()
    - [Area Detector]()
    - [Busy]()
- [Hardware Support](https://epics-controls.org/resources-and-support/modules/hardware-support): A Hardware Support module provides software for use within an IOC to control a real-world commercial device. Unless a design is published as Open Hardware and already in use by multiple sites, drivers for site-specific hardware are not appropriate here. Entries provide the manufacturer’s name and module number, a description, the current maintainer’s name and a web-site for the software if one exists.

## Off-the-shelf EPICS control system

## How To - Build & Install

### EPICS Base
### Phoebus
### Archiver System
### Alarm System
### Channel Finder
### Phoebus Olog
### PV Web Socket
### Display Builder Web Runtime
### Save-and-restore
### Gateway
### Soft Modules
### Hard Modules

## Tutorials
This section provides links to existing resources already available and scattered at different places.


## Trainings
This section provides links to existing resources already available and scattered at different places.

## References

