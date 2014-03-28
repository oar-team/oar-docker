# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/precise64"
  config.vm.hostname = "oarcluster"
  config.vm.provision "docker", images: ["debian"]

  # share src folder
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder ".", "/home/vagrant/docker-oarcluster", type: "rsync"

  # enable ssh forward agent for all VMs
  config.ssh.forward_agent = true
  config.vm.network "forwarded_port", guest: 80, host: 8080

  # Config provider
  config.vm.provider :virtualbox do |vm|
    vm.memory = 1024
    vm.cpus = 1
  end
end
