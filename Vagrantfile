Vagrant.configure(2) do |config|
  config.ssh.username = "pablo"
  config.ssh.private_key_path = "key"
  config.vm.provider "docker" do |d|
    d.image = "custom"
    d.create_args = ["--device", "/dev/fuse", "--cap-add", "SYS_ADMIN", "-t", "-i"]
    d.has_ssh = true
  end
end
