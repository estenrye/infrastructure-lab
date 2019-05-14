# frozen_string_literal: true
vagrant_api_version = '2'

machines = {
  router: {
    box: 'estenrye/lab-router',
    box_version: '1.0.20190514.054538',
    cpus: 2,
    mem: 2048,
    vmname: 'router',
    network: 'Default Switch',
  },
  test: {
    box: 'estenrye/ubuntu-server-1804',
    box_version: '1804.20190512.0',
    cpus: 2,
    mem: 2048,
    vmname: 'test',
    network: 'Private'
  },
}

Vagrant.configure(vagrant_api_version) do |config|
  machines.each do |hostname, info|
    config.vm.define hostname do |machine|
      machine.vm.box = info[:box]
      machine.vm.box_version = info[:box_version] if info[:box_version]
      machine.vm.hostname = hostname
      machine.vm.network 'public_network', bridge: info[:network]
      machine.vm.synced_folder info[:share][:source], info[:share][:target] if info[:share]
      machine.vm.provider 'hyperv' do |hv|
        hv.vmname = info[:vmname]
        hv.memory = info[:mem]
        hv.cpus = info[:cpus]
        hv.mac = info[:hv_mac] if info[:hv_mac]
      end
    end
  end
end
