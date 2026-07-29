# Your First Week at a Facility

This guide says *"this is site-specific and not in this guide"* on about eight different pages. That's honest, and on its own it's useless. This page turns it into a list of questions to ask.

**Why this matters:** the most important knowledge at any facility is the part that was never written down. How IOCs get deployed, where the environment comes from, who owns the naming convention, what happens if you restart something during a user run — none of it is on the internet, all of it is in your colleagues' heads, and most of them have forgotten that they ever had to learn it.

Asking these questions in week one is normal and expected. Asking them in month six, after you've broken something, is worse.

!!! tip "Write the answers down"
    Not for you — for the next person. A page in your team's wiki called "how our controls system actually works" is one of the more valuable things a new starter can produce, precisely because you can still see what isn't obvious. Six months from now you won't be able to.

## The environment

Everything else depends on getting this right.

- **How do I get a working EPICS environment?** A site setup script (`source /opt/epics/setup.sh`)? [Environment modules](../reference/environment-variables.md) (`module load epics/7.0.9`)? Conda? A container? Something in `~/.bashrc` that someone copied to you?
- **Which Base version, and are there several in use?** A facility mid-migration may have three.
- **Where do support modules live**, and which versions are considered blessed? Is there a [synApps](../toolbox/deployment-and-operations.md#synapps)-style tested set, or does each IOC pick its own?
- **What's in `configure/RELEASE`** for a typical IOC here, and is it hand-maintained or generated?
- **Which network zone am I on**, and what are `EPICS_CA_ADDR_LIST` and friends set to? Can I see production PVs from my desk, and can I *write* to them? ([You'd hope not.](../architecture/networking.md))
- **Is there a development or simulation environment** separate from production, and how do I get onto it?

The last question is the one to ask hardest. If the answer is "we develop against production", that's important to know on day one rather than day thirty.

## Deployment

The most site-specific area in all of EPICS, and the one where guessing causes the most damage.

- **How does an IOC get from source to running?** [Containers](../toolbox/deployment-and-operations.md#epics-containers)? [e3](../toolbox/deployment-and-operations.md#e3-ess-epics-environment)? `make` and a shared filesystem? Ansible? Somebody's script?
- **Where does an IOC's source live**, and is there one repository per IOC or one big one?
- **How is an IOC started and supervised?** [procServ](../toolbox/deployment-and-operations.md#procserv), systemd, Kubernetes, or `screen` in a session somebody must not close?
- **How do I get to an IOC's console** to run `dbpr` and `casr`? What's the port allocation scheme?
- **Can I restart an IOC, and when?** Is there a change window? Does anything need to be told first? **Ask before you ever need to.**
- **How do I know what version is running where?** And does anyone check that it matches what's committed?
- **Who is allowed to deploy?** And is that written down or just understood?

## Conventions

- **Is there a written naming convention**, and where is the document? Is it enforced, and how? ([It should be mechanical.](../architecture/naming-conventions.md))
- **What's the setpoint/readback convention** here — `-SP`/`-RB`, `:Set`/`:Get`, something else?
- **Is there an authoritative device database** that PV names are generated from, or are names hand-written?
- **How are IOCs named**, and how does that relate to hostnames and console ports?
- **Where do displays live**, and are they version-controlled?
- **Is there a code review process** for database changes? For screens?

## The services

For each of these: **does it exist, where is it, and who owns it?**

| Service | What to ask |
| --- | --- |
| [Archiver](../toolbox/archiving.md) | Which one? How do I check whether a PV is archived? How do I get one added? |
| [Alarms](../toolbox/alarms.md) | How do I add an alarm? Who reviews the alarm list? Am I on an on-call rota? |
| [Directory service](../toolbox/directory-services.md) | Is there ChannelFinder? Can I query "which IOC serves this PV?" |
| [Save & restore](../toolbox/save-and-restore.md) | What are the golden configurations, and who may restore them? |
| [Logbook](../toolbox/logbooks.md) | Which one, and what's the expectation for logging your own work? |
| [caPutLog](../toolbox/logbooks.md#caputlog) | Is every write logged? Where can I read it? |
| [Gateways](../toolbox/gateways.md) | What crosses which boundary, and who maintains the rule files? |
| Monitoring | Is there a control-system health dashboard? Do IOCs have heartbeats? |

## Safety, and the boundary

Ask these early, explicitly, and don't infer the answers.

- **What are the protection systems here** — PPS, MPS, subsystem interlocks — and who owns them?
- **Where exactly is the boundary** between EPICS and those systems? Which PVs are read-only reflections of them?
- **What training and authorisation do I need** before I can touch anything near the machine? Radiation safety, access, electrical, lockout/tagout?
- **What must I never do?** Every facility has a short list, and it is usually taught by anecdote rather than documentation. Ask for the anecdotes.
- **Who do I call at 03:00**, and for what?
- **What's the incident process** when something goes wrong? Is it blameless? (The answer tells you a lot about whether people will report their mistakes, which determines whether anything gets fixed.)

!!! danger "If anyone tells you an interlock is implemented in EPICS"
    That's worth escalating rather than accepting. [EPICS has no safety certification](../example-facility/machine-protection.md), and a protection function implemented in a `calc` record is a serious finding — not a quirk of local practice to work around.

## The machine itself

You're supporting a physics instrument, and the physics is not optional context.

- **What does this machine do**, in terms a user would recognise?
- **What are the operating modes**, and how do they differ for controls?
- **What is the operations schedule** — user runs, machine studies, shutdowns, maintenance days? When is it safe to work on things?
- **What's the cost of an hour of downtime**, in beam time and in money? This calibrates every risk judgement you will make.
- **Which subsystems break most often**, and what does the fault look like in the control system?
- **Who are the operators**, and can you sit with them for a shift? **Do this in your first month.** Watching someone use the screens you're about to modify will change how you build them, and it is the single most useful day a new controls engineer can spend.

## The people

- **Who owns which subsystem**, on the controls side and on the engineering side?
- **Who is the expert on** the archiver, the alarm system, the timing system, motion, PLCs?
- **Which decisions need whose agreement?**
- **Where does the team communicate** — a chat channel, a weekly meeting, a ticket system?
- **Is anyone using this facility's work upstream?** Some facilities maintain community modules; you may be joining a team that supports other labs too.

## History

The questions that explain why things are strange.

- **What was the last big migration**, and is it finished? (It usually isn't.)
- **What's the oldest thing still running**, and why hasn't it been replaced?
- **What's the known technical debt** everyone agrees about but nobody has time for?
- **Has anything been tried and abandoned?** Knowing that a previous attempt at containerising IOCs failed for a specific reason will save you from proposing it in week three as though it were a fresh idea.
- **Where are the old design documents?** Facility CDRs and TDRs have controls chapters, and yours may explain decisions that look inexplicable now.

## What to do in week one

A concrete plan, if you'd like one:

1. **Get the environment working**, and successfully `caget` a real PV. If this takes two days, that's normal and it's information about the facility.
2. **Read your facility's naming convention document** end to end.
3. **Find one IOC's source**, read its `st.cmd` and its databases, and work out what every line does. Ask about the parts you can't.
4. **Sit with the operators for a shift.**
5. **Deploy something trivial** — with supervision — through the full local process, so you learn the pipeline before you need it under pressure.
6. **Write down what you learned**, including the questions nobody could answer. Those are the interesting ones.

## And a word on the questions nobody can answer

You will ask some of the above and get "hmm, nobody really knows" or "that's just how it's always been". Those answers are findings, not dead ends. Write them down. A newcomer's list of unanswerable questions is often the most accurate available survey of a facility's technical debt — and being the person who documented it is a much better first contribution than being the person who quietly worked around it.

## Next

→ [The Toolbox](../toolbox/index.md) to put names to what you find, or the [Example Facility](../example-facility/index.md) to see one set of answers written out in full.
