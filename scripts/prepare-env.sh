#!/usr/bin/env bash

USER=$(whoami)
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/completions
mkdir -p ~/.local/man/man{1,2,3,4,5,6,7,8,9}
mkdir -p ~/.config/k9s
if [ ! -f ~/.config/.disk ]; then
  if [ -f /tmp/.disk ]; then
    mv /tmp/.disk ~/.config
  else
    echo "Did not detech Disk Device name!!"
    echo "LXD profile may be incorrect configured. Proceed at your own risk!!"
  fi
fi
curl -sSL -o ~/.config/k9s/skin.yml https://raw.githubusercontent.com/derailed/k9s/master/skins/dracula.yml
# CONTAINERD_LATEST=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest)
# CONTAINERD_VER=$(echo -E "$CONTAINERD_LATEST" | jq -M ".tag_name" | tr -d '"')
# CRUN_LATEST=$(curl -s https://api.github.com/repos/containers/crun/releases/latest)
# CRUN_VER=$(echo -E "$CRUN_LATEST" | jq -M ".tag_name" | tr -d '"')

# Install get-fzf.sh

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

# Install get-cilium.sh

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

# Install get-hubble.sh

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
HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
export HUBBLE_VERSION
curl -L --remote-name-all https://github.com/cilium/hubble/releases/download/"$HUBBLE_VERSION"/hubble-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-amd64.tar.gz.sha256sum
tar xzvfC hubble-linux-amd64.tar.gz ~/.local/bin
rm hubble-linux-amd64.tar.gz{,.sha256sum}
EOF

# Install get-krew.sh
cat <<'EOF' > ~/.local/bin/get-krew.sh
#!/usr/bin/env bash

echo
echo "*****************************"
echo "*                           *"
echo "* Download and Install Krew *"
echo "*                           *"
echo "*****************************"
echo
# Ref: https://krew.sigs.k8s.io/docs/user-guide/setup/install/
if [ ! -d ~/.krew ]; then
  mkdir ~/.krew
fi
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)
EOF

# Install get-helm.sh
cat <<'EOF' > ~/.local/bin/get-helm.sh
#!/usr/bin/env bash

echo
echo "*****************************"
echo "*                           *"
echo "* Download and Install Helm *"
echo "*                           *"
echo "*****************************"
echo
curl -fsSL -o ~/.local/bin/get-helm-3.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sed -i "/HELM_INSTALL_DIR/s#/usr/local#$HOME/.local#" ~/.local/bin/get-helm-3.sh
sed -i "/runAsRoot cp/s#runAsRoot cp#cp#" ~/.local/bin/get-helm-3.sh
chmod +x ~/.local/bin/get-helm-3.sh
~/.local/bin/get-helm-3.sh
EOF

# Install VirtualBox
cat <<'EOF' > ~/.local/bin/get-vb.sh
#!/usr/bin/env bash

echo
echo "***********************************"
echo "*                                 *"
echo "* Download and Install VirtualBox *"
echo "*                                 *"
echo "***********************************"
echo

curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor -o /usr/share/keyrings/oracle_vbox_2016.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/oracle_vbox_2016.gpg] \
  http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | \
  sudo tee /etc/apt/sources.list.d/oracle_vbox.list

sudo apt update
sudo apt install virtualbox mkisofs -y
EOF

# Install Vagrant
cat <<'EOF' > ~/.local/bin/get-vagrant.sh
#!/usr/bin/env bash

pushd () {
    command pushd "$@" > /dev/null || exit
}

popd () {
    command popd > /dev/null || exit
}

