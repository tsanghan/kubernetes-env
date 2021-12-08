#!/usr/bin/env bash

mkdir -p ~/.local/bin

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
EOF

cat <<'MYEOF' > ~/.local/bin/prepare-vm.sh
#!/bin/bash

echo -e "overlay\nbr_netfilter\nnf_conntrack" >> /etc/modules-load.d/containerd.conf
echo -e "options nf_conntrack hashsize=32768" >> /etc/modprobe.d/containerd.conf
modprobe overlay
modprobe br_netfilter
# Ref: https://github.com/kinvolk/kube-spawn/issues/14
modprobe nf_conntrack hashsize=32768

# Ref: https://linuxcontainers.org/lxd/docs/master/production-setup
cat <<EOF > /etc/sysctl.d/99-lxd.conf
fs.aio-max-nr                     = 524288
fs.inotify.max_queued_events      = 1048576
fs.inotify.max_user_instances     = 1048576
fs.inotify.max_user_watches       = 1048576
kernel.dmesg_restrict             = 1
kernel.keys.maxbytes              = 2000000
kernel.keys.maxkeys               = 2000
net.core.bpf_jit_limit            = 3000000000
net.ipv4.neigh.default.gc_thresh3 = 8192
net.ipv6.neigh.default.gc_thresh3 = 8192
vm.max_map_count                  = 262144
net.netfilter.nf_conntrack_max    = 131072
EOF

# Ref: https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# /etc/sysctl.d/99-lxd.conf
sysctl fs.aio-max-nr=524288
sysctl fs.inotify.max_queued_events=1048576
sysctl fs.inotify.max_user_instances=1048576
sysctl fs.inotify.max_user_watches=1048576
sysctl kernel.dmesg_restrict=1
sysctl kernel.keys.maxbytes=2000000
sysctl kernel.keys.maxkeys=2000
sysctl net.core.bpf_jit_limit=3000000000
sysctl net.ipv4.neigh.default.gc_thresh3=8192
sysctl net.ipv6.neigh.default.gc_thresh3=8192
sysctl vm.max_map_count=262144
# Ref: https://www.claudiokuenzler.com/blog/1106/unable-to-deploy-rancher-managed-kubernetes-cluster-lxc-lxd-nodes
sysctl net.netfilter.nf_conntrack_max=131072

# /etc/sysctl.d/99-kubernetes-cri.conf
sysctl net.bridge.bridge-nf-call-iptables=1
sysctl net.ipv4.ip_forward=1
sysctl net.bridge.bridge-nf-call-ip6tables=1

if ! [ -x $(which snap) ]; then
  apt install -y --no-install-recommends snapd
  snap install lxd
fi

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gnupg lsb-release jq
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io

# Install kubelet
curl -sSL -o /usr/local/bin/kubectl \
  "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl

# Install kind
curl -sSL -o /usr/local/bin/kind \
  $(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq ".assets[].browser_download_url" | grep amd64 | grep linux | tr -d '"')
chmod +x /usr/local/bin/kind

# Install kubectx & kubens
KUBE_FRIENDS=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep linux | tr -d '"')
for friend in $KUBE_FRIENDS
do
  curl -SL $friend | sudo tar -C /usr/local/bin -zxvf - $(basename $friend | sed 's/\(.*\)_v.*/\1/')
done

cat <<'EOF' > /home/$SUDO_USER/.bash_complete
# For kubeernetes-env

if [ -x /usr/local/bin/kubectl ]
then
  source <(kubectl completion bash)
  alias k=kubectl
  complete -F __start_kubectl k
fi

if [ -x /usr/local/bin/kind ]
then
  source <(kind completion bash)
  complete -F __start_kind kind
fi
EOF

chown $SUDO_USER.$SUDO_USER /home/$SUDO_USER/.bash_complete

usermod -aG lxd,docker $SUDO_USER

echo -e "\n"
echo "*************************************************************************************"
echo "*                                                                                   *"
echo "*  Please logout and relogin again for docker,lxd group membership to take effect.  *"
echo "*                                                                                   *"
echo "*************************************************************************************"
echo -e "\n\n"
MYEOF

cat <<'MYEOF' > ~/.local/bin/prepare-lxd.sh
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
MYEOF

chmod +x ~/.local/bin/*
