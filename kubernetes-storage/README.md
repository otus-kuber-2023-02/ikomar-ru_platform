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
   Получили следующую конфигурацию сервера:
   ```text
    NAME                        STATUS   ROLES    AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
    cl1b58tb5f55te3ditem-iban   Ready    <none>   2m      v1.24.8   10.129.0.3    <none>        Ubuntu 20.04.5 LTS   5.4.0-139-generic   containerd://1.6.18
    cl1b58tb5f55te3ditem-ijet   Ready    <none>   2m1s    v1.24.8   10.129.0.25   <none>        Ubuntu 20.04.5 LTS   5.4.0-139-generic   containerd://1.6.18
    cl1b58tb5f55te3ditem-inod   Ready    <none>   2m16s   v1.24.8   10.129.0.9    <none>        Ubuntu 20.04.5 LTS   5.4.0-139-generic   containerd://1.6.18   
    ```

2. Создали StorageClass для CSI Host Path Driver. В качестве основы используем 
https://github.com/kubernetes-csi/csi-driver-host-path/blob/master/examples/csi-storageclass.yaml.
  ```

## PR checklist:
 - [x] Выставлен label с темой домашнего задания
