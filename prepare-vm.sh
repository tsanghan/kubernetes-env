#!/bin/bash

sudo echo "overlay\nbr_netfilter" >> /etc/modules
sudo modprobe overlay
sudo modprobe br_netfilter

sudo usermod -aG lxd,docker "$USER"
