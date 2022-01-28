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

apt install -y --no-install-recommends snapd
snap install lxd

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gnupg lsb-release jq xz-utils
#
if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
fi
#
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo \
  "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
  | tee /etc/apt/sources.list.d/kubernetes.list
#
apt-get update
apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io kubectl httpie

fdisk -l | grep Linux | awk '{print $1}' > /tmp/.disk
chown "$SUDO_USER"."$SUDO_USER" /tmp/.disk

usermod -aG lxd,docker "$SUDO_USER"

cat <<EOF | lxd init --preseed
config: {}
networks:
- config:
    ipv4.address: 10.254.254.254/24
    ipv4.dhcp.gateway: 10.254.254.254
    ipv4.dhcp.ranges: 10.254.254.1-10.254.254.239
    ipv4.nat: "true"
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

sudo -u "$SUDO_USER" ./scripts/prepare-env.sh