Vagrant.configure("2") do |config|

  config.vm.define "foreman" do |foreman|
    foreman.vm.box = "centos/7"
    foreman.vm.hostname = "foreman.local"
    foreman.vm.network :private_network, ip: "192.168.50.3"
    foreman.vm.provision :shell, path: "scripts/foreman.sh"
    foreman.vm.provider "virtualbox" do |foreman|
      foreman.memory = 2048
    end
  end

end
