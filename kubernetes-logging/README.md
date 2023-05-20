# Выполнено ДЗ №9 
## Сервисы централизованного логирования для компонентов Kubernetes и приложений 

 - [x] Основное ДЗ
 - [ ] Задание со *

## В процессе сделано:

Подготовка к заданию:
```bash
mkdir kubernetes-logging
cd kubernetes-logging
# установка Terraform в yc
yc iam service-account create --name terraform
# добавил ему роль admin в интерфейсе, чтобы не заморачиваться
yc iam key create \
  --service-account-id ajehf53me551dgp8e6io \
  --folder-name default \
  --output key.json
yc config profile create sa-terraform
yc config set service-account-key key.json
yc config set cloud-id b1g7vl9ofg6pq269b87f
yc config set folder-id b1g4eqcgv9u4pfhp54tt
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
nano ~/.terraformrc
```
Содержимое файла .terraformrc:
```text
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```
Выполнение задания:
1. Подготовка k8s кластера в yandex-cloud через terraform
    ```bash
    cd k8s-tf
    terraform init
    terraform validate
    terraform plan
    terraform apply
    kubectl get nodes
    ```
    Получили следующую конфигурацию сервера:
    ```text
    NAME                        STATUS   ROLES    AGE     VERSION
    cl1h5eo9kgaqk16p4vtp-eloc   Ready    <none>   2m32s   v1.24.8
    cl1kqom3q3hvg5f1a1e4-orop   Ready    <none>   118s    v1.24.8
    cl1kqom3q3hvg5f1a1e4-ovel   Ready    <none>   2m9s    v1.24.8
    cl1kqom3q3hvg5f1a1e4-utak   Ready    <none>   2m21s   v1.24.8
    ```
    Проверка `taints`:
    ```bash
    kubectl get nodes -o json | jq '.items[].spec.taints'
    ```
    ```text
    [
      {
        "effect": "NoSchedule",
        "key": "node-role",
        "value": "infra"
      }
    ]
    [
      {
        "effect": "NoSchedule",
        "key": "node-role",
        "value": "infra"
      }
    ]
    [
      {
        "effect": "NoSchedule",
        "key": "node-role",
        "value": "infra"
      }
    ]
    ```
2. Установка HipsterShop   
    ```bash
    kubectl create ns microservices-demo
    kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Logging/microservices-demo-without-resources.yaml -n microservices-demo
    kubectl get pods -n microservices-demo -o wide
    ```
    ```text
    NAME                                     READY   STATUS         RESTARTS       AGE     IP              NODE                        NOMINATED NODE   READINESS GATES
    adservice-58f8655b97-r59wz               0/1     ErrImagePull   0              4m21s   10.112.131.19   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
    cartservice-6f6b5b875d-f6m48             1/1     Running        2 (105s ago)   4m22s   10.112.131.14   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
    checkoutservice-b5545dc95-96fcd          1/1     Running        0              4m23s   10.112.131.9    cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
    currencyservice-f7b9cc-skbgb             1/1     Running        0              4m22s   10.112.131.16   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
    emailservice-59954c6bff-dv55t            1/1     Running        0              4m24s   10.112.131.8    cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
    frontend-75f46fcfb7-gwsbz                1/1     Running        0              4m23s   10.112.131.11   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
    loadgenerator-7d88bdbbf8-jnjwm           1/1     Running        4 (90s ago)    4m22s   10.112.131.15   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
    paymentservice-556f7b5695-xxjdq          1/1     Running        0              4m23s   10.112.131.12   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
    productcatalogservice-78854d86ff-rcnkz   1/1     Running        0              4m23s   10.112.131.13   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
    recommendationservice-b8f974fc-57l4j     1/1     Running        0              4m23s   10.112.131.10   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
    redis-cart-745456dd9b-x94lw              1/1     Running        0              4m22s   10.112.131.18   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
    shippingservice-7b5695bdb5-qsmt8         1/1     Running        0              4m22s   10.112.131.17   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
    ```
