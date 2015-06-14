- Scripted generation of an Arch Linux docker image:

```bash
$ cd lib/arch-install-scripts
$ make
$ cd ../../
$ sudo ./mkimage-arch.sh
```

- Creating a `custom` image, based on the above one (`authorized_keys` and `key` need to be properly set, e.g. with `ssh-keygen`):

```bash
$ docker build -t custom .
```

The container is then started with `vagrant up` and may be accessed with `vagrant ssh`.
