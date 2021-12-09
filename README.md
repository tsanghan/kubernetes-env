# Kubernetes-env

## Hello and welcome to Kubenetes-env

* ***This open source project comes with absolutely no warrenty and support.***
* ***Fork this project for your own needs.***
* This is a Kubernetes *self-learning education aids*.
* For education/learning purpose, *1x Control-Plane, 2x Workers* will be more then enough.
* This *1x Control-Plane, 2x Workers* Kubernetes Cluster can all reside in 1 single VM.
* A base VM with the following specification will be required

| Resources | Specifications     |
| --------- |:------------------:|
| vCPU      | 4                  |
| Memory    | 8GB                |
| Disk      | 30GB               |
| NIC       | 1                  |
| Base OS   | Ubuntu 20.04 Focal |

1. Create a base VM with above specification
2. ***Disable swap on the base VM***
3. Bootup and login to the VM
4. Create a `Projects` directory and `cd` into it
5. `git clone https://github.com/tsanghan/kubernetes-env.git`
6. `cd` into `kubernetes-env`
7. `sudo ./prepare-vm.sh`
8. Follow the instruction at the end of the completion of `prepare-vm.sh` script
9. Log back into the VM
10. There are 2 choices to deploy a kubernetes cluster, using *LXD* or *KIND*

### Kubernetes on LXD

1. `cd` into `Projects/kubernetes-env/kubernetes-on-lxd`
2. Run `./prepare-lxd.sh`
3. Wait untill script finish
4. `lxc launch -p k8s focal-cloud <lxc node name>`
5. Instructions below will use the node name of *lxd-ctrlp-1*
6. Launch 2 more worker nodes with above command (example *lxd-wrker-1* and *lxd-wrker-2*)
7. `watch lxc ls`
8. All 3 lxc nodes will power down after being prepared
9. Start all nodes `lxc start --all`
10. Run `kubeadm init` on control-plane node with the following long command
11. `lxc exec lxd-ctrlp-1 -- kubeadm init --ignore-preflight-errors=FileContent--proc-sys-net-bridge-bridge-nf-call-iptables,SystemVerification,Swap --upload-certs | tee kubeadm-init.out`  
12. Wait till kubeadm finish initializing control-plane node
13. Perform `kubeadm join` command from `kubeadm init` output on 2 worker nodes. Please refer to last 2 lines of local `kubeadm-init.out` file for the full `kubeadm join` command.
14. Pull `/etc/kubernetes/admin.conf` from within `lxd-ctrlp-1` node into your local `~/.kube` directory with the following command
15. `lxc file pull lxd-ctrlp-1/etc/kubernetes/admin.conf ~/.kube/config` make sure you have created ~/.kube directory first
16. Activate `kubectl` auto-completion
17. `source <(kubectl completion bash)` assuming you are using bash
18. `alias k=kubectl`
19. `completion -F __start_kubectl k`
20. Access the cluster with `kubectl` command, alised with `k`
21. `k get no`
22. All the nodes are not ready, becasue a CNI plugin has yet to be installed
```
NAME          STATUS     ROLES                  AGE     VERSION
lxd-ctrlp-1   NotReady   control-plane,master   2m55s   v1.22.4
lxd-wrker-1   NotReady   <none>                 15s     v1.22.4
lxd-wrker-2   NotReady   <none>                 5s      v1.22.4
```
23. Install calico as it support Network Policy
24. `k apply -f https://docs.projectcalico.org/manifests/calico.yaml`
25. `k get no` again
26. Wait till all nodes are ready
```
NAME          STATUS   ROLES                  AGE     VERSION
lxd-ctrlp-1   Ready    control-plane,master   5m42s   v1.22.4
lxd-wrker-1   Ready    <none>                 3m2s    v1.22.4
lxd-wrker-2   Ready    <none>                 2m52s   v1.22.4
```
27. Type `k get all -A` to see all pods
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
28. Run `k-apply.sh` script in the current directory.
29. The following services will be installed
```
metrics server
local path provisioner
NGINX ingress controller
metallb

NAMESPACE       NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
default         kubernetes                           ClusterIP      10.96.0.1        <none>           443/TCP                      23m
default         svc-deploy-nginx                     LoadBalancer   10.104.3.132     10.127.202.241   80:31880/TCP                 3m41s
ingress-nginx   ingress-nginx-controller             LoadBalancer   10.102.143.1     10.127.202.240   80:30116/TCP,443:30765/TCP   13m
ingress-nginx   ingress-nginx-controller-admission   ClusterIP      10.110.81.97     <none>           443/TCP                      13m
kube-system     kube-dns                             ClusterIP      10.96.0.10       <none>           53/UDP,53/TCP,9153/TCP       23m
kube-system     metrics-server                       ClusterIP      10.107.154.234   <none>           443/TCP                      13m
```
30. There is also a `ingress.yaml` manifest that will deploy an `ingressClass` and a *ingress resource*
31. However, a `Deployment` and a `Service` is missing, waiting to be create.
32. Explore and enjoy the *1x Control-Plane, 2x Workers* Kubernetes cluster
33. Check the memory usage with `htop`

### Kubernetes with KIND