3. Установка EFK стека | Helm charts
   ```bash
   helm repo add elastic https://helm.elastic.co
   kubectl create ns observability
   helm upgrade --install elasticsearch elastic/elasticsearch --namespace observability
   helm upgrade --install kibana elastic/kibana --namespace observability
   helm upgrade --install fluent-bit stable/fluent-bit --namespace observability
   ```
   Elastic заблокирован в России, 403 ошибка.
   ```text
   namespace/observability created
   Release "elasticsearch" does not exist. Installing it now.
   Error: failed to fetch https://helm.elastic.co/helm/elasticsearch/elasticsearch-8.5.1.tgz : 403 Forbidden
   Release "kibana" does not exist. Installing it now.
   Error: failed to fetch https://helm.elastic.co/helm/kibana/kibana-8.5.1.tgz : 403 Forbidden
   Release "fluent-bit" does not exist. Installing it now.
   WARNING: This chart is deprecated
   NAME: fluent-bit
   LAST DEPLOYED: Sat May 20 11:42:28 2023
   NAMESPACE: observability
   STATUS: deployed
   REVISION: 1
   NOTES:
   fluent-bit is now running.
   
   It will forward all container logs to the svc named fluentd on port: 24284
   ```
   Используем чарты bitnami:
   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update bitnami
   helm upgrade --install elasticsearch bitnami/elasticsearch --namespace observability
   helm upgrade --install kibana bitnami/kibana --namespace observability
   kubectl get pods -n observability -o wide
   ```
   Фокус не удался, на одну слабенькую ноду все не влезло:
   ```text
   NAME                           READY   STATUS    RESTARTS   AGE     IP              NODE                        NOMINATED NODE   READINESS GATES
   elasticsearch-coordinating-0   0/1     Running   0          3m26s   10.112.131.21   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
   elasticsearch-coordinating-1   0/1     Running   0          3m26s   10.112.131.23   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
   elasticsearch-data-0           0/1     Pending   0          3m26s   <none>          <none>                      <none>           <none>
   elasticsearch-data-1           0/1     Pending   0          3m26s   <none>          <none>                      <none>           <none>
   elasticsearch-ingest-0         0/1     Running   0          3m26s   10.112.131.22   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
   elasticsearch-ingest-1         0/1     Running   0          3m26s   10.112.131.24   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
   elasticsearch-master-0         0/1     Running   0          3m26s   10.112.131.25   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
   elasticsearch-master-1         0/1     Running   0          3m26s   10.112.131.26   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
   fluent-bit-rmxsc               1/1     Running   0          7m4s    10.112.131.20   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
   ```
   Для начала, обратимся к файлу `values.yaml` в и найдем там ключ `tolerations`. Мы помним, что ноды из `infra-pool` имеют 
   `taint` `node-role=infra:NoSchedule`. Давайте разрешим ElasticSearch запускаться на данных нодах:
   ```yaml
   # elasticsearch.values.yaml
   master:
     tolerations:
       - key: node-role
         operator: Equal
         value: infra
         effect: NoSchedule
   
   data:
     tolerations:
       - key: node-role
         operator: Equal
         value: infra
         effect: NoSchedule
   
   coordinating:
     tolerations:
       - key: node-role
         operator: Equal
         value: infra
         effect: NoSchedule
   
   ingest:
     tolerations:
       - key: node-role
         operator: Equal
         value: infra
         effect: NoSchedule
   
   metrics:
     tolerations:
       - key: node-role
         operator: Equal
         value: infra
         effect: NoSchedule
   ```
   ```bash
   helm upgrade --install elasticsearch bitnami/elasticsearch --namespace observability -f elasticsearch.values.yaml
   ```
   ```text
   NAME                           READY   STATUS    RESTARTS       AGE     IP              NODE                        NOMINATED NODE   READINESS GATES
   elasticsearch-coordinating-0   0/1     Running   5 (66s ago)    14m     10.112.131.21   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
   elasticsearch-coordinating-1   0/1     Running   0              3m28s   10.112.133.3    cl1kqom3q3hvg5f1a1e4-ovel   <none>           <none>
   elasticsearch-data-0           0/1     Pending   0              14m     <none>          <none>                      <none>           <none>
   elasticsearch-data-1           0/1     Running   0              3m31s   10.112.134.3    cl1kqom3q3hvg5f1a1e4-orop   <none>           <none>
   elasticsearch-ingest-0         0/1     Running   5 (56s ago)    14m     10.112.131.22   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
   elasticsearch-ingest-1         0/1     Running   1 (17s ago)    3m28s   10.112.132.3    cl1kqom3q3hvg5f1a1e4-utak   <none>           <none>
   elasticsearch-master-0         0/1     Running   2 (3m3s ago)   14m     10.112.131.25   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
   elasticsearch-master-1         0/1     Running   3 (86s ago)    14m     10.112.131.26   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
   fluent-bit-rmxsc               1/1     Running   0              17m     10.112.131.20   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
   ```
   Теперь ElasticSearch может запускаться на нодах из `infra-pool`, но это не означает, что он должен это делать.
   Исправим этот момент и добавим в `elasticsearch.values.yaml` NodeSelector, определяющий, на каких нодах мы можем 
   запускать наши `pod`. Исправляем:
   ```yaml
   # elasticsearch.values.yaml
   
   master:
     nodeSelector:
       yandex.cloud/node-group-id: catjfbbimoh5ondn7i35
     tolerations: 
       - key: node-role
         operator: Equal
         value: infra
         effect: NoSchedule
   
   data:
     nodeSelector:
       yandex.cloud/node-group-id: catjfbbimoh5ondn7i35
     tolerations:
       - key: node-role
         operator: Equal
         value: infra
         effect: NoSchedule
   
   coordinating:
     nodeSelector:
       yandex.cloud/node-group-id: catjfbbimoh5ondn7i35
     tolerations:
       - key: node-role
         operator: Equal
         value: infra
         effect: NoSchedule
   
   ingest:
     nodeSelector:
       yandex.cloud/node-group-id: catjfbbimoh5ondn7i35
     tolerations:
       - key: node-role
         operator: Equal
         value: infra
         effect: NoSchedule
   
   metrics:
     nodeSelector:
       yandex.cloud/node-group-id: catjfbbimoh5ondn7i35
     tolerations:
       - key: node-role
         operator: Equal
         value: infra
         effect: NoSchedule
   ```
   ```bash
   helm uninstall elasticsearch --namespace observability
   helm upgrade --install elasticsearch bitnami/elasticsearch --namespace observability -f elasticsearch.values.yaml
   kubectl get pods -n observability -o wide
   ```
   ```text
   NAME                           READY   STATUS    RESTARTS        AGE     IP              NODE                        NOMINATED NODE   READINESS GATES
   elasticsearch-coordinating-0   1/1     Running   2 (3m35s ago)   8m19s   10.112.134.9    cl1kqom3q3hvg5f1a1e4-orop   <none>           <none>
   elasticsearch-coordinating-1   1/1     Running   2 (3m38s ago)   8m19s   10.112.133.8    cl1kqom3q3hvg5f1a1e4-ovel   <none>           <none>
   elasticsearch-data-0           1/1     Running   2 (3m3s ago)    8m19s   10.112.132.9    cl1kqom3q3hvg5f1a1e4-utak   <none>           <none>
   elasticsearch-data-1           1/1     Running   2 (3m7s ago)    8m19s   10.112.133.9    cl1kqom3q3hvg5f1a1e4-ovel   <none>           <none>
   elasticsearch-ingest-0         1/1     Running   2 (3m35s ago)   8m19s   10.112.134.8    cl1kqom3q3hvg5f1a1e4-orop   <none>           <none>
   elasticsearch-ingest-1         1/1     Running   2 (3m48s ago)   8m19s   10.112.132.8    cl1kqom3q3hvg5f1a1e4-utak   <none>           <none>
   elasticsearch-master-0         1/1     Running   2 (3m27s ago)   8m19s   10.112.134.10   cl1kqom3q3hvg5f1a1e4-orop   <none>           <none>
   elasticsearch-master-1         1/1     Running   1 (4m40s ago)   8m19s   10.112.134.11   cl1kqom3q3hvg5f1a1e4-orop   <none>           <none>
   fluent-bit-rmxsc               1/1     Running   0               41m     10.112.131.20   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
   ```
4. Установка nginx-ingress | Самостоятельное задание
   ```bash
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo update ingress-nginx
   kubectl create ns nginx-ingress
   helm upgrade --install nginx-ingress-release ingress-nginx/ingress-nginx --namespace=nginx-ingress --version="4.6.1" -f nginx-ingress.values.yaml
   kubectl get pods -n nginx-ingress -o wide
   ```
   ```text
   NAME                                                              READY   STATUS    RESTARTS   AGE   IP              NODE                        NOMINATED NODE   READINESS GATES
   nginx-ingress-release-ingress-nginx-controller-589c8579ff-bgb7j   1/1     Running   0          90s   10.112.134.12   cl1kqom3q3hvg5f1a1e4-orop   <none>           <none>
   nginx-ingress-release-ingress-nginx-controller-589c8579ff-pq4rw   1/1     Running   0          90s   10.112.134.13   cl1kqom3q3hvg5f1a1e4-orop   <none>           <none>
   nginx-ingress-release-ingress-nginx-controller-589c8579ff-z5fsz   1/1     Running   0          90s   10.112.133.10   cl1kqom3q3hvg5f1a1e4-ovel   <none>           <none>
   ```
5. Установка  EFK стека | Kibana

   По традиции создадим файл `kibana.values.yaml` в директории `kubernetes-logging` и добавим туда конфигурацию для 
создания ingress:
   ```yaml
   ingress:
     enabled: true
     ingressClassName: nginx
     path: /
     hostname: kibana.51.250.12.209.nip.io
   ```
   ```bash
   # Kibana
   helm upgrade --install kibana bitnami/kibana --namespace observability --set "elasticsearch.hosts[0]=elasticsearch,elasticsearch.port=9200" -f kibana.values.yaml
   ```
   Видим, что в ElasticSearch пока что не обнаружено никаких данных.
   Посмотрим в логи решения, которое отвечает за отправку логов (Fluent Bit) и увидим следующие строки:
   ```bash
   kubectl logs -n observability -l app=fluent-bit --tail 2
   ```
   ```text
   [2023/05/20 09:41:43] [error] [out_fw] no upstream connections available
   [2023/05/20 09:41:43] [ warn] [engine] failed to flush chunk '1-1684572156.469587566.flb', retry in 782 seconds: task_id=7, input=tail.0 > output=forward.0
   ```

6. Установка  EFK стека | Fluent Bit
   ```yaml
   config:
     outputs: |
       [OUTPUT]
           Name  es
           Match *
           Host  elasticsearch
           Port  9200
           Suppress_Type_Name On
           Replace_Dots    On
   
   tolerations:
     - key: node-role
       operator: Equal
       value: infra
       effect: NoSchedule
   ```
   Конфигурацию можно подсмотреть на https://docs.fluentbit.io/manual/pipeline/outputs/elasticsearch и stackoverflow.
   Запускаем:
   ```bash
   helm upgrade --install fluent-bit fluent/fluent-bit --namespace observability -f fluentbit.values.yaml
   kubectl get pod -n observability -l app.kubernetes.io/instance=fluent-bit -o wide
   ```
   Fluent-bit развёрнут на всех нодах.
   ```text
   NAME               READY   STATUS    RESTARTS   AGE   IP              NODE                        NOMINATED NODE   READINESS GATES
   fluent-bit-bbqmg   1/1     Running   0          72s   10.112.134.16   cl1kqom3q3hvg5f1a1e4-orop   <none>           <none>
   fluent-bit-pjrx2   1/1     Running   0          76s   10.112.133.13   cl1kqom3q3hvg5f1a1e4-ovel   <none>           <none>
   fluent-bit-shb2r   1/1     Running   0          87s   10.112.131.37   cl1h5eo9kgaqk16p4vtp-eloc   <none>           <none>
   fluent-bit-zvnxg   1/1     Running   0          82s   10.112.132.12   cl1kqom3q3hvg5f1a1e4-utak   <none>           <none>
   ```
   Попробуем повторно создать `index pattern`. В этот раз ситуация изменилась, и какие-то индексы в ElasticSearch уже есть.
7. Мониторинг ElasticSearch
   + Установим `prometheus-operator` и `exporter` в namespace `observability`
   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm upgrade --install prometheus-operator prometheus-community/kube-prometheus-stack -n observability -f prometheus.values.yaml
   helm upgrade --install elasticsearch-exporter prometheus-community/prometheus-elasticsearch-exporter \
     --set es.uri=http://elasticsearch:9200 \
     --set serviceMonitor.enabled=true \
     --namespace=observability
   ```
   + Prometheus и Grafana доступны по следующим адресам:
     + http://prometheus.51.250.12.209.nip.io
     + http://grafana.51.250.12.209.nip.io
     + Импортировал в Grafana один из популярных Dashboard для ElasticSearch exporter, содержащий визуализацию основных 
     собираемых метрик.
        + http://grafana.51.250.12.209.nip.io/d/f6ff9008-b163-4611-86c3-5ada5edaa236/elasticsearch?orgId=1&refresh=1m
     + применил drain на одной из нод и посмотрел изменение параметров на дашборде
