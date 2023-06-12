# Выполнено ДЗ №12
## Домашнее задание. Развертывание системы хранения данных

 - [x] Основное ДЗ
 - [ ] Задание со *

## Обзор

+ Ветка для работы: kubernetes-storage
+ В ходе работы мы:
  + установим CSI-драйвер
  + протестируем функционал снапшотов

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

2. Установил CSI-драйвер, скачанный из https://github.com/kubernetes-csi/csi-driver-host-path/ (`/deploy/kubernetes-1.24/deploy.sh`)

3. Создал StorageClass для CSI Host Path Driver. В качестве основы использовали 
https://github.com/kubernetes-csi/csi-driver-host-path/blob/master/examples/csi-storageclass.yaml.
    ```bash
    kubectl apply -f ./hw/storage-class.yaml
    kubectl get StorageClass
    ```
    ```text
    NAME                           PROVISIONER                     RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
    csi-hostpath-storageclass      hostpath.csi.k8s.io             Delete          Immediate              true                   21s
    yc-network-hdd (default)       disk-csi-driver.mks.ycloud.io   Delete          WaitForFirstConsumer   true                   7d21h
    yc-network-nvme                disk-csi-driver.mks.ycloud.io   Delete          WaitForFirstConsumer   true                   7d21h
    yc-network-ssd                 disk-csi-driver.mks.ycloud.io   Delete          WaitForFirstConsumer   true                   7d21h
    yc-network-ssd-nonreplicated   disk-csi-driver.mks.ycloud.io   Delete          WaitForFirstConsumer   true                   7d21h
    ```

4. Создал объект PVC c именем `storage-pvc` (https://github.com/kubernetes-csi/csi-driver-host-path/blob/master/examples/csi-pvc.yaml)
    ```bash
    kubectl apply -f ./hw/storage-pvc.yaml
    kubectl get pvc
    ```
    ```text
    NAME                                  STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
    storage-pvc                           Bound    pvc-f653367a-f722-4dd6-b442-3ca6566be956   1Gi        RWO            csi-hostpath-sc   6s
    ```

5. Создал объект Pod c именем `storage-pod` (https://github.com/kubernetes-csi/csi-driver-host-path/blob/master/examples/csi-app-inline.yaml)
    ```bash
    kubectl apply -f ./hw/storage-pod.yaml
    kubectl get pod
    ```
    ```text
    NAME                                    READY   STATUS      RESTARTS   AGE
    storage-pod                             1/1     Running     0          9s
    ```

6. Протестировал функционал снапшотов
+ Создал данные
```bash
kubectl exec storage-pod -- ls /data/
kubectl exec storage-pod -- touch /data/test.file
kubectl exec storage-pod -- ls /data/ 
```
+ сделал снапшот
```bash
kubectl apply -f hw/csi-snapshot.yaml
```
```text
volumesnapshot.snapshot.storage.k8s.io/csi-snapshot created
```
+ убил Pod, PVC, PV
```bash
kubectl delete -f ./hw/storage-pvc.yaml -f ./hw/storage-pod.yaml  
```
```text
persistentvolumeclaim "storage-pvc" deleted
pod "storage-pod" deleted
```
+ Создал pvc из снапшота
```bash
kubectl apply -f hw/csi-restore.yaml
```
```text
persistentvolumeclaim/storage-pvc created
```
+ пересоздал объект Pod c именем `storage-pod`
```bash
kubectl apply -f ./hw/storage-pod.yaml 
```
```text
pod/storage-pod created
```
+ проверил файл
```bash
kubectl exec storage-pod -- ls /data/
```
```text
test.file
```

## PR checklist:
 - [x] Выставлен label с темой домашнего задания
