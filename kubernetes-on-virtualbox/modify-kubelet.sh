#!/usr/bin/env bash

while true; do
  IPADDR=$(ip a s | grep "enp0s8$" | awk '{print $2}' | awk -F/ '{print $1}')
  if [ "$IPADDR" != "" ]; then
    break;
  fi
  sleep 2
done
sed -i "s/\(^ExecStart=.*KUBELET_EXTRA_ARGS$\)/\1 --node-ip=$IPADDR/" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
