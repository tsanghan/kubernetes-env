#!/usr/bin/env bash

mkdir -p ~/.local/bin
mkdir -p ~/.config/k9s
curl -sSL -o ~/.config/k9s/skin.yml https://raw.githubusercontent.com/derailed/k9s/master/skins/dracula.yml

cat <<'EOF' > ~/.local/bin/get-fzf.sh
#!/usr/bin/env bash

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
EOF

cat <<'EOF' > ~/.local/bin/k-apply.sh
#!/usr/bin/env bash
kubectl apply -f https://raw.githubusercontent.com/tsanghan/content-cka-resources/master/metrics-server-components.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.4/deploy/static/provider/cloud/deploy.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/metallb.yaml
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
EOF

cat <<'MYEOF' > ~/.local/bin/prepare-lxd.sh
#!/bin/bash

cat <<EOF | sudo lxd init --preseed
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

cat <<EOF | lxc profile edit k8s
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
MYEOF

cat <<'EOF' > ~/.local/bin/get-cilium.sh
#!/usr/bin/env bash

# Ref: https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}
EOF

chmod +x ~/.local/bin/*
