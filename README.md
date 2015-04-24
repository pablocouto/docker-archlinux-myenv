- Scripted generation of an Arch Linux docker image:

```bash
$ cd lib/arch-install-scripts
$ make
$ cd ../../
$ sudo ./mkimage-arch.sh
```

- Creating a `custom` image, based on the above one, and running a container from it:

```bash
$ docker build -t custom .
$ docker run -t -i --rm custom
```
