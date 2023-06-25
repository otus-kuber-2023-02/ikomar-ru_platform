# Выполнено ДЗ №9 
## Домашнее задание. GitOps и инструменты поставки

 - [x] Основное ДЗ
 - [ ] Задание со *

## В процессе сделано:

Выполнение задания:
1. Подготовка GitLab репозитория
   ```bash
   git clone https://github.com/GoogleCloudPlatform/microservices-demo
   cd microservices-demo
   git remote add origin https://gitlab.com/ikomar/microservices-demo.git
   git branch -M main
   git push -uf origin main
   ```
   
2. Создание Helm чартов
Скопировал готовые чарты из демонстрационного решения (директория `deploy/charts`)
   ```text
   ikomar@ikomar-server:~/microservices-demo$ tree -L 1 deploy/charts
   deploy/charts
   ├── adservice
   ├── cartservice
   ├── checkoutservice
   ├── currencyservice
   ├── emailservice
   ├── frontend
   ├── grafana-load-dashboards
   ├── loadgenerator
   ├── paymentservice
   ├── productcatalogservice
   ├── recommendationservice
   └── shippingservice
   ```

3. Подготовка k8s кластера в yandex-cloud
    ```bash
    yc managed-kubernetes cluster create k8s-otus \
    --network-id "enp02k4ifo4p5ndu0d15" \
    --zone "ru-central1-b" \
    --subnet-id "e2l3a8ho8nun654f6bee" \
    --public-ip \
    --release-channel REGULAR \
    --version 1.23 \
    --node-service-account-name k8s-node-group-pm1 \
    --service-account-id "ajebdf109kiq85a9v9ks" \
    --cloud-id "b1g7vl9ofg6pq269b87f" \
    --folder-id "b1g4eqcgv9u4pfhp54tt"
   
    yc managed-kubernetes node-group create node-1 \
    --cluster-name k8s-otus \
    --fixed-size 4 \
    --platform standard-v2 \
    --network-interface subnets=["e2l3a8ho8nun654f6bee"],ipv4-address="auto" \
    --core-fraction 50 \
    --preemptible \
    --memory 16 \
    --cores 4 \
    --disk-size 60 \
    --disk-type network-hdd \
    --version 1.23 \
    --cloud-id "b1g7vl9ofg6pq269b87f" \
    --folder-id "b1g4eqcgv9u4pfhp54tt"
   
    yc managed-kubernetes cluster get-credentials k8s-otus --external --force --folder-id b1g4eqcgv9u4pfhp54tt
    kubectl get nodes -o wide
    ```
   Получили следующую конфигурацию сервера:
   ```text
   NAME                        STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
   cl1q1frg52fq94embn5e-arev   Ready    <none>   6m37s   v1.23.6   10.129.0.31   158.160.72.171   Ubuntu 20.04.4 LTS   5.4.0-124-generic   containerd://1.6.7
   cl1q1frg52fq94embn5e-ijag   Ready    <none>   6m34s   v1.23.6   10.129.0.19   158.160.64.24    Ubuntu 20.04.4 LTS   5.4.0-124-generic   containerd://1.6.7
   cl1q1frg52fq94embn5e-umyw   Ready    <none>   6m35s   v1.23.6   10.129.0.10   158.160.72.174   Ubuntu 20.04.4 LTS   5.4.0-124-generic   containerd://1.6.7
   cl1q1frg52fq94embn5e-yzej   Ready    <none>   6m35s   v1.23.6   10.129.0.22   158.160.64.179   Ubuntu 20.04.4 LTS   5.4.0-124-generic   containerd://1.6.7
   ```
   Установка Istio (ставим через Helm):
   ```bash
   helm repo add istio https://istio-release.storage.googleapis.com/charts
   helm repo update istio
   kubectl create namespace istio-system
   helm install istio-base istio/base -n istio-system --version 1.17.2
   helm install istiod istio/istiod -n istio-system --wait --version 1.17.2
   kubectl create namespace istio-ingress
   kubectl label namespace istio-ingress istio-injection=enabled
   helm install istio-ingress istio/gateway -n istio-ingress --wait --version 1.17.2
   helm ls -n istio-system
   helm status istiod -n istio-system
   ```
   ```text
   NAME      	NAMESPACE   	REVISION	UPDATED                                	STATUS  	CHART        	APP VERSION
   istio-base	istio-system	1       	2023-06-03 14:56:38.917951142 +0300 MSK	deployed	base-1.17.2  	1.17.2     
   istiod    	istio-system	1       	2023-06-03 14:57:01.961725223 +0300 MSK	deployed	istiod-1.17.2	1.17.2 
   ```
   ```text
   NAME: istiod
   LAST DEPLOYED: Sat Jun  3 14:57:01 2023
   NAMESPACE: istio-system
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   "istiod" successfully installed!
   
   To learn more about the release, try:
     $ helm status istiod
     $ helm get all istiod
   
   Next steps:
     * Deploy a Gateway: https://istio.io/latest/docs/setup/additional-setup/gateway/
       * Try out our tasks to get started on common configurations:
         * https://istio.io/latest/docs/tasks/traffic-management
         * https://istio.io/latest/docs/tasks/security/
         * https://istio.io/latest/docs/tasks/policy-enforcement/
         * https://istio.io/latest/docs/tasks/policy-enforcement/
       * Review the list of actively supported releases, CVE publications and our hardening guide:
         * https://istio.io/latest/docs/releases/supported-releases/
         * https://istio.io/latest/news/security/
         * https://istio.io/latest/docs/ops/best-practices/security/
   
   For further documentation see https://istio.io website
   
   Tell us how your install/upgrade experience went at https://forms.gle/hMHGiwZHPU7UQRWe9
   ```
