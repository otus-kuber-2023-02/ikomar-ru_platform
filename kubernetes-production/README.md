# Выполнено ДЗ №14
## Домашнее задание.  Создание и обновление кластера при помощи kubeadm

 - [x] Основное ДЗ
 - [ ] Задание со *

## Обзор

+ Ветка для работы: kubernetes-production

## В процессе сделано:

### Создание кластера версии 1.17 и обновление его с помощью Kubeadm
Выполнение задания:
1. Создал машины
      ```bash
      yc compute instance create \
        --name master \
        --platform=standard-v2 \
        --cores=4 \
        --memory=4 \
        --zone ru-central1-b \
        --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 \
        --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1804-lts,size=30,type=network-ssd \
        --ssh-key ~/.ssh/id_rsa.pub
      ```
      ```text
      yc compute instance create \
        --name worker-1 \
        --platform=standard-v2 \
        --cores=4 \
        --memory=4 \
        --zone ru-central1-b \
        --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 \
        --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1804-lts,size=30,type=network-ssd \
        --ssh-key ~/.ssh/id_rsa.pub
      yc compute instance create \
        --name worker-2 \
        --platform=standard-v2 \
        --cores=4 \
        --memory=4 \
        --zone ru-central1-b \
        --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 \
        --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1804-lts,size=30,type=network-ssd \
        --ssh-key ~/.ssh/id_rsa.pub
      yc compute instance create \
        --name worker-3 \
        --platform=standard-v2 \
        --cores=4 \
        --memory=4 \
        --zone ru-central1-b \
        --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 \
        --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1804-lts,size=30,type=network-ssd \
        --ssh-key ~/.ssh/id_rsa.pub   
      ```
      ```bash
      yc compute instance list
      ```
      ```text
      +----------------------+---------------------------+---------------+---------+----------------+-------------+
      |          ID          |           NAME            |    ZONE ID    | STATUS  |  EXTERNAL IP   | INTERNAL IP |
      +----------------------+---------------------------+---------------+---------+----------------+-------------+
      | epd9tsc1s84815die2rh | worker-3                  | ru-central1-b | RUNNING | 158.160.66.245 | 10.129.0.11 |
      | epddulutu3vrq4m17dk4 | worker-2                  | ru-central1-b | RUNNING | 158.160.68.86  | 10.129.0.24 |
      | epdj5ejgnrl1vtkep7ud | worker-1                  | ru-central1-b | RUNNING | 158.160.6.232  | 10.129.0.8  |
      | epdmv41f9s4j5mg4doet | master                    | ru-central1-b | RUNNING | 158.160.17.142 | 10.129.0.10 |
      +----------------------+---------------------------+---------------+---------+----------------+-------------+
      ```

2. Отключил swap на машинах
    ```bash
    ssh master sudo swapoff -a
    ssh w1 sudo swapoff -a
    ssh w2 sudo swapoff -a
    ssh w3 sudo swapoff -a
    ```

3. Включил маршрутизацию (для всех машин аналогично)
    ```bash
    ssh master
    sudo -s
    cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    EOF
    sysctl --system
    ```

4. Установил Docker (для всех машин аналогично)
    ```bash
    ssh master
    sudo -s
    apt update && apt-get install -y \
        apt-transport-https ca-certificates curl software-properties-common gnupg2
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - 
    add-apt-repository \
                "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt update && apt-get install -y \
              containerd.io=1.2.13-1 \
              docker-ce=5:19.03.8~3-0~ubuntu-$(lsb_release -cs) \
              docker-ce-cli=5:19.03.8~3-0~ubuntu-$(lsb_release -cs)
    cat > /etc/docker/daemon.json <<EOF
    {
        "exec-opts": ["native.cgroupdriver=systemd"],
        "log-driver": "json-file",
        "log-opts": {
            "max-size": "100m"
         },
        "storage-driver": "overlay2"
    }
    EOF
    mkdir -p /etc/systemd/system/docker.service.d && systemctl daemon-reload && systemctl restart docker 
    ```
