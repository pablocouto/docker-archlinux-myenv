FROM archlinux-fffffff
MAINTAINER Pablo Couto <pablo@0x221e.net>

RUN pacman --noconfirm --needed -S \
      sudo \
      vim \
      base-devel \
      git

# add user and enable no-password sudo
RUN useradd -ms /bin/zsh pablo; \
    usermod -aG wheel pablo; \
    sed -i -e 's/^# %wheel ALL=(ALL) NOPASSWD: ALL$/%wheel ALL=(ALL) NOPASSWD: ALL/g' \
        /etc/sudoers

# other settings
RUN sed -i -e 's/^#MAKEFLAGS="-j2"$/MAKEFLAGS="-j4"/g' /etc/makepkg.conf

USER pablo
WORKDIR /home/pablo/
CMD /bin/bash
