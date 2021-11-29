#!/bin/bash

echo "overlay\nbr_netfilter" >> /etc/modules-load.d/containerd.conf
modprobe overlay
modprobe br_netfilter

cat <<EOF > /etc/sysctl.d/99-lxd.conf
fs.aio-max-nr = 524288
fs.inotify.max_queued_events = 1048576
fs.inotify.max_user_instances = 1048576
fs.inotify.max_user_watches = 1048576
kernel.dmesg_restrict = 1
kernel.keys.maxbytes = 2000000
kernel.keys.maxkeys = 2000
net.core.bpf_jit_limit = 3000000000
net.ipv4.neigh.default.gc_thresh3 = 8192
net.ipv6.neigh.default.gc_thresh3 = 8192
vm.max_map_count = 262144
EOF

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

curl -sSL -o /usr/local/bin/kubectl \
  "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl

curl -sSL -o /usr/local/bin/kind \
  $(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq ".assets[].browser_download_url" | grep amd64 | grep linux | tr -d '"')
chmod +x /usr/local/bin/kind

usermod -aG lxd,docker $SUDO_USER

echo "Please logout and relogin again for docker,lxd group member to take effect."