5. Установил kubeadm, kubectl, kubelet на всех нодах
   ```bash
   sudo -s
   apt update && apt install -y apt-transport-https curl
   curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
   cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
   deb https://apt.kubernetes.io/ kubernetes-xenial main
   EOF
   apt update && apt install -y kubelet=1.17.4-00 kubeadm=1.17.4-00 kubectl=1.17.4-00
   exit
   ```
6. Создал кластер
   ```bash
   sudo -s
   kubeadm init --pod-network-cidr=192.168.0.0/24
   kubectl get nodes
   ```
   ```text
   Your Kubernetes control-plane has initialized successfully!
   
   To start using your cluster, you need to run the following as a regular user:
   
     mkdir -p $HOME/.kube
     sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
     sudo chown $(id -u):$(id -g) $HOME/.kube/config
   
   You should now deploy a pod network to the cluster.
   Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
     https://kubernetes.io/docs/concepts/cluster-administration/addons/
   
   Then you can join any number of worker nodes by running the following on each as root:
   
   kubeadm join 10.129.0.10:6443 --token 6pllu9.b3wztpt7ip0a67hv \
       --discovery-token-ca-cert-hash sha256:c7368520abb1a0a9aa86f218e197967e0c0f799ddb9b3e04e4279fe196f3ecba 
   
   NAME                   STATUS     ROLES    AGE     VERSION
   epdmv41f9s4j5mg4doet   NotReady   master   2m23s   v1.17.4
   ```
7. Установил Calico
   ```bash
   sudo -s
   kubectl apply -f https://docs.projectcalico.org/archive/v3.12/manifests/calico.yaml 
   ```
8. Подключил worker-ноды
   ```bash
   kubeadm join 10.129.0.10:6443 --token 6pllu9.b3wztpt7ip0a67hv \
          --discovery-token-ca-cert-hash sha256:c7368520abb1a0a9aa86f218e197967e0c0f799ddb9b3e04e4279fe196f3ecba 
   kubectl get nodes
   ```
   ```text
   NAME                   STATUS     ROLES    AGE     VERSION
   epd9tsc1s84815die2rh   NotReady   <none>   11s     v1.17.4
   epddulutu3vrq4m17dk4   NotReady   <none>   26s     v1.17.4
   epdj5ejgnrl1vtkep7ud   Ready      <none>   111s    v1.17.4
   epdmv41f9s4j5mg4doet   Ready      master   7m34s   v1.17.4
   ```
9. Тестовый запуск
   ```bash
   sudo -s
   cat <<EOF > deployment.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx-deployment
   spec:
     selector:
       matchLabels:
         app: nginx
     replicas: 4
     template:
       metadata:
         labels:
           app: nginx
       spec:
         containers:
         - name: nginx
           image: nginx:1.17.2
           ports:
           - containerPort: 80
   EOF
   kubectl apply -f deployment.yaml
   ```
   ```text
   NAME                               READY   STATUS    RESTARTS   AGE   IP               NODE                   NOMINATED NODE   READINESS GATES
   nginx-deployment-c8fd555cc-9t29k   1/1     Running   0          69s   192.168.123.65   epd9tsc1s84815die2rh   <none>           <none>
   nginx-deployment-c8fd555cc-k5zdr   1/1     Running   0          69s   192.168.214.65   epdj5ejgnrl1vtkep7ud   <none>           <none>
   nginx-deployment-c8fd555cc-md4ds   1/1     Running   0          69s   192.168.180.1    epddulutu3vrq4m17dk4   <none>           <none>
   nginx-deployment-c8fd555cc-t8vkq   1/1     Running   0          69s   192.168.180.2    epddulutu3vrq4m17dk4   <none>           <none>
   ```
