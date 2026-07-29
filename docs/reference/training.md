# Training Material

Free, complete, exercise-driven EPICS courses. The SNS/ORNL material is the best there is, and it is what most people actually learn from.

## The main courses

| Course | Notes |
| --- | --- |
| **[SNS Controls training index](https://controlssoftware.sns.ornl.gov/training/)** | The whole collection. Start here. |
| **[2022 USPAS EPICS course](https://controlssoftware.sns.ornl.gov/training/2022_USPAS)** | A full course with slides, exercises and a **prebuilt VirtualBox VM** containing a complete EPICS control system |
| **[2022 EPICS Collaboration Meeting — PV Access workshop](https://controlssoftware.sns.ornl.gov/training/2022_EPICS)** | PV Access in depth |
| [EPICS official training resources](https://epics-controls.org/resources-and-support/documents/training/) | Links to courses run over the years, including European and Asian ones |

!!! tip "Use the prebuilt VM"
    The USPAS and Collaboration Meeting pages link a VirtualBox image with EPICS Base, Phoebus, the archiver, the alarm system and example IOCs already installed and running.

    If your goal is to *learn EPICS* rather than to *learn to build EPICS*, this saves you a day and lets you start on the interesting part immediately. Build things from source later, when you know what you're building.

## The USPAS material, by topic

Everything below is from the [2022 USPAS course](https://controlssoftware.sns.ornl.gov/training/2022_USPAS) unless noted. The `-l`/`e` suffixed items are lab exercises, and they're the valuable part.

### Foundations

- [Linux for EPICS](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/00%20Linux.pdf)
- [Overview](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/01%20Overview.pdf)

### Database and IOCs

- [EPICS Database](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/02%20EPICS%20Database.pdf) · [exercises](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/02e%20EPICS%20Database%20Exercises.pdf)
- [Database Updates](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/12%20EPICS%20Database%20Updates.pdf)
- [makeBaseApp](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/07%20makeBaseApp.pdf)
- [Database Interlocks](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/20b%20DB%20Interlocks.pdf)
- [EPICS Automation](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/13%20EPICS%20Automation.pdf)

### Protocols

- [Channel Access](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/10%20Channel%20Access.pdf)
- [CA vs Records vs CAS](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/10a%20CA%20vs%20Records%20vs%20CAS.pdf)
- [PV Access](https://controlssoftware.sns.ornl.gov/training/2022_EPICS/Presentations/1%20PV%20Access%20EPICS.pdf)
- [PV Access Java API](https://controlssoftware.sns.ornl.gov/training/2022_EPICS/Presentations/2%20PV%20Access%20Java.pdf)
- [PVA Gateway](https://controlssoftware.sns.ornl.gov/training/2022_EPICS/Presentations/3%20PVA%20Gateway.pdf)
- [CA Security](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/11%20CA%20Security.pdf) · [lab](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/11l%20CA%20Security%20Lab.pdf)

### User interfaces

- [User Interfaces](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/03%20User%20Interfaces.pdf)
- [CS-Studio](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/04%20CS-Studio.pdf)
- [Database UI First Steps](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/04a%20DataBase%20UI%20First%20Steps.pdf)
- [Display Builder](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/05%20Display%20Builder.pdf)
- [Display Web Runtime](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/06%20Display%20Web%20Runtime.pdf)

### Device support and hardware

- [Device Support Intro](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/17_DeviceSupportIntro.pdf)
- [Basic Device Support](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/17b_BasicDeviceSupport.pdf)
- [Device Support Problematic](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/17c%20Device%20Support_Problematic.pdf)
- [Custom Device Support, VME](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/17d%20Custom%20Device%20Support%20VME.txt)
- [asyn](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/18_Asyn.pdf)
- [StreamDevice](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/08%20Stream%20Device.pdf) · [lab](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/08l%20Stream%20Device%20Lab.pdf)
- [Allen-Bradley PLCs](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/15%20Allen%20Bradley%20PLCs.pdf)
- [areaDetector](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/16%20AreaDetector.pdf)

### Modules

- [Autosave](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/09%20Autosave.pdf) · [lab](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/09l%20Autosave%20Lab.pdf)
- [Sequencer](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/14%20Sequencer.pdf) · [lab](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/14l%20SequencerLab.pdf)
- [Busy Record](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/21%20Busy%20Record.pdf) · [lab](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/21l%20Busy%20Record%20Lab.pdf)

### Central services

- [Archive Systems](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/19%20Archive.pdf)
- [Alarm System](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/20%20Alarm%20System.pdf)
- [Alarm Guidelines](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/20a%20Alarm%20Guidelines.pdf)
- [ChannelFinder](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/26%20Channel%20Finder.pdf)

**[Alarm Guidelines](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/20a%20Alarm%20Guidelines.pdf) deserves particular attention.** Alarm *philosophy* is what makes an alarm system usable, it is almost never taught, and this deck teaches it. Read it before configuring a single alarm. See also [Alarms](../toolbox/alarms.md) and the [Helios alarm plan](../example-facility/alarm-plan.md).

### Python and scripting

- [Python CA Client](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/22%20Python%20CA%20Client.pdf)
- [Python IOC — pcaspy](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/23%20Python%20IOC_pcaspy.pdf)
- [Python IOC — pyDevice](https://controlssoftware.sns.ornl.gov/training/2022_USPAS/Presentations/23%20Python%20IOC_pydevice.pdf)

## How to use this material

**Do the labs.** The slides are useful; the exercises are where the learning is. `02e EPICS Database Exercises`, `08l Stream Device Lab`, `09l Autosave Lab`, `14l Sequencer Lab` and `11l CA Security Lab` between them cover most of what a new controls engineer needs to be able to do.

**A realistic order:**

1. Linux for EPICS (skim, if the shell is familiar)
2. Overview
3. **EPICS Database + exercises** — the most important item on this page
4. Channel Access
5. makeBaseApp
6. User Interfaces + Display Builder
7. asyn, then **StreamDevice + lab**
8. **Autosave + lab**
9. Archive Systems, Alarm System, **Alarm Guidelines**
10. Sequencer + lab
11. Whichever hardware topic matches your actual job
12. Device Support Intro, when you need to write your own

That's roughly a week of full-time work, or a month alongside a job, and it takes you from nothing to competent.

**Note the dates.** This material is from 2022 and the fundamentals haven't moved — records, links, scanning, CA, StreamDevice and autosave are the same. What has moved: Phoebus has developed considerably, [epics-containers](../toolbox/deployment-and-operations.md#epics-containers) barely appears, and CS-Studio references mean the Eclipse version. Check current project documentation for anything version-specific.

## Other courses and workshops

- [EPICS Collaboration Meetings](https://epics-controls.org/news-and-events/meetings/) — most include tutorial sessions, and the slides are published
- [EPICS Codeathons](https://epics-controls.org/news-and-events/codeathons/) — working sessions where you learn by contributing
- Facility-internal courses at APS, Diamond, PSI, DESY, ESS and others — often available on request to collaborators, and worth asking about

## And then

- Work through [Build a Mini-HLS](../example-facility/build-a-mini-hls.md) to assemble the pieces yourself
- Read the [Application Developer's Guide](documentation.md) properly
- Subscribe to [tech-talk](community.md) and lurk for a month
