#!/bin/bash

cat <<EOF | tee lxd-preseed.yaml | sudo lxd init --preseed
config: {}
networks:
- config:
    ipv4.address: auto
    ipv6.address: none
  description: ""
  name: lxdbr0
  type: ""
storage_pools:
- config:
  description: ""
  name: default
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
cluster: null
EOF

sudo lxc profile create k8s

cat <<EOF | tee lxd-kubernetes-profile.yaml | lxc profile edit k8s
config:
  linux.kernel_modules: ip_tables,ip6_tables,netlink_diag,nf_nat,overlay
  raw.lxc: |-
    lxc.apparmor.profile=unconfined
    lxc.cap.drop=
    lxc.cgroup.devices.allow=a
    lxc.mount.auto=proc:rw sys:rw cgroup:rw
    lxc.seccomp.profile=
  security.nesting: "true"
  security.privileged: "true"
  user.k8s.version: "0.5"
  user.user-data: |
    #cloud-config
    apt:
      preserve_sources_list: false
      primary:
        - arches:
          - amd64
          uri: "http://archive.ubuntu.com/ubuntu/"
      security:
        - arches:
          - amd64
          uri: "http://security.ubuntu.com/ubuntu"
      sources:
        kubernetes.list:
          source: "deb http://apt.kubernetes.io/ kubernetes-xenial main"
          keyid: 7F92E05B31093BEF5A3C2D38FEEA9169307EA071
    packages:
      - apt-transport-https
      - ca-certificates
      - curl
      - kubectl=1.23.0-00
      - kubelet=1.23.0-00
      - kubeadm=1.23.0-00
      - containerd
      - jq
    package_update: true
    package_upgrade: true
    package_reboot_if_required: true
    locale: en_SG.UTF-8
    locale_configfile: /etc/default/locale
    timezone: Asia/Singapore
    write_files:
    - content: |
        [Unit]
        Description=Mount Make Rshare

        [Service]
        ExecStart=/bin/mount --make-rshare /

        [Install]
        WantedBy=multi-user.target
      owner: root:root
      path: /etc/systemd/system/mount-make-rshare.service
      permissions: '0644'
    runcmd:
      - apt-get -y purge nano
      - apt-get -y autoremove
      - systemctl enable mount-make-rshare
    default: none
    power_state:
      delay: "+1"
      mode: poweroff
      message: Bye Bye
      timeout: 10
      condition: True
description: ""
devices:
  _dev_sda1:
    path: /dev/sda1
    source: /dev/sda1
    type: unix-block
  aadisable:
    path: /sys/module/nf_conntrack/parameters/hashsize
    source: /dev/null
    type: disk
  aadisable1:
    path: /sys/module/apparmor/parameters/enabled
    source: /dev/null
    type: disk
  boot_dir:
    path: /boot
    source: /boot
    type: disk
  dev_kmsg:
    path: /dev/kmsg
    source: /dev/kmsg
    type: unix-char
  eth0:
    name: eth0
    nictype: bridged
    parent: lxdbr0
    type: nic
  root:
    path: /
    pool: default
    type: disk
name: k8s
EOF

# VERSION=$(curl -sSL https://uk.lxd.images.canonical.com/streams/v1/images.json | jq '.products."ubuntu:focal:amd64:cloud".versions | keys[]' | sort -r | head -1 | tr -d '"')
# curl -SLO https://uk.lxd.images.canonical.com/images/ubuntu/focal/amd64/cloud/"$VERSION"/lxd.tar.xz
# curl -SLO https://uk.lxd.images.canonical.com/images/ubuntu/focal/amd64/cloud/"$VERSION"/rootfs.squashfs
# lxc image import lxd.tar.xz rootfs.squashfs --alias focal-cloud
# rm lxd.tar.xz rootfs.squashfs
VERSION=$(curl -sSL https://cloud-images.ubuntu.com/daily/streams/v1/com.ubuntu.cloud:daily:download.json | jq '.products."com.ubuntu.cloud.daily:server:20.04:amd64".versions | keys[]' | sort -r | head -1 | tr -d '"')
curl -SLO https://cloud-images.ubuntu.com/server/focal/"$VERSION"/focal-server-cloudimg-amd64-lxd.tar.xz
curl -SLO https://cloud-images.ubuntu.com/server/focal/"$VERSION"/focal-server-cloudimg-amd64.squashfs
lxc image import focal-server-cloudimg-amd64-lxd.tar.xz focal-server-cloudimg-amd64.squashfs --alias focal-cloud
rm focal-server-cloudimg-amd64-lxd.tar.xz focal-server-cloudimg-amd64.squashfs
