#!/usr/bin/env bash

# If the user's home dir does not exist, then create it.  this allows for configurable locations for user home.
if [ ! -d "${HOME}" ]
then
  mkdir -p "${HOME}"
fi

# Make sure the shell is ready
touch ${HOME}/.bashrc
touch ${HOME}/.zshrc

# Configure the container runtime to use an ephemeral graphroot, and to use fuse-overlay instead of vfs.
if [ ! -d "${HOME}/.config/containers" ]
then
  mkdir -p ${HOME}/.config/containers
  (echo '[storage]';echo 'driver = "overlay"';echo 'graphroot = "/tmp/graphroot"';echo '[storage.options.overlay]';echo 'mount_program = "/usr/bin/fuse-overlayfs"') > ${HOME}/.config/containers/storage.conf
fi

# Set up UID and GID mappings for the user
echo "" > /etc/subuid
echo "" > /etc/subgid
NAMESPACE_SIZE=$(awk '{end=$1 + $3; if (end > max) max = end} END{print max}' /proc/self/uid_map)
CURRENT_UID=$(id -u)
USER_NAME=$(whoami)
if [[ ${CURRENT_UID} -gt 1 ]]
then
  R1_START_ID=1
  R1_ID_COUNT=$(( CURRENT_UID - 1 ))
  echo "${USER_NAME}:${R1_START_ID}:${R1_ID_COUNT}" > /etc/subuid
  echo "${USER_NAME}:${R1_START_ID}:${R1_ID_COUNT}" > /etc/subgid
fi
START_ID=$(( CURRENT_UID + 1 ))
SUB_ID_COUNT=$(( NAMESPACE_SIZE - START_ID ))
echo "${USER_NAME}:${START_ID}:${SUB_ID_COUNT}" >> /etc/subuid
echo "${USER_NAME}:${START_ID}:${SUB_ID_COUNT}" >> /etc/subgid

# Configure Chrome
if [ ! -d ${HOME}/.config/google-chrome ]
then
  mkdir -p ${HOME}/.config/google-chrome
  touch ${HOME}/.config/google-chrome/'First Run'
fi
rm -f ${HOME}/.config/google-chrome/Singleton{Cookie,Lock,Socket}

# Configure KasmVNC
if [ ! -d ${HOME}/.vnc ]
then
  mkdir ${HOME}/.vnc
  touch ${HOME}/.vnc/.de-was-selected
  (echo '#!/bin/sh';echo 'unset SESSION_MANAGER';echo 'unset DBUS_SESSION_BUS_ADDRESS';echo 'echo starting Xvnc') > ${HOME}/.vnc/xstartup
  chmod +x ${HOME}/.vnc/xstartup
  VNC_PASSWD=nopasswd
  echo -e "${VNC_PASSWD}\n${VNC_PASSWD}\n" | vncpasswd -w -r -u user ${HOME}/.kasmpasswd
fi

/usr/bin/vncserver :0 -disableBasicAuth &

exec "$@"