10. Обновил кластер с помощью kubeadm, начал с master-ноды
   ```bash
   sudo -s
   apt-get update && apt-get install -y kubeadm=1.18.0-00 kubelet=1.18.0-00 kubectl=1.18.0-00
   kubeadm version
   kubectl version
   kubectl describe pod -l component=kube-apiserver -n kube-system
   ```
   ```text
   kubeadm version: &version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.0", GitCommit:"9e991415386e4cf155a24b1da15becaa390438d8", GitTreeState:"clean", BuildDate:"2020-03-25T14:56:30Z", GoVersion:"go1.13.8", Compiler:"gc", Platform:"linux/amd64"}
   Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.0", GitCommit:"9e991415386e4cf155a24b1da15becaa390438d8", GitTreeState:"clean", BuildDate:"2020-03-25T14:58:59Z", GoVersion:"go1.13.8", Compiler:"gc", Platform:"linux/amd64"}
   Server Version: version.Info{Major:"1", Minor:"17", GitVersion:"v1.17.17", GitCommit:"f3abc15296f3a3f54e4ee42e830c61047b13895f", GitTreeState:"clean", BuildDate:"2021-01-13T13:13:00Z", GoVersion:"go1.13.15", Compiler:"gc", Platform:"linux/amd64"}
   Name:                 kube-apiserver-epdmv41f9s4j5mg4doet
   Namespace:            kube-system
   Priority:             2000000000
   Priority Class Name:  system-cluster-critical
   Node:                 epdmv41f9s4j5mg4doet/10.129.0.10
   Start Time:           Mon, 12 Jun 2023 12:28:45 +0000
   Labels:               component=kube-apiserver
                         tier=control-plane
   Annotations:          kubernetes.io/config.hash: 114d4fbf12223b6e27ea1a5c22899dcb
                         kubernetes.io/config.mirror: 114d4fbf12223b6e27ea1a5c22899dcb
                         kubernetes.io/config.seen: 2023-06-12T12:28:44.330573284Z
                         kubernetes.io/config.source: file
   Status:               Running
   IP:                   10.129.0.10
   IPs:
     IP:           10.129.0.10
   Controlled By:  Node/epdmv41f9s4j5mg4doet
   Containers:
     kube-apiserver:
       Container ID:  docker://a273857068ee77200ef11abd333e8beea3009ef5d119cd4a7564efa0ccd1783e
       Image:         k8s.gcr.io/kube-apiserver:v1.17.17
       Image ID:      docker-pullable://k8s.gcr.io/kube-apiserver@sha256:71344dfb6a804ff6b2c8bf5f72b1f7941ddee1fbff7369836339a79387aa071a
       Port:          <none>
       Host Port:     <none>
       Command:
         kube-apiserver
         --advertise-address=10.129.0.10
         --allow-privileged=true
         --authorization-mode=Node,RBAC
         --client-ca-file=/etc/kubernetes/pki/ca.crt
         --enable-admission-plugins=NodeRestriction
         --enable-bootstrap-token-auth=true
         --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
         --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
         --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
         --etcd-servers=https://127.0.0.1:2379
         --insecure-port=0
         --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
         --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
         --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
         --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
         --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
         --requestheader-allowed-names=front-proxy-client
         --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
         --requestheader-extra-headers-prefix=X-Remote-Extra-
         --requestheader-group-headers=X-Remote-Group
         --requestheader-username-headers=X-Remote-User
         --secure-port=6443
         --service-account-key-file=/etc/kubernetes/pki/sa.pub
         --service-cluster-ip-range=10.96.0.0/12
         --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
         --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
       State:          Running
         Started:      Mon, 12 Jun 2023 12:28:56 +0000
       Ready:          True
       Restart Count:  0
       Requests:
         cpu:        250m
       Liveness:     http-get https://10.129.0.10:6443/healthz delay=15s timeout=15s period=10s #success=1 #failure=8
       Environment:  <none>
       Mounts:
         /etc/ca-certificates from etc-ca-certificates (ro)
         /etc/kubernetes/pki from k8s-certs (ro)
         /etc/ssl/certs from ca-certs (ro)
         /usr/local/share/ca-certificates from usr-local-share-ca-certificates (ro)
         /usr/share/ca-certificates from usr-share-ca-certificates (ro)
   Conditions:
     Type              Status
     Initialized       True 
     Ready             True 
     ContainersReady   True 
     PodScheduled      True 
   Volumes:
     ca-certs:
       Type:          HostPath (bare host directory volume)
       Path:          /etc/ssl/certs
       HostPathType:  DirectoryOrCreate
     etc-ca-certificates:
       Type:          HostPath (bare host directory volume)
       Path:          /etc/ca-certificates
       HostPathType:  DirectoryOrCreate
     k8s-certs:
       Type:          HostPath (bare host directory volume)
       Path:          /etc/kubernetes/pki
       HostPathType:  DirectoryOrCreate
     usr-local-share-ca-certificates:
       Type:          HostPath (bare host directory volume)
       Path:          /usr/local/share/ca-certificates
       HostPathType:  DirectoryOrCreate
     usr-share-ca-certificates:
       Type:          HostPath (bare host directory volume)
       Path:          /usr/share/ca-certificates
       HostPathType:  DirectoryOrCreate
   QoS Class:         Burstable
   Node-Selectors:    <none>
   Tolerations:       :NoExecute
   Events:
     Type    Reason   Age   From                           Message
     ----    ------   ----  ----                           -------
     Normal  Pulled   96s   kubelet, epdmv41f9s4j5mg4doet  Container image "k8s.gcr.io/kube-apiserver:v1.17.17" already present on machine
     Normal  Created  95s   kubelet, epdmv41f9s4j5mg4doet  Created container kube-apiserver
     Normal  Started  95s   kubelet, epdmv41f9s4j5mg4doet  Started container kube-apiserver
   ```
   ```text
   COMPONENT   CURRENT       AVAILABLE
   Kubelet     3 x v1.17.4   v1.18.20
               1 x v1.18.0   v1.18.20
   
   Upgrade to the latest stable version:
   
   COMPONENT            CURRENT    AVAILABLE
   API Server           v1.17.17   v1.18.20
   Controller Manager   v1.17.17   v1.18.20
   Scheduler            v1.17.17   v1.18.20
   Kube Proxy           v1.17.17   v1.18.20
   CoreDNS              1.6.5      1.6.7
   Etcd                 3.4.3      3.4.3-0
   ```
   ```bash
   sudo -s
   kubeadm upgrade plan
   kubeadm upgrade apply v1.18.0 -f
   kubeadm version
   kubelet --version
   kubectl version
   kubectl describe pod -l component=kube-apiserver -n kube-system | grep kube-apiserver
   ```
   ```text
   Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.0", GitCommit:"9e991415386e4cf155a24b1da15becaa390438d8", GitTreeState:"clean", BuildDate:"2020-03-25T14:58:59Z", GoVersion:"go1.13.8", Compiler:"gc", Platform:"linux/amd64"}
   Server Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.0", GitCommit:"9e991415386e4cf155a24b1da15becaa390438d8", GitTreeState:"clean", BuildDate:"2020-03-25T14:50:46Z", GoVersion:"go1.13.8", Compiler:"gc", Platform:"linux/amd64"}
   Name:                 kube-apiserver-epdmv41f9s4j5mg4doet
   Namespace:            kube-system
   Priority:             2000000000
   Priority Class Name:  system-cluster-critical
   Node:                 epdmv41f9s4j5mg4doet/10.129.0.10
   Start Time:           Mon, 12 Jun 2023 12:28:45 +0000
   Labels:               component=kube-apiserver
                         tier=control-plane
   Annotations:          kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 10.129.0.10:6443
                         kubernetes.io/config.hash: 52c2831a8abaf2e4d2b60df66e888919
                         kubernetes.io/config.mirror: 52c2831a8abaf2e4d2b60df66e888919
                         kubernetes.io/config.seen: 2023-06-12T12:32:37.691902466Z
                         kubernetes.io/config.source: file
   Status:               Running
   IP:                   10.129.0.10
   IPs:
     IP:           10.129.0.10
   Controlled By:  Node/epdmv41f9s4j5mg4doet
   Containers:
     kube-apiserver:
       Container ID:  docker://be98ddbb2d7cb917545ae1e97d0fe026f65b0b922ca0bdfa853de0ae4bf13bae
       Image:         k8s.gcr.io/kube-apiserver:v1.18.0
       Image ID:      docker-pullable://k8s.gcr.io/kube-apiserver@sha256:fc4efb55c2a7d4e7b9a858c67e24f00e739df4ef5082500c2b60ea0903f18248
       Port:          <none>
       Host Port:     <none>
       Command:
         kube-apiserver
         --advertise-address=10.129.0.10
         --allow-privileged=true
         --authorization-mode=Node,RBAC
         --client-ca-file=/etc/kubernetes/pki/ca.crt
         --enable-admission-plugins=NodeRestriction
         --enable-bootstrap-token-auth=true
         --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
         --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
         --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
         --etcd-servers=https://127.0.0.1:2379
         --insecure-port=0
         --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
         --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
         --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
         --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
         --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
         --requestheader-allowed-names=front-proxy-client
         --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
         --requestheader-extra-headers-prefix=X-Remote-Extra-
         --requestheader-group-headers=X-Remote-Group
         --requestheader-username-headers=X-Remote-User
         --secure-port=6443
         --service-account-key-file=/etc/kubernetes/pki/sa.pub
         --service-cluster-ip-range=10.96.0.0/12
         --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
         --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
       State:          Running
         Started:      Mon, 12 Jun 2023 12:32:44 +0000
       Ready:          True
       Restart Count:  0
       Requests:
         cpu:        250m
       Liveness:     http-get https://10.129.0.10:6443/healthz delay=15s timeout=15s period=10s #success=1 #failure=8
       Environment:  <none>
       Mounts:
         /etc/ca-certificates from etc-ca-certificates (ro)
         /etc/kubernetes/pki from k8s-certs (ro)
         /etc/ssl/certs from ca-certs (ro)
         /usr/local/share/ca-certificates from usr-local-share-ca-certificates (ro)
         /usr/share/ca-certificates from usr-share-ca-certificates (ro)
   Conditions:
     Type              Status
     Initialized       True 
     Ready             True 
     ContainersReady   True 
     PodScheduled      True 
   Volumes:
     ca-certs:
       Type:          HostPath (bare host directory volume)
       Path:          /etc/ssl/certs
       HostPathType:  DirectoryOrCreate
     etc-ca-certificates:
       Type:          HostPath (bare host directory volume)
       Path:          /etc/ca-certificates
       HostPathType:  DirectoryOrCreate
     k8s-certs:
       Type:          HostPath (bare host directory volume)
       Path:          /etc/kubernetes/pki
       HostPathType:  DirectoryOrCreate
     usr-local-share-ca-certificates:
       Type:          HostPath (bare host directory volume)
       Path:          /usr/local/share/ca-certificates
       HostPathType:  DirectoryOrCreate
     usr-share-ca-certificates:
       Type:          HostPath (bare host directory volume)
       Path:          /usr/share/ca-certificates
       HostPathType:  DirectoryOrCreate
   QoS Class:         Burstable
   Node-Selectors:    <none>
   Tolerations:       :NoExecute
   Events:
     Type    Reason   Age   From                           Message
     ----    ------   ----  ----                           -------
     Normal  Pulled   4m5s  kubelet, epdmv41f9s4j5mg4doet  Container image "k8s.gcr.io/kube-apiserver:v1.18.0" already present on machine
     Normal  Created  4m5s  kubelet, epdmv41f9s4j5mg4doet  Created container kube-apiserver
     Normal  Started  4m5s  kubelet, epdmv41f9s4j5mg4doet  Started container kube-apiserver
   ```
   ```bash
   kubectl get nodes -o wide
   ```
   ```text
   NAME                   STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
   epd9tsc1s84815die2rh   Ready    <none>   16m   v1.17.4   10.129.0.11   <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   docker://19.3.8
   epddulutu3vrq4m17dk4   Ready    <none>   16m   v1.17.4   10.129.0.24   <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   docker://19.3.8
   epdj5ejgnrl1vtkep7ud   Ready    <none>   17m   v1.17.4   10.129.0.8    <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   docker://19.3.8
   epdmv41f9s4j5mg4doet   Ready    master   23m   v1.18.0   10.129.0.10   <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   docker://19.3.8
   ```