echo
echo "********************************"
echo "*                              *"
echo "* Download and Install Vagrant *"
echo "*                              *"
echo "********************************"
echo
pushd .
cd /tmp || exit
LATEST=$(curl -SL https://releases.hashicorp.com/vagrant | grep ">vagrant_.*<" | sed 's#^.*>vagrant_\(.*\)<.*#\1#' | head -1)
curl -sSLO https://releases.hashicorp.com/vagrant/"$LATEST"/vagrant_"$LATEST"_x86_64.deb
sudo apt install ./vagrant_"$LATEST"_x86_64.deb
rm ./vagrant_"$LATEST"_x86_64.deb
popd || exit
vagrant plugin install vagrant-vbguest
EOF

# Install arkade
cat <<'EOF' > ~/.local/bin/get-arkade.sh
#!/usr/bin/env bash

pushd () {
    command pushd "$@" > /dev/null || exit
}

popd () {
    command popd > /dev/null || exit
}

echo
echo "*******************************"
echo "*                             *"
echo "* Download and Install Arkade *"
echo "*                             *"
echo "*******************************"
echo
pushd .
cd /tmp || exit
LATEST=$(curl -s https://api.github.com/repos/alexellis/arkade/releases/latest | jq ".assets[].browser_download_url" | egrep -v "arm|darwin|\.exe|sha" | tr -d '"')
curl -L --remote-name-all "$LATEST"{,.sha256}
OK=$(sed "s#bin/##" < arkade.sha256 | sha256sum --check)
if [[ ! "$OK" =~ .*OK$ ]]; then
  echo "Arkade checksum NOT OK!! Exiting!!"
  rm arkade*
  exit 1
fi
chmod +x arkade
mv arkade ~/.local/bin
ln -s ~/.local/bin/arkade ~/.local/bin/ark
rm arkade*
popd || exit
EOF

# Install step

cat <<'EOF' > ~/.local/bin/get-step.sh
#!/usr/bin/env bash

pushd () {
    command pushd "$@" > /dev/null || exit
}

popd () {
    command popd > /dev/null || exit
}
echo
echo "*****************************"
echo "*                           *"
echo "* Download and Install Step *"
echo "*                           *"
echo "*****************************"
echo
pushd .
cd /tmp || exit
# Ref: https://github.com/smallstep/cli/releases/
STEP_VER=$(curl -s https://api.github.com/repos/smallstep/cli/releases/latest | jq ".tag_name" | tr -d '"')
STEP=$(curl -s https://api.github.com/repos/smallstep/cli/releases/latest | jq ".assets[].browser_download_url" | grep amd64 | grep linux | grep -v sig | tr -d '"')
CHECKSUM=$(curl -s https://api.github.com/repos/smallstep/cli/releases/latest | jq ".assets[].browser_download_url" | grep checksum | grep -v sig | tr -d '"')
curl -L --remote-name-all "$STEP" "$CHECKSUM"
sha256sum --ignore-missing --check $(basename "$CHECKSUM")
tar xzvf $(basename "$STEP")
mv step_"${STEP_VER:1}"/bin/step ~/.local/bin/step
mv step_"${STEP_VER:1}"/autocomplete/* ~/.local/share/completions
rm -rf step_*
popd || exit
EOF

# Install calicoctl

cat <<'EOF' > ~/.local/bin/get-calicoctl.sh
#!/usr/bin/env bash

echo
echo "**********************************"
echo "*                                *"
echo "* Download and Install Calicoctl *"
echo "*                                *"
echo "**********************************"
echo
# Ref: https://projectcalico.docs.tigera.io/maintenance/clis/calicoctl/install#install-calicoctl-as-a-binary-on-a-single-host
curl -L https://github.com/projectcalico/calico/releases/download/v3.22.0/calicoctl-linux-amd64 -o ~/.local/bin/calicoctl
curl -L https://github.com/projectcalico/calico/releases/download/v3.22.0/calicoctl-linux-amd64 -o ~/.local/bin/kubectl-calico
chmod +x ~/.local/bin/calicoctl ~/.local/bin/kubectl-calico
EOF

# Create VBX cluster
cat <<'EOF' > ~/.local/bin/create-vbx-cluster.sh
#!/usr/bin/env bash

# Ref: https://github.com/scriptcamp/vagrant-kubeadm-kubernetes/blob/main/scripts/master.sh

if [ -f kubeadm-init.out ]; then
  rm kubeadm-init.out
fi
if [ -f config ]; then
  rm config
fi

cat <<MYEOF > cloud.cfg
#cloud-config

apt:
  preserve_sources_list: false

  primary:
    - arches:
      - amd64
      uri: "http://mirror.0x.sg/ubuntu/"

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
 - jq
 - kubeadm
 - kubelet
 - containerd

package_update: true

package_upgrade: true

package_reboot_if_required: true

mount_default_fields: [ None, None, "auto", "defaults,nobootwait", "0", "2" ]

locale: en_SG.UTF-8
locale_configfile: /etc/default/locale

resize_rootfs: True

final_message: "The system is finally up, after $UPTIME seconds"

timezone: Asia/Singapore

ntp:
  enabled: true
manual_cache_clean: True

write_files:
- content: |
      overlay
      br_netfilter
      nf_conntrack
  owner: root:root
  path: /etc/modules-load.d/containerd.conf
  permissions: '0644'

- content: |
      options nf_conntrack hashsize=32768
  owner: root:root
  path: /etc/modprobe.d/containerd.conf
  permissions: '0644'

- content: |
      net.bridge.bridge-nf-call-iptables=1
      net.ipv4.ip_forward=1
      net.bridge.bridge-nf-call-ip6tables=1
  path: /etc/sysctl.d/99-sysctl.conf
  append: true

- content: |
      127.0.0.1 localhost
      10.253.253.11 vbx-ctrlp-1
      10.253.253.12 vbx-wrker-1
      10.253.253.13 vbx-wrker-2

      # The following lines are desirable for IPv6 capable hosts
      ::1 ip6-localhost ip6-loopback
      fe00::0 ip6-localnet
      ff00::0 ip6-mcastprefix
      ff02::1 ip6-allnodes
      ff02::2 ip6-allrouters
      ff02::3 ip6-allhosts
  owner: root:root
  path: /etc/hosts
  permissions: '0644'

runcmd:
 - apt-get -y purge nano
 - apt-get -y autoremove
 - modprobe br_netfilter
 - modprobe nf_conntrack
 - sysctl --system
 - mkdir -p /etc/containerd
 - containerd config default | tee /etc/containerd/config.toml
 - systemctl restart containerd
MYEOF

cat <<MYEOF > Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

    CtrlpCount = 1

    (1..CtrlpCount).each do |i|
    config.vm.define "vbx-ctrlp-1" do |ctrlp|
            ctrlp.vm.box = "ubuntu/focal64"
            ctrlp.vm.network :private_network, ip: "10.253.253.1#{i}"
            ctrlp.vm.hostname = "vbx-ctrlp-1"
            ctrlp.vm.cloud_init :user_data, content_type: "text/cloud-config", path: "cloud.cfg"
            ctrlp.vm.provider :virtualbox do |v|
                v.memory = 2048
                v.cpus = 2
            end
        end
    end

    NodeCount = 2

    (1..NodeCount).each do |i|
        config.vm.define "vbx-wrker-#{i}" do |node|
            node.vm.box = "ubuntu/focal64"
            node.vm.network :private_network, ip: "10.253.253.1#{i+CtrlpCount}"
            node.vm.hostname = "vbx-wrker-#{i}"
            node.vm.cloud_init :user_data, content_type: "text/cloud-config", path: "cloud.cfg"
            node.vm.provider :virtualbox do |v|
                v.memory = 1536
                v.cpus = 2
            end
        end
    end

    config.vm.box_check_update = false
    config.vbguest.auto_update = false
    config.vm.boot_timeout = 600
end
MYEOF

VAGRANT_EXPERIMENTAL="cloud_init,disks" vagrant up
vagrant ssh vbx-ctrlp-1 -c "sudo kubeadm init \
                              --apiserver-advertise-address=10.253.253.11 \
                              --apiserver-cert-extra-sans=10.253.253.11 \
                              --node-name vbx-ctrlp-1 \
                              --pod-network-cidr=192.168.0.0/16 \
                              --upload-certs | \
                              tee kubeadm-init.out" 2> /dev/null
vagrant ssh vbx-ctrlp-1 -c "mv kubeadm-init.out /vagrant" 2> /dev/null
vagrant ssh vbx-ctrlp-1 -c "sudo cp /etc/kubernetes/admin.conf /vagrant/config" 2> /dev/null
cp config ~/.kube/config
vagrant ssh vbx-wrker-1 -c "sudo $(tail -2 kubeadm-init.out | tr -d '\\\n')" 2> /dev/null
vagrant ssh vbx-wrker-2 -c "sudo $(tail -2 kubeadm-init.out | tr -d '\\\n')" 2> /dev/null
curl -sSL https://docs.projectcalico.org/manifests/calico.yaml | sed 's#policy/v1beta1#policy/v1#' | kubectl apply -f -
rm cloud.cfg Vagrantfile
EOF

# Stop VBX cluster
#!/usr/bin/env bash
cat <<'EOF' > ~/.local/bin/stop-vbx-cluster.sh
#!/usr/bin/env bash
cat <<MYEOF > Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

    CtrlpCount = 1

    (1..CtrlpCount).each do |i|
    config.vm.define "vbx-ctrlp-1" do |ctrlp|
            ctrlp.vm.box = "ubuntu/focal64"
            ctrlp.vm.network :private_network, ip: "10.253.253.1#{i}"
            ctrlp.vm.hostname = "vbx-ctrlp-1"
            ctrlp.vm.cloud_init :user_data, content_type: "text/cloud-config", path: "cloud.cfg"
            ctrlp.vm.provider :virtualbox do |v|
                v.memory = 2048
                v.cpus = 2
            end
        end
    end

    NodeCount = 2

    (1..NodeCount).each do |i|
        config.vm.define "vbx-wrker-#{i}" do |node|
            node.vm.box = "ubuntu/focal64"
            node.vm.network :private_network, ip: "10.253.253.1#{i+CtrlpCount}"
            node.vm.hostname = "vbx-wrker-#{i}"
            node.vm.cloud_init :user_data, content_type: "text/cloud-config", path: "cloud.cfg"
            node.vm.provider :virtualbox do |v|
                v.memory = 1536
                v.cpus = 2
            end
        end
    end

    config.vm.box_check_update = false
    config.vbguest.auto_update = false
    config.vm.boot_timeout = 600
end
MYEOF
vagrant destroy -f
rm Vagrantfile
EOF

# Install k-apply.sh
cat <<'EOF' > ~/.local/bin/k-apply.sh
#!/usr/bin/env bash

echo
echo "****************************************************************************************"
echo "*                                                                                      *"
echo "* Deploy Metrics Server (abridged version), MetalLB & Local-Path-Provisioner (Rancher) *"
echo "*                                                                                      *"
echo "****************************************************************************************"
echo
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/metrics-server-helm-chart-3.7.0/components.yaml
kubectl apply -f https://raw.githubusercontent.com/tsanghan/content-cka-resources/master/metrics-server-components.yaml
# kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

# Deprecated Chart: Ref: https://github.com/helm/charts/tree/master/stable/metallb
# helm upgrade --install metallb metallb \
#   --repo https://metallb.github.io/metallb \
#   --namespace metallb --create-namespace \
#   --values metallb-values.yaml
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install metallb --namespace metallb --create-namespace --values metallb-values.yaml
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
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.1/deploy/static/provider/cloud/deploy.yaml
# helm upgrade --install ingress-nginx ingress-nginx \
#   --repo https://kubernetes.github.io/ingress-nginx \
#   --namespace ingress-nginx --create-namespace
# Ref: https://github.com/f5devcentral/nginx_microservices_march_labs/blob/main/one/content.md
helm repo add nginx-stable https://helm.nginx.com/stable
helm install main nginx-stable/nginx-ingress \
  --set controller.watchIngressWithoutClass=true
EOF

cat <<'EOF' > ~/.local/bin/nginx-ap-ingress.sh
#!/usr/bin/env bash
iface=$(ip link | grep ens | awk '{print $2}' | tr -d ':')
if [ "$iface" == "" ]; then
  echo "Interface ens* no found!!"
  exit 127
fi
IP=$(ip a s "$iface" | head -3 | tail -1 | awk '{print $2}' | tr -d '/24$')
while getopts "p" o; do
    case "$o" in
        p)
            private="true"
            ;;
        *)
            ;;
    esac
done
shift $((OPTIND-1))

echo
echo "**************************************"
echo "*                                    *"
echo "* Deploy F5 NGINX Ingress Controller *"
echo "*                                    *"
echo "**************************************"
echo
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/ns-and-sa.yaml
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
if [ "$private" == "true" ]; then
  curl -sSL https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/master/deployments/deployment/nginx-plus-ingress.yaml |\
    sed '/image\:/s#\: #\: '"$IP"'/nginx-ic-nap/#' |\
    sed '/enable-app-protect$/s%#-% -%'|\
    kubectl apply -f -
else
  kubectl create secret docker-registry regcred \
    --docker-server=private-registry.nginx.com \
    --docker-username="$(/usr/bin/cat ~/.local/share/nginx-repo.jwt)" \
    --docker-password=none -n nginx-ingress
  curl -sSL https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/master/deployments/deployment/nginx-plus-ingress.yaml |\
    sed '/image\:/s#\: #\: private-registry.nginx.com/nginx-ic-nap/#' |\
    sed '/enable-app-protect$/s%#-% -%'|\
    kubectl apply -f -
fi
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/master/deployments/service/loadbalancer.yaml
EOF

cat <<'MYEOF' > ~/.local/bin/prepare-lxd.sh
#!/usr/bin/env bash

CONTAINERD_LATEST=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest)
CONTAINERD_VER=$(echo -E "$CONTAINERD_LATEST" | jq -M ".tag_name" | tr -d '"')
CRUN_LATEST=$(curl -s https://api.github.com/repos/containers/crun/releases/latest)
CRUN_VER=$(echo -E "$CRUN_LATEST" | jq -M ".tag_name" | tr -d '"')
KUBE_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt)
if [ -f ~/.config/.disk ]; then
  disk=$(< ~/.config/.disk)
else
  disk=$(fdisk -l | grep Linux | awk '{print $1}')
fi

while getopts "s" o; do
    case "$o" in
        s)
            slim="true"
            ;;
        *)
            ;;
    esac
done
shift $((OPTIND-1))

for profile in lb k8s-cloud-init nfs-server;
do
  exists=$(lxc profile ls | grep "$profile")
  if [ "$exists" != "" ]; then
    lxc profile delete "$profile"
  fi
done

PROXY=$(grep Proxy /etc/apt/apt.conf.d/* | awk '{print $2}' | tr -d ';')
if [ "$PROXY" == "" ]; then
  k8s_cloud_init=$(lxc profile ls | grep k8s-cloud-init)
  if [ "$k8s_cloud_init"  == "" ]; then
    lxc profile create k8s-cloud-init
    cat <<-EOF | lxc profile edit k8s-cloud-init
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
          - kubeadm=${KUBE_VER:1}-00
          - kubelet=${KUBE_VER:1}-00
          - jq
        package_update: false
        package_upgrade: false
        package_reboot_if_required: false
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
          - mkdir -p /etc/containerd
          - containerd config default | sed '/config_path/s#""#"/etc/containerd/certs.d"#' | tee /etc/containerd/config.toml
          - systemctl restart containerd
          - kubeadm config images pull
          - ctr oci spec | tee /etc/containerd/cri-base.json
        power_state:
          delay: "+1"
          mode: poweroff
          message: Bye Bye
          timeout: 10
          condition: True
    description: ""
    devices:
      _dev_sda1:
        path: $disk
        source: $disk
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
else
  # Ref: below PROXY=$(grep Proxy /etc/apt/apt.conf.d/* | awk '{print $2}' | tr -d ';|"' | sed 's@^http://\(.*\):3142/@\1@')
  IP=$(echo "$PROXY" | tr -d ';|"' | sed 's@^http://\(.*\):3142/@\1@')

  k8s_cloud_init=$(lxc profile ls | grep k8s-cloud-init)
  if [ "$k8s_cloud_init"  == "" ]; then
    lxc profile create k8s-cloud-init

    cat <<-EOF | lxc profile edit k8s-cloud-init
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
          proxy: $PROXY
          sources:
            kubernetes.list:
              source: "deb http://apt.kubernetes.io/ kubernetes-xenial main"
              keyid: 7F92E05B31093BEF5A3C2D38FEEA9169307EA071
        packages:
          - apt-transport-https
          - ca-certificates
          - containerd
          - curl
          - kubeadm=${KUBE_VER:1}-00
          - kubelet=${KUBE_VER:1}-00
          - jq
          - nfs-common
          - lsof
          - psmisc
        package_update: false
        package_upgrade: false
        package_reboot_if_required: false
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
        - content: |
            server = "https://docker.io"

            [host."http://$IP:5000"]
              capabilities = ["pull", "resolve"]
          owner: root:root
          path: /etc/containerd/certs.d/docker.io/hosts.toml
          permissions: '0644'
        - content: |
            server = "https://k8s.gcr.io"

            [host."http://$IP:5001"]
              capabilities = ["pull", "resolve"]
          owner: root:root
          path: /etc/containerd/certs.d/k8s.gcr.io/hosts.toml
          permissions: '0644'
        - content: |
            server = "https://quay.io"

            [host."http://$IP:5002"]
              capabilities = ["pull", "resolve"]
          owner: root:root
          path: /etc/containerd/certs.d/quay.io/hosts.toml
          permissions: '0644'
        - content: |
            server = "http://$IP"

            [host."http://$IP:6000"]
              capabilities = ["pull", "resolve"]
          owner: root:root
          path: /etc/containerd/certs.d/$IP/hosts.toml
          permissions: '0644'
        runcmd:
          - apt-get -y purge nano
          - apt-get -y autoremove
          - systemctl enable mount-make-rshare
          - tar -C / -zxvf /mnt/containerd/cri-containerd-cni-${CONTAINERD_VER:1}-linux-amd64.tar.gz
          # - cp /mnt/containerd/crun-${CRUN_VER:1}-linux-amd64 /usr/local/sbin/crun
          - mkdir -p /etc/containerd
          # - containerd config default | sed '/config_path/s#""#"/etc/containerd/certs.d"#' | sed '/plugins.*linux/{n;n;s#runc#crun#}' | tee /etc/containerd/config.toml
          # - containerd config default | sed '/config_path/s#""#"/etc/containerd/certs.d"#' | sed '/default_runtime_name/s#runc#crun#' | tee /etc/containerd/config.toml
          - containerd config default | sed '/config_path/s#""#"/etc/containerd/certs.d"#' | sed '/SystemdCgroup/s/false/true/' | tee /etc/containerd/config.toml
          - systemctl enable containerd
          - systemctl start containerd
          - kubeadm config images pull
          - ctr oci spec | tee /etc/containerd/cri-base.json
          - rm /etc/cni/net.d/10-containerd-net.conflist
        power_state:
          delay: "+1"
          mode: poweroff
          message: Bye Bye
          timeout: 10
          condition: True
    description: ""
    devices:
      _dev_sda1:
        path: $disk
        source: $disk
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
      containerd:
        path: /mnt/containerd
        source: /home/$USER/Projects/kubernetes-env/.containerd
        type: disk
EOF
  fi

  lb=$(lxc profile ls | grep lb)
  if [ "$lb"  == "" ]; then
    lxc profile create lb

    cat <<-EOF | lxc profile edit lb
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
          proxy: $PROXY
          sources:
            kubernetes.list:
              source: "deb http://apt.kubernetes.io/ kubernetes-xenial main"
              keyid: 7F92E05B31093BEF5A3C2D38FEEA9169307EA071
        packages:
          - apt-transport-https
          - ca-certificates
          - nginx
        package_update: false
        package_upgrade: false
        package_reboot_if_required: false
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
          - sleep 10
          - nginx -s reload
        default: none
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
  nfs=$(lxc profile ls | grep nfs)
  if [ "$nfs"  == "" ]; then
    # Ref: https://github.com/lxc/lxd/issues/2703
    # Ref: https://www.tecmint.com/install-nfs-server-on-ubuntu/
    # Ref: https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-20-04
    lxc profile create nfs-server

    cat <<-EOF | lxc profile edit nfs-server
    config:
      linux.kernel_modules: ip_tables,ip6_tables,netlink_diag,nf_nat,overlay
      raw.lxc: |-
        lxc.apparmor.profile=unconfined
        lxc.cap.drop=
        lxc.cgroup.devices.allow=a
        lxc.mount.auto=proc:rw sys:rw cgroup:rw
        lxc.seccomp.profile=
      raw.apparmor: "mount fstype=rpc_pipefs,\nmount fstype=nfsd,"
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
          proxy: $PROXY
          sources:
            kubernetes.list:
              source: "deb http://apt.kubernetes.io/ kubernetes-xenial main"
              keyid: 7F92E05B31093BEF5A3C2D38FEEA9169307EA071
        packages:
          - apt-transport-https
          - ca-certificates
          - nfs-kernel-server
        package_update: false
        package_upgrade: false
        package_reboot_if_required: false
        locale: en_SG.UTF-8
        locale_configfile: /etc/default/locale
        timezone: Asia/Singapore
        write_files:
        - content: |
              /mnt/nfs_share  10.254.254.0/24(rw,sync,no_subtree_check)
          path: /etc/exports
          append: true
          defer: true
        runcmd:
          - apt-get -y purge nano
          - apt-get -y autoremove
          - mkdir -p /mnt/nfs_share
          - chown -R nobody:nogroup /mnt/nfs_share/
          - chmod 777 /mnt/nfs_share/
          - exportfs -a
          - systemctl restart nfs-kernel-server
        default: none
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
  step=$(lxc profile ls | grep step)
  if [ "$step"  == "" ]; then
    # Ref: https://github.com/lxc/lxd/issues/2703
    # Ref: https://github.com/smallstep/mongo-tls/blob/main/0-step-ca.sh
    lxc profile create step-ca

    cat <<-EOF | lxc profile edit step-ca
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
          proxy: $PROXY
        packages:
          - apt-transport-https
          - ca-certificates
          - curl
          - jq
        package_update: false
        package_upgrade: false
        package_reboot_if_required: false
        locale: en_SG.UTF-8
        locale_configfile: /etc/default/locale
        timezone: Asia/Singapore
        runcmd:
          - apt-get -y purge nano
          - apt-get -y autoremove
        default: none
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
  pull-containerd.sh
fi

YY=20
CODE_NAMES=(focal impish jammy)
image=$(lxc image ls | grep focal-cloud)
if [ "$image" == "" ]; then
  if [ "$slim" == "" ]; then
    VERSION=$(curl -sSL https://cloud-images.ubuntu.com/daily/streams/v1/com.ubuntu.cloud:daily:download.json | \
              jq ".products.\"com.ubuntu.cloud.daily:server:$YY.04:amd64\".versions | keys[]" | sort -r | head -1 | tr -d '"')
    PROXY=$(grep Proxy /etc/apt/apt.conf.d/* | awk '{print $2}' | tr -d ';|"' | sed 's@^http://\(.*\):3142/@\1@')
    if [ "$PROXY" != "" ]; then
      SERVER=http://$PROXY
    else
      SERVER="https://cloud-images.ubuntu.com"
    fi
    curl -SLO "$SERVER"/server/focal/"$VERSION"/focal-server-cloudimg-amd64-lxd.tar.xz
    curl -SLO "$SERVER"/server/focal/"$VERSION"/focal-server-cloudimg-amd64.squashfs
    lxc image import focal-server-cloudimg-amd64-lxd.tar.xz focal-server-cloudimg-amd64.squashfs --alias focal-cloud
    rm focal-server-cloudimg-amd64-lxd.tar.xz focal-server-cloudimg-amd64.squashfs
  else
    for CODE_NAME in "${CODE_NAMES[@]}"; do
      VERSION=$(curl -sSL https://us.lxd.images.canonical.com/streams/v1/images.json | \
                jq ".products.\"ubuntu:$CODE_NAME:amd64:cloud\".versions | keys[]" | sort -r | head -1 | tr -d '"')
      curl -SLO https://us.lxd.images.canonical.com/images/ubuntu/"$CODE_NAME"/amd64/cloud/"$VERSION"/lxd.tar.xz
      curl -SLO https://us.lxd.images.canonical.com/images/ubuntu/"$CODE_NAME"/amd64/cloud/"$VERSION"/rootfs.squashfs
      lxc image import lxd.tar.xz rootfs.squashfs --alias "$CODE_NAME"-cloud
      rm lxd.tar.xz rootfs.squashfs
    done
  fi
fi
MYEOF

cat <<'EOF' > ~/.bash_complete
# For kubernetes-env

if [ -x ~/.local/bin/kubectl ]
then
  source <(kubectl completion bash)
  alias k=kubectl
  complete -F __start_kubectl k
  alias k=kubecolor
fi

if [ -x ~/.local/bin/helm ]
then
  source <(helm completion bash)
  complete -F __start_helm helm
fi

if [ -x ~/.local/bin/kind ]
then
  source <(kind completion bash)
  complete -F __start_kind kind
fi

if [ -x ~/.local/bin/kubecolor ]
then
  alias kc=kubecolor
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

OLD_KUBECTL_VER=$(kubectl version --short --client)
NEW_KUBECTL_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt)

verlt "${OLD_KUBECTL_VER:1}" "${NEW_KUBECTL_VER:1}"
if [ "$?"  = 1 ]; then
  echo "No upgrade required!!"
  exit
else
  curl -sSL -o /tmp/kubectl "https://dl.k8s.io/$NEW_KUBECTL_VER/bin/linux/amd64/kubectl"
  KUBECTL_SHA256=$(curl -sSL https://dl.k8s.io/"$NEW_KUBECTL_VER"/bin/linux/amd64/kubectl.sha256)
  OK=$(echo "$KUBECTL_SHA256" /tmp/kubectl | sha256sum --check)
  if [[ ! "$OK" =~ .*OK$ ]]; then
    echo "kubectl binary does not match sha256 checksum, aborting!!"
    rm /tmp/kubectl
    exit $?
  else
    echo "Installing kubectl verion=$NEW_KUBECTL_VER"
    mv /tmp/kubectl ~/.local/bin/kubectl
    chmod +x ~/.local/bin/kubectl
  fi
fi
MYEOF

cat <<'MYEOF' > ~/.local/bin/update_k9s.sh
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

if [ ! -x ~/.local/bin/k9s ]; then
  echo "k9s not found or not executable!!"
  exit
fi

OLD_K9S_VER=$(k9s version | grep Version)
K9S_LATEST=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest)
NEW_K9S_VER=$(echo -E "$K9S_LATEST" | jq ".tag_name" | tr -d '"')

verlt "${OLD_K9S_VER:1}" "${NEW_K9S_VER:1}"
if [ "$?"  = 1 ]; then
  echo "No upgrade required!!"
  exit
else
  K9S_FRIEND=$(echo -E "$K9S_LATEST" | jq ".assets[].browser_download_url" | grep x86_64 | grep Linux | tr -d '"')
  curl -sSL "$K9S_FRIEND" | tar -C ~/.local/bin -zxvf - "$(basename \""$K9S_FRIEND\"" | sed 's/\(.*\)_Linux_.*/\1/')"
fi
MYEOF

cat <<'MYEOF' > ~/.local/bin/create-cluster.sh
#!/usr/bin/env bash

USER=$(whoami)

usage() {
  echo "Usage: $(basename $0) [-c] [-m] [-d <focal|impish|jammy>] [-w <2|3>][-n <cilium|calico|weave> [-i <ingress-ngx|nic-ap> ]]" 1>&2
  echo '       -c   "Create lxc/lxd containers only"'
  echo '       -m   "Multi-control-plane mode"'
  echo '       -n   "Install CNI. Only 2 options"'
  echo '       -i   "Install Ingress. Only 2 options. F5/NGINX Ingress Controller/AP installation not yet enabled."'
  echo
  exit 1
}

while getopts ":rlcmn:i:d:w:" o; do
    case "$o" in
        c)
            containersonly="true"
            ;;
        m)
            multimaster="true"
            ;;
        n)
            n=$OPTARG
            if [ "$n" != "cilium" ] && [ "$n" != "calico" ] && [ "$n" != "weave" ]; then
                usage
            else
                cni="$n"
            fi
            ;;
        i)
            i=$OPTARG
            if [ "$i" != "ingress-ngx" ] && [ "$n" != "nic-ap" ] || [ -z "$n" ]; then
                usage
            fi
            ;;
        d)
            d=$OPTARG
            if [ "$d" != "focal" ] && [ "$d" != "impish" ] && [ "$d" != "jammy" ]; then
                usage
            else
              code_name=$d
            fi
            ;;
        w)
            w=$OPTARG
            if [ "$w" != 2 ] && [ "$w" != 3 ]; then
              usage
            fi
            number=$w
            ;;
        *)
            usage
            ;;
    esac
