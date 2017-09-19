Build your own OAR cluster with docker
--------------------------------------

oar-docker is a set of docker images especially configured for deploying
your own OAR cluster. The main idea is to have a mini development cluster with
a frontend, a server and some nodes that launch in just a few seconds on a
simple laptop.


Why use oar-docker ?
--------------------

Various case scenarios may affect you:
 - Quickly test OAR on a cluster
 - Gain time: a ten-node cluster (or more) is launched in just a
   few seconds and is cleaned in less than a second.
 - Save resources: docker allows the user to pool the node between
   various systems, resource utilization is thus considerably reduced.
 - Synced volume : allowing you to continue working on your host machine, but
   use the resources in the guest machine to compile or run your project.


Installation
------------

Requirements:
  - python >= 2.7
  - docker >= 1.3

You can install, upgrade, uninstall oar-docker with these commands::

  $ pip install [--user] oar-docker
  $ pip install [--user] --upgrade oar-docker
  $ pip uninstall oar-docker

Or from git (last development version)::

  $ pip install git+https://github.com/oar-team/oar-docker.git

Or if you already pulled the sources::

  $ pip install path/to/sources

Or if you don't have pip::

  $ easy_install oar-docker

Usage
-----

::

    Usage: oardocker [OPTIONS] COMMAND1 [ARGS]... [COMMAND2 [ARGS]...]...

      Manage a small OAR developpement cluster with docker.

    Options:
      --workdir DIRECTORY   Changes the folder to operate on.
      --docker-host TEXT    The docker socket [default:
                            unix://var/run/docker.sock].
      --cgroup-path TEXT    The cgroup file system path [default: /sys/fs/cgroup].
      --docker-binary TEXT  The docker client binary [default: docker].
      --verbose             Verbose mode.
      --debug               Enable debugging
      --version             Show the version and exit.
      -h, --help            Show this message and exit.

    Commands:
      build    Build base images
      clean    Remove all stopped containers and untagged...
      connect  Connect to a node.
      destroy  Stop containers and remove all images
      exec     Run a command in an existing node.
      init     Initialize a new environment.
      install  Install and configure OAR from src
      logs     Fetch the logs of all nodes or only one.
      reset    Restart the containers
      start    Create and start the nodes
      status   Output status of the cluster
      stop     Stop and remove all nodes


Getting started
---------------

To get started with oar-docker, the first thing to do is to initialize a
project::

    $ oardocker init -e stretch

If you already have OAR sources, the best is to initialize directly the
oardocker project in the OAR sources directory::

    $ cd path/to/oar/src
    $ oardocker init -e stretch

You have to do this only once. It allows you to import the Dockerfiles
and other configuration files.

We then launch the base image build::

    $ oardocker build

Now, we have to install OAR. To do this, several options are available.

If you already have the OAR sources::

    $ oardocker install /path/to/oar_src

Or if you want to install from tarball::

    $ oardocker install http://oar-ftp.imag.fr/oar/2.5/sources/testing/oar-2.5.8+rc4.tar.gz

You can also launch the installation from a git repository::

    $ oardocker install git+https://github.com/oar-team/oar.git


We start a OAR cluster with 5 nodes::

    $ oardocker start -n 5

It is possible to share directories between host machines and
all containers with the ``-v`` option::

    $ oardocker start -v $PWD:/oar_src -v /my/custom/lib:/usr/local/ma_lib

To manage the cluster::

    $ oardocker connect frontend|server|nodeXX
    $ oardocker logs [frontend|server|nodeXX]


To clean::

    $ oardocker stop  # stops and removes all containers
    $ oardocker clean  # removes all stopped containers (failed) and the untagged images <none:none>
    $ oardocker destroy  # removes all images and containers


With oar-docker, it is possible to chain all commands to go faster::

    $ oardocker init -f build install oar-2.5.8+rc4.tar.gz start -n 4 connect -l root frontend

For instance, to develop on OAR, we often need to install OAR,
start the cluster and connect to it::


    $ oardocker install $PWD start -n 10 -v $PWD:/home/docker/oar_src connect frontend


One last thing to know. The ``stop`` command is automatically launched before
every ``start``, ``install`` and ``build`` ... If we launch multiple times the
last command, we will always obtain the same result. It can be useful to
experiment and develop (even) faster.


Security
--------

oar-docker is a development project and a testing one. It is in no way secure.
Besides, the private ssh key used is also insecured since it is public (you can
find it in the sources).


OAR3 development environment
----------------------------

Prerequisite
~~~~~~~~~~~~

``oar3-dev`` environment is based on and partially uses OAR 2 installed on ``stretch``::
  $ oardocker init -e stretch
  $ oardocker build

  $ oardocker install http://oar-ftp.imag.fr/oar/2.5/sources/testing/oar-2.5.8+rc4.tar.gz


Afterward generate ``oar3-dev`` environment from another directory::

  $ oardocker init -e oar3-dev
  $ oardocker build

In subsequent, oar3 source is considered accessible from ``/home/user/oar3`` and launched via::
    
  $ oardocker start -n 3  -v /home/user/oar3:/data/  

Finalize resource setup and oar3 installation on server::
    
  $ oardocker connect server
  $ sudo su
  $ # oardocker-resources service blocks systemd is it's enabled at launching time  
  $ systemctl start oardocker-resources 
  $ cd /data
  $ # Install oar3 files
  $ pip install -e . 


Kamelot Scheduler Test  
~~~~~~~~~~~~~~~~~~~~~~  

Kamelot scheduler is set by default, no special requirements ::
  
  $ oardocker connect 
  $ oarsub -I

Kao Metascheduler Test
~~~~~~~~~~~~~~~~~~~~~~

On server enable kao metascheduler use::

  $ echo 'META_SCHED_CMD="/usr/local/bin/kao"' >> /etc/oar/oar.conf


Almighty3 Automaton Test
~~~~~~~~~~~~~~~~~~~~~~~~

OAR3 is based on zeromq for data exchanges between its modules also a proxy is needed
to cooperate with OAR2 (transitional phase). On server the required are::

  $ systemctl stop oardocker-server
  $ echo 'META_SCHED_CMD="/usr/local/bin/kao"' >> /etc/oar/oar.conf

  $ sudo su oar
  $ export OARCONFFILE='/etc/oar/oar.conf'
  $ oar3-appendice-proxy &
  $ oar3-bipbip-commander &
  $ oar3-almighty

Oarsub3 Test
~~~~~~~~~~~~  

Oarsub3 implies the admission rules are written in Python so we need to remove those in Perl on server::

  $ systemctl stop oardocker-server 
  $ echo 'META_SCHED_CMD="/usr/local/bin/kao"' >> /etc/oar/oar.conf

  $ sudo su oar
  $ psql oar -c 'truncate admission_rules'
  $ export OARCONFFILE='/etc/oar/oar.conf'
  $ oar3-appendice-proxy&
  $ oar3-bipbip-commander&
  $ oar3-almighty

Without admission rules, one must provide default values with ``oarsub3`` command::

  $ oardocker connect
  $ export OARDO_USER=docker
  $ export OARDIR='/usr/local/lib/oar/'
  $ oarsub3 -l "{type='default'}/resource_id=1,walltime=30" -q default "sleep 10"

Rest API Test
~~~~~~~~~~~~~

Upto now, Rest API is accessible only from server and json format is available::

  $ systemctl stop oardocker-server
  $ echo 'META_SCHED_CMD="/usr/local/bin/kao"' >> /etc/oar/oar.conf

  $ cd /data
  $ python runapi.py 

  $ wget -O - http://127.0.0.1:9090/resources
  $ wget -O - http://127.0.0.1:9090/resources/2
  
Related resources
-----------------

- `A minimal Ubuntu base image modified for Docker-friendliness`_
- `Got a Minute? Spin up a Spark cluster on your laptop with Docker`_