11. Обновил worker-ноды
   ```bash
   ssh w1
   sudo -s
   apt-get install -y kubelet=1.18.0-00 kubeadm=1.18.0-00
   systemctl restart kubelet
   ```
   ```text
   NAME                   STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
   epd9tsc1s84815die2rh   Ready    <none>   19m   v1.17.4   10.129.0.11   <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   docker://19.3.8
   epddulutu3vrq4m17dk4   Ready    <none>   20m   v1.17.4   10.129.0.24   <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   docker://19.3.8
   epdj5ejgnrl1vtkep7ud   Ready    <none>   21m   v1.18.0   10.129.0.8    <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   docker://19.3.8
   epdmv41f9s4j5mg4doet   Ready    master   27m   v1.18.0   10.129.0.10   <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   docker://19.3.8
   ```
12. Обновил оставшиеся ноды при помощи kubeadm
   ```bash
   ssh master
   sudo -s
   kubectl drain epd9tsc1s84815die2rh --ignore-daemonsets
   kubectl drain epddulutu3vrq4m17dk4 --ignore-daemonsets
   ```
   ```bash
   # на оставшихся нодах
   sudo -s
   apt install -y kubelet=1.18.0-00 kubeadm=1.18.0-00
   systemctl restart kubelet
   ```
   ```bash
   ssh master
   sudo -s
   kubectl uncordon epd9tsc1s84815die2rh
   kubectl uncordon epddulutu3vrq4m17dk4
   kubectl get nodes -o wide
   ```
   ```text
   NAME                   STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
   epd9tsc1s84815die2rh   Ready    <none>   26m   v1.18.0   10.129.0.11   <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   docker://19.3.8
   epddulutu3vrq4m17dk4   Ready    <none>   26m   v1.18.0   10.129.0.24   <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   docker://19.3.8
   epdj5ejgnrl1vtkep7ud   Ready    <none>   27m   v1.18.0   10.129.0.8    <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   docker://19.3.8
   epdmv41f9s4j5mg4doet   Ready    master   33m   v1.18.0   10.129.0.10   <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   docker://19.3.8
   ```
