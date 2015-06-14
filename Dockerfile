FROM archlinux-fffffff
MAINTAINER Pablo Couto <pablo@0x221e.net>

RUN pacman --noconfirm --needed -S \
      sudo \
      vim \
      base-devel \
      git

# sets up sshd
RUN pacman --noconfirm --needed -S \
      openssh; \
    ssh-keygen -A
RUN sed -i \
      -e 's/^#*\(PermitRootLogin\) .*$/\1 no/' \
      -e 's/^#*\(PasswordAuthentication\) .*$/\1 no/' \
      -e 's/^#*\(PermitEmptyPasswords\) .*$/\1 no/' \
      -e 's/^#*\(UsePAM\) .*$/\1 no/' \
      /etc/ssh/sshd_config

# other settings
RUN sed -i \
      -e 's/^#*\(MAKEFLAGS\)=.*$/\1="-j4"/' \
      /etc/makepkg.conf

# adds user and enables password-less sudo for it
RUN useradd -ms /bin/bash pablo; \
    usermod -aG wheel pablo; \
    sed -i \
      -e 's/^# *\(%wheel ALL=(ALL) NOPASSWD: ALL\).*$/\1/' \
      /etc/sudoers

# enables ssh access with user
ADD authorized_keys /home/pablo/.ssh/authorized_keys
RUN echo "AllowUsers pablo" >> /etc/ssh/sshd_config; \
    chown -R pablo:pablo /home/pablo/.ssh/; \
    chmod 700 /home/pablo/.ssh/; \
    chmod 600 /home/pablo/.ssh/*; \
    echo "pablo:pablo" | chpasswd

CMD ["/usr/bin/sshd", "-D"]
