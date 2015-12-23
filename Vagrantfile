# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "debian8"
  config.vm.box_url = "http://static.gender-api.com/debian-8-jessie-rc2-x64-slim.box"
  config.vm.network :private_network, ip: "192.168.33.10"
  config.vm.hostname = "cakephpbox"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus   = 2
  end
  config.vm.provision "shell", path: "bootstrap.sh", privileged: true
  config.vm.synced_folder "./my.cakephp.com", "/var/www/my.cakephp.com", onwer: "vagrant", group: "vagrant"
end