13. Автоматическое развертывание кластеров
+ создал виртуалки заново
```text
+----------------------+---------------------------+---------------+---------+---------------+-------------+
|          ID          |           NAME            |    ZONE ID    | STATUS  |  EXTERNAL IP  | INTERNAL IP |
+----------------------+---------------------------+---------------+---------+---------------+-------------+
| epd7msvrfibmvc4v0ffe | master                    | ru-central1-b | RUNNING | 51.250.24.199 | 10.129.0.23 |
| epd7tg1ng84jnvj2r9i8 | worker-2                  | ru-central1-b | RUNNING | 158.160.6.232 | 10.129.0.38 |
| epda1oo9q3om0s7s0rlo | worker-3                  | ru-central1-b | RUNNING | 158.160.73.98 | 10.129.0.25 |
| epdq96dab4nj6qr3be2v | worker-1                  | ru-central1-b | RUNNING | 158.160.15.53 | 10.129.0.18 |
+----------------------+---------------------------+---------------+---------+---------------+-------------+
```
+ установил kubespray
```bash
# получение kubespray
git submodule add https://github.com/kubernetes-sigs/kubespray.git
# установка зависимостей
pip install -r requirements.txt
# копирование примера конфига в отдельную директорию
cp -rfp inventory/sample inventory/mycluster
```
+ настроил ansible
```text
worker-1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
master | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
worker-2 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
worker-3 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```
+ запустил магию ansible
```bash
ansible-playbook -i ../inventory.ini --become --become-user=root --user=${SSH_USERNAME} --key-file=${SSH_PRIVATE_KEY} cluster.yml
```
```bash
sudo -s
mkdir -p $HOME/.kube
sudo cp -if /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes -o wide
```
```text
NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
master     Ready    control-plane   4m47s   v1.26.5   10.129.0.23   <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   containerd://1.7.1
worker-1   Ready    <none>          3m36s   v1.26.5   10.129.0.18   <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   containerd://1.7.1
worker-2   Ready    <none>          3m37s   v1.26.5   10.129.0.38   <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   containerd://1.7.1
worker-3   Ready    <none>          3m36s   v1.26.5   10.129.0.25   <none>        Ubuntu 18.04.6 LTS   4.15.0-112-generic   containerd://1.7.1
```

## PR checklist:
 - [x] Выставлен label с темой домашнего задания