done
# Ref: https://unix.stackexchange.com/questions/50563/how-can-i-detect-that-no-options-were-passed-with-getopts
shift $((OPTIND-1))

check_lxd_status () {
  echo -n "Wait"
  while true; do
    STATUS=$(lxc ls | grep -c "$1")
    if [ "$STATUS" = "$2" ]; then
      break
    fi
    echo -en "$3"
    sleep 5
  done
  sleep 2
  echo
}

check_lb_status () {
  echo -n "Wait"
  while true; do
    STATUS=$(lxc ls | grep lxd-lb | grep eth0)
    if [ ! "$STATUS" = "" ]; then
      break
    fi
    echo -en "\U0001F601"
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
    echo -en "$1"
    sleep 2
  done
  sleep 2
  echo
}

check_cni_status () {
  echo -n "Wait"
  while true; do
    STATUS=$(kubectl get no | grep -c NotReady)
    if [ "$STATUS" -eq 0 ]; then
      break
    fi
    echo -en "$1"
    sleep 2
  done
  sleep 2
  echo
}

update_local_etc_hosts () {
  if [ "$multimaster" == "true" ]; then
    HOST=lxd-lb
  else
    HOST=lxd-ctrlp-1
  fi
  OUT=$(grep "$HOST" /etc/hosts)
  if [[ $OUT == "" ]]; then
    sudo sed -i "/127.0.0.1 localhost/s/localhost/localhost\n$1 $HOST/" /etc/hosts
  elif [[ "$OUT" =~ $HOST ]]; then
    sudo sed -ri "/$HOST/s/^([0-9]{1,3}\.){3}[0-9]{1,3}/$1/" /etc/hosts
  else
    echo "Error!!"
  fi
}

