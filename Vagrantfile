# frozen_string_literal: true
vagrant_api_version = '2'

dev = false;

machines = {
  router: {
    box: 'estenrye/lab-router',
    box_version:  if dev
                    '0'
                  else
                    '1.0.20190521.040826'
                  end,
    cpus: 2,
    mem: 2048,
    vmname: 'router',
    network: 'Default Switch',
  },
  dc: {
    box: 'estenrye/lab-dc',
    box_version:  if dev
                    '0'
                  else
                    '1.0.20190521.040834'
                  end,
    cpus: 2,
    mem: 2048,
    vmname: 'dc',
    network: 'Private',
    hv_mac: '00:35:10:00:00:02',
  },
  manager: {
    box: 'estenrye/lab-docker',
    box_version:  if dev
                    '0'
                  else
                    '1.0.20190521.043754'
                  end,
    cpus: 2,
    mem: 2048,
    vmname: 'manager',
    network: 'Private',
    hv_mac: '00:35:10:00:00:03',
    runtime: 'docker',
    limit: 'manager',
  },
  worker: {
    box: 'estenrye/lab-docker',
    box_version:  if dev
                    '0'
                  else
                    '1.0.20190520.074038'
                  end,
    cpus: 2,
    mem: 2048,
    vmname: 'worker',
    network: 'Private',
    hv_mac: '00:35:10:00:00:04',
    runtime: 'docker',
    limit: 'worker',
  },
}

$opt_ssh_script = <<-SCRIPT
sudo mkdir -p /opt/.ssh
sudo chown vagrant /opt/.ssh
chgrp vagrant /opt/.ssh
chmod 700 /opt/.ssh
SCRIPT

# echo -e 'y\n' | ssh-keygen -f /home/vagrant/.ssh/id_rsa -t rsa -b 4096 -N ''
# cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys

Vagrant.configure(vagrant_api_version) do |config|
  machines.each do |hostname, info|
    config.vm.define hostname do |machine|
      machine.vm.box = info[:box]
      machine.vm.box_version = info[:box_version] if info[:box_version]
      machine.vm.hostname = hostname
      machine.vm.network 'public_network', bridge: info[:network]
      machine.vm.provider 'hyperv' do |hv|
        hv.vmname = info[:vmname]
        hv.memory = info[:mem]
        hv.cpus = info[:cpus]
        hv.mac = info[:hv_mac] if info[:hv_mac]
      end

      $script = <<-SCRIPT
      export ANSIBLE_CONFIG='/tmp/src/ansible.cfg'
      ansible-galaxy install --force -r '/tmp/src/playbooks/#{info[:runtime]}.requirements.yml'
      ansible-playbook --limit #{info[:limit]} '/tmp/src/playbooks/#{info[:runtime]}.runtime.yml' -i /tmp/src/inventory
      SCRIPT

      machine.vm.provision 'shell', name: 'Apply netplan', inline: 'sudo netplan apply'
      machine.vm.provision 'shell', name: 'create /opt/.ssh directory', inline: $opt_ssh_script if info[:runtime] == 'docker'
      machine.vm.provision 'file', source: 'src', destination: '/tmp/src' if info[:runtime]
      machine.vm.provision 'file', source: 'build/certificates/private/docker_id_rsa', destination: '/opt/.ssh/id_rsa' if info[:runtime] == 'docker'
      machine.vm.provision 'file', source: 'build/certificates/private/docker_id_rsa.pub', destination: '/opt/.ssh/id_rsa.pub' if info[:runtime] == 'docker'
      machine.vm.provision 'shell', name: 'Apply Runtime Playbook', inline: $script if info[:runtime]

      config.vm.synced_folder '.', '/vagrant', type: 'nfs', disabled: true
      machine.vm.boot_timeout = 600
    end
  end
end
