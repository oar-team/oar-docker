# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "oardocker"
  config.vm.provision "docker", images: ["scratch"]

  # share src folder
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder ".", "/home/vagrant/oar-docker"

  # enable ssh forward agent for all VMs
  config.ssh.forward_agent = true

  if Vagrant.has_plugin?("vagrant-proxyconf")
    config.proxy.http     = "http://10.0.2.2:8123/"
    config.proxy.https     = "http://10.0.2.2:8123/"
    config.proxy.ftp     = "http://10.0.2.2:8123/"
    config.proxy.no_proxy = "localhost,127.0.0.1"
  end

  # Config provider
  config.vm.provider :virtualbox do |vm|
    vm.memory = 1024
    vm.cpus = 2
  end
end