check_containerd_status () {
  echo -n "Wait"
  while true; do
    if [ "$multimaster" == "true" ]; then
      STATUS1=$(lxc exec lxd-ctrlp-1 -- systemctl status containerd | grep Active | grep running)
      STATUS2=$(lxc exec lxd-ctrlp-2 -- systemctl status containerd | grep Active | grep running)
      STATUS3=$(lxc exec lxd-ctrlp-3 -- systemctl status containerd | grep Active | grep running)
      if [[ "$STATUS1" =~ .*running.* ]] && [[ "$STATUS2" =~ .*running.* ]] && [[ "$STATUS3" =~ .*running.* ]]; then
        break
      fi
      echo -en "$1"
      sleep 2
    else
      STATUS=$(lxc exec lxd-ctrlp-1 -- systemctl status containerd | grep Active | grep running)
      if [[ "$STATUS" =~ .*running.* ]]; then
        break
      fi
      echo -e "$1"
      sleep 2
    fi
  done
  sleep 2
  echo
}

check_if_cluster_already_exists () {
  STATUS=$(lxc ls | grep -c "lxd-.*")
  if [ "$STATUS" -ne 0 ]; then
    echo "Old K8s Cluster exists!!"
    echo "Run 'stop-cluster.sh -d' first!!"
    exit
  fi
}