4. Continuous Integration: собраны образы для всех микросервисов
   ```text
   docker images
   REPOSITORY                                                       TAG       IMAGE ID       CREATED       SIZE
   cr.yandex/crpslghuie8p9triok1p/recommendationservice             0.0.1     c6a690cbe656   2 weeks ago   286MB
   cr.yandex/crpslghuie8p9triok1p/shippingservice                   0.0.1     e8ad239483c6   2 weeks ago   37.6MB
   cr.yandex/crpslghuie8p9triok1p/currencyservice                   0.0.1     7f78318b30e4   2 weeks ago   289MB
   cr.yandex/crpslghuie8p9triok1p/emailservice                      0.0.1     02c9d80b0698   2 weeks ago   288MB
   cr.yandex/crpslghuie8p9triok1p/checkoutservice                   0.0.1     46c68b1c01ab   2 weeks ago   38.9MB
   cr.yandex/crpslghuie8p9triok1p/paymentservice                    0.0.1     42b721a39ef6   2 weeks ago   285MB
   cr.yandex/crpslghuie8p9triok1p/productcatalogservice             0.0.1     9c7e52238432   2 weeks ago   39MB
   cr.yandex/crpslghuie8p9triok1p/loadgenerator                     0.0.1     8f3f132585c3   2 weeks ago   185MB
   cr.yandex/crpslghuie8p9triok1p/cartservice                       0.0.1     574542875c9f   2 weeks ago   48.1MB
   cr.yandex/crpslghuie8p9triok1p/frontend                          0.0.1     077b8f83d827   2 weeks ago   45.8MB
   cr.yandex/crpslghuie8p9triok1p/adservice                         0.0.1     2577602901db   2 weeks ago   248MB
   ```
