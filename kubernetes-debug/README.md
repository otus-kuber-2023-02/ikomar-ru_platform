# Выполнено ДЗ №13
## Домашнее задание. Проведение диагностики состояния кластера, знакомство с инструментами для диагностики

 - [x] Основное ДЗ
 - [ ] Задание со *

## Обзор

+ Ветка для работы: kubernetes-debug

## В процессе сделано:

Выполнение задания:
1. Подготовка k8s кластера в yandex-cloud
    ```bash
    yc managed-kubernetes cluster create k8s-otus \
    --network-id "enp02k4ifo4p5ndu0d15" \
    --zone "ru-central1-b" \
    --subnet-id "e2l3a8ho8nun654f6bee" \
    --public-ip \
    --release-channel REGULAR \
    --version 1.24 \
    --node-service-account-name k8s-node-group-pm1 \
    --service-account-id "ajebdf109kiq85a9v9ks" \
    --cloud-id "b1g7vl9ofg6pq269b87f" \
    --folder-id "b1g4eqcgv9u4pfhp54tt"
   
    yc managed-kubernetes node-group create node-1 \
    --cluster-name k8s-otus \
    --fixed-size 3 \
    --platform standard-v2 \
    --network-interface subnets=["e2l3a8ho8nun654f6bee"]
    --core-fraction 5 \
    --preemptible \
    --public-ip \
    --memory 4 \
    --cores 2 \
    --disk-size 60 \
    --disk-type network-hdd \
    --version 1.24 \
    --cloud-id "b1g7vl9ofg6pq269b87f" \
    --folder-id "b1g4eqcgv9u4pfhp54tt"

    yc managed-kubernetes cluster get-credentials k8s-otus --external --force --folder-id b1g4eqcgv9u4pfhp54tt
    kubectl get nodes -o wide
    ```
   Получил следующую конфигурацию сервера:
   ```text
    NAME                        STATUS   ROLES    AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
    cl1b58tb5f55te3ditem-iban   Ready    <none>   2m      v1.24.8   10.129.0.3    <none>        Ubuntu 20.04.5 LTS   5.4.0-139-generic   containerd://1.6.18
    cl1b58tb5f55te3ditem-ijet   Ready    <none>   2m1s    v1.24.8   10.129.0.25   <none>        Ubuntu 20.04.5 LTS   5.4.0-139-generic   containerd://1.6.18
    cl1b58tb5f55te3ditem-inod   Ready    <none>   2m16s   v1.24.8   10.129.0.9    <none>        Ubuntu 20.04.5 LTS   5.4.0-139-generic   containerd://1.6.18   
    ```

2. Установил `kubectl-debug` из https://github.com/JamesTGrant/kubectl-debug (форк устаревшего репозитория)
   ```bash
   curl -Lo kubectl-debug.tar.gz https://github.com/aylei/kubectl-debug/releases/download/v0.1.1/kubectl-debug_0.1.1_linux_amd64.tar.gz
   tar -zxvf kubectl-debug.tar.gz kubectl-debug
   sudo mv kubectl-debug /usr/local/bin/ 
   kubectl-debug --version
   ```
   ```text
   debug version v0.0.0-master+$Format:%h$
   ```

3. Запустил в кластере поды с агентом `kubectl-debug`
   ```bash
   kubectl apply -f strace/agent_daemonset.yml 
   ```

4. Запустил `nginx`
   ```bash
   kubectl run nginx --image=nginx 
   ```
   ```text
   pod/nginx create
   ```

5. В итоге не увидел никакой разницы между 5 лет не обновлявшимся инструментом и нынешним состоянием команды `kubectl debug`
   ```bash
   kubectl debug -it nginx --image=busybox:1.28 --target=nginx 
   ```
   ```text
   Targeting container "nginx". If you don't see processes from this container it may be because the container runtime doesn't support this feature.
   Defaulting debug container name to debugger-msl7n.
   If you don't see a command prompt, try pressing enter.
   / # ps
   PID   USER     TIME  COMMAND
       1 root      0:00 nginx: master process nginx -g daemon off;
      29 101       0:00 nginx: worker process
      30 101       0:00 nginx: worker process
      31 root      0:00 sh
      37 root      0:00 ps
   / # 
   ```
   Добавление прав можно произвести через kube api
   ```text
   curl -v -XPATCH -H "Content-Type: application/json-patch+json" \
   'http://127.0.0.1:8001/api/v1/namespaces/default/pods/nginx-8f458dc5b-wkvq4/ephemeralcontainers' \
   --data-binary @- << EOF
   [{
   "op": "add", "path": "/spec/ephemeralContainers/-",
   "value": {
   "command":[ "/bin/sh" ],
   "stdin": true, "tty": true,
   "image": "nicolaka/netshoot",
   "name": "debug-strace",
   "securityContext": {"capabilities": {"add": ["SYS_PTRACE"]}},
   "targetContainerName": "nginx" }}]
   EOF
   ```

6. iptables-tailer

+ по совету товарищей установил в старой версии kind (в 2023 году процесс довольно бессмысленый)
```bash
kind create cluster --config kind-config.yaml
```
+ Calico
```bash
kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml
kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true
```
+ установим манифесты для оператора
```bash
kubectl apply -f ./kit/deploy/crd.yaml
kubectl apply -f ./kit/deploy/rbac.yaml
kubectl apply -f ./kit/deploy/operator.yaml
kubectl get pods -l name=netperf-operator 
```
```text
NAME                                READY   STATUS    RESTARTS   AGE
netperf-operator-569c597b9b-249bd   1/1     Running   0          267s
```
+ установил оставшиеся манифесты
```bash
kubectl apply -f ./kit/deploy/cr.yaml
kubectl apply -f ./kit/netperf-calico-policy.yaml 
```
+ установил kube-iptables-tailer
```bash
kubectl apply -f kit/iptables-tailer.yaml 
```

## PR checklist:
 - [x] Выставлен label с темой домашнего задания