change_current_context () {
  yq e ".current-context = \"$1\"" - < ~/.kube/config > .tmp.config-new-context-current
  mv .tmp.config-new-context-current ~/.kube/config
}

check_if_cluster_already_exists

if [ "$multimaster" == "true" ]; then
  lb=$(lxc profile ls | grep lb)
  if [ "$lb"  == "" ]; then
    echo "Multi-control-plane mode not available in your current Environment!!"
    echo "Missing lxd lb profile."
    exit 1
  fi
  NODESNUM=6
  CTRLP=lxd-lb
  NODES=(ctrlp-1 ctrlp-2 ctrlp-3 wrker-1 wrker-2 wrker-3)
  WRKERNODES=(1 2 3)
else
  if [ "$number" == "" ]; then
    number=3
  fi
  NODESNUM="$number"
  CTRLP=lxd-ctrlp-1
  # NODES=(ctrlp-1 wrker-1 wrker-2 wrker-3)
  # WRKERNODES=(1 2 3)
  NODES=(ctrlp-1)
  WRKERNODES=()
  for n in $(seq $(($number-1))); do
    NODES+=(wrker-"$n")
    WRKERNODES+=("$n")
  done
fi

if [ "$code_name" == "" ]; then
  code_name=$(lsb_release -a 2> /dev/null | grep Codename | awk '{print $2}')
  if [ "$code_name" != "focal" ] && [ "$code_name" != "impish" ] && [ "$code_name" != "jammy" ]; then
    echo "Unsupported Ubuntu Release $code_name!! Exiting!!"
    exit 1
  fi
fi

image=$(lxc image ls | grep "$code_name"-cloud)
if [ "$image" == "" ]; then
  echo "LXD Image "$code_name"-cloud not found!! Exiting!!"
  exit 1
else
  image="$code_name"-cloud
fi

profile=$(lxc profile ls | grep k8s-cloud-init)
if [ "$profile" == "" ]; then
  echo "LXD Profile k8s-cloud-init not found!! Exiting!!"
  exit 1
else
  profile=k8s-cloud-init
fi


for c in "${NODES[@]}"; do
  lxc launch -p "$profile" "$image" lxd-"$c"
done

check_lxd_status STOP "$NODESNUM" "\U0001F600"
lxc start --all

check_lxd_status eth0 "$NODESNUM" "\U0001F604"

if [ "$multimaster" != "true" ]; then
  IPADDR=$(lxc ls | grep ctrlp | awk '{print $6}')
  update_local_etc_hosts "$IPADDR"
fi

check_containerd_status "\U0001F601"

if [ "$containersonly" == "true" ]; then
  echo "Cluster container created!!"
  exit;
fi

if [ "$multimaster" == "true" ]; then
  lxc launch -p lb "$code_name"-cloud lxd-lb
  check_lb_status
  IPADDR=$(lxc ls | grep lxd-lb | awk '{print $6}')
  update_local_etc_hosts "$IPADDR"
fi

lxc exec lxd-ctrlp-1 -- kubeadm init --control-plane-endpoint "$CTRLP":6443 --upload-certs --apiserver-cert-extra-sans apiserver-$(echo "$IPADDR" | sed 's/\./-/g').nip.io | tee kubeadm-init.out
echo
if [ ! -d ~/.kube ]; then
  mkdir ~/.kube
  ln -s ~/.kube ~/.k
fi
lxc file pull lxd-ctrlp-1/etc/kubernetes/admin.conf ~/.kube/config-lxd
if [ -f ~/.kube/config ]; then
  KUBECONFIG=~/.kube/config:~/.kube/config-lxd kubectl config view --flatten > /tmp/config
  mv /tmp/config ~/.kube/config
  change_current_context kubernetes-admin@kubernetes
else
  cp ~/.kube/config-lxd ~/.kube/config
fi
chmod 0600 ~/.kube/config*

if [ "$multimaster" == "true" ]; then
  for c in 2 3; do
    # shellcheck disable=SC2046 # code is irrelevant because lxc exec will not run commands in containers with quotes
    lxc exec lxd-ctrlp-"$c" -- $(tail -12 kubeadm-init.out | head -3 | tr -d '\\\n')
    sleep 2
    echo
  done
fi

