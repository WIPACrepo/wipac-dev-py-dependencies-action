#!/bin/bash
sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$( basename "$0" )..." && echo
set -ex

########################################################################
#
# install podman using kubic
# https://podman.io/docs/installation#debian
#
########################################################################

sudo mkdir -p /etc/apt/keyrings

# # Debian Testing/Bookworm
# curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/Debian_Testing/Release.key \
#   | gpg --dearmor \
#   | sudo tee /etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg > /dev/null
# echo \
#   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg]\
#     https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/Debian_Testing/ /" \
#   | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:unstable.list > /dev/null

# OS=Debian_Unstable
OS="xUbuntu_22.04"

# Debian Unstable/Sid
curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/$OS/Release.key \
  | gpg --dearmor \
  | sudo tee /etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg > /dev/null
# -> see https://github.com/openSUSE/MirrorCache/issues/428#issuecomment-1814992424
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg]\
    https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/unstable/$OS/ /" \
  | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:unstable.list > /dev/null

# install deps
sudo apt-get update
sudo apt-get -y upgrade
# https://github.com/containers/podman/issues/21024#issuecomment-1859449360
wget https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_22.04/amd64/conmon_2.1.2~0_amd64.deb -O /tmp/conmon_2.1.2.deb
sudo apt install /tmp/conmon_2.1.2.deb

# Install Podman
sudo apt-get -y install podman

sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