8. EFK | nginx ingress
   + Добавим раздел `config` в `nginx-ingress.values.yaml` чтобы логи ingress-nginx попадали в Kibana.
   + Сделаем редеплой.
      ```bash
      helm upgrade --install nginx-ingress-release ingress-nginx/ingress-nginx --namespace=nginx-ingress --version="4.6.1" -f nginx-ingress.values.yaml
      ```
   + Создадим визуализации и рабочий стол.
   + Экспортируем получившиеся визуализации и рабочий стол в файл [export.ndjson](export.ndjson)

9. Loki
+ Установите Loki в namespace `observability`, используя любой способ. Должны быть установлены непосредственно Loki и 
Promtail
   ```bash
   helm repo add grafana https://grafana.github.io/helm-charts
   helm repo update grafana
   helm upgrade --install loki grafana/loki-distributed -n observability -f loki.values.yaml
   helm upgrade --install promtail grafana/promtail -n observability -f promtail.values.yaml
   ```
+ Модифицируйте конфигурацию `prometheus-operator` таким образом, чтобы datasource Loki создавался сразу после 
установки оператора
+ Итоговый файл prometheus-operator.values.yaml выложите в репозиторий в директорию kubernetes-logging
+ Loki доступен в графане, можно просматривать логи ingress-nginx
+ Добавил экспорт метрик в ingress-nginx, метрики доступны в прометеус
+ 

## Как запустить проект:
+ Клонировать репозиторий
+ Применить манифесты

## Как проверить работоспособность:
 - Перейти по ссылке http://localhost:8000

## PR checklist:
 - [x] Выставлен label с темой домашнего задания
