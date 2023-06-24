# EPICS Ecosystem - Getting Started Guide for Beginners

Welcome to the world of EPICS! As someone new to EPICS, you may be coming from a non-software background, and that's perfectly fine. EPICS is designed to be accessible to individuals from various domains, including physics, engineering, and industrial control. There are lots of components to a complete EPICS control system in production at various particle accelerator laboratories. This is sometimes overwhelming to a newcomer, this guide is intended to provide introduction to EPICS infrastructure, all at one place. Links are provided for further reading from official EPICS website and other resources.

## What is EPICS?

The Experimental Physics and Industrial Control System (EPICS) comprises a set of software components and tools that can be used to create distributed control systems. EPICS provides capabilities that are typically expected from a distributed control system:

- Remote control & monitoring of facility equipment
- Automatic sequencing of operations
- Facility mode and configuration control
- Management of common time across the facility
- Alarm detection, reporting and logging
- Closed loop (feedback) control [1]
- Modeling and simulation
- Data conversions and filtering
- Data acquisition including image data
- Data trending, archiving, retrieval and plotting
- Data analysis
- Access security (basic protection against unintended manipulation)

EPICS can scale from very big to very small systems. Big systems have to be able to transport and store large amounts of data, be robust and reliable but also failure-tolerant. Failure of a single component should not bring the system down. For small installations it has to be possible to set up a control system without requiring complicated or expensive infrastructure components.

For modern applications, management of data is becoming increasingly important. It shall be possible to store acquired operational data for the long term and to retrieve it in the original form. EPICS provides the tools to achieve this and to tailor the data management to the needs of the facility.

One of the most appreciated aspects of EPICS is the lively collaboration that is spread around the globe. Members of the collaboration are happy to help other users with their issues and to discuss new ideas.

## Components of EPICS Ecosystem

The EPICS (Experimental Physics and Industrial Control System) ecosystem consists of various components that work together to create a robust control system framework. These components include:

1. **EPICS Base**: EPICS Base forms the foundation of the EPICS ecosystem. It is the main core of EPICS, comprising the build system and tools, common and OS-interface libraries, network protocol client and server libraries, static and run-time database access routines, the database processing code, and standard record, device and driver support.

    [Official EPICS Website - Base](https://epics-controls.org/resources-and-support/base/)

    [First things first - Let's install EPICS Base]()



2. **IOCs (Input/Output Controllers)**: IOCs are software applications responsible for interfacing with physical devices and subsystems in the control system. They run EPICS software, communicate with other components using Channel Access/PV Access, and handle input/output operations, data acquisition, and control.

    [Let's create a simple IOC and see the magic]()

3. **IOC Support Modules**: As more device and record support software was written at various EPICS sites to interface to different kinds of hardware, it became obvious that these modules could not all be managed and distributed centrally as part of Base. Since then many of the support layers have been removed from Base and are now maintained separately.

    There are lots of support modules developed by the community, these can be divided into two major categories:

    **Soft Modules**: A Soft Support module may contain a new record type, software-only device support, or some other software that runs in the IOC but which is not readily identified with a particular piece of hardware.

    **Hardware Support**: A Hardware Support module provides software for use within an IOC to control a real-world commercial device. Unless a design is published as Open Hardware and already in use by multiple sites, drivers for site-specific hardware are not appropriate here. Entries provide the manufacturer’s name and module number, a description, the current maintainer’s name and a web-site for the software if one exists.

    [Official EPICS Website - Modules](https://epics-controls.org/resources-and-support/modules/)

    [Official EPICS Website - Soft Support Modules Database](https://epics-controls.org/resources-and-support/modules/soft-support/)

    [Official EPICS Website - Hardware Support Modules Database](https://epics-controls.org/resources-and-support/modules/hardware-support/)

    [Github - EPICS Modules](https://github.com/epics-modules)


Simply put, the installation of EPICS Base is an essential requirement for the creation of EPICS IOCs. IOCs serve as the backbone of the EPICS ecosystem, carrying out crucial input/output operations by leveraging the tools and libraries provided by EPICS Base and IOC Support Modules.

4. **Databases**: EPICS control systems utilize databases to store configuration information, parameter values, and status records of devices and subsystems. The databases define EPICS records, which describe the properties and behavior of the control system components.

5. **CA Clients**: CA clients are software applications that interact with IOCs and access control system data. They can be used for monitoring, controlling, or analyzing the system. CA clients communicate with IOCs using the Channel Access protocol to retrieve or update data.

6. **Middle Layer Services**: The EPICS ecosystem includes middle layer services that provide additional functionality and services to the control system. These services can include:

   - *Archive Service*: The Archive Service stores historical data from the control system, enabling retrieval, analysis, and visualization of past measurements. It helps with troubleshooting, data logging, and long-term storage of system information.

   - *Alarm Service*: The Alarm Service monitors the status of the control system and generates alerts or notifications when specific conditions are met. It ensures that operators are promptly informed about critical events or system failures.

   - *Data Visualization and Analysis Services*: EPICS control systems can integrate with external tools or software packages for data visualization, analysis, and further processing. These services enable operators, scientists, or engineers to analyze and visualize control system data using tools like MATLAB, Python, or dedicated data analysis software.

7. **User Interfaces**: EPICS control systems often include user interfaces that allow operators, scientists, or engineers to interact with the system. These interfaces can be implemented as graphical user interfaces (GUIs), web-based applications, or command-line tools. They provide a means to monitor the system, adjust parameters, and visualize data.

8. **Network Infrastructure**: A reliable network infrastructure is essential for communication between EPICS components. It includes switches, routers, cables, and other networking equipment that ensure seamless data transfer and connectivity.

9. **Physical Devices and Subsystems**: The EPICS ecosystem interfaces with various physical devices and subsystems that are controlled and monitored. These can include sensors, actuators, motors, detectors, and other hardware components specific to the experimental setup or industrial process.

The EPICS ecosystem is highly modular and customizable, allowing for flexible and scalable control system implementations. Each component plays a vital role in creating a comprehensive and efficient control system environment.
