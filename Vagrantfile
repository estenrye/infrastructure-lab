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
  },
}

Vagrant.configure(vagrant_api_version) do |config|
  machines.each do |hostname, info|
    config.vm.define hostname do |machine|
      machine.vm.box = info[:box]
      machine.vm.box_version = info[:box_version] if info[:box_version]
      machine.vm.hostname = hostname
      machine.vm.network 'public_network', bridge: info[:network]
      machine.vm.provision 'shell', inline: 'sudo netplan apply'
      machine.vm.provider 'hyperv' do |hv|
        hv.vmname = info[:vmname]
        hv.memory = info[:mem]
        hv.cpus = info[:cpus]
        hv.mac = info[:hv_mac] if info[:hv_mac]
      end
    end

    # Disable NFS sharing (==> default: Mounting NFS shared folders...)
    config.vm.synced_folder ".", "/vagrant", type: "nfs", disabled: true
    config.vm.boot_timeout = 60
  end
end