5. GitOps Подготовка
Произведем установку Flux в кластер, в namespace flux
```bash
helm repo add fluxcd https://charts.fluxcd.io
helm repo update fluxcd
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/1.4.4/deploy/crds.yaml
kubectl create namespace flux
helm upgrade --install flux fluxcd/flux -f flux.values.yaml --namespace flux
```
```text
Release "flux" does not exist. Installing it now.
NAME: flux
LAST DEPLOYED: Wed Jun 14 20:19:56 2023
NAMESPACE: flux
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Get the Git deploy key by either (a) running

  kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2

or by (b) installing fluxctl through
https://fluxcd.io/legacy/flux/references/fluxctl/#installing-fluxctl
and running:

  fluxctl identity --k8s-fwd-ns flux

---

**Flux v1 is deprecated, please upgrade to v2 as soon as possible!**

New users of Flux can Get Started here:
https://fluxcd.io/docs/get-started/

Existing users can upgrade using the Migration Guide:
https://fluxcd.io/docs/migration/
```
Наконец, добавим в свой профиль GitLab публичный ssh-ключ, при помощи которого flux получит доступ к нашему git-репозиторию.
```bash
kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2
```
Установим Helm operator:
```bash
helm upgrade --install helm-operator fluxcd/helm-operator -f helm-operator.values.yaml --namespace flux
```
```text
NAME: helm-operator
LAST DEPLOYED: Wed Jun 14 20:23:09 2023
NAMESPACE: flux
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Flux Helm Operator docs https://fluxcd.io/legacy/helm-operator

Example:

AUTH_VALUES=$(cat <<-END
usePassword: true
password: "redis_pass"
usePasswordFile: true
END
)

kubectl create secret generic redis-auth --from-literal=values.yaml="$AUTH_VALUES"

cat <<EOF | kubectl apply -f -
apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: redis
  namespace: default
spec:
  releaseName: redis
  chart:
    repository: https://kubernetes-charts.storage.googleapis.com
    name: redis
    version: 10.5.7
  valuesFrom:
  - secretKeyRef:
      name: redis-auth
  values:
    master:
      persistence:
        enabled: false
    volumePermissions:
      enabled: true
    metrics:
      enabled: true
    cluster:
      enabled: false
EOF

watch kubectl get hr
```
Установим fluxctl на локальную машину для управления нашим CD инструментом.
```bash
curl -s https://fluxcd.io/install.sh | sudo bash
```
Пришло время проверить корректность работы Flux. Как мы уже знаем, Flux умеет автоматически синхронизировать состояние 
кластера и репозитория. Это касается не только сущностей HelmRelease , которыми мы будем оперировать для развертывания 
приложения, но и обыкновенных манифестов. Поместим манифест, описывающий namespace microservices-demo в директорию 
`deploy/namespaces` и сделаем push в GitLab:
```text
microservices-demo   Active   2m3s
ts=2023-06-14T17:48:32.959055641Z caller=sync.go:608 method=Sync cmd="kubectl apply -f -" took=288.419777ms err=null output="namespace/microservices-demo created"
```
В итоге поднял все сервисы и понял, что flux нельзя использовать никогда, если не хочется бесконечно разбираться в магии.
```text
NAME                   	NAMESPACE         	REVISION	UPDATED                                	STATUS  	CHART                        	APP VERSION
adservice              	microservices-demo	1       	2023-06-15 06:08:35.450034685 +0000 UTC	deployed	adservice-0.5.0              	1.16.0     
cartservice            	microservices-demo	1       	2023-06-15 06:08:39.365486885 +0000 UTC	deployed	cartservice-0.4.1            	1.16.0     
checkoutservice        	microservices-demo	1       	2023-06-15 06:08:33.261503545 +0000 UTC	deployed	checkoutservice-0.4.0        	1.16.0     
currencyservice        	microservices-demo	1       	2023-06-15 06:08:22.531198169 +0000 UTC	deployed	currencyservice-0.4.0        	1.16.0     
emailservice           	microservices-demo	1       	2023-06-15 06:08:33.868098282 +0000 UTC	deployed	emailservice-0.4.0           	1.16.0     
frontend	            microservices-demo	1       	2023-06-15 06:08:23.412874999 +0000 UTC	deployed	frontend-0.0.3	                1.16.0   
loadgenerator          	microservices-demo	1       	2023-06-15 06:08:23.777516978 +0000 UTC	deployed	loadgenerator-0.4.0          	1.16.0     
paymentservice         	microservices-demo	1       	2023-06-15 06:08:25.522889275 +0000 UTC	deployed	paymentservice-0.3.0         	1.16.0     
productcatalogservice  	microservices-demo	1       	2023-06-15 06:08:26.710935379 +0000 UTC	deployed	productcatalogservice-0.3.0  	1.16.0     
recommendationservice  	microservices-demo	1       	2023-06-15 06:08:27.796258786 +0000 UTC	deployed	recommendationservice-0.3.0  	1.16.0     
shippingservice        	microservices-demo	1       	2023-06-15 06:08:32.795861456 +0000 UTC	deployed	shippingservice-0.3.0        	1.16.0    

adservice                 adservice                 Succeeded      deployed        Release was successful for Helm release 'adservice' in 'microservices-demo'.                 69s
cartservice               cartservice               Succeeded      deployed        Release was successful for Helm release 'cartservice' in 'microservices-demo'.               69s
checkoutservice           checkoutservice           Succeeded      deployed        Release was successful for Helm release 'checkoutservice' in 'microservices-demo'.           69s
currencyservice           currencyservice           Succeeded      deployed        Release was successful for Helm release 'currencyservice' in 'microservices-demo'.           69s
emailservice              emailservice              Succeeded      deployed        Release was successful for Helm release 'emailservice' in 'microservices-demo'.              69s
frontend                  frontend                  Succeeded      deployed        Release was successful for Helm release 'frontend' in 'microservices-demo'.                  69s
loadgenerator             loadgenerator             Succeeded      deployed        Release was successful for Helm release 'loadgenerator' in 'microservices-demo'.             68s
paymentservice            paymentservice            Succeeded      deployed        Release was successful for Helm release 'paymentservice' in 'microservices-demo'.            68s
productcatalogservice     productcatalogservice     Succeeded      deployed        Release was successful for Helm release 'productcatalogservice' in 'microservices-demo'.     68s
recommendationservice     recommendationservice     Succeeded      deployed        Release was successful for Helm release 'recommendationservice' in 'microservices-demo'.     68s
shippingservice           shippingservice           Succeeded      deployed        Release was successful for Helm release 'shippingservice' in 'microservices-demo'.           68s
```

