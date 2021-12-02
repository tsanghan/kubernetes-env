# kubernetes-env

## Hello and welcome to Kubenetes-Env

This is a Kubernetes *self-learning education aids*.
For education/learning purpose, *1x Control-Plane, 2x Worker* will be more then enough.
This 1x Control-Plane, 2x Worker Kubernetes Cluster can all reside in 1 single VM.
You will need a base VM with the folloing specification

| Resources | Specifications     |
| --------- |:------------------:|
| vCPU      | 4                  |
| Memory    | 8GB                |
| Disk      | 30GB               |
| NIC       | 1                  |
| Base OS   | Ubuntu 20.04 Focal |

1. Create a base VM with above specification
2. Bootup and login to your VM
3. Create a Projects directory and `cd` into it
4. `git clone https://github.com/tsanghan/kubernetes-env.git`
5. `cd` into `kubernetes-env`
6. `sudo ./prepare-vm.sh`
7. Follow the instruction at the end of the completion of `prepare-vm.sh` script
8. Log back into your VM
9. You have 2 choice to deploy a kubernetes cluster, using KIND and LXD
10. We will explore LXD method first
11. `cd` into `Projects/kubernetes-env/kubernetes-on-lxd`
12. Run `./prepare-lxd.sh`
13. Wait untill script finish
14. `lxc launch -p k8s focal-cloud <your lxc node name>`
...instruction below will use the node name of *lxd-ctrlp-1*
15. Launch 2 more worker nodes with above command
16. `watch lxc ls`
17. All 3 lxc nodes will power down after being prepared
18) Start all nodes `lxc start --all`
19) Run `kubeadm init` on control-plane node with the following long command
20) `lxc exec lxd-ctrlp-1 -- kubeadm init --ignore-preflight-errors=FileContent--proc-sys-net-bridge-bridge-nf-call-iptables,SystemVerification,Swap --upload-certs | tee kubeadm-init.out`
21) Wait till kubeadm finish initializing control-plane node
22) Perform `kubeadm join` command from `kubeadm init` output on 2 worker nodes. Please refer to last 2 lines of local `kubeadm-init.out` file for the full `kubeadm join` command.
23) Pull `/etc/kubernetes/admin.conf` from within `lxd-ctrlp-1` node into your local `~/.kube` directory with the following command
24) `lxc file pull lxd-ctrlp-1/etc/kubernetes/admin.conf ~/.kube/config`
...make sure you have created ~/.kube first
25) Activate auto-completion
26) `source <(kubectl completion bash)`
...assuming you are using bash
27) `alias k=kubectl`
28) `completion -F __start_kubectl k`
29) Now you can access you cluster with `kubectl` command, alised to `k`
30) `k get no`
31) All your nodes are not ready, becasue we have yet to instal a CNI plugin
32) We will use calico as it support Network Policy
33) `k apply -f https://docs.projectcalico.org/manifests/calico.yaml`
34) `k get no` again
35) Wait till all you nodes are ready
36) There is a `k-apply.sh` script in the current directory.
37) If you run it it will install metrics server amoung other services.
38) Explore your *1x Control-Plane, 2x Worker* Kubernetes cluster.
