FROM archlinux-fffffff
MAINTAINER Pablo Couto <pablo@0x221e.net>

RUN pacman --noconfirm -S \
      zsh

RUN useradd -ms /bin/zsh pablo

USER pablo
WORKDIR /home/pablo/
CMD /bin/bash
