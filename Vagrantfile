# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "yungsang/boot2docker"
  # share src folder
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder ".", "/home/docker/docker-oarcluster", type: "nfs"

  # enable ssh forward agent for all VMs
  config.ssh.forward_agent = true

  # ssh auth
#   config.vm.provision "shell", privileged: false, inline: <<-shellprovision
#     cat >> ~/.profile <<<'
# remove-all-docker-container() {
#   containers=$(docker ps -a | grep -v ^CONTAINER | awk "{print \$1}")
#   if [ ! -z "$containers" ]; then
#     docker kill $containers
#     docker rm $containers
#   fi
# }'
#   EOF
#   shellprovision

  # Network
  config.vm.network :private_network, ip: "10.10.30.130"
  # proxy cache with polipo
  if Vagrant.has_plugin?("vagrant-proxyconf")
    config.proxy.http = "http://10.10.30.1:3128/"
    config.proxy.https = "http://10.10.30.1:3128/"
    config.proxy.ftp = "http://10.10.30.1:3128/"
    config.proxy.no_proxy = "localhost,127.0.0.1"
    config.apt_proxy.http  = "http://10.10.30.1:3128/"
    config.apt_proxy.https = "http://10.10.30.1:3128/"
    config.apt_proxy.ftp = "http://10.10.30.1:3128/"
  end

  # Config provider
  config.vm.provider :virtualbox do |vm|
    vm.memory = 1024
    vm.cpus = 1
  end
end
