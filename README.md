# kubernetes-env

## Hello and welcome to Kubenetes-Env

* This is a Kubernetes *self-learning education aids*.
* For education/learning purpose, *1x Control-Plane, 2x Workers* will be more then enough.
* This 1x Control-Plane, 2x Workers Kubernetes Cluster can all reside in 1 single VM.
* You will need a base VM with the folloing specification

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
9. You have 2 choices to deploy a kubernetes cluster, using KIND and LXD
10. We will explore LXD method first
11. `cd` into `Projects/kubernetes-env/kubernetes-on-lxd`
12. Run `./prepare-lxd.sh`
13. Wait untill script finish
14. `lxc launch -p k8s focal-cloud <your lxc node name>`
15. Instruction below will use the node name of *lxd-ctrlp-1*
16. Launch 2 more worker nodes with above command (example *lxd-wrker-1* and *lxd-wrker-2*)
17. `watch lxc ls`
18. All 3 lxc nodes will power down after being prepared
19. Start all nodes `lxc start --all`
20. Run `kubeadm init` on control-plane node with the following long command
21. `lxc exec lxd-ctrlp-1 -- kubeadm init --ignore-preflight-errors=FileContent--proc-sys-net-bridge-bridge-nf-call-iptables,SystemVerification,Swap --upload-certs | tee kubeadm-init.out`  
22. Wait till kubeadm finish initializing control-plane node
23. Perform `kubeadm join` command from `kubeadm init` output on 2 worker nodes. Please refer to last 2 lines of local `kubeadm-init.out` file for the full `kubeadm join` command.
24. Pull `/etc/kubernetes/admin.conf` from within `lxd-ctrlp-1` node into your local `~/.kube` directory with the following command
25. `lxc file pull lxd-ctrlp-1/etc/kubernetes/admin.conf ~/.kube/config` make sure you have created ~/.kube first
26. Activate auto-completion
27. `source <(kubectl completion bash)` assuming you are using bash
28. `alias k=kubectl`
29. `completion -F __start_kubectl k`
30. Now you can access you cluster with `kubectl` command, alised to `k`
31. `k get no`
32. All your nodes are not ready, becasue we have yet to instal a CNI plugin
```
NAME          STATUS     ROLES                  AGE     VERSION
lxd-ctrlp-1   NotReady   control-plane,master   2m55s   v1.22.4
lxd-wrker-1   NotReady   <none>                 15s     v1.22.4
lxd-wrker-2   NotReady   <none>                 5s      v1.22.4
```
35. We will use calico as it support Network Policy
36. `k apply -f https://docs.projectcalico.org/manifests/calico.yaml`
37. `k get no` again
38. Wait till all your nodes are ready
```
NAME          STATUS   ROLES                  AGE     VERSION
lxd-ctrlp-1   Ready    control-plane,master   5m42s   v1.22.4
lxd-wrker-1   Ready    <none>                 3m2s    v1.22.4
lxd-wrker-2   Ready    <none>                 2m52s   v1.22.4
```
39. Type `k get all -A` to see all your pods
```
NAMESPACE     NAME                                           READY   STATUS    RESTARTS   AGE
kube-system   pod/calico-kube-controllers-56b8f699d9-vwvvc   1/1     Running   0          85s
kube-system   pod/calico-node-4nvzn                          1/1     Running   0          85s
kube-system   pod/calico-node-j7sw4                          1/1     Running   0          85s
kube-system   pod/calico-node-qvqwx                          1/1     Running   0          85s
kube-system   pod/coredns-78fcd69978-jg7nt                   1/1     Running   0          6m14s
kube-system   pod/coredns-78fcd69978-nnzzt                   1/1     Running   0          6m14s
kube-system   pod/etcd-lxd-ctrlp-1                           1/1     Running   0          6m21s
kube-system   pod/kube-apiserver-lxd-ctrlp-1                 1/1     Running   0          6m15s
kube-system   pod/kube-controller-manager-lxd-ctrlp-1        1/1     Running   0          6m15s
kube-system   pod/kube-proxy-5mthj                           1/1     Running   0          3m43s
kube-system   pod/kube-proxy-999t4                           1/1     Running   0          3m32s
kube-system   pod/kube-proxy-lwb4r                           1/1     Running   0          6m15s
kube-system   pod/kube-scheduler-lxd-ctrlp-1                 1/1     Running   0          6m15s

NAMESPACE     NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP                  6m22s
kube-system   service/kube-dns     ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   6m20s

NAMESPACE     NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-system   daemonset.apps/calico-node   3         3         3       3            3           kubernetes.io/os=linux   85s
kube-system   daemonset.apps/kube-proxy    3         3         3       3            3           kubernetes.io/os=linux   6m20s

NAMESPACE     NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   deployment.apps/calico-kube-controllers   1/1     1            1           85s
kube-system   deployment.apps/coredns                   2/2     2            2           6m20s

NAMESPACE     NAME                                                 DESIRED   CURRENT   READY   AGE
kube-system   replicaset.apps/calico-kube-controllers-56b8f699d9   1         1         1       85s
kube-system   replicaset.apps/coredns-78fcd69978                   2         2         2       6m15s
```
41. There is a `k-apply.sh` script in the current directory.
42. If you run it, the following services will be installed
```
metrics server
local path provisioner
NGINX ingress controller
metallb (you can now create a Service of Type Loadbalancer)

NAMESPACE       NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
default         kubernetes                           ClusterIP      10.96.0.1        <none>           443/TCP                      23m
default         svc-deploy-nginx                     LoadBalancer   10.104.3.132     10.127.202.241   80:31880/TCP                 3m41s
ingress-nginx   ingress-nginx-controller             LoadBalancer   10.102.143.1     10.127.202.240   80:30116/TCP,443:30765/TCP   13m
ingress-nginx   ingress-nginx-controller-admission   ClusterIP      10.110.81.97     <none>           443/TCP                      13m
kube-system     kube-dns                             ClusterIP      10.96.0.10       <none>           53/UDP,53/TCP,9153/TCP       23m
kube-system     metrics-server                       ClusterIP      10.107.154.234   <none>           443/TCP                      13m
```
43. There is also a `ingress.yaml` manifest that will deploy an `ingressClass` and a *ingress resource*
44. However, a `Deployment` and a `Service` is missing, waiting for you to create. :-)
45. Explore and enjoy your *1x Control-Plane, 2x Workers* Kubernetes cluster

## How to stop the cluster?
1. `lxc stop --all`
2. To start again `lxc start --all`
3. You can purge/delete the cluster and start installation again, but you will need to delete individual nodes after they are stopped.
4. `lxc delete <node name>` 
