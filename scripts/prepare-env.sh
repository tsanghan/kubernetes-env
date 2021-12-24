#!/usr/bin/env bash

mkdir -p ~/.local/bin
mkdir -p ~/.config/k9s
curl -sSL -o ~/.config/k9s/skin.yml https://raw.githubusercontent.com/derailed/k9s/master/skins/dracula.yml

cat <<'EOF' > ~/.local/bin/get-fzf.sh
#!/usr/bin/env bash

echo
echo "****************************"
echo "*                          *"
echo "* Download and Install fzf *"
echo "*                          *"
echo "****************************"
echo
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
yes | ~/.fzf/install
EOF

cat <<'EOF' > ~/.local/bin/get-cilium.sh
#!/usr/bin/env bash

echo
echo "*******************************"
echo "*                             *"
echo "* Download and Install Cilium *"
echo "*                             *"
echo "*******************************"
echo
# Ref: https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
tar xzvfC cilium-linux-amd64.tar.gz ~/.local/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}
EOF

cat <<'EOF' > ~/.local/bin/get-hubble.sh
#!/usr/bin/env bash

echo
echo "*******************************"
echo "*                             *"
echo "* Download and Install Hubble *"
echo "*                             *"
echo "*******************************"
echo
# Ref: https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/
export HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
curl -L --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-amd64.tar.gz.sha256sum
sudo tar xzvfC hubble-linux-amd64.tar.gz ~/.local/bin
rm hubble-linux-amd64.tar.gz{,.sha256sum}
EOF

cat <<'EOF' > ~/.local/bin/k-apply.sh
#!/usr/bin/env bash

echo
echo "*****************************************************************************************"
echo "*                                                                                       *"
echo "* Deploy Metrics Server (abridged version), MetalLB  & Local-Path-Provisioner (Rancher) *"
echo "*                                                                                       *"
echo "*****************************************************************************************"
echo
kubectl apply -f https://raw.githubusercontent.com/tsanghan/content-cka-resources/master/metrics-server-components.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/metallb.yaml
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
EOF

cat <<'EOF' > ~/.local/bin/ingress-nginx.sh
#!/usr/bin/env bash

echo
echo "*****************************************************************************************"
echo "*                                                                                       *"
echo "* Deploy Ingress-NGINX Controller (Kubernetes Ingress) *"
echo "*                                                                                       *"
echo "*****************************************************************************************"
echo
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.4/deploy/static/provider/cloud/deploy.yaml
EOF

cat <<'EOF' > ~/.local/bin/nginx-ap-ingress.sh
#!/usr/bin/env bash

echo
echo "**************************************"
echo "*                                    *"
echo "* Deploy F5 NGINX Ingress Controller *"
echo "*                                    *"
echo "**************************************"
echo
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/ns-and-sa.yaml
kubectl create secret docker-registry regcred --docker-server=private-registry.nginx.com --docker-username=$(/usr/bin/cat ~/.local/share/nginx-repo.jwt) --docker-password=none -n nginx-ingress
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/rbac/rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/rbac/ap-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/default-server-secret.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/nginx-config.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/ingress-class.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/k8s.nginx.org_virtualservers.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/k8s.nginx.org_virtualserverroutes.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/k8s.nginx.org_transportservers.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/k8s.nginx.org_policies.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/k8s.nginx.org_globalconfigurations.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/appprotect.f5.com_aplogconfs.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/appprotect.f5.com_appolicies.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/appprotect.f5.com_apusersigs.yaml
kubectl apply -f https://gist.githubusercontent.com/tsanghan/496b6edfc734cacaa3b50a8fa88082a4/raw/14f48314dd500fe75ed1a7d0df65ba7919d12e33/nginx-ap-ingress.yaml
EOF

cat <<'MYEOF' > ~/.local/bin/prepare-lxd.sh
#!/usr/bin/env bash

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

k8s=$(lxc profile ls | grep k8s)
if [ "$k8s"  == "" ]; then
  lxc profile create k8s

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
EOF
fi

