oar-docker CHANGELOG
====================

Version 1.6.4
------------------

Released on April 17th 2023
- add bookworm support
- rework image templates
- switch to python3 venv

Version 1.6.3
-------------

Released on January 06th 2022
- add bullseye support

Version 1.6.2
-------------

Released on October 21st 2021
- update docker image recipes for Debian buster: use buster instead of stable as the release name, add the man package
- add support for the oar-node and oar-server systemd native unit files
- fix python3 collections callable

Version 1.6.1
-------------

Released on March 31st 2020
- Set the drawgantt label_cmp_regex configuration to sort nodes correctly

Version 1.6.0
-------------

Released on March 31st 2020

- Change the ``web_services`` to ``net_services`` in the ``manifest.json`` file (but keep the backward compatibility)
- Add an extra field in the ``net_services`` for port forwarding other than http (cosmetic)
- Add information in the ``README.rst`` file about the TCP ports forwarding
- Do not create the ``/dev/oar_cgroups_links/`` and ``/dev/cpuset`` in ``oardocker install``, but let OAR take care of it
- This breaks with OAR ``job_resource_manager_cgroup.pl`` before OAR 2.5.9+g5k5, see ``README.rst``

Version 1.5.0
-------------

Released on March 06th 2020

Version 1.4.0
-------------

Released on December 06th 2018

- Improve systemd usage in container
- Use of Docker API version 1.21
- Enhance 
- Change Debian8 base image
- Add better CiGri template

Version 1.3.0
-------------

Released on June 13th 2016

- Rework install_oar.sh scripts (apache2 configuration + chmod 0600 oar.conf)
- Add newapi apache2 config (for the Python OAR API)
- Fix apache2 startup by systemd
- Rework port bindings, using the manifest
- Add port bindings to 6668 for OAR API
- Change default host port numbers for forwarding

Version 1.2.0
-------------

Released on March 30th 2016

- Reverted the frontend http server from nginx to apache
- Fixed OAR Rest API unit tests
- Configured COORM images to use the new oar3 python package and kamelot as default scheduler
- Fixed "core" resources creation
- Minor python3 fixes

Version 1.1.0
-------------

Released on February 10th 2016

