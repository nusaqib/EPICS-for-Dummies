# Books and Papers

There is no O'Reilly book on EPICS. The literature is conference proceedings, facility design reports, and standards — which is worth knowing so you stop looking for the book.

## Where the EPICS literature actually is

### ICALEPCS

**International Conference on Accelerator and Large Experimental Physics Control Systems.** Biennial, and the primary venue for controls papers.

- Proceedings are open access via [JACoW](https://www.jacow.org/) — searchable, free, and going back decades.

Searching JACoW for a topic ("archiver appliance", "alarm system", "EPICS deployment", "orbit feedback") gets you papers describing how real facilities solved the problem, with numbers. This is the closest thing to a literature review that this field has, and it is much better than its obscurity suggests.

### PAC, IPAC and EPAC

Also on [JACoW](https://www.jacow.org/). Controls papers appear here too, generally with more machine physics context.

### EPICS Collaboration Meeting slides

[epics-controls.org/news-and-events/meetings](https://epics-controls.org/news-and-events/meetings/) — published presentations. **Often the only source on current work**, since a new tool is typically presented at a meeting a year or two before it is documented.

## Facility design reports

The single most useful category for someone designing a control system, and the least well known.

Most major facilities publish a **Conceptual Design Report (CDR)** or **Technical Design Report (TDR)** with a controls chapter covering architecture, PV counts, IOC counts, network design, service deployment and staffing. Real numbers from real machines.

Worth seeking out for light sources specifically: the design reports of the 4th-generation upgrade projects (MAX IV, Sirius, APS-U, ALS-U, ESRF-EBS, HEPS, Diamond-II, SOLEIL-II, PETRA IV). Search for the project name plus "design report" — most are public PDFs, and their controls chapters are exactly what the [Helios Light Source](../example-facility/index.md) chapters are modelled on in spirit.

Read two or three and you will have a much better sense of what a facility-scale control system looks like than any textbook could give you.

## Standards worth knowing about

Not EPICS documents, and they govern the boundaries EPICS sits inside.

| Standard | Subject |
| --- | --- |
| **IEC 61508** | Functional safety of electrical/electronic/programmable systems. The foundation for safety-rated PLC design. |
| **IEC 61511** | Functional safety for the process industry |
| **IEC 62682** | Management of alarm systems for the process industries |
| **ISA-18.2** | Alarm systems management — the ANSI/ISA counterpart |
| **IEEE 1588 (PTP)** | Precision Time Protocol |
| **IEC 61131-3** | PLC programming languages |
| **OPC UA (IEC 62541)** | Industrial interoperability |

**IEC 62682 / ISA-18.2 are the ones to read even though a synchrotron isn't a refinery.** Alarm philosophy — how many alarms a human can handle, why every alarm needs an action, how to design for a flood, how to review an alarm system — is identical across domains, and these standards are where it's written down properly. The [alarm plan](../example-facility/alarm-plan.md) chapter is essentially an application of them.

**IEC 61508 and 61511** matter because they define what "certified" means for the [protection systems](../example-facility/machine-protection.md) EPICS must not be. You don't need to design to them; you need to know that someone does, and why that puts those functions outside your software.

## Adjacent technical reading

Not about EPICS, and it will make you better at this job:

| Topic | Why |
| --- | --- |
| **Accelerator physics basics** | Knowing what a tune, an emittance and an orbit correction *are* changes you from someone implementing requests to someone understanding them. Any introductory accelerator physics text; USPAS material is free. |
| **Distributed systems** | EPICS is a distributed system with unusual properties (no broker, no transactions, best-effort monitors). Standard distributed-systems reasoning about failure modes and consistency applies directly. |
| **Human factors and control room design** | [Operator interfaces](../toolbox/operator-interfaces.md) and [alarms](../toolbox/alarms.md) are human-factors problems wearing software costumes. The process-industry literature on this is decades deep. |
| **Time series data and storage** | The [archiver](../toolbox/archiving.md) is a purpose-built time-series database. Understanding compression, downsampling and retention generally helps you operate it. |
| **Industrial protocols** | Modbus, EtherNet/IP, OPC UA and PROFINET have their own literature, and half of controls work is talking to equipment that speaks them. |
| **Site reliability engineering** | The SRE literature on monitoring, alerting, on-call and blameless postmortems maps almost perfectly onto [operating a control system](../toolbox/observability.md). |

The SRE parallel is stronger than it looks: "alarm on absence", "review your alerts monthly", "make restarts boring", "the thing that fails silently is the dangerous one" are all conclusions both communities reached independently.

## What doesn't exist, and what to read instead

| You want | Read instead |
| --- | --- |
| "EPICS: The Definitive Guide" | The [Application Developer's Guide](documentation.md). It is the specification, it is complete, and it is more readable than its length suggests. |
| A modern textbook on control system architecture for accelerators | Two or three [facility design reports](#facility-design-reports) |
| A tutorial book | The [SNS training material](training.md) — free, complete, with exercises |
| Best practices for EPICS at scale | ICALEPCS proceedings, searched by topic |
| A course you can be certified in | There isn't one. The field is small enough that reputation is personal. |

## Contributing to the literature yourself

Worth stating, because people underestimate how welcome it is: facilities publish their controls work at ICALEPCS and Collaboration Meetings, and *most* of the useful papers are "here is how we solved a specific problem, with numbers".

If you build something that works, write it up. The bar is usefulness, not novelty, and the paper you would have wanted to read three years ago is the paper worth writing.