k8s_cloud_init=$(lxc profile ls | grep k8s-cloud-init)
if [ "$k8s_cloud_init"  == "" ]; then
  lxc profile create k8s-cloud-init

  cat <<EOF > /tmp/lxd-profile-k8s-cloud-init
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
EOF

  KUBE_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt | sed 's/v\(.*\)/\1/')
  PROXY=$(grep Proxy /etc/apt/apt.conf.d/* | awk '{print $2}' | tr -d ';')
  if [ "$PROXY" != "" ]; then
    echo "        proxy: $PROXY" >> /tmp/lxd-profile-k8s-cloud-init
  fi

  cat <<EOF >> /tmp/lxd-profile-k8s-cloud-init
        sources:
          kubernetes.list:
            source: "deb http://apt.kubernetes.io/ kubernetes-xenial main"
            keyid: 7F92E05B31093BEF5A3C2D38FEEA9169307EA071
      packages:
        - apt-transport-https
        - ca-certificates
        - containerd
        - curl
        - kubeadm=$KUBE_VER-00
        - kubelet=$KUBE_VER-00
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
      - content: |
          runtime-endpoint: unix:///run/containerd/containerd.sock
          image-endpoint: unix:///run/containerd/containerd.sock
          timeout: 10
        owner: root:root
        path: /etc/crictl.yaml
        permissions: '0644'
      runcmd:
        - apt-get -y purge nano
        - apt-get -y autoremove
        - systemctl enable mount-make-rshare
        - kubeadm config images pull
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
EOF

  cat /tmp/lxd-profile-k8s-cloud-init | lxc profile edit k8s-cloud-init
  rm /tmp/lxd-profile-k8s-cloud-init
fi


lb=$(lxc profile ls | grep lb)
  if [ "$lb"  == "" ]; then
  lxc profile create lb

  cat <<EOF > /tmp/lxd-profile-lb
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
EOF

  PROXY=$(grep Proxy /etc/apt/apt.conf.d/* | awk '{print $2}' | tr -d ';')
  if [ "$PROXY" != "" ]; then
    echo "        proxy: $PROXY" >> /tmp/lxd-profile-lb
  fi

  cat <<EOF >> /tmp/lxd-profile-lb
        sources:
          kubernetes.list:
            source: "deb http://apt.kubernetes.io/ kubernetes-xenial main"
            keyid: 7F92E05B31093BEF5A3C2D38FEEA9169307EA071
      packages:
        - apt-transport-https
        - ca-certificates
        - nginx
      package_update: true
      package_upgrade: true
      package_reboot_if_required: true
      locale: en_SG.UTF-8
      locale_configfile: /etc/default/locale
      timezone: Asia/Singapore
      write_files:
      - content: |
          stream {
              upstream lxd-ctrlp {
                  server lxd-ctrlp-1:6443;
                  server lxd-ctrlp-2:6443;
                  server lxd-ctrlp-3:6443;
              }
              server {
                  listen 6443;
                  proxy_pass lxd-ctrlp;
              }
          }
        path: /etc/nginx/nginx.conf
        append: true
        defer: true
      runcmd:
        - apt-get -y purge nano
        - apt-get -y autoremove
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
EOF

  cat /tmp/lxd-profile-lb | lxc profile edit lb
  rm /tmp/lxd-profile-lb
fi
MYEOF

cat <<'MYEOF' >> ~/.local/bin/prepare-lxd.sh
# VERSION=$(curl -sSL https://uk.lxd.images.canonical.com/streams/v1/images.json | jq '.products."ubuntu:focal:amd64:cloud".versions | keys[]' | sort -r | head -1 | tr -d '"')
# curl -SLO https://uk.lxd.images.canonical.com/images/ubuntu/focal/amd64/cloud/"$VERSION"/lxd.tar.xz
# curl -SLO https://uk.lxd.images.canonical.com/images/ubuntu/focal/amd64/cloud/"$VERSION"/rootfs.squashfs
# lxc image import lxd.tar.xz rootfs.squashfs --alias focal-cloud
# rm lxd.tar.xz rootfs.squashfs
image=$(lxc image ls | grep focal-cloud)
if [ "$image" == "" ]; then
  VERSION=$(curl -sSL https://cloud-images.ubuntu.com/daily/streams/v1/com.ubuntu.cloud:daily:download.json | jq '.products."com.ubuntu.cloud.daily:server:20.04:amd64".versions | keys[]' | sort -r | head -1 | tr -d '"')
  PROXY=$(grep Proxy /etc/apt/apt.conf.d/* | awk '{print $2}' | tr -d ';|"' | sed 's@^http://\(.*\):3142/@\1@')
  if [ "$PROXY" != "" ]; then
    SERVER=$PROXY
  else
    SERVER="https://cloud-images.ubuntu.com"
  fi
  curl -SLO "$SERVER"/server/focal/"$VERSION"/focal-server-cloudimg-amd64-lxd.tar.xz
  curl -SLO "$SERVER"/server/focal/"$VERSION"/focal-server-cloudimg-amd64.squashfs
  lxc image import focal-server-cloudimg-amd64-lxd.tar.xz focal-server-cloudimg-amd64.squashfs --alias focal-cloud
  rm focal-server-cloudimg-amd64-lxd.tar.xz focal-server-cloudimg-amd64.squashfs
fi
MYEOF

cat <<'EOF' > ~/.local/bin/create-common.sh
#!/usr/bin/env bash

check_lxd_status () {
  echo -n "Wait"
  while true; do
    STATUS=$(lxc ls | grep -c "$1")
    if [ "$STATUS" = "$2" ]; then
      break
    fi
    echo -n "$3"
    sleep 2
  done
  sleep 2
  echo
}

common=$(lxc image ls | grep lxd-common)
if [ "common" == "" ]; then
  lxc launch -p k8s-cloud-init focal-cloud lxd-common
  check_lxd_statuc STOP 1 .
  lxc publish lxd-common --alias lxd-common
  lxc delete lxd-common
else
  echo "lxd-common already created."
fi
EOF

cat <<'EOF' > ~/.bash_complete
# For kubernetes-env

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

cat <<'MYEOF' > ~/.local/bin/update_kubectl.sh
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
  echo "kubeclt not found or not executable!!"
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

cat <<'MYEOF' > ~/.local/bin/create-cluster.sh
#!/usr/bin/env bash

check_lxd_status () {
  echo -n "Wait"
  while true; do
    STATUS=$(lxc ls | grep -c "$1")
    if [ "$STATUS" = "$2" ]; then
      break
    fi
    echo -n "$3"
    sleep 2
  done
  sleep 2
  echo
}

check_cilium_status () {
  echo -n "Wait"
  while true; do
    STATUS=$(cilium status | grep "Cilium:" | awk '{print $4}' | sed 's/\x1b\[[0-9;]*m//g')
    if [ "$STATUS" = "OK" ]; then
      break
    fi
    echo -n "$1"
    sleep 2
  done
  sleep 2
  echo
}

update_local_etc_hosts () {
  OUT=$(grep lxd-ctrlp-1 /etc/hosts)
  if [[ $OUT == "" ]]; then
    sudo sed -i "/127.0.0.1 localhost/s/localhost/localhost\n$1 lxd-ctrlp-1/" /etc/hosts
  elif [[ "$OUT" =~ lxd-ctrlp-1 ]]; then
    sudo sed -ri "/lxd/s/^([0-9]{1,3}\.){3}[0-9]{1,3}/$1/" /etc/hosts
  else
    echo "Error!!"
  fi
}

common=$(lxc image ls | grep lxd-common)
if [ "common" == "" ]; then
  image=focal-cloud
else
  image=lxd-common
fi

for c in ctrlp-1 wrker-1 wrker-2; do
  lxc launch -p k8s "$image" lxd-"$c"
done

common=$(lxc image ls | grep lxd-common)
if [ "common" == "" ]; then
  check_lxd_status STOP 3 .
  lxc start --all
  check_lxd_status eth0 3 \!
fi

IPADDR=$(lxc ls | grep ctrlp | awk '{print $6}')
update_local_etc_hosts "$IPADDR"
echo
lxc exec lxd-ctrlp-1 -- kubeadm init --control-plane-endpoint lxd-ctrlp-1:6443 --upload-certs | tee kubeadm-init.out
lxc file pull lxd-ctrlp-1/etc/kubernetes/admin.conf ~/.k/config-lxd
ln -sf ~/.k/config-lxd ~/.k/config
sleep 8
echo
for c in 1 2; do
  # shellcheck disable=SC2046 # code is irrelevant because lxc exec will not run commands in containers
  lxc exec lxd-wrker-"$c" -- $(tail -2 kubeadm-init.out | tr -d '\\\n')
  sleep 8
  echo
done
kubectl get no -owide | grep --color NotReady
echo
if ! command  -v cilium &> /dev/null; then
  get-cilium.sh
fi
cilium install
check_cilium_status @
echo
kubectl get no -owide | GREP_COLORS="ms=1;92" grep --color Ready
echo
sed "/replace/s/{{ replace-me }}/10.254.254/g" < metallab-configmap.yaml.tmpl | kubectl apply -f -
k-apply.sh
nginx-ap-ingress.sh
MYEOF

cat <<'MYEOF' > ~/.local/bin/create-cluster-mm.sh
#!/usr/bin/env bash

check_lxd_status () {
  echo -n "Wait"
  while true; do
    STATUS=$(lxc ls | grep -c "$1")
    if [ "$STATUS" = "$2" ]; then
      break
    fi
    echo -n "$3"
    sleep 2
  done
  sleep 2
  echo
}

check_cilium_status () {
  echo -n "Wait"
  while true; do
    STATUS=$(cilium status | grep "Cilium:" | awk '{print $4}' | sed 's/\x1b\[[0-9;]*m//g')
    if [ "$STATUS" = "OK" ]; then
      break
    fi
    echo -n "$1"
    sleep 2
  done
  sleep 2
  echo
}

update_local_etc_hosts () {
  OUT=$(grep lxd-ctrlp-1 /etc/hosts)
  if [[ $OUT == "" ]]; then
    sudo sed -i "/127.0.0.1 localhost/s/localhost/localhost\n$1 lxd-lb/" /etc/hosts
  elif [[ "$OUT" =~ lxd-lb ]]; then
    sudo sed -ri "/lxd/s/^([0-9]{1,3}\.){3}[0-9]{1,3}/$1/" /etc/hosts
  else
    echo "Error!!"
  fi
}

common=$(lxc image ls | grep lxd-common)
if [ "common" == "" ]; then
  image=focal-cloud
else
  image=lxd-common
fi

lxc launch -p lb focal-cloud lxd-lb
for c in ctrlp-1 ctrlp-2 ctrlp-3 wrker-1 wrker-2 wrker-3; do
  lxc launch -p k8s "$image" lxd-"$c"
done

common=$(lxc image ls | grep lxd-common)
if [ "common" == "" ]; then
  check_lxd_status STOP 7 .
  lxc start lxd-ctrlp-1 lxd-ctrlp-2 lxd-ctrlp-3
  sleep 8
  lxc start --all
  check_lxd_status eth0 7 \!
fi

IPADDR=$(lxc ls | grep lb | awk '{print $6}')
update_local_etc_hosts "$IPADDR"
sleep 8
echo
lxc exec lxd-ctrlp-1 -- kubeadm init --control-plane-endpoint lxd-lb:6443 --upload-certs | tee kubeadm-init.out
lxc file pull lxd-ctrlp-1/etc/kubernetes/admin.conf ~/.k/config-lxd
ln -sf ~/.k/config-lxd ~/.k/config
sleep 8
echo
for c in 2 3; do
  # shellcheck disable=SC2046 # code is irrelevant because lxc exec will not run commands in containers
  lxc exec lxd-ctrlp-"$c" -- $(tail -12 kubeadm-init.out | head -3 | tr -d '\\\n')
  sleep 8
  echo
done
for c in 1 2 3; do
  # shellcheck disable=SC2046 # code is irrelevant because lxc exec will not run commands in containers
  lxc exec lxd-wrker-"$c" -- $(tail -2 kubeadm-init.out | tr -d '\\\n')
  sleep 8
  echo
done
kubectl get no -owide | grep --color NotReady
echo
if ! command  -v cilium &> /dev/null; then
  get-cilium.sh
fi
cilium install
check_cilium_status @
echo
kubectl get no -owide | GREP_COLORS="ms=1;92" grep --color Ready
echo
sed "/replace/s/{{ replace-me }}/10.254.254/g" < metallab-configmap.yaml.tmpl | kubectl apply -f -
k-apply.sh
nginx-ap-ingress.sh
MYEOF

cat <<'MYEOF' > ~/.local/bin/stop-cluster.sh
#!/usr/bin/env bash

while getopts "d" o; do
    case "${o}" in
        d)
            delete="true"
            ;;
    esac
done
shift $((OPTIND-1))
lxc stop --all --force
if [ "$delete"  == "true" ]; then
  for c in $(lxc ls | grep lxd | awk '{print $2}'); do lxc delete "$c"; done
fi
rm ~/.k/{config,config-lxd} 2> /dev/null
MYEOF

cat <<'MYEOF' > ~/.local/bin/record-k9s.sh
#!/usr/bin/env bash

while true;
do
  if [ -e ~/.k/config ]; then
    break;
  fi
done
k9s
MYEOF

# Install kubectl
if [ ! -f ~/.local/bin/kubectl ]; then
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
fi

# Install kind
if [ ! -f ~/.local/bin/kind ]; then
  curl -sSL -o ~/.local/bin/kind \
    "$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq ".assets[].browser_download_url" | grep amd64 | grep linux | tr -d '"')"
fi 
# Install k9s
if [ ! -f ~/.local/bin/k9s ]; then
  K9S_FRIEND=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep Linux | tr -d '"')
  curl -sSL "$K9S_FRIEND" | tar -C ~/.local/bin -zxvf - "$(basename \""$K9S_FRIEND\"" | sed 's/\(.*\)_Linux_.*/\1/')"
fi
# Install yq
if [ ! -f ~/.local/bin/yq ]; then
curl -sSL -o ~/.local/bin/yq \
  "$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | jq ".assets[].browser_download_url" | grep -v "tar.gz" | grep amd64 | grep linux | tr -d '"')"
fi

# Install shellcheck
if [ ! -f ~/.local/bin/shellcheck ]; then
  SHELLCHECK=$(curl -s https://api.github.com/repos/koalaman/shellcheck/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep linux | tr -d '"')
  SHELLCHECK_DIR=$(basename "$SHELLCHECK" | sed 's/\(^.*v.*\).linux.*/\1/')
  SHELLCHECK_BIN=$(basename "$SHELLCHECK" | sed 's/\(.*\)-v.*/\1/')
  curl -sSL "$SHELLCHECK" | tar -C /tmp --xz -xvf - "$SHELLCHECK_DIR"/"$SHELLCHECK_BIN"
  mv /tmp/"$SHELLCHECK_DIR"/"$SHELLCHECK_BIN" ~/.local/bin
  rm -rf /tmp/"$SHELLCHECK_DIR"
fi

# Install kubectx & kubens
if [ ! -f ~/.local/bin/kubectx ] || [ ! -f ~/.local/bin/kubens ]; then
  KUBE_FRIENDS=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep linux | tr -d '"')
  for friend in $KUBE_FRIENDS
  do
    curl -sSL "$friend" | tar -C ~/.local/bin -zxvf - "$(basename \""$friend\"" | sed 's/\(.*\)_v.*/\1/')"
  done
fi

chmod +x ~/.local/bin/*

echo -e "\n"
echo "*************************************************************************************"
echo "*                                                                                   *"
echo "*  Please logout and relogin again for docker,lxd group membership to take effect.  *"
echo "*                                                                                   *"
echo "*************************************************************************************"
echo -e "\n\n"