for c in "${WRKERNODES[@]}"; do
  # shellcheck disable=SC2046 # code is irrelevant because lxc exec will not run commands in containers with quotes
  lxc exec lxd-wrker-"$c" -- $(tail -2 kubeadm-init.out | tr -d '\\\n')
  sleep 2
  # Ref: https://stackoverflow.com/questions/48854905/how-to-add-roles-to-nodes-in-kubernetes
  kubectl label nodes lxd-wrker-"$c" node-role.kubernetes.io/worker=
  echo
done

# Ref: https://askubuntu.com/questions/1042234/modifying-the-color-of-grep
kubectl get no -owide | GREP_COLORS="ms=1;91;107" grep --color STATUS
kubectl get no -owide | grep --color NotReady
echo
if [ -z "$cni" ]; then
  echo "No CNI specified!! Doing nothing for CNI plugin!!"
  echo "You might want to deploy Calico. 'kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml'"
  echo -e "Will exit here!!\ncreate-cluster.sh -h for help!!"
  exit
else
  if [ "$cni" == "cilium" ]; then
    if ! command  -v cilium &> /dev/null; then
      get-cilium.sh
    fi
    cilium install
    check_cilium_status "\U0001F680"
  elif [ "$cni" == "calico" ]; then
    curl -sSL https://docs.projectcalico.org/manifests/calico.yaml | sed 's#policy/v1beta1#policy/v1#' | kubectl apply -f -
    # Ref: https://projectcalico.docs.tigera.io/getting-started/kubernetes/helm
    # DOES NOT WORK
    # helm upgrade --install calico tigera-operator \
    #   --repo https://projectcalico.docs.tigera.io/charts
    check_cni_status "\U0001F680"
  elif [ "$cni" == "weave" ]; then
    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
    check_cni_status "\U0001F680"
  else
    echo "Error!! CNI flag exists but != <cilium|calico|weave>!!"
    exit
  fi
fi
echo
# Ref: https://askubuntu.com/questions/1042234/modifying-the-color-of-grep
kubectl get no -owide | GREP_COLORS="ms=1;92;107" grep --color STATUS
kubectl get no -owide | GREP_COLORS="ms=1;92" grep --color Ready
echo
k-apply.sh

if [ -z "$i" ]; then
  echo "No Ingress-Controller specified!! Doing nothing for Ingress-Controller!!"
  echo "You might want to deploy Ingress-Nginx. 'kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.1/deploy/static/provider/cloud/deploy.yaml'"
  exit
else
  if [ "$i" == "ingress-ngx" ]; then
    ingress-nginx.sh
  elif [ "$i" == "nic-ap" ]; then
    # nginx-ap-ingress.sh -p
    echo "Not implemented yet!!"
  fi
fi
MYEOF

cat <<'MYEOF' > ~/.local/bin/stop-cluster.sh
#!/usr/bin/env bash

while getopts "d" o; do
    case "$o" in
        d)
            delete="true"
            ;;
        *)
            ;;
    esac
done
shift $((OPTIND-1))

KUBECONFIG=~/.kube/config

lxc stop --all --force
if [ "$delete"  == "true" ]; then
  for c in $(lxc ls | grep lxd | awk '{print $2}'); do lxc delete "$c"; done
  sudo sed -i '/lxd/d' /etc/hosts

  context=kubernetes-admin@kubernetes
  if [ ! -f $KUBECONFIG ]; then
    printf "%s" "$KUBECONFIG file not found!!"
    exit
  fi

  user=$(yq e ".contexts[] | select(.name == \"$context\") | .context.user" - < $KUBECONFIG)
  # echo "User to delete: $user"
  yq e "del(.users[] | select(.name == \"$user\"))" - < $KUBECONFIG > .tmp.config-user

  cluster=$(yq e ".contexts[] | select(.name == \"$context\") | .context.cluster" - < $KUBECONFIG)
  # echo "Cluster to delete: $cluster"
  yq e "del(.clusters[] | select(.name == \"$cluster\"))" - < .tmp.config-user > .tmp.config-user-cluster

  # echo "Context to delete: $context"
  yq e "del(.contexts[] | select(.name == \"$context\"))" - < .tmp.config-user-cluster > .tmp.config-user-cluster-context
  current_context=$(yq e '.current-context' - < $KUBECONFIG)
  if [ "$current_context" == "$context" ]; then
    yq e ".current-context = \"\"" - < .tmp.config-user-cluster-context > .tmp.config-user-cluster-context-current
    mv .tmp.config-user-cluster-context-current $KUBECONFIG
    rm .tmp*
  else
    mv .tmp.config-user-cluster-context $KUBECONFIG
    rm .tmp*
  fi
fi
chmod 0600 $KUBECONFIG
MYEOF

cat <<'MYEOF' > ~/.local/bin/record-k9s.sh
#!/usr/bin/env bash

usage() {
  echo "Usage: $(basename $0) [-c <kind-kind|kubernetes-admin@kubernetes>" 1>&2
  echo '       -c   "which Cluster only kind-kind or kubernetes-admin@kubernetes"'
  echo
  exit 1
}

while getopts "c:" o; do
    case "$o" in
        c)
            context=$OPTARG
            if [ "$context" != "kind-kind" ] && [ "$context" != "kubernetes-admin@kubernetes" ]; then
                usage
            fi
            ;;
        *)
            ;;
    esac
done
shift $((OPTIND-1))


KUBECONFIG=~/.kube/config
if [ "$context" == "" ]; then
  context=kubernetes-admin@kubernetes
fi

until [ -e "$KUBECONFIG" ]; do
    sleep 2
done

until [ x$(yq e ".contexts[] | select(.name == \"$context\") | .context.cluster" - < $KUBECONFIG) != "x" ]; do
  sleep 2
done

k9s
MYEOF

cat <<'MYEOF' > ~/.local/bin/pull-containerd.sh
#!/usr/bin/env bash

pushd () {
    command pushd "$@" > /dev/null || exit
}

popd () {
    command popd > /dev/null || exit
}

USER=$(whoami)
pushd "$(pwd)" || exit

if [ -d "/home/$USER/Projects/kubernetes-env/.containerd" ]; then
  echo "/home/$USER/Projects/kubernetes-env/.containerd exists!! Not downloading!!"
  exit
fi

mkdir -p /home/"$USER"/Projects/kubernetes-env/.containerd
cd /home/"$USER"/Projects/kubernetes-env/.containerd || exit

CONTAINERD_LATEST=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest)
CONTAINERD_VER=$(echo -E "$CONTAINERD_LATEST" | jq -M ".tag_name" | tr -d '"')
echo "Downloading Containerd $CONTAINERD_VER..."
echo
echo "*********************************"
echo "*                               *"
echo "* Downloading Containerd $CONTAINERD_VER *"
echo "*                               *"
echo "*********************************"
echo
CONTAINERD_URL=$(echo -E "$CONTAINERD_LATEST" | jq -M ".assets[].browser_download_url" | grep amd64 | grep linux | grep cri | grep cni | grep -v sha256 | tr -d '"')
curl -L --remote-name-all "$CONTAINERD_URL"{,.sha256sum}
sha256sum --check "$(basename "$CONTAINERD_URL")".sha256sum

# CRUN_LATEST=$(curl -s https://api.github.com/repos/containers/crun/releases/latest)
# CRUN_VER=$(echo -E "$CRUN_LATEST" | jq -M ".tag_name" | tr -d '"')
# echo "Downloading Crun $CRUN_VER..."
# echo
# echo "***************************"
# echo "*                         *"
# echo "* Downloading Crun $CRUN_VER *"
# echo "*                         *"
# echo "***************************"
# echo
# CRUN_URL=$(echo -E "$CRUN_LATEST" | jq -M ".assets[].browser_download_url" | grep amd64 | grep linux | grep -v asc | grep -v systemd | tr -d '"')
# curl -L --remote-name-all "$CRUN_URL"{,.asc}

popd || exit
MYEOF

cat <<'MYEOF' > ~/.local/bin/create-nfs-server.sh
#!/usr/bin/env bash

