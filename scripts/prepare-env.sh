#!/usr/bin/env bash

mkdir -p ~/.local/bin
mkdir -p ~/.config/k9s
curl -sSL -o ~/.config/k9s/skin.yml https://raw.githubusercontent.com/derailed/k9s/master/skins/dracula.yml

cat <<'EOF' > ~/.local/bin/get-fzf.sh
#!/usr/bin/env bash

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
yes | ~/.fzf/install
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
      - containerd
      - curl
      - kubeadm=1.23.1-00
      - kubelet=1.23.1-00
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
tar xzvfC cilium-linux-amd64.tar.gz ~/.local/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}
EOF

cat <<'EOF' > ~/.bash_complete
# For kubeernetes-env

if [ -x ~/.local/bin/kubectl ]
then
  source <(kubectl completion bash)
  alias k=kubectl
  complete -F __start_kubectl k
fi

if [ -x ~/.local/bin/kind ]
then
  source <(kind completion bash)
  complete -F __start_kind kind
fi
EOF

cat <<'EOF' > ~/.vimrc
colorscheme delek
set nu rnu
autocmd FileType yaml,yml,sh setlocal ts=2 sts=2 sw=2 et ai
set pastetoggle=<F10>
inoremap <Up> <Nop>
inoremap <Down> <Nop>
inoremap <Left> <Nop>
inoremap <Right> <Nop>
nnoremap <Up> <Nop>
nnoremap <Down> <Nop>
nnoremap <Left> <Nop>
nnoremap <Right> <Nop>
EOF

cat <<'MYEOF' >
#!/usr/bin/env bash

verlte() {
  [  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}

verlt() {
  if [ "$1" = "$2" ]; then
    return 1
  else
    verlte "$1" "$2"
  fi
}

if [ ! -x ~/.local/bin/kubectl ]; then
  echo "kubeclt not found or not executanle!!"
  exit
fi

OLD_KUBECTL_VER=$(kubectl version --short --client | sed 's/.*v\(.*\)/\1/')
NEW_KUBECTL_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt | sed 's/.*v\(.*\)/\1/')

verlt "$OLD_KUBECTL_VER" "$NEW_KUBECTL_VER"
if [ "$?"  = 1 ]; then
  echo "No upgrade required!!"
  exit
else
  KUBECTL_VER=v"$NEW_KUBECTL_VER"
  curl -sSL -o /tmp/kubectl "https://dl.k8s.io/$KUBECTL_VER/bin/linux/amd64/kubectl"
  KUBECTL_SHA256=$(curl -sSL https://dl.k8s.io/"$KUBECTL_VER"/bin/linux/amd64/kubectl.sha256)
  OK=$(echo "$KUBECTL_SHA256" /tmp/kubectl | sha256sum --check)
  if [[ ! "$OK" =~ .*OK$ ]]; then
    echo "kubectl binary does not match sha256 checksum, aborting!!"
    rm /tmp/kubectl
    exit $?
  else
    echo "Installing kubectl verion=$KUBECTL_VER"
    mv /tmp/kubectl ~/.local/bin/kubectl
    chmod +x ~/.local/bin/kubectl
  fi
fi
MYEOF

# Install kubectl
KUBECTL_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -sSL -o /tmp/kubectl "https://dl.k8s.io/$KUBECTL_VER/bin/linux/amd64/kubectl"
KUBECTL_SHA256=$(curl -sSL https://dl.k8s.io/"$KUBECTL_VER"/bin/linux/amd64/kubectl.sha256)
OK=$(echo "$KUBECTL_SHA256" /tmp/kubectl | sha256sum --check)
if [[ ! "$OK" =~ .*OK$ ]]; then
  echo "kubectl binary does not match sha256 checksum, aborting!!"
  rm /tmp/kubectl
  exit $?
else
  echo "Installing kubectl verion=$KUBECTL_VER"
  mv /tmp/kubectl ~/.local/bin/kubectl
  chmod +x ~/.local/bin/kubectl
fi

# Install kind
curl -sSL -o ~/.local/bin/kind \
  "$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq ".assets[].browser_download_url" | grep amd64 | grep linux | tr -d '"')"

# Install k9s
K9S_FRIEND=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep Linux | tr -d '"')
curl -sSL "$K9S_FRIEND" | tar -C ~/.local/bin -zxvf - "$(basename \""$K9S_FRIEND\"" | sed 's/\(.*\)_Linux_.*/\1/')"

# Install yq
curl -sSL -o ~/.local/bin/yq \
  "$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | jq ".assets[].browser_download_url" | grep -v "tar.gz" | grep amd64 | grep linux | tr -d '"')"

# Install shellcheck
SHELLCHECK=$(curl -s https://api.github.com/repos/koalaman/shellcheck/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep linux | tr -d '"')
SHELLCHECK_DIR=$(basename "$SHELLCHECK" | sed 's/\(^.*v.*\).linux.*/\1/')
SHELLCHECK_BIN=$(basename "$SHELLCHECK" | sed 's/\(.*\)-v.*/\1/')
curl -sSL "$SHELLCHECK" | tar -C /tmp --xz -xvf - "$SHELLCHECK_DIR"/"$SHELLCHECK_BIN"
mv /tmp/"$SHELLCHECK_DIR"/"$SHELLCHECK_BIN" ~/.local/bin
rm -rf /tmp/"$SHELLCHECK_DIR"

# Install kubectx & kubens
KUBE_FRIENDS=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep linux | tr -d '"')
for friend in $KUBE_FRIENDS
do
  curl -sSL "$friend" | tar -C ~/.local/bin -zxvf - "$(basename \""$friend\"" | sed 's/\(.*\)_v.*/\1/')"
done

chmod +x ~/.local/bin/*

echo -e "\n"
echo "*************************************************************************************"
echo "*                                                                                   *"
echo "*  Please logout and relogin again for docker,lxd group membership to take effect.  *"
echo "*                                                                                   *"
echo "*************************************************************************************"
echo -e "\n\n"
