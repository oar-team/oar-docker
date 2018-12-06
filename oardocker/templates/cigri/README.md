# CIGRI devel virtual cluster

## Linux install

We will assume that you have a ``git`` directory into your home directory, where you store all your git repositories. If it is not yet the case, then:
```sh
mkdir ~/git
``` 

###1. Create a python virtualenv
You need "Python" and "Virtualenv".  Check with your distribution how to install it. With Debian, it's `` apt-get install python virtualenv`` 
Then create a new python environment:
```sh
cd ~
virtualenv oar-venv
```
Each time you need to work with oardocker, you load this environment into your current shell:
```sh
source ~/oar-venv/bin/activate
```
###2. Install oardocker
Be sure to be into your python environment (remember: ``source ~/oar-venv/bin/activate``)
```sh
cd ~/git
git clone https://github.com/oar-team/oar-docker.git
pip install ~/git/oar-docker
```
When upgrading, simply add the ``--upgrade`` to the ``pip`` command.

###3. Get OAR sources (only necessary if you need the latest sources)
```sh
cd ~/git
git clone https://github.com/oar-team/oar.git
```

###4. Create or refresh the Debian/Jessie base images for oardocker
```sh
mkdir ~/oar-stretch
cd ~/oar-stretch
oardocker init -e stretch
oardocker build
oardocker install ~/git/oar
```

###5. Create the Cigri docker images
```sh
mkdir ~/cigri-stretch
cd ~/cigri-stretch
oardocker init -e cigri
oardocker build
oardocker install http://oar-ftp.imag.fr/oar/2.5/sources/testing/oar-2.5.8+rc5.tar.gz
# Or if you need the latest OAR sources: oardocker install ~/git/oar
```

###6. Start your OAR cluster with 3 nodes
```sh
cd ~/cigri-stretch
oardocker start -n 3
```

###7. Connect on the frontend and initiate and start the CIGRI server
```sh
oardocker connect frontend
sudo su -
/root/init_cigri.sh
/root/start_cigri.sh
```

###8. From another shell, launch a Cigri campaign
```sh
oardocker connect frontend
mkdir -p cigri-3/tmp
cp /root/cigri/tmp/test1.sh cigri-3/tmp
gridsub -f /root/cigri/tmp/test1.json
```

## Cleaning

Docker caches a lot of things (containers and images). So, if you want to restart from a fresh environment, do the following. WARNING: this will erase everything, even other docker containers you may have created for other purposes.

```sh
# Remove all containers
docker ps -a -q |awk '{print "docker rm " $1}' |bash
# Remove all images
docker images |awk '{print "docker rmi " $3}' |bash
# From the working directory, remove oardocker config
rm -rf .oardocker
```