1. `cd ../kind`
2. Activate `kind` auto-completion
3. `source <(kind completion bash)`
4. `completion -F __start_kind kind`
5. Start the `kind` cluster
6. `kind create cluster --config kind.yaml`
7. The provided `kind.yaml` will start 1x *Control-Plane Node* and 2x *Worker Nodes* and disable default CNI
8. `kind` automatically merge `kind` cluster config into `~/.kube/config`
9. `k config get-contexts` will show that there are 2 contexts for 2 clusters
```
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kind-kind                     kind-kind    kind-kind
          kubernetes-admin@kubernetes   kubernetes   kubernetes-admin
```
10. The current context is `kind-kind`
11. `k get no`
12. All the nodes are not ready, a CNI plugin as yet to be installed (default CNI hin `kind.yaml` is disabled)
```
NAME                 STATUS     ROLES                  AGE     VERSION
kind-control-plane   NotReady   control-plane,master   6m46s   v1.22.0
kind-worker          NotReady   <none>                 6m15s   v1.22.0
kind-worker2         NotReady   <none>                 6m15s   v1.22.0
```
13. We will use calico as it support Network Policy
14. `k apply -f https://docs.projectcalico.org/manifests/calico.yaml`
15. `k get no` again
16. Wait till all the nodes are ready
```

NAME                 STATUS   ROLES                  AGE     VERSION
kind-control-plane   Ready    control-plane,master   9m      v1.22.0
kind-worker          Ready    <none>                 8m29s   v1.22.0
kind-worker2         Ready    <none>                 8m29s   v1.22.0
```
17. `k get all -A` to see all the pods
```
NAMESPACE            NAME                                             READY   STATUS    RESTARTS   AGE
kube-system          pod/calico-kube-controllers-56b8f699d9-f9jxp     1/1     Running   0          2m9s
kube-system          pod/calico-node-79vcm                            1/1     Running   0          2m9s
kube-system          pod/calico-node-lp9md                            1/1     Running   0          2m9s
kube-system          pod/calico-node-t9h7f                            1/1     Running   0          2m9s
kube-system          pod/coredns-78fcd69978-q5vw4                     1/1     Running   0          9m42s
kube-system          pod/coredns-78fcd69978-zxk77                     1/1     Running   0          9m42s
kube-system          pod/etcd-kind-control-plane                      1/1     Running   0          9m56s
kube-system          pod/kube-apiserver-kind-control-plane            1/1     Running   0          9m56s
kube-system          pod/kube-controller-manager-kind-control-plane   1/1     Running   0          9m58s
kube-system          pod/kube-proxy-b75hl                             1/1     Running   0          9m28s
kube-system          pod/kube-proxy-d6858                             1/1     Running   0          9m43s
kube-system          pod/kube-proxy-k654c                             1/1     Running   0          9m28s
kube-system          pod/kube-scheduler-kind-control-plane            1/1     Running   0          9m56s
local-path-storage   pod/local-path-provisioner-85494db59d-8bq57      1/1     Running   0          9m42s

NAMESPACE     NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP                  9m58s
kube-system   service/kube-dns     ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   9m56s

NAMESPACE     NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-system   daemonset.apps/calico-node   3         3         3       3            3           kubernetes.io/os=linux   2m9s
kube-system   daemonset.apps/kube-proxy    3         3         3       3            3           kubernetes.io/os=linux   9m56s

NAMESPACE            NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
kube-system          deployment.apps/calico-kube-controllers   1/1     1            1           2m9s
kube-system          deployment.apps/coredns                   2/2     2            2           9m56s
local-path-storage   deployment.apps/local-path-provisioner    1/1     1            1           9m55s

NAMESPACE            NAME                                                 DESIRED   CURRENT   READY   AGE
kube-system          replicaset.apps/calico-kube-controllers-56b8f699d9   1         1         1       2m9s
kube-system          replicaset.apps/coredns-78fcd69978                   2         2         2       9m43s
local-path-storage   replicaset.apps/local-path-provisioner-85494db59d    1         1         1       9m43s
```
18. Follow step 28. from `Kubernetes on LXD` to proceed
19. Explore and enjoy the 2 Kubernetes clusters
20. Check memory usage with `htop`

## How to stop the clusters?
### Kubernetes on LXD
1. `lxc stop --all`
2. To start again `lxc start --all`
3. Nodes instance can deleted the with `lxc delete <node name>`
### Kubernetes with KIND
1. There are no provision to stop a `kind` cluster with `kind`.
2. Kind cluster can only be `create`d or `delete`d
3. `kind delete cluster`
4. Kind cluster can be stopped with `docker` command
5. `docker container ls`
```
CONTAINER ID   IMAGE                  COMMAND                  CREATED             STATUS              PORTS                       NAMES
20ffab3b00a3   kindest/node:v1.22.0   "/usr/local/bin/entr…"   About an hour ago   Up About a minute   127.0.0.1:44651->6443/tcp   kind-control-plane
38f750fd85cb   kindest/node:v1.22.0   "/usr/local/bin/entr…"   About an hour ago   Up About a minute                               kind-worker2
26e00165cc2c   kindest/node:v1.22.0   "/usr/local/bin/entr…"   About an hour ago   Up About a minute                               kind-worker
```
5. `docker stop <NAME/CONTAINER ID> <NAME/CONTAINER ID> ...`
