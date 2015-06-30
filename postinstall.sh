#!/bin/sh
# This runs in the debian installer.

# arrange for machine to start with the terminal console
sed -i -e 's,\(GRUB_CMDLINE_LINUX_DEFAULT\)=.*,\1="text nomodeset",' \
       -e 's,#GRUB_TERMINAL=console,GRUB_TERMINAL=console,' \
  /etc/default/grub
update-grub

# add ssh key for the ubuntu user
mkdir -p /home/ubuntu/.ssh
if [ -f /tmp/extra-user-ssh-key ]; then cp /tmp/extra-user-ssh-key /home/ubuntu/.ssh/authorized_keys; fi;
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# create an extra user
EXTRA_USER_FULLNAME=$(cat /tmp/extra-user-fullname)
EXTRA_USER_USERNAME=$(cat /tmp/extra-user-username)
adduser --disabled-password --gecos "$EXTRA_USER_FULLNAME" $EXTRA_USER_USERNAME
addgroup $EXTRA_USER_USERNAME adm
addgroup $EXTRA_USER_USERNAME sudo
if [ -f /tmp/extra-user-passwd ]; then chpasswd --encrypted < /tmp/extra-user-passwd; fi;
mkdir -p /home/$EXTRA_USER_USERNAME/.ssh
if [ -f /tmp/extra-user-ssh-key ]; then cp /tmp/extra-user-ssh-key /home/$EXTRA_USER_USERNAME/.ssh/authorized_keys; fi
chown -R $EXTRA_USER_USERNAME:$EXTRA_USER_USERNAME /home/$EXTRA_USER_USERNAME/.ssh
chmod go-rwx /home/$EXTRA_USER_USERNAME/.ssh/authorized_keys