check_nfs_status () {
  echo -n "Wait"
  while true; do
    STATUS=$(lxc ls | grep nfs | grep eth0)
    if [ ! "$STATUS" = "" ]; then
      break
    fi
    echo -en "\U0001F601"
    sleep 2
  done
  sleep 2
  echo
}

check_cloud_init_status () {
  echo -n "Wait"
  while true; do
    STATUS=$(lxc exec nfs-server -- cloud-init status)
    if [[ "$STATUS" =~ .*done$ ]]; then
      break
    fi
    echo -en "\U0001F601"
    sleep 2
  done
  sleep 2
  echo
}

cluster_running=$(kubectl cluster-info 2> /dev/null| head -1)
if [[ ! "$cluster_running" =~ .*running.* ]]; then
  echo "No Kubernetes Cluster running!! Start a Kubernetes Cluster first!!"
  exit 1
fi

nfs=$(lxc profile ls | grep nfs)
if [ "$nfs"  == "" ]; then
  echo "LXD Profile nfs-server not found!! Exiting!!"
  exit 1
else
  nfs_server=$(lxc ls | grep nfs-server)
  if [ "$nfs_server" == "" ]; then
    lxc launch -p nfs-server focal-cloud nfs-server
    check_nfs_status
    check_cloud_init_status
  fi
  # Ref: https://stackoverflow.com/questions/65642967/why-almost-all-helm-packages-are-deprecated#:~:text=helm%2Fcharts%20has%20been%20deprecated,at%20datawire%2Fambassador%2Dchart.
  # helm upgrade --install nfs-subdir-external-provisioner nfs-subdir-external-provisioner \
  #   --repo https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ \
  #   --set nfs.server=nfs-server \
  #   --set nfs.path=/mnt/nfs_share \
  #   --set replicaCount=2
  helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
  helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=nfs-server \
    --set nfs.path=/mnt/nfs_share \
    --set replicaCount=2 \
    --set storageClass.defaultClass=true
fi
MYEOF

cat <<'MYEOF' > ~/.local/bin/stop-nfs-server.sh
#!/usr/bin/env bash

helm_nfs=$(helm list | grep nfs-subdir-external-provisioner)
if [ ! "$helm_nfs" == "" ]; then
  helm uninstall nfs-subdir-external-provisioner
  sleep 3
  helm repo remove nfs-subdir-external-provisioner
fi
nfs_server=$(lxc ls | grep nfs)
if [ "$nfs_server" == "" ]; then
  echo "nfs-server not running!! Exiting!!"
  exit 1
else
  if [[ ! "$nfs_server" =~ .*STOP.* ]]; then
    lxc stop nfs-server --force
  fi
  lxc delete nfs-server
fi
MYEOF

cat <<'MYEOF' > ~/.local/bin/create-storage-demo.sh
#!/usr/bin/env bash

create-nfs-server.sh
# helm upgrade --install mongodb mongodb \
#   --repo https://charts.bitnami.com/bitnami \
#   --namespace mongodb --create-namespace \
#   --values mongodb-values.yaml
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install mongodb bitnami/mongodb --namespace mongodb --create-namespace --values mongodb-values.yaml
k apply -f mongodb-demo-mongo-express.yaml
k apply -f mongodb-demo-ingress.yaml
MYEOF

cat <<'MYEOF' > ~/.local/bin/stop-storage-demo.sh
#!/usr/bin/env bash

k delete -f mongodb-demo-ingress.yaml
k delete -f mongodb-demo-mongo-express.yaml
helm --namespace mongodb uninstall mongodb
helm repo remove bitnami
PVCS=($(kubectl -n mongodb get pvc --no-headers | awk '{print $1}'))
for pvc in "${PVCS[@]}"; do kubectl -n mongodb delete pvc "$pvc"; done
stop-nfs-server.sh
MYEOF

cat <<'EOF' > ~/.local/bin/create-cluster.py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Jan 23 15:10:26 2022

@author: tsanghan
"""

# import argparse
from pathlib import Path
from pylxd import Client
from time import sleep
import urllib3
from yaml import safe_load, dump


# client = Client()

# image_data = Path('focal-server-cloudimg-amd64.squashfs').open(mode='rb').read()
# meta_data = Path('focal-server-cloudimg-amd64-lxd.tar.xz').open(mode='rb').read()

# image = client.images.create(image_data, meta_data, public=True, wait=True)
# print(image.fingerprint)
# image.add_alias('my-alias', '')


# Ref: https://stackoverflow.com/questions/27981545/suppress-insecurerequestwarning-unverified-https-request-is-being-made-in-pytho
urllib3.disable_warnings()


def get_client():
    return Client()


def _wait(instance, status):
    while not instance.state().status == status:
        print("\N{grinning face with smiling eyes}", end="", flush=True)
        sleep(5)


def wait_for_cluster(instance_list, status):
    print("Wait", end="", flush=True)
    for instance in instance_list:
        if status == "Stopped":
            _wait(instance, status)
        elif status == "Running":
            instance.start()
            _wait(instance, status)
        else:
            raise Exception("Invalid status requested.")
    print(flush=True)


def create_and_start_instances(client, instance_name_list):
    instance_list = []
    for instance_name in instance_name_list:
        if not client.instances.exists(instance_name):
            config = {
                "name": instance_name,
                "source": {
                    "type": "image",
                    "mode": "pull",
                    "server": "",
                    "protocol": "simplestreams",
                    "alias": "focal-cloud",
                },
                "profiles": ["k8s-cloud-init"],
            }
            print(f"Creating {instance_name}")
            instance = client.instances.create(config, wait=True)
            instance_list.append(instance)
            print(f"Starting {instance_name}")
            instance.start()
        else:
            print(
                f"Instance: {instance_name} exists!!\nNothing to do here for {instance_name}.\n"
            )
    return instance_list


def _check_containerd(instance):
    _, stdout, _ = instance.execute(
        ["/bin/bash", "-c", "systemctl status containerd | grep running"]
    )
    return str(stdout)


def check_containerd(instance):
    print("Wait", end="", flush=True)
    while not _check_containerd(instance):
        print("\N{grinning face with smiling eyes}", end="", flush=True)
        sleep(1)
    print(flush=True)


def kubeadm_init(instance):
    for address in instance.state().network["eth0"]["addresses"]:
        if address["family"] == "inet":
            ip = address["address"]
            print(f"Instance {instance.name} has eth0 IP Address {ip}")

            _, stdout, _ = instance.execute(
                [
                    "/bin/bash",
                    "-c",
                    f"kubeadm init \
                    --control-plane-endpoint {ip}:6443 \
                    --upload-certs |\
                    tee kubeadm-init.out",
                ]
            )
            print(stdout)
            init_out = stdout.splitlines()
            return init_out[-2].strip("\\") + init_out[-1].strip("\t")


def kubeadm_join(instance, kube_join_command):
    _, stdout, _ = instance.execute(
        [
            "/bin/bash",
            "-c",
            f"{kube_join_command}",
        ]
    )
    return str(stdout)


def load_kubeconfig(file=Path.home() / Path(".kube/config")):
    return safe_load(Path(file).read_text())


def merge_kubeocnfig_files(kubeconfig_file, kubeconfig_lxd_file):
    kubeconfig = load_kubeconfig(kubeconfig_file)
    kubeconfig_lxd = load_kubeconfig(kubeconfig_lxd_file)
    kubeconfig["clusters"].append(kubeconfig_lxd.get("clusters")[0])
    kubeconfig["contexts"].append(kubeconfig_lxd.get("contexts")[0])
    kubeconfig["users"].append(kubeconfig_lxd.get("users")[0])
    kubeconfig["current-context"] = kubeconfig_lxd.get("contexts")[0].get("name")
    kubeconfig_file.unlink(missing_ok=True)
    kubeconfig_file.write_text(dump(kubeconfig))


def pull_admin_conf(instance):
    kubeconfig_file = Path.home() / Path(".kube/config")
    if kubeconfig_file.exists():
        kubeconfig_lxd_file = Path.home() / Path(".kube/config-lxd")
        kubeconfig_lxd_file.write_bytes(instance.files.get("/etc/kubernetes/admin.conf"))
        merge_kubeocnfig_files(kubeconfig_file, kubeconfig_lxd_file)
    else:
        kubeconfig_file.write_bytes(instance.files.get("/etc/kubernetes/admin.conf"))
    kubeconfig_file.chmod(0o600)


def start_cluster(client, instance_name_list):

    kubeadm_join_command = ""
    instance_list = create_and_start_instances(client, instance_name_list)
    if not instance_list:
        exit()

    wait_for_cluster(instance_list, "Stopped")

    wait_for_cluster(instance_list, "Running")

    for instance in instance_list:
        print(f"Instance {instance.name}")
        if instance.name == "lxd-ctrlp-1":
            check_containerd(instance)
            kubeadm_join_command = kubeadm_init(instance)
            print(kubeadm_join_command)
            pull_admin_conf(instance)
        elif instance.name != "lxd-ctrlp-1":
            stdout = kubeadm_join(instance, kubeadm_join_command)
            print(stdout)
        else:
            raise Exception("Unknown Instance name")


def main():
    # parser = argparse.ArgumentParser()
    # parser.add_argument("-d", "--delete", help="Stop Cluster", action="store_true")
    # parser.add_argument("-f", "--force", help="Delete Cluster", action="store_true")
    # args = parser.parse_args()
    # delete, force = args.delete, args.force
    start_cluster(get_client(), ["lxd-ctrlp-1", "lxd-wrker-1", "lxd-wrker-2"])


if __name__ == "__main__":
    main()

EOF

cat <<EOF > ~/.local/bin/stop-cluster.py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Jan 23 15:21:37 2022

@author: tsanghan
"""
import argparse
from pathlib import Path
from pylxd import Client
from time import sleep
import urllib3
from yaml import safe_load, dump

