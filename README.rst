Build your own OAR cluster with docker
--------------------------------------

.. image:: https://img.shields.io/pypi/v/oar-docker.svg
    :target: https://pypi.python.org/pypi/oar-docker

.. image:: https://travis-ci.org/oar-team/oar-docker.svg?branch=master
    :target: https://travis-ci.org/oar-team/oar-docker
    :alt: CI Status

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

Using a virtualenv may help overcome issues between python and your distribution.

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

    $ oardocker init

If you already have OAR sources, the best is to initialize directly the
oardocker project in the OAR sources directory::

    $ cd path/to/oar/src
    $ oardocker init

You have to do this only once. It allows you to import the Dockerfiles
and other configuration files.

We then launch the base image build::

    $ oardocker build

Now, we have to install OAR. To do this, several options are available.

If you already have the OAR sources::

    $ oardocker install /path/to/oar_src

Or if you want to install from tarball::

    $ oardocker install http://oar-ftp.imag.fr/oar/2.5/sources/testing/oar-2.5.4+rc4.tar.gz

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

    $ oardocker init -f build install oar-2.5.4+rc4.tar.gz start -n 4 connect -l root frontend

For instance, to develop on OAR, we often need to install OAR,
start the cluster and connect to it::

    $ oardocker install $PWD start -n 10 -v $PWD:/home/docker/oar_src connect frontend

One last thing to know. The ``stop`` command is automatically launched before
every ``start``, ``install`` and ``build`` ... If we launch multiple times the
last command, we will always obtain the same result. It can be useful to
experiment and develop (even) faster.

Note for OAR < 2.5.9+g5k5
-------------------------

oardocker ≥ 1.6.0 does not create the ``/dev/oar_cgroups_links/`` and ``/dev/cpuset`` in ``oardocker install``, to let OAR take care of it so that the concerned part of ``job_resource_manager_cgroup.pl`` is actually tested.

This breaks ``job_resource_manager_cgroup.pl`` before OAR 2.5.9+g5k5. See ``.oardocker/init-scripts/prepare_oar_cgroup.sh`` to revert to the old behaviour, by setting::

    CREATE_OAR_CGROUPS_LINKS=yes

Network services
----------------

By default, oardocker forwards the 80 and 6667 TCP ports to the frontend
container, for the OAR web services. To add other TCP ports forwarding to
the frontend, modify the ``.oardocker/manifest.json`` file, adding extra lines
in the ``net_services`` array. For instance::

    "network_services": [
        ["Netcat", " (tcp test)", "5000", "TCP: "],
        ["Secure web service", "/secure", "443", "https://"],
        ["Python API", "/newoarapi", "6668"],
        ...
    ]

Which translates to the following forwardings::

    ******************** Network Services *********************
    
                  Netcat: TCP: localhost:45000 (tcp test)
      Secure web service: https://localhost:40443/secure
              Python API: http://localhost:46668/newoarapi
                     ...
    ***********************************************************

Only the numerical port numbers really matters, texts are only informative.

Security
--------

oar-docker is a development project and a testing one. It is in no way secure.
Besides, the private ssh key used is also insecured since it is public (you can
find it in the sources).