## Canary deployments с Flagger и Istio
### Flagger
```bash
helm repo add flagger https://flagger.app
helm repo update flagger
kubectl apply -f https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml
helm install prometheus -n istio-system prometheus-community/prometheus
helm upgrade --install flagger flagger/flagger \
--namespace=istio-system \
--set crd.create=false \
--set meshProvider=istio \
--set metricsServer=http://prometheus-server:80
```
### Istio | Sidecar Injection
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: microservices-demo
  labels:
    istio-injection: enabled
```
```text
istio-proxy:
    Container ID:  containerd://289607a79180ee25c5642ee69ba3d19e2bf7003894b9b09ad41e8b3cf207f607
    Image:         docker.io/istio/proxyv2:1.17.2
    Image ID:      docker.io/istio/proxyv2@sha256:f41745ee1183d3e70b10e82c727c772bee9ac3907fea328043332aaa90d7aa18
    Port:          15090/TCP
    Host Port:     0/TCP
    Args:
      proxy
      sidecar
      --domain
      $(POD_NAMESPACE).svc.cluster.local
      --proxyLogLevel=warning
      --proxyComponentLogLevel=misc:error
      --log_output_level=default:info
      --concurrency
      2
    State:          Running
      Started:      Thu, 15 Jun 2023 09:21:46 +0300
```
## Flagger | Canary
Перейдем непосредственно к настройке канареечных релизов. Добавим в Helm chart frontend еще один файл - canary.yaml 
В нем будем хранить описание стратегии, по которой необходимо обновлять данный микросервис.

Проверим, что Flagger инициализировал canary ресурс frontend:

```text
NAME       STATUS         WEIGHT   LASTTRANSITIONTIME
frontend   Initializing   0        2023-06-15T09:27:31
```

```text
NAME                                        READY   STATUS    RESTARTS   AGE
frontend-hipster-primary-597478d856-llvb6   2/2     Running   0          117s
```
```text
  Type     Reason  Age                 From     Message
  ----     ------  ----                ----     -------
  Warning  Synced  20m                 flagger  frontend-primary.microservices-demo not ready: waiting for rollout to finish: observed deployment generation less than desired generation
  Normal   Synced  20m (x2 over 20m)   flagger  all the metrics providers are available!
  Normal   Synced  20m                 flagger  Initialization done! frontend.microservices-demo
  Normal   Synced  17m                 flagger  Starting canary analysis for frontend.microservices-demo
  Warning  Synced  17m                 flagger  canary deployment frontend.microservices-demo not ready: waiting for rollout to finish: 1 old replicas are pending termination
  Normal   Synced  13m (x2 over 18m)   flagger  New revision detected! Scaling up frontend.microservices-demo
  Normal   Synced  12m (x2 over 17m)   flagger  Advance frontend.microservices-demo canary weight 10
  Normal   Synced  12m (x2 over 16m)   flagger  Advance frontend.microservices-demo canary weight 20
  Normal   Synced  11m (x2 over 16m)   flagger  Advance frontend.microservices-demo canary weight 30
  Normal   Synced  11m (x2 over 15m)   flagger  Advance frontend.microservices-demo canary weight 40
  Normal   Synced  10m (x2 over 15m)   flagger  Advance frontend.microservices-demo canary weight 50
  Normal   Synced  10m                 flagger  Copying frontend.microservices-demo template spec to frontend-primary.microservices-demo
  Normal   Synced  9m3s (x6 over 14m)  flagger  (combined from similar events): Promotion completed! Scaling down frontend.microservices-demo
```
```text
NAME       STATUS      WEIGHT   LASTTRANSITIONTIME
frontend   Succeeded   0        2023-06-15T09:30:19Z
```

## PR checklist:
 - [x] Выставлен label с темой домашнего задания