# Ref: https://stackoverflow.com/questions/27981545/suppress-insecurerequestwarning-unverified-https-request-is-being-made-in-pytho
urllib3.disable_warnings()


def _get_client():
    return Client()

def _load_kubeconfig(file=Path.home()/Path(".kube/config")):
    try:
      return safe_load(Path(file).read_text())
    except FileNotFoundError:
      print(f"Kubeconfig File {file.as_posix()} not found!!")
      exit()

def _delete_context(selected_context="kubernetes-admin@kubernetes"):
    kubeconfig = _load_kubeconfig()
    selected_user = ""
    selected_cluster = ""
    for index, context in enumerate(kubeconfig.get("contexts")):
        if context.get("name") == selected_context:
            selected_user = context.get("context").get("user")
            selected_cluster = context.get("context").get("cluster")
            del kubeconfig.get("contexts")[index]
    for index, cluster in enumerate(kubeconfig.get("clusters")):
        if cluster.get("name") == selected_cluster:
            del kubeconfig.get("clusters")[index]
    for index, user in enumerate(kubeconfig.get("users")):
        if user.get("name") == selected_user:
            del kubeconfig.get("users")[index]
    if (
        kubeconfig.get("current-context") == selected_context and
        len(kubeconfig.get("contexts")) > 0
    ):
        kubeconfig["current-context"] = kubeconfig.get("contexts")[0].get("name")
    else:
        kubeconfig["current-context"] = '""'
    return kubeconfig

def delete_context():
    kubeconfig = _delete_context()
    kubeconfig_file = Path.home()/Path(".kube/config")
    kubeconfig_file.unlink(missing_ok=True)
    kubeconfig_file.write_text(dump(kubeconfig))

def stop_cluster(delete=False, force=False):
    client = _get_client()
    for instance in client.containers.all():
        if instance.name.startswith('lxd-'):
            instance.stop(force=force)
            if delete:
                while True:
                    now = instance.state()
                    if now.status.startswith('Stopped'):
                        instance.delete()
                        break
                    sleep(2)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--delete", help="Stop Cluster", action="store_true")
    parser.add_argument("-f", "--force", help="Delete Cluster", action="store_true")
    args = parser.parse_args()
    delete, force = args.delete, args.force
    stop_cluster(delete=delete, force=force)
    if delete:
      delete_context()


if __name__ == "__main__":
    main()

EOF

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
  fi
fi

# Install helm
if [ ! -f ~/.local/bin/helm ]; then
  HELM_VER=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | jq ".tag_name" | tr -d '"')
  curl -L --remote-name-all https://get.helm.sh/helm-"$HELM_VER"-linux-amd64.tar.gz{,.sha256sum}
  OK=$(sha256sum --check helm-"$HELM_VER"-linux-amd64.tar.gz.sha256sum)
  if [[ ! "$OK" =~ .*OK$ ]]; then
    echo "heml tarball does not match sha256 checksum, aborting!!"
    rm helm*
    exit $?
  else
    echo "Installing helm verion=$HELM_VER"
    tmp_dir=$(mktemp -d -q)
    tar -C "$tmp_dir" -zxvf helm-"$HELM_VER"-linux-amd64.tar.gz linux-amd64/helm
    mv "$tmp_dir"/linux-amd64/helm ~/.local/bin
    rm helm*
    rm -rf "$temp_dir"
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

# Install bat
if [ ! -f ~/.local/bin/bat ]; then
  BAT=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep linux | grep gnu | tr -d '"')
  BAT_DIR=$(basename "$BAT" | sed 's/\(^.*\).tar.gz/\1/')
  BAT_BIN=$(basename "$BAT" | sed 's/\(.*\)-v.*/\1/')
  curl -sSL "$BAT" | tar -C /tmp -zxvf -
  mv /tmp/"$BAT_DIR"/"$BAT_BIN" ~/.local/bin
  mv /tmp/"$BAT_DIR"/"$BAT_BIN".1 ~/.local/man/man1
  mv /tmp/"$BAT_DIR"/autocomplete/* ~/.local/share/completions
  rm -rf /tmp/"$BAT_DIR"
fi

# Install exa
if [ ! -f ~/.local/bin/exa ]; then
  EXA=$(curl -s https://api.github.com/repos/ogham/exa/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep linux | grep -v musl | tr -d '"')
  EXA_ZIP=$(basename "$EXA")
  curl -sSL -o /tmp/"$EXA_ZIP" "$EXA"
  unzip /tmp/"${EXA_ZIP}" -d /tmp/exa_unzip
  mv /tmp/exa_unzip/completions/exa.zsh /home/${USER}/.local/share/completions/exa.zsh
  mv /tmp/exa_unzip/man/exa.1 /home/${USER}/.local/man/man1
  mv /tmp/exa_unzip/man/exa_colors.5 /home/${USER}/.local/man/man5
  mv /tmp/exa_unzip/bin/exa /home/${USER}/.local/bin
  rm -rf /tmp/exa_unzip
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

# Install kubecolor
if [ ! -f ~/.local/bin/kubecolor ]; then
  KUBECOLOR=$(curl -s https://api.github.com/repos/hidetatz/kubecolor/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep Linux | tr -d '"')
  curl -sSL "$KUBECOLOR" | tar -C ~/.local/bin -zxvf - kubecolor
fi

chmod 0755 ~/.local/bin/*

pylxd=$(pip3 list 2> /dev/null | grep pylxd)
if [ "$pylxd" == "" ]; then
  pip3 install pylxd 2> /dev/null
  codename=$(lsb_release -a 2> /dev/null | grep Codename | awk '{print $2}')
  if [ "$codename" != "jammy" ]; then
    pip3 uninstall -y cryptography 2> /dev/null
  fi
fi

lxd_grp=$(id | sed 's/^.*\(lxd\).*$/\1/')
docker_grp=$(id | sed 's/^.*\(lxd\).*$/\1/')
if [ "$lxd_grp" == "" ] || [ "$docker_grp" == "" ]; then
  echo -e "\n"
  echo "*************************************************************************************"
  echo "*                                                                                   *"
  echo "*  Please logout and relogin again for docker,lxd group membership to take effect.  *"
  echo "*                                                                                   *"
  echo "*************************************************************************************"
  echo -e "\n\n"
fi
