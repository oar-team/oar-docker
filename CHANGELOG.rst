oar-docker CHANGELOG
====================

version 0.1.4
=============

Released on Oct 28th 2014

- Ignored my-init scripts if filename ends by "~"
- Added wait_pgsql script to wait postgresql to be available
- Fixed monika config (db server hostname is server)
- Removed old code
- Adapt cgroup mount script to job_resource_manager_cgroup.pl and remove old cpuset workaround
- Fixed cpu/core/thread affinity


version 0.1.3
=============

Released on Sep 10 2014

- Added `oar reset` cmd to restart containers
- Added a better comments about oardocker images with git information
- Used default job_resource_manager script (from oar sources)
- Mount the host cgroup path in the containers (default path is /sys/fs/cgroup)
- Removed stopped containers from ssh_config
- Remove dnsmasq and mount a custom /etc/hosts for the nodes (need docker >= 1.2.0)


version 0.1.2
=============

Released on Sep 16th 2014

- Keep compatible with older versions of git
- Don't name the containers
- Mounting OAR src as Copy-on-Write directory with unionfs-fuse
- Stopped installation when container failed during ``oardocker install``
- Added option to print version
- Allow ssh connection with different user

version 0.1.1
=============

Released on Sep 11th 2014

 - Minor bug fixes

version 0.1
===========

Released on Sep 11th 2014

Initial public release of oar-docker
