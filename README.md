- [EPICS for Dummies](#epics-for-dummies)
  - [Introduction](#introduction)
    - [Getting Started with EPICS Ecosystem](#getting-started-with-epics-ecosystem)
    - [EPICS IOC Support Modules](#epics-ioc-support-modules)
    - [EPICS Extensions](#epics-extensions)
  - [Off-the-shelf EPICS control system](#off-the-shelf-epics-control-system)
  - [How To - Build \& Install](#how-to---build--install)
    - [EPICS Base](#epics-base)
    - [Phoebus](#phoebus)
    - [Channel Finder](#channel-finder)
    - [Phoebus Olog](#phoebus-olog)
    - [PV Web Socket](#pv-web-socket)
    - [Display Builder Web Runtime](#display-builder-web-runtime)
    - [Gateway](#gateway)
    - [PV Info](#pv-info)
    - [Soft Modules](#soft-modules)
    - [Hard Modules](#hard-modules)
    - [VDCT](#vdct)
    - [procServ](#procserv)
  - [Tutorials](#tutorials)
  - [Trainings/Resources](#trainingsresources)
    - [References](#references)
    - [2022 USPAS + 2022 EPICS Collaboration Meeting](#2022-uspas--2022-epics-collaboration-meeting)
      - [EPICS (General)](#epics-general)
      - [IOC/Database](#iocdatabase)
      - [User Interface](#user-interface)
      - [Network Protocols - Channel Access/PV Access](#network-protocols---channel-accesspv-access)
      - [Central Services](#central-services)
      - [Modules](#modules)
      - [Clients/Servers](#clientsservers)
      - [Device Support](#device-support)
  - [Explanations](#explanations)
  - [References](#references-1)

# EPICS for Dummies

EPICS --> Experimental Physics and Industrial Control System

Are you familiar with EPICS a little bit? Keep reading : [What is EPICS](https://docs.epics-controls.org/en/latest/guides/EPICS_Intro.html)

If you wanna learn EPICS but couldn't understand what is the above line, you're at the right place.

This guide is intended to be a one-stop for an EPICS beginner (including myself) to build and run a complete EPICS infrastructure. At the time of writing, there are lots of components, tools and applications that together build an amazing control system framework that can operate today's most complex machines like Particle Accelerators, Telescopes, Fusion experiments and a lot more (including a small setup at your lap consisting of a single commercial-off-the-shelf equipment).

## Introduction
As someone new to EPICS, one may be coming from a non-software background (like me), and that's perfectly fine. EPICS is designed to be accessible to individuals coming from a wide range of domains like physics, engineering etc. There are lots of components to a complete EPICS control system in production at various research facilities all over the world. This is sometimes overwhelming to a newcomer, hence this guide is intended to provide introduction to EPICS infrastructure, all at one place. Links are provided for further readings from the official repositories and/or other sources.

Initially, intension is to build, configure and run the following (even I don't know how do to this all at the time of writing). We'll be doing this for a test environment as production environment requires expertise which I don't have (hoping one day I'll have that). This list will keep incrementing hopefully to incorporate everything related to EPICS for a beginner.

### Getting Started with EPICS Ecosystem

1. [EPICS base](https://epics-controls.org/resources-and-support/base): "*Lets touch base with EPICS*". EPICS base is the set of core software, i.e. the components of EPICS without which EPICS would not function. EPICS base allows an arbitrary number of target systems, IOCs (input/output controllers), and host systems, OPIs (operator interfaces) of various types.

2. [Phoebus](https://github.com/ControlSystemStudio/phoebus): Phoebus is a framework and a collections of tools to monitor and operate large scale control systems, such as the ones in the particle accelerator community.There is a history of user interface tools in EPICS from MEDM(199x), EDM(200x), CS-Studio(201x) and now Phoebus(202x). Phoebus is an update of the Control System Studio toolset that removes dependencies on Eclipse RCP and SWT.

3. Data Archiver: "*It's strange to have a control system without archiver but it's not strange to have a wife with a perfect archiver system that can retreive your mistakes with timestamps from past in matter of seconds*". Data archiving is an essential part of any control system. We will look at the following two implementations of EPICS archivers:
    - [Phoebus RDB Archive Engine Service](https://control-system-studio.readthedocs.io/en/latest/services/archive-engine/doc/index.html)
    - [The EPICS Archiver Appliance](https://slacmshankar.github.io/epicsarchiver_docs/index.html)

4. [Alarm System](https://control-system-studio.readthedocs.io/en/latest/app/alarm/ui/doc/index.html): "*Press Acknowledge all & Reset all, they said...everything will become OK, they said*". Alarm system assists operators as they monitor and control the complex systems, and alert them to abnormal situations. The alarm system monitors the alarm state for a configurable list of PVs. When the alarm severity of any PV changes from OK to for example MAJOR, the alarm system changes to that same alarm severity. It consists of three services:
    - [Alarm Server](https://control-system-studio.readthedocs.io/en/latest/services/alarm-server/doc/index.html)
    - [Alarm Logger](https://control-system-studio.readthedocs.io/en/latest/services/alarm-logger/doc/index.html)
    - [Alarm Config Logger](https://control-system-studio.readthedocs.io/en/latest/services/alarm-config-logger/doc/index.html)

5. [Channel Finder](https://channelfinder.github.io/): "*It's always compelling to see how easily everyone agrees on one naming convention*". ChannelFinder is a directory service for EPICS channels. It consists of a few projects:

    - [The Web Service](https://github.com/ChannelFinder/ChannelFinderService): It is implemented as a REST style web service.
    - Client libraries: There are currently [Java](https://github.com/ChannelFinder/javaCFClient) and [python](https://github.com/ChannelFinder/pyCFClient) client libraries available.
    - [Recsync](https://github.com/ChannelFinder/recsync): An EPICS module which enables IOCs to report its list of records to ChannelFinder. The record synchronizer project includes two parts. A client (RecCaster) which runing as part of an EPICS IOC, and a server (RecCeiver) which is a stand alone daemon. Together they work to ensure the the server(s) have a complete list of all records currently provided by the client IOCs.

6. [Phoebus Olog](https://github.com/Olog/phoebus-olog): "*Oh look! Wer're logging sensitive information....Don't worry! Nobody will see it*" [(geek-and-poke)](https://geek-and-poke.com/geekandpoke/2021/3/16/simply-explained). This is an online logbook for EPICS as logging is also an essential part of an operational facility.

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

### [EPICS IOC Support Modules](https://epics-controls.org/resources-and-support/modules)
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

### [EPICS Extensions](https://epics-controls.org/resources-and-support/extensions)
EPICS Host tools and client software are known in the community as Extensions. Except EPICS Base and IOC support modules, all the above mentioned components lie under EPICS extensions. We'll look at the following extensions:
- [VDCT (Visual Database Configuration Tool)](https://github.com/epics-extensions/VisualDCT): Visual Database Configuration Tool (VisualDCT) is an EPICS database configuration tool which was developed to provide features missing in existing configuration tools such as Capfast and Graphical Database Configuration Tool (GDCT). VisualDCT has a powerful DB parser, which allows importing existing DB and DBD files. Output file is also DB file, all comments and record order is preserved and visual data saved as comment, which allows DBs to be edited in other tools or manually.
- [procServ](https://github.com/ralphlange/procServ): 
- [Fault Tree](https://controlssoftware.sns.ornl.gov/ftree): The idea is to use a Mind-Mapping tool like "FreeMind", which is basically a tree editor, to document dependencies between various inputs and subsystems and the overall "System OK" status.

## Off-the-shelf EPICS control system
Follow guidelines in [2022 USPAS EPICS](https://controlssoftware.sns.ornl.gov/training/2022_USPAS) or [EPICS Collaboration Meeting 2022 PV Access Workshop](https://controlssoftware.sns.ornl.gov/training/2022_EPICS) to setup a VirtualBox VM containing a complete EPICS Control System. PDFs/PPTs at these two links contain major portion of [Tutorials section](#tutorials).

Do you wanna try building the control system yourself? [Sure thing](#how-to---build--install) : [What are you talking about](#tutorials)

## How To - Build & Install

For now, the operating system is assumed to be Linux. I am using Debian 12 VM.

### [EPICS Base](./docs/build_install/Base.md)
### [Phoebus](./docs/build_install/Phoebus.md)
- RDB Archiver System
- Alarm System
- Save-and-restore
### [Channel Finder]()
### [Phoebus Olog]()
### [PV Web Socket]()
### [Display Builder Web Runtime]()
### [Gateway]()
### [PV Info]()
### [Soft Modules]()
### [Hard Modules]()
### [VDCT]()
### [procServ]()

## Tutorials

## Trainings/Resources
### References
- [EPICS Official Website](https://epics-controls.org/resources-and-support/documents/training)
- [SNS Controls EPICS Training Resources](https://controlssoftware.sns.ornl.gov/training)
- [EPICS Collaboration Meetings](https://epics-controls.org/news-and-events/meetings)
- [EPICS Codeathons/Documentathons](https://epics-controls.org/news-and-events/codeathons)

After having installed kind of complete EPICS control system, we are ready to play and explore what it really is, how much power does it contain...

### [2022 USPAS + 2022 EPICS Collaboration Meeting](https://controlssoftware.sns.ornl.gov/training/2022_USPAS)
[Use the ready made VM](#off-the-shelf-epics-control-system)
#### EPICS (General)
- [Overview](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/01%20Overview.pdf)

#### IOC/Database
- [Database](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/02%20EPICS%20Database.pdf)
- [Database Exercise](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/02e%20EPICS%20Database%20Exercises.pdf)
- [Database Updates](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/12%20EPICS%20Database%20Updates.pdf)
- [makeBaseApp](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/07%20makeBaseApp.pdf)
- [Access Security](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/11%20CA%20Security.pdf)
- [Access Security Lab](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/11l%20CA%20Security%20Lab.pdf)
- [DB Interlocks](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/20b%20DB%20Interlocks.pdf)
- [Automation](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/13%20EPICS%20Automation.pdf)

#### User Interface
- [User Interfaces](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/03%20User%20Interfaces.pdf)
- [CS Studio](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/04%20CS-Studio.pdf)
- [Database UI First Steps](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/04a%20DataBase%20UI%20First%20Steps.pdf)
- [Display Builder](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/05%20Display%20Builder.pdf)

#### Network Protocols - Channel Access/PV Access
- [Channel Access](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/10%20Channel%20Access.pdf)
- [CA vs PVA vs Records](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/10a%20CA%20vs%20Records%20vs%20CAS.pdf)
- [PV Access](https://controlssoftware.sns.ornl.gov/training/2022_EPICS/Presentations/1%20PV%20Access%20EPICS.pdf)
- [PV Access Java API](https://controlssoftware.sns.ornl.gov/training/2022_EPICS/Presentations/2%20PV%20Access%20Java.pdf)

#### Central Services
- [Archiver Systems](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/19%20Archive.pdf)
- [Alarm System](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/20%20Alarm%20System.pdf)
- [Alarm Guidelines](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/20a%20Alarm%20Guidelines.pdf)
- [Channel Finder](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/26%20Channel%20Finder.pdf)
- [PVA Gateway](https://controlssoftware.sns.ornl.gov/training/2022_EPICS/Presentations/3%20PVA%20Gateway.pdf)
- [Display Builder Web Runtime](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/06%20Display%20Web%20Runtime.pdf)

#### Modules
- [Asyn](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/18_Asyn.pdf)
- [Stream Device](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/08%20Stream%20Device.pdf)
- [Stream Device Lab](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/08l%20Stream%20Device%20Lab.pdf)
- [Autosave](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/09%20Autosave.pdf)
- [Autosave Lab](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/09l%20Autosave%20Lab.pdf)
- [Sequencer](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/14%20Sequencer.pdf)
- [Sequencer Lab](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/14l%20SequencerLab.pdf)
- [Allen Bradley PLCs](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/15%20Allen%20Bradley%20PLCs.pdf)
- [Area Detector](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/16%20AreaDetector.pdf)
- [Busy Record](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/21%20Busy%20Record.pdf)
- [Busy Record Lab](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/21l%20Busy%20Record%20Lab.pdf)
- [Python IOC pyDevice](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/23%20Python%20IOC_pydevice.pdf)

#### Clients/Servers
- [Python Channel Access Client](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/22%20Python%20CA%20Client.pdf)
- [Python IOC pcaspy](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/23%20Python%20IOC_pcaspy.pdf)

#### Device Support
- [Device Support Intro](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/17_DeviceSupportIntro.pdf)
- [Basic Device Support](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/17b_BasicDeviceSupport.pdf)
- [Device Support Problematic](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/17c%20Device%20Support_Problematic.pdf)
- [Custom Device Support VME](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/17d%20Custom%20Device%20Support%20VME.txt)

## Explanations
- [EPICS Overview](https://docs.epics-controls.org/en/latest/guides/EPICS_Process_Database_Concepts.html)
- [EPICS Process Database Concepts](https://docs.epics-controls.org/en/latest/guides/EPICS_Process_Database_Concepts.html)

## References

1. [EPICS Website - New](https://epics-controls.org)

2. [EPICS Website - Old](https://epics.anl.gov)

3. [EPICS Documentation](https://docs.epics-controls.org/en/latest)

4. [EPICS Application Developer's Guide - Recent web version (incomplete)](https://docs.epics-controls.org/en/latest/appdevguide/AppDevGuide.html)

5. [EPICS Application Developer's Guide - Base Release 3.16.2](https://epics.anl.gov/base/R3-16/2-docs/AppDevGuide.pdf)

6. [EPICS Record Reference Manual](https://epics.anl.gov/base/R7-0/6-docs/RecordReference.html)

7. [Channel Access Reference Manual](https://epics.anl.gov/base/R3-14/8-docs/CAref.html)
