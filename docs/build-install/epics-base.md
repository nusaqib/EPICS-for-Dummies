- [How To build and install EPICS Base](#how-to-build-and-install-epics-base)
  - [Pre-requisites](#pre-requisites)
      - [Building EPICS Base:](#building-epics-base)
      - [Other](#other)
  - [Build \& Install](#build--install)
  - [Test the installation](#test-the-installation)
  - [Troubleshooting](#troubleshooting)


# How To build and install EPICS Base

[EPICS Base installation - Official website](https://docs.epics-controls.org/projects/how-tos/en/latest/getting-started/installation.html)

## Pre-requisites
#### Building EPICS Base:
- make
- c++
- readline library
- perl

#### Other
- git

Hopefully [requirements](../../scripts/base/install_requirements.sh) should install these on Debian and Red-Hat distributions.

## Build & Install
We'll be installing EPICS base in ${HOME}/EPICS/base directory.

- Create directory
~~~bash
mkdir ${HOME}/EPICS 
~~~

- Clone the source code of EPICS base
~~~bash
git clone --recursive https://github.com/epics-base/epics-base.git
~~~

- Some stuff
~~~bash
mv epics-base base
cd base
~~~

- Build
~~~bash
make
~~~

Congratulations if there was no error, you successfully built the EPICS base. To run EPICS commands from anywhere we need to add EPICS Base binaries to our PATH variable. Do the following in your terminal:

~~~bash
export EPICS_BASE=${HOME}/EPICS/base
export EPICS_HOST_ARCH=$(${EPICS_BASE}/startup/EpicsHostArch)
export PATH=${EPICS_BASE}/bin/${EPICS_HOST_ARCH}:${PATH}
~~~

## Test the installation
Run either `softIoc` (Channel Access) or `softIocPVA` (PV Access) from the terminal, if everything is fine, you'll see an `epics>` prompt which validates that EPICS Base is installed correctly

## Troubleshooting

- Commands not accesible from another terminal or after logging in
    - The commands for exporting variables above are valid for the same terminal session only
    - For consistent configuration, copy/paste the above three lines in either ${HOME}/.bashrc or ${HOME}/.profile.
    - Also, do the following:
~~~bash
source ${HOME}/.bashrc
# or
source ${HOME}/.profile
~~~