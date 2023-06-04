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
   git remote add gitlab git@gitlab.com:ikomar/microservices-demo.git
   git remote remove origin
   git push gitlab main
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

3. Подготовка k8s кластера в yandex-cloud через terraform
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
   helm install istiod istio/istiod -n istio-system --wait
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
5. GitOps
Подготовка


## PR checklist:
 - [x] Выставлен label с темой домашнего задания
