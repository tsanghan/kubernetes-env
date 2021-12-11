# Kubernetes-env

## Hello and welcome to Kubenetes-env

* This is a Kubernetes *self-learning education aids*.
* For education/learning purpose, *1x Control-Plane, 2x Workers* will be more then enough.
* This *1x Control-Plane, 2x Workers* Kubernetes Cluster can all reside in 1 single VM.
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
3. Create a `Projects` directory and `cd` into it
4. `git clone https://github.com/tsanghan/kubernetes-env.git`
5. `cd` into `kubernetes-env`
6. `sudo ./prepare-vm.sh`
7. Follow the instruction at the end of the completion of `prepare-vm.sh` script
8. Log back into your VM
9. `./prepare-env.sh`
10. You have 2 choices to deploy a kubernetes cluster, using *LXD* or *KIND*

### Kubernetes on LXD

11. We will explore LXD method first
12. Run `prepare-lxd.sh`
13. `cd` into `Projects/kubernetes-env/kubernetes-on-lxd`
14. Wait untill script finish
15. `lxc launch -p k8s focal-cloud <your lxc node name>`
16. Instructions below will use the node name of *lxd-ctrlp-1*
17. Launch 2 more worker nodes with above command (example *lxd-wrker-1* and *lxd-wrker-2*)
18. `watch lxc ls`
19. All 3 lxc nodes will power down after being prepared
20. Start all nodes `lxc start --all`
21. Run `kubeadm init` on control-plane node with the following long command
22. `lxc exec lxd-ctrlp-1 -- kubeadm init --upload-certs | tee kubeadm-init.out`  
23. Wait till kubeadm finish initializing control-plane node
24. Perform `kubeadm join` command from `kubeadm init` output on 2 worker nodes. Please refer to last 2 lines of local `kubeadm-init.out` file for the full `kubeadm join` command.
25. Pull `/etc/kubernetes/admin.conf` from within `lxd-ctrlp-1` node into your local `~/.kube` directory with the following command
26. `lxc file pull lxd-ctrlp-1/etc/kubernetes/admin.conf ~/.kube/config` make sure you have created ~/.kube directory first
27. Activate `kubectl` auto-completion
28. `source ~/.bash_complete` assuming you are using bash
31. Now you can access you cluster with `kubectl` command, alised with `k`
32. `k get no`
33. All your nodes are not ready, becasue we have yet to instal a CNI plugin
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
41. Run `k-apply.sh`
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
46. What is your memory usage out of 8GB? Check with `htop`

### Kubernetes with KIND

1. `cd ../kind`
2. Activate `kind` auto-completion
3. `source <(kind completion bash)` assuming you are using bash
4. `completion -F __start_kind kind`
5. Start the `kind` cluster
6. `kind create cluster --config kind.yaml`
7. The provided `kind.yaml` will start 1x *Control-Plane Node* and 2x *Worker Nodes* and disable default CNI
8. `kind` automatically merge `kind` cluster config into your `~/.kube/config`
9. if you `k config get-contexts` you can see you will have 2 contexts for 2 clusters (if you have not deleted LXD cluster)
```
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kind-kind                     kind-kind    kind-kind
          kubernetes-admin@kubernetes   kubernetes   kubernetes-admin
```
10. The current context is `kind-kind`
11. `k get no`
12. All your nodes are not ready, becasue we have yet to instal a CNI plugin (we disabled default CNI in `kind.yaml`)
```
NAME                 STATUS     ROLES                  AGE     VERSION
kind-control-plane   NotReady   control-plane,master   6m46s   v1.22.0
kind-worker          NotReady   <none>                 6m15s   v1.22.0
kind-worker2         NotReady   <none>                 6m15s   v1.22.0
```
13. We will use calico as it support Network Policy
14. `k apply -f https://docs.projectcalico.org/manifests/calico.yaml`
15. `k get no` again
16. Wait till all your nodes are ready
```

NAME                 STATUS   ROLES                  AGE     VERSION
kind-control-plane   Ready    control-plane,master   9m      v1.22.0
kind-worker          Ready    <none>                 8m29s   v1.22.0
kind-worker2         Ready    <none>                 8m29s   v1.22.0
```
17. Type `k get all -A` to see all your pods
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
18. From here onwards, you can follow step 41. from `Kubernetes on LXD` to proceed
19. Explore and enjoy your 2 Kubernetes clusters
20. What is your memory usage out of 8GB? Check with `htop`

## How to stop the clusters?
### Kubernetes on LXD
1. `lxc stop --all`
2. To start again `lxc start --all`
3. You can purge/delete the cluster and start installation again, but you will need to delete individual nodes after they are stopped.
4. `lxc delete <node name>`
### Kubernetes with KIND
1. You cannot stop a `kind` cluster with `kind`. You can only `create` and `delete` with `kind`
2. `kind delete cluster`
3. If you really want to stop a `kind` cluster, you will need to use `docker` command
4. `docker container ls`
```
CONTAINER ID   IMAGE                  COMMAND                  CREATED             STATUS              PORTS                       NAMES
20ffab3b00a3   kindest/node:v1.22.0   "/usr/local/bin/entr…"   About an hour ago   Up About a minute   127.0.0.1:44651->6443/tcp   kind-control-plane
38f750fd85cb   kindest/node:v1.22.0   "/usr/local/bin/entr…"   About an hour ago   Up About a minute                               kind-worker2
26e00165cc2c   kindest/node:v1.22.0   "/usr/local/bin/entr…"   About an hour ago   Up About a minute                               kind-worker
```
5. `docker stop <NAME/CONTAINER ID> <NAME/CONTAINER ID> ...`
