Vagrant.configure("2") do |config|
  # Set box to latest kalilinux/rolling
  config.vm.box = "generic/ubuntu2004"
  config.vm.synced_folder ".", "/vagrant"
  # Forward ports
  config.vm.network "forwarded_port", id: "traefik_websecure", host: 8443, guest: 443
  config.vm.network "forwarded_port", id: "cowrie_ssh", host: 5222, guest: 2222
  config.vm.network "forwarded_port", id: "cowrie_telnet", host: 5223, guest: 2223
  # Set virtualbox provider config
  config.vm.provider :virtualbox do |virtualbox|
    virtualbox.gui = true
    virtualbox.name = "Manuka"
    virtualbox.cpus = "2"
    virtualbox.memory = "4096"
  end
  # Set vmware provider config
  config.vm.provider :vmware_desktop do |vmware|
    vmware.gui = true
    vmware.vmx["displayname"] = "Manuka"
    vmware.vmx["numvcpus"] = "2"
    vmware.vmx["memsize"] = "4096"
  end
  # Provision ansible playbooks
  config.vm.provision :ansible_local do |ansible|
    ansible.playbook = "ansible/main.yml"
    ansible.config_file = "ansible/ansible.cfg"
  end
  # # Reboot host after ansible provisioning has completed
  config.vm.provision :shell do |shell|
    shell.name = "Reboot after provisioning"
    shell.reboot = true
  end
end
