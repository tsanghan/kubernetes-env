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

# Install kubectl
curl -sSL -o /usr/local/bin/kubectl \
  "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl

# Install kind
curl -sSL -o /usr/local/bin/kind \
  $(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq ".assets[].browser_download_url" | grep amd64 | grep linux | tr -d '"')
chmod +x /usr/local/bin/kind

# Install k9s
K9S_FRIEND=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep Linux | tr -d '"')
curl -sSL $K9S_FRIEND | sudo tar -C /usr/local/bin -zxvf - $(basename $K9S_FRIEND | sed 's/\(.*\)_Linux_.*/\1/')
chmod +x /usr/local/bin/k9s

# Install kubectx & kubens
KUBE_FRIENDS=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep linux | tr -d '"')
for friend in $KUBE_FRIENDS
do
  curl -sSL $friend | sudo tar -C /usr/local/bin -zxvf - $(basename $friend | sed 's/\(.*\)_v.*/\1/')
done

chown $SUDO_USER.$SUDO_USER /home/$SUDO_USER/.bash_complete

usermod -aG lxd,docker $SUDO_USER

echo -e "\n"
echo "*************************************************************************************"
echo "*                                                                                   *"
echo "*  Please logout and relogin again for docker,lxd group membership to take effect.  *"
echo "*                                                                                   *"
echo "*************************************************************************************"
echo -e "\n\n"