- Updated base image version to 1.3.2
- Configured debian branches to pin some up-to-date packages from sid (nginx, systemd)
- Unmask systemd-tmpfiles-setup service (Fixed #45)
- Fixed /etc/hosts again mountpoint with the latest version of docker (>1.9)
- Added new coorm env based on jessie one
- Made init-scripts executable
- The install operation is not supported if no install_script is set to the manifest.json
- Added a manifest.json file to describe environments
- Try to pull docker images if missing
- Added ``--rebuild`` option to rebuild images even if already done
- send original oar-server log to journalctl
- Allocate tty by default in ``oardocker exec`` cmd

Version 1.0.0
-------------

Released on November 18th 2015

- Improved stability, performance and security
- Used systemd as default init for the containers
- Improved ressources usage with systemd activation socket.
- Used tmpfiles.d to create runtimes volatile files (pid,/var/run etc.)
- Passed environement variables to containers by using /etc/profile
- No more insecure ssh keys
- Fixed all web services (api, monika...) by replacing apache2 by nginx
- Improved logging by adding rsyslog node to centralize all logs
- Added ``--no-tail`` and ``--lines/-n`` options to ``oardocker logs`` command
- Created resources manually as it is faster than oar_resources_ini (no ssh connection)
- Removed unused scripts
- OAR3 ready


Version 0.6.0
-------------

Released on October 22nd 2015

- Removed wheezy environement (Fixed #39)
- Logged to stdout by default
- Fixed oar.conf permissions to allow normal user to read it
- disable_unicode_literals_warning in click
- Added oidentd start for the API to do auth
- Enabled mod_cgi (for monika)
- Let the oar makefile configure the web tools
- New template for cigri base
- Fixed resources initialization
- Fixed string formating
- Do not allocate a pseudo-TTY by default
- Fixed oar-node and oar-server init.d script for OAR 2.5.3 and older
- Adapt new oar_resources_init options
- Setup cosystem and deploy jobs and install oar-node on the frontend


Version 0.5.10
--------------

Released on July 03rd 2015

- Make /etc/oar/job_resource_manager_cgroup.pl a symlink to improve debugging (Fixed #34)
- Fixed API by reverted to oidentd


Version 0.5.9
-------------

Released on July 01st 2015

- Set OAREXEC_DEBUG_MODE=1 to improve the dev environement (Fixed #34)

Version 0.5.8
-------------

Released on June 29th 2015

- Removed compiled python3 versions
- Bumped base images version to 1.2 

Version 0.5.7
-------------

Released on June 25th 2015

- Bumped base images version to 1.1 (included apache2-suexec and pidentd)
- Fixed the stamp for setup_resources script (Fixed #33)
- Fixed oar-api apache configuration

Version 0.5.6
-------------

Released on June 23rd 2015

- Used jessie as default env

Version 0.5.5
-------------

Released on June 12th 2015

- Minor bug fix about persistent bash history

Version 0.5.4
-------------

Released on June 02nd 2015

- Bumped base image version to 1.0.4
- Added persistent .bash_history and .pyhistory
- Added :ro, :rw and :cow options to ``--volume`` option
- Fixed phppgadmin and oarapi 403 error in jessie
- Fixed oarapi 403 error in jessie
- Removed duplicated package installation from dockerfile
- Fixed rest-client installation in debian jessie
- Installed chandler in base image
- Configured postgresql just after OAR installation
- Update wait_pgsql script : used UNIX socket if no host provided


Version 0.5.3
-------------

Released on May 22nd 2015

- Installed ruby-rspec librestclient-ruby for Rest API unittests
- Fixed oar resources initialization
- Initialized database during OAR installation
- Installed chandler
- Sequential oar resources Initialization (Fixed #28)
- Run cleanup scripts and kill all processes in the container when receiving SIGINT (Fixed #27)
- Updated base images to version 1.0.3
- Improved oardocker cgroup cleanup
- Cleanup oardocker nodes cgroup on oardocker stop (Fixed #27)
- Configured oarsh to get the current cpuset from the containers (Fixed #30)
- Added ugly patch to fix /etc/hosts mount with docker >=1.6.0


Version 0.5.2
-------------

Released on May 05th 2015

- Installed socat in the nodes
- Wait ssh daemon on nodes before oar_resources_init
- Improved ssh connection on colmet nodes


Version 0.5.1
-------------

Released on April 21st 2015

- Fixed compatibility with docker-py==1.1.0


Version 0.5.0
-------------

Released on Apr 2nd 2015

- Removed chandler and ruby from images
- Installed libdatatime-perl on server
- Dropped python environment
- Added new environment for colmet based on jessie one
- Based on oardocker/debian7 and oardocker/debian8 images built wit kameleon

Version 0.4.3
-------------

Released on Feb 23rd 2015

- Added --debug option
- Set default docker API to 1.15 (#25)
- Workaround phpphadmin apache install
- Removed drawgantt-svg permissions errors (#23)
- Fixed ``oardocker init`` subcommand (#22)
- Upload workdir to containers during the build
- Updated Dockerfiles to execute custom_setup.sh script


Version 0.4.2
-------------

Released on Jan 28th 2015

- Cleaned up unversionned OAR files (git clean) from sources before installing OAR (Fixed #20)


Version 0.4.0
-------------

Released on Jan 24th 2015

- Python3 support
- Prefixed all container outputs with the container hostname  (like oardocker logs subcommand)
- Added ``--force-rm`` and ``--pull`` options to oardocker build subcommand
- Allowed user to build custom images with custom_setup.sh script located in ``.oardocker/images/<image_name>/``
- Added a proper way to shutdown container
- Updated /etc/hosts when reseting containers
- Removed dockerpty package from dependencies
- Removed oardocker ssh/ssh-config subcommand
- Added ``--verbose`` option
- Fixed oardocker logs subcommand


Version 0.3.2
-------------

Released on Dec 16th 2014

- Added ``--enable-x11`` option to allow containers to display x11 applications
- Auto-loaded OAR module on python startup
- Added ``--env`` option to ``oardocker start`` to set custom environment variables
- Added ``--workdir`` option to ``oardocker exec``

Version 0.3.1
-------------

Released on Nov 27th 2014

**Bug fixes**:
- Fixed the Dockerfiles "FROM" statement

**Improvements**:
- Removed implicit 'default' alias from available env


Version 0.3.0
-------------

Released on Nov 27th 2014

**Features**:

- Added ``oardocker exec`` command
- Manage multiple environment variants with ``oardocker init``: added wheezy|jessie|python bases images

**Bug fixes**:
- Revert default environment to Debian Wheezy due to breaking OAR API in Jessie
- Fixed locales issue

**Improvements**:
- better synchronisation between oar-server and postgresql services


Version 0.2.0
-------------

Released on Nov 5th 2014

**Features**:

- Updated base images to debian jessie
- Added ``oardocker connect`` to connect to the nodes without ssh
- The commands ``oardocker ssh`` and ``oardocker ssh-config`` are deprecated from now

**Improvements**:

- Removed supervisor and make init process less complex by only using my_init.d statup scripts
- Customized help parameter to accept ``-h`` and ``--help``
- Used docker client binary for some task instead of the API

**Bug fixes**:

- Make sure that /etc/hosts file contain the localhost entry

Version 0.1.4
-------------

Released on Oct 28th 2014

- Ignored my-init scripts if filename ends by "~"
- Added wait_pgsql script to wait postgresql to be available
- Fixed monika config (db server hostname is server)
- Removed old code
- Adapt cgroup mount script to job_resource_manager_cgroup.pl and remove old cpuset workaround
- Fixed cpu/core/thread affinity


Version 0.1.3
-------------

Released on Sep 10th 2014

- Added `oar reset` cmd to restart containers
- Added a better comments about oardocker images with git information
- Used default job_resource_manager script (from oar sources)
- Mount the host cgroup path in the containers (default path is /sys/fs/cgroup)
- Removed stopped containers from ssh_config
- Remove dnsmasq and mount a custom /etc/hosts for the nodes (need docker >= 1.2.0)


Version 0.1.2
-------------

Released on Sep 16th 2014

- Keep compatible with older versions of git
- Don't name the containers
- Mounting OAR src as Copy-on-Write directory with unionfs-fuse
- Stopped installation when container failed during ``oardocker install``
- Added option to print version
- Allow ssh connection with different user

Version 0.1.1
-------------

Released on Sep 11th 2014

 - Minor bug fixes

Version 0.1
-----------

Released on Sep 11th 2014

Initial public release of oar-docker
