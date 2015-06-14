Vagrant.configure(2) do |config|
  config.ssh.username = "pablo"
  config.ssh.private_key_path = "key"
  config.vm.provider "docker" do |d|
    d.image = "custom"
    d.create_args = ["-t", "-i"]
    d.has_ssh = true
  end
end
