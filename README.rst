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

You can install, upgrade, uninstall oar-docker with these commands::

  $ pip install oar-docker
  $ pip install --upgrade oar-docker
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
      --workdir DIRECTORY  Changes the folder to operate on.
      --docker-host TEXT
      --help               Show this message and exit.

    Commands:
      build       Build base images
      clean       Remove all stopped containers and untagged...
      destroy     Stop containers and remove all images
      init        Initialize a new environment.
      install     Install and configure OAR from src
      logs        Fetch the logs of all containers.
      ssh         Connect to machine via SSH.
      ssh-config  Output OpenSSH valid configuration to connect...
      start       Start the cluster
      status      Output status of the cluster
      stop        Stop the running cluster


Security
--------

oar-docker is a development project and a testing one. It is in no way secure.
Besides, the private ssh key used is also insecured since it is public (you can
find it in the sources).


Related resources
-----------------

- `A minimal Ubuntu base image modified for Docker-friendliness`_
- `Got a Minute? Spin up a Spark cluster on your laptop with Docker`_
