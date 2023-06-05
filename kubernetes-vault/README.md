# Выполнено ДЗ №11
## Домашнее задание. Устанавливаем и настраиваем Vault для нужд платформенной команды и команд разработки

 - [x] Основное ДЗ
 - [ ] Задание со *

## Обзор

+ Ветка для работы: kubernetes-vault
+ В ходе работы мы:
  + установим кластер vault в kubernetes
  + научимся создавать секреты и политики
  + настроим авторизацию в vault через kubernetes sa
  + сделаем под с контейнером nginx, в который прокинем секреты из vault через consul-template

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

2. Инсталляция hashicorp vault HA в k8s

+ "склонируем" репозиторий consul (необходимо минимум 3 ноды)
```bash
git clone https://github.com/hashicorp/consul-helm.git
helm install consul consul-helm
```
+ "склонируем" репозиторий vault
```bash
git clone https://github.com/hashicorp/vault-helm.git 
```
+ Отредактируем параметры установки в values.yaml
+ Установим vault (последняя версия не сможет достучаться до консула, откатился на предыдущую)
```bash
helm install vault vault-helm -f ./vault.values.yaml
helm status vault
kubectl logs vault-0
```
```text
NAME: vault
LAST DEPLOYED: Sun Jun  4 14:49:37 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://www.vaultproject.io/docs/


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get manifest vault
```
```text
==> Vault server configuration:

             Api Address: http://10.112.133.7:8200
                     Cgo: disabled
         Cluster Address: https://vault-0.vault-internal:8201
              Go Version: go1.19.2
              Listener 1: tcp (addr: "[::]:8200", cluster address: "[::]:8201", max_request_duration: "1m30s", max_request_size: "33554432", tls: "disabled")
               Log Level: info
                   Mlock: supported: true, enabled: false
           Recovery Mode: false
                 Storage: consul (HA available)
                 Version: Vault v1.12.1, built 2022-10-27T12:32:05Z
             Version Sha: e34f8a14fb7a88af4640b09f3ddbb5646b946d9c

==> Vault server started! Log data will stream in below:

2023-06-04T11:49:45.302Z [INFO]  proxy environment: http_proxy="" https_proxy="" no_proxy=""
2023-06-04T11:49:45.302Z [WARN]  storage.consul: appending trailing forward slash to path
2023-06-04T11:49:45.306Z [INFO]  core: Initializing version history cache for core
2023-06-04T11:49:53.459Z [INFO]  core: security barrier not initialized
2023-06-04T11:49:53.459Z [INFO]  core: seal configuration missing, not initialized
2023-06-04T11:49:58.451Z [INFO]  core: security barrier not initialized
2023-06-04T11:49:58.452Z [INFO]  core: seal configuration missing, not initialized
2023-06-04T11:50:03.454Z [INFO]  core: security barrier not initialized
2023-06-04T11:50:03.455Z [INFO]  core: seal configuration missing, not initialized
2023-06-04T11:50:08.464Z [INFO]  core: security barrier not initialized
2023-06-04T11:50:08.465Z [INFO]  core: seal configuration missing, not initialized
2023-06-04T11:50:13.459Z [INFO]  core: security barrier not initialized
2023-06-04T11:50:13.460Z [INFO]  core: seal configuration missing, not initialized
```
+ Инициализируем vault
```bash
kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1
```
```text
Unseal Key 1: KuLzWrBHFskFDUlh1f5/0ZSUBY/xBmZUOCzFl632uqo=

Initial Root Token: hvs.Pqhg5IUOYZ5vOVIZ2p9l0VN1

Vault initialized with 1 key shares and a key threshold of 1. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 1 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated root key. Without at least 1 keys to
reconstruct the root key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```
> -key-shares (int: 5) - Number of key shares to split the generated master key into. This is the number of "unseal keys" to generate. This is aliased as -n.

> -key-threshold (int: 3) - Number of key shares required to reconstruct the root key. This must be less than or equal to -key-shares. This is aliased as -t.
+ Проверим состояние vault'а
```bash
kubectl exec -it vault-0 -- vault status
```
```text
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       1
Threshold          1
Unseal Progress    0/1
Unseal Nonce       n/a
Version            1.12.1
Build Date         2022-10-27T12:32:05Z
Storage Type       consul
HA Enabled         true
command terminated with exit code 2
```
+ Распечатаем vault 
Проверим состояние vault'а
```bash
kubectl exec vault-0 -- env | grep VAULT_ADDR
```
```text
VAULT_ADDR=http://127.0.0.1:8200
```
```bash
kubectl exec -it vault-0 -- vault operator unseal 'KuLzWrBHFskFDUlh1f5/0ZSUBY/xBmZUOCzFl632uqo='
kubectl exec -it vault-1 -- vault operator unseal 'KuLzWrBHFskFDUlh1f5/0ZSUBY/xBmZUOCzFl632uqo='
kubectl exec -it vault-2 -- vault operator unseal 'KuLzWrBHFskFDUlh1f5/0ZSUBY/xBmZUOCzFl632uqo='
```
```text
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.12.1
Build Date      2022-10-27T12:32:05Z
Storage Type    consul
Cluster Name    vault-cluster-3a756625
Cluster ID      93ef2e4d-8e64-4670-7580-c61c2c6ce142
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active
Active Since    2023-06-04T12:02:49.20761133Z
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.12.1
Build Date             2022-10-27T12:32:05Z
Storage Type           consul
Cluster Name           vault-cluster-3a756625
Cluster ID             93ef2e4d-8e64-4670-7580-c61c2c6ce142
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.112.133.7:8200
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.12.1
Build Date             2022-10-27T12:32:05Z
Storage Type           consul
Cluster Name           vault-cluster-3a756625
Cluster ID             93ef2e4d-8e64-4670-7580-c61c2c6ce142
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.112.133.7:8200
```
Проверим состояние vault'а
```bash
kubectl exec -it vault-0 -- vault status
```
```text
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.12.1
Build Date      2022-10-27T12:32:05Z
Storage Type    consul
Cluster Name    vault-cluster-3a756625
Cluster ID      93ef2e4d-8e64-4670-7580-c61c2c6ce142
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active
Active Since    2023-06-04T12:02:49.20761133Z
```
+ Посмотрим список доступных авторизаций
```bash
kubectl exec -it vault-0 -- vault auth list
```
```text
Error listing enabled authentications: Error making API request.

URL: GET http://127.0.0.1:8200/v1/sys/auth
Code: 403. Errors:

* permission denied
command terminated with exit code 2
```
+ Залогинимся в vault (у нас есть root token)
```bash
kubectl exec -it vault-0 -- vault login
```
```text
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.Pqhg5IUOYZ5vOVIZ2p9l0VN1
token_accessor       lPrhseX8KHuvb2rPRPVRnNYy
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```
+ повторно запросим список авторизаций
```bash
kubectl exec -it vault-0 -- vault auth list
```
```text
Path      Type     Accessor               Description                Version
----      ----     --------               -----------                -------
token/    token    auth_token_2e092535    token based credentials    n/a
```
+ Заведем секреты
```bash
kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
kubectl exec -it vault-0 -- vault secrets list --detailed
kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault read otus/otus-ro/config
kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config
```
```text
Success! Enabled the kv secrets engine at: otus/
Path          Plugin       Accessor              Default TTL    Max TTL    Force No Cache    Replication    Seal Wrap    External Entropy Access    Options    Description                                                UUID                                    Version    Running Version          Running SHA256    Deprecation Status
----          ------       --------              -----------    -------    --------------    -----------    ---------    -----------------------    -------    -----------                                                ----                                    -------    ---------------          --------------    ------------------
cubbyhole/    cubbyhole    cubbyhole_b026b5b3    n/a            n/a        false             local          false        false                      map[]      per-token private secret storage                           6bd672ba-d33f-da22-064c-41ccba3eed0f    n/a        v1.12.1+builtin.vault    n/a               n/a
identity/     identity     identity_67e1535d     system         system     false             replicated     false        false                      map[]      identity store                                             a32d28f0-3426-4c8e-8db7-4d51e6f940a2    n/a        v1.12.1+builtin.vault    n/a               n/a
otus/         kv           kv_03628b16           system         system     false             replicated     false        false                      map[]      n/a                                                        ac60c895-d00a-dab7-f3a5-031e00c94c62    n/a        v0.13.0+builtin          n/a               supported
sys/          system       system_14bbd3bf       n/a            n/a        false             replicated     true         false                      map[]      system endpoints used for control, policy and debugging    c26bff5f-d228-78a7-e014-6c9c25c09885    n/a        v1.12.1+builtin.vault    n/a               n/a
Success! Data written to: otus/otus-ro/config
Success! Data written to: otus/otus-rw/config
Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus
```
+ Включим авторизацию черерз k8s
```bash
kubectl exec -it vault-0 -- vault auth enable kubernetes
kubectl exec -it vault-0 -- vault auth list
```
```text
Success! Enabled kubernetes auth method at: kubernetes/
Path           Type          Accessor                    Description                Version
----           ----          --------                    -----------                -------
kubernetes/    kubernetes    auth_kubernetes_ee49871e    n/a                        n/a
token/         token         auth_token_2e092535         token based credentials    n/a
```
+ Создадим yaml для ClusterRoleBinding
+ Создадим Service Account vault-auth и применим ClusterRoleBinding
```bash
# Create a service account, 'vault-auth'
kubectl create serviceaccount vault-auth
# Update the 'vault-auth' service account
kubectl apply --filename vault-auth-service-account.yml
```
```text
serviceaccount/vault-auth created
Warning: resource serviceaccounts/vault-auth is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
serviceaccount/vault-auth configured
clusterrolebinding.rbac.authorization.k8s.io/role-tokenreview-binding created
```
+ Создадим файл vault-auth-secret.yml
```bash
kubectl apply --filename vault-auth-secret.yml
```
+ Подготовим переменные для записи в конфиг кубер авторизации
```bash
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(more ~/.kube/config | grep server |awk '/http/ {print $NF}')
### alternative way
export K8S_HOST=$(kubectl cluster-info | grep ‘Kubernetes master’ | awk ‘/https/ {print $NF}’ | sed ’s/\x1b\[[0-9;]*m//g’ ) 
```
+ Запишем конфиг в vault
```bash
kubectl exec -it vault-0 -- vault write auth/kubernetes/config \
     token_reviewer_jwt="$SA_JWT_TOKEN" \
     kubernetes_host="$K8S_HOST" \
     kubernetes_ca_cert="$SA_CA_CRT" \
     issuer="https://kubernetes.default.svc.cluster.local"
```
```text
Success! Data written to: auth/kubernetes/config
```
+ Создадим файл политики
+ создадим политику и роль в vault (чтобы все оотработало правильно необходимо вручную скопировать политику на под)
```bash
kubectl cp otus-policy.hcl vault-0:./
kubectl exec -it vault-0 -- vault policy write otus-policy /otus-policy.hcl
kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
bound_service_account_names=vault-auth \
bound_service_account_namespaces=default policies=otus-policy ttl=24h
```
+ Проверим как работает авторизация
  + Создадим под с привязанным сервис аккоунтом и установим туда curl и jq
    ```bash
    kubectl run tmp --rm -i --tty --overrides='{ "spec": { "serviceAccount": "vault-auth" }  }' --image alpine:3.7
    ```
  + Залогинимся и получим клиентский токен
    ```bash
    VAULT_ADDR=http://vault:8200
    KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
    curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq
    ```
    ```json
    {
      "request_id": "77baa379-9397-de76-b7b8-51fc1a4304f4",
      "lease_id": "",
      "renewable": false,
      "lease_duration": 0,
      "data": null,
      "wrap_info": null,
      "warnings": null,
      "auth": {
        "client_token": "hvs.CAESIMGQhHxpjakX380C8tfET2TxWLxmYYyQEaPQ_yyvch5tGh4KHGh2cy5WekF5Zms4SmMwUGU1NnVLVkMwVjNTY04",
        "accessor": "GFixcHqlOSTEIarcYGT8nKNH",
        "policies": [
          "default",
          "otus-policy"
        ],
        "token_policies": [
          "default",
          "otus-policy"
        ],
        "metadata": {
          "role": "otus",
          "service_account_name": "vault-auth",
          "service_account_namespace": "default",
          "service_account_secret_name": "",
          "service_account_uid": "01384542-cfbd-49cc-bc14-a2368d4930d1"
        },
        "lease_duration": 86400,
        "renewable": true,
        "entity_id": "b8f786fb-2a50-fec6-52b5-b9126972b20c",
        "token_type": "service",
        "orphan": true,
        "mfa_requirement": null,
        "num_uses": 0
      }
    }
    ```
    ```bash
    TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')
    echo $TOKEN
    ```
    ```text
    hvs.CAESIIPK4nWLMr74MUrsIC4pZnwGmvDPYQRovI54gFxe4XLRGh4KHGh2cy5BcDB3VWV5OGRIcUNwcENiOFlpVXFOVlM
    ```
+ Прочитаем записанные ранее секреты и попробуем их обновить
  + проверим чтение
    ```bash
    curl --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-ro/config
    curl --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config
    ```
    ```json
    {"request_id":"f28e8cc3-2463-7985-479b-b48d140613f2","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"password":"asajkjkahs","username":"otus"},"wrap_info":null,"warnings":null,"auth":null}
    ```
    ```json
    {"request_id":"6ecf0d78-8499-99b9-3a85-99c40ce51c75","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"password":"asajkjkahs","username":"otus"},"wrap_info":null,"warnings":null,"auth":null}
    ```
  + проверим запись
    ```bash
    curl --request POST --data '{"bar": "baz"}' --header "X-VaultToken:$TOKEN" $VAULT_ADDR/v1/otus/otus-ro/config
    curl --request POST --data '{"bar": "baz"}' --header "X-VaultToken:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config
    curl --request POST --data '{"bar": "baz"}' --header "X-VaultToken:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config1 
    ```
    ```text
    {"errors":["permission denied"]}
    {"errors":["permission denied"]}
    {"errors":["permission denied"]}
    ```
  + добавляем права в `capabilities` для пути `otus/otus-rw/*` - "update", "delete"
+ Заберем репозиторий с примерами
  ```bash
  git clone https://github.com/hashicorp/vault-guides.git
  cd vault-guides/identity/vault-agent-k8s-demo 
  ```
+ Запускаем пример с откорректированным конфигом
  ```bash
  kubectl create -f ./configs-k8s/configmap.yaml 
  kubectl get configmap example-vault-agent-config -o yaml
  kubectl apply -f configs-k8s/example-k8s-spec.yaml
  ```
  + Проверка
    ```bash
    kubectl exec -ti vault-agent-example -c nginx-container  -- cat /usr/share/nginx/html/index.html
    ```
    ```text
    <html>
    <body>
    <p>Some secrets:</p>
    <ul>
    <li><pre>username: otus</pre></li>
    <li><pre>password: asajkjkahs</pre></li>
    </ul>
  
    </body>
    </html>
    ```
+ создадим CA на базе vault
  + Включим pki секретс
    ```bash
    kubectl exec -it vault-0 -- vault secrets enable pki
    kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
    kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal common_name="exmaple.ru" ttl=87600h > CA_cert.crt
    ```
    ```text
    Success! Enabled the pki secrets engine at: pki/
    Success! Tuned the secrets engine at: pki/
    ```
+ пропишем урлы для ca и отозванных сертификатов
  ```bash
  kubectl exec -it vault-0 -- vault write pki/config/urls issuing_certificates="http://vault:8200/v1/pki/ca" crl_distribution_points="http://vault:8200/v1/pki/crl"
  ```
  ```text
  Success! Data written to: pki/config/urls
  ```
+ создадим промежуточный сертификат
  ```bash
  kubectl exec -it vault-0 -- vault secrets enable --path=pki_int pki
  kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
  kubectl exec -it vault-0 -- vault write -format=json \
  pki_int/intermediate/generate/internal \
  common_name="example.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr
  ```
  ```text
  Success! Enabled the pki secrets engine at: pki_int/
  Success! Tuned the secrets engine at: pki_int/
  pki_int/intermediate/generate/internal \
  common_name="example.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr
  ```
+ пропишем промежуточный сертификат в vault
  ```bash
  kubectl cp pki_intermediate.csr vault-0:/tmp
  kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate \
  csr=@/tmp/pki_intermediate.csr \
  format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem
  kubectl cp intermediate.cert.pem vault-0:/tmp
  kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed \
  certificate=@/tmp/intermediate.cert.pem
  ```
  ```text
  WARNING! The following warnings were returned from Vault:
      
    * This mount hasn't configured any authority information access (AIA)
    fields; this may make it harder for systems to find missing certificates
    in the chain or to validate revocation status of certificates. Consider
    updating /config/urls or the newly generated issuer with this information.
      
  Key                 Value
  ---                 -----
  imported_issuers    [7eb2f4d5-6047-34df-dd01-e1b640f4fbb7 3a8ce361-4ef4-be4b-d943-8708f751d3f2]
  imported_keys       <nil>
  mapping             map[3a8ce361-4ef4-be4b-d943-8708f751d3f2: 7eb2f4d5-6047-34df-dd01-e1b640f4fbb7:bfbed0c7-9faf-d45b-60f1-075613642210]
  ```
+ Создадим и отзовем новые сертификаты
  + Создадим роль для выдачи сертификатов
  ```bash
  kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-ru \
  allowed_domains="example.ru" allow_subdomains=true max_ttl="720h"
  ```
  ```text
  Success! Data written to: pki_int/roles/example-dot-ru
  ```
    + Создадим и отзовем сертификат
  ```bash
  kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru \
  common_name="gitlab.example.ru" ttl="24h"
  ```
  ```text
  Key                 Value
  ---                 -----
  ca_chain            [-----BEGIN CERTIFICATE-----
  MIIDnDCCAoSgAwIBAgIURu0t+u1TAu1NbM5guSnfpRs3LLswDQYJKoZIhvcNAQEL
  BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMzA2MDQxMzIxMDhaFw0yODA2
  MDIxMzIxMzhaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
  dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAN+htYgtDtjL
  5l82e2B+aafZWIUOZWW5+O8D/uxalvTHdUTzYvrDxs2+7YMC4oHCQZBPNxUELwdZ
  f62bPrUT0cR3lPrR5FNiCQCyzYLWtfD+Mz7k4F9/LtUS00uWKX+w5rjzXm9J8+rK
  NEUBn88xUOlY7JYb9675Sp0t3vsMAW2iKCU9PTx+g/Ty0P4pFtUZx2Fw7Lc+PSr3
  7LpkzQ2+KYF/Bg4CdOEsuQJXutzJCRUtXSNprzCjktl44UPjZInbpwi5gkSX+eG4
  2FQQJbhbtMu4tPa4nEXMi1SSJEfhE58N+nufot7fQqwRlhet4bL8Jg1bZFSJ7bI4
  67QLZweAss8CAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
  AwEB/zAdBgNVHQ4EFgQU/v1pGtG1XIIEwuVMHD5xSTphOoYwHwYDVR0jBBgwFoAU
  kwfNTl6Dd6TVjswxcSjLtrgzQBUwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
  hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
  aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
  iXdQBZTVzdWfXeLaBL3APjDApNbbGbGRHvaY1Tle35Nx4a3ICmjz+PTdg0x+1ytY
  Xwji0JN/n+0iLs0dg3WBXUr3sramtGqli93l4+POmW6qknFdyRhxpzZMW0/Pfuot
  c6iW2gVpAWSW8m0Hon9GOb59IU3icU5hcfgwdE84v/H9mvmE7ZeG+EeoYug8YRQr
  uFvi+MxWcuvnYl29fMR37AdiWzfqwgTBeaQCjxfUkS5SVShkAIDtNUwQh99BGwEX
  WcqTgghP9kHycRplyXFb9ERlB23AJbTE8ugA8g0T6mYIJl+ZYF/K1yqI5eK29bUM
  FQWJTwx93yYVtPFO9iO+HA==
  -----END CERTIFICATE----- -----BEGIN CERTIFICATE-----
  MIIDMjCCAhqgAwIBAgIUdT9osoK83oJCdkJOMI2UUI/fvmgwDQYJKoZIhvcNAQEL
  BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMzA2MDQxMzE0MTdaFw0zMzA2
  MDExMzE0NDdaMBUxEzARBgNVBAMTCmV4bWFwbGUucnUwggEiMA0GCSqGSIb3DQEB
  AQUAA4IBDwAwggEKAoIBAQCflpb13Oq2xha38r0NGHNLUCzCeCMh1eLErt43Xj3M
  Zrey7p7eEb6fmw7kmPz7sr/sYDj8FuPLCTCGxnrs0hToYtBynuSKiYzgpFYLsrS5
  HJIY11gijTgAW6IvK+YaSExBDxYeAdL2BZf7Na8rJ/abYBUk+ZB/RFUPV98+PMuf
  sIGFZFtMtWD6LezriaOkS4UEcGUOprl+h05uSZkx4ScD0Bl34GgNWcN5OhLgbED2
  F19uWy5Z3HxSUfwWgHy9aNvZG857RT5+h1qfybRzZA5srVuGS6INblfF1sk+ktfh
  CFCxsw1ARLKqQsNu4smcZ7oS1YaDjYvmSKhWDXDIzhInAgMBAAGjejB4MA4GA1Ud
  DwEB/wQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBSTB81OXoN3pNWO
  zDFxKMu2uDNAFTAfBgNVHSMEGDAWgBSTB81OXoN3pNWOzDFxKMu2uDNAFTAVBgNV
  HREEDjAMggpleG1hcGxlLnJ1MA0GCSqGSIb3DQEBCwUAA4IBAQATW2UAtu5ZTcNq
  uVXFqsXDqFUiq8zuIwQaL0iYxkEg1AtqHLp+2u0KzC4X9GJPCJ1x6A/1C8JOy7CM
  8+RETNQXJxTjt1m3VP1X1qlotjnB2WRH8M+k9agGMu/36Id8kXA+X56g8HNmjgnX
  RVlYB5fTIXtWTa4saXxwYTqrEcbbYakTLcrs2JuVhU58HutbycW5A8rmVSnZjaJp
  o3uDWHiJMe9CIwBK8/lX8gaMrKKxsfRIDSZGPiAPTN9TnapJQdt+icbTMox0x+Je
  dYKr52xnxpu/Q95OI8eEPh4xKiZe454ziLmXFxiqxqi/hQ8wC4rqgsRVYs6Birzo
  OpJlCqH9
  -----END CERTIFICATE-----]
  certificate         -----BEGIN CERTIFICATE-----
  MIIDZzCCAk+gAwIBAgIUA5FHXLBl/6RGD0lKBe6mTL+FFxowDQYJKoZIhvcNAQEL
  BQAwLDEqMCgGA1UEAxMhZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgQXV0aG9yaXR5
  MB4XDTIzMDYwNDEzMjM1OFoXDTIzMDYwNTEzMjQyOFowHDEaMBgGA1UEAxMRZ2l0
  bGFiLmV4YW1wbGUucnUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC5
  TB8D9dhHzhQgVIfNltmhgi9mICCOrs1thPXsmFhMvaJS4i1ed4mQmjtSXnh/kfdE
  LmMX8Vfr3lvdw89vi4gHIFj0PM6hyf4QnUN95kVCcDayOQBXcqoFOQBuhSe6A/0k
  jN+gQfvI9/I6JCR19fP1NwwhZx2hrf/aRqg3kkVqhSPgS14kCcRnDGGWYScSMjee
  BSdSyvdL1aldzK1m7FE+C6SHmSwdnmiti07ry9xoTmfBEZXDcvFRdfXhSBUbdnzV
  ciBRK6lWNqwoRTNnsWLPPfxaQUUs+SypmAn1hRax+lLu6jtGGv5Q8lync/Nppu/c
  hX4YO4DT26WtrEhHNJj5AgMBAAGjgZAwgY0wDgYDVR0PAQH/BAQDAgOoMB0GA1Ud
  JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNVHQ4EFgQU/NuingXd6+Q/Vocd
  +Auh0rUONDUwHwYDVR0jBBgwFoAU/v1pGtG1XIIEwuVMHD5xSTphOoYwHAYDVR0R
  BBUwE4IRZ2l0bGFiLmV4YW1wbGUucnUwDQYJKoZIhvcNAQELBQADggEBAIIrrWtl
  ijC0hyhZFSSktpgFnxsL3mn05omSI/pvBMPhf9UpL2REigDktMcMDqcNCUP7hw3g
  S65wk2HB3VpQJ3PFWxmR6VBY49rHgdG3vHUnvCrSLyjSyVaRXoQCtagv6RIrH3My
  EHE8++Wd4IteK2vx9z9MGmesX8SHzTWxSz9I3HCOcwPr8FbLQKltbAlzhDqKswFR
  PzKvBZx05GIpRiSjw3F/+Ha8sDWzVoa4aQW6xak574myQeD8niGztB/C4QVtWzaD
  X/u+/BWJUnt+1QIqDQmnDetzgG4ObL07K4QV5IBCtkyW6oI439HZRzKduFtaU6h3
  3HC5jM3th4/I8Rg=
  -----END CERTIFICATE-----
  expiration          1685971468
  issuing_ca          -----BEGIN CERTIFICATE-----
  MIIDnDCCAoSgAwIBAgIURu0t+u1TAu1NbM5guSnfpRs3LLswDQYJKoZIhvcNAQEL
  BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMzA2MDQxMzIxMDhaFw0yODA2
  MDIxMzIxMzhaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
  dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAN+htYgtDtjL
  5l82e2B+aafZWIUOZWW5+O8D/uxalvTHdUTzYvrDxs2+7YMC4oHCQZBPNxUELwdZ
  f62bPrUT0cR3lPrR5FNiCQCyzYLWtfD+Mz7k4F9/LtUS00uWKX+w5rjzXm9J8+rK
  NEUBn88xUOlY7JYb9675Sp0t3vsMAW2iKCU9PTx+g/Ty0P4pFtUZx2Fw7Lc+PSr3
  7LpkzQ2+KYF/Bg4CdOEsuQJXutzJCRUtXSNprzCjktl44UPjZInbpwi5gkSX+eG4
  2FQQJbhbtMu4tPa4nEXMi1SSJEfhE58N+nufot7fQqwRlhet4bL8Jg1bZFSJ7bI4
  67QLZweAss8CAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
  AwEB/zAdBgNVHQ4EFgQU/v1pGtG1XIIEwuVMHD5xSTphOoYwHwYDVR0jBBgwFoAU
  kwfNTl6Dd6TVjswxcSjLtrgzQBUwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
  hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
  aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
  iXdQBZTVzdWfXeLaBL3APjDApNbbGbGRHvaY1Tle35Nx4a3ICmjz+PTdg0x+1ytY
  Xwji0JN/n+0iLs0dg3WBXUr3sramtGqli93l4+POmW6qknFdyRhxpzZMW0/Pfuot
  c6iW2gVpAWSW8m0Hon9GOb59IU3icU5hcfgwdE84v/H9mvmE7ZeG+EeoYug8YRQr
  uFvi+MxWcuvnYl29fMR37AdiWzfqwgTBeaQCjxfUkS5SVShkAIDtNUwQh99BGwEX
  WcqTgghP9kHycRplyXFb9ERlB23AJbTE8ugA8g0T6mYIJl+ZYF/K1yqI5eK29bUM
  FQWJTwx93yYVtPFO9iO+HA==
  -----END CERTIFICATE-----
  private_key         -----BEGIN RSA PRIVATE KEY-----
  MIIEowIBAAKCAQEAuUwfA/XYR84UIFSHzZbZoYIvZiAgjq7NbYT17JhYTL2iUuIt
  XneJkJo7Ul54f5H3RC5jF/FX695b3cPPb4uIByBY9DzOocn+EJ1DfeZFQnA2sjkA
  V3KqBTkAboUnugP9JIzfoEH7yPfyOiQkdfXz9TcMIWcdoa3/2kaoN5JFaoUj4Ete
  JAnEZwxhlmEnEjI3ngUnUsr3S9WpXcytZuxRPgukh5ksHZ5orYtO68vcaE5nwRGV
  w3LxUXX14UgVG3Z81XIgUSupVjasKEUzZ7Fizz38WkFFLPksqZgJ9YUWsfpS7uo7
  Rhr+UPJcp3Pzaabv3IV+GDuA09ulraxIRzSY+QIDAQABAoIBAQCRcsoJvsmVm5K6
  yf+LhnSwTVNNc7x6o4XHCQ5NOExfeJ9ZNgbs1yIZaqdUAanOYVJZp5vLKHuePv2X
  duN2KG2PQnnwxWZhIwAWJIvc4IrPGuwkO5AkFHKXBOZs2oKThhwHu7ixv/mXB+GQ
  d9xS58wmWJ5h/eIJjl5+BOZ4MI3ijOfXVMfiW55pEgGO8TgANEskd5mWfNzYTugj
  elOO2j5k0kqSIFX43u8XDxBSvsdnJzyec/wVw1KOSheANBXVKL44Boj37dqdcrRT
  hzAhFpJS8dEZSvXgTuPGaVu7GpadTLddfta9UshwQbAqLfucd8ibruj4HSigoF0I
  EsBhU5vtAoGBANTWhHvLYi9eASLrYml72PDV6sNgKXNI0UccETXXB3HEZuK8hGm+
  A73fn9FoZAXLDue4z/ZEL5dTWlEeRKTXpb4SgsD1ZNiJMUHxav3Va9Et7a3XCiqG
  LuaNRUXN5ucuTlm82ZBZVEa5jCkBjB5lWj1qeBzBIbyLoivmvpu3p/3LAoGBAN7f
  1TXI3Ayf0jy6OAyCtyd59xj/gKjyFW+G4HYWk2iKETSRBGLwuxk13aOdCdf88hay
  36Fjr9rfdImp9ZvmzdEx9FGtFivY5KlWqKqGYTNesvuvY+pjpR1kc0f8nEVmqa0O
  TcbG43EnzucY2CcOIECrDdwVI1j49fPvYzGsb+vLAoGAJemYa9zMvpdGKIw5WYTg
  HfZc/TRx7cE41ivfvPFyuAc+NIFULOnWDMp603h+6LFFFG3NTZbTy2bjnbOAksR/
  F56AgBK2RgQaLB7u6gxMSlSeE+tMOkrwq8zaXBbTXLbY6g9Dyfy/kGGY3+0QopF3
  Q51li+mzMrzExIEzztUmLYUCgYBada8sLWJjHVtPmqW1Ljj4pOBOHSYzbE6W/b+N
  LoyWGbPyCgolvl+yU9Kp3ctpBxmbbO6nqrZtt9StK3as2HkhN41auU4ObfIhaTL8
  Q56gIweyb/W15MvXqjXAOh+Ta5/ixbN7wq3995Ja6hKRh4I/vS3a7hlyu1nYsIkq
  WDr1EQKBgHoWgu+1+utmEp9j/s2NzYedPiTVy/HWPEg2eoIdBzlrEEkShgrWaHgu
  ExvrWHgQmHqODd8AQ1IBg8cs59TUBdlHW37jJvi/INPRNmGV3U00dHrGDp8OMKz4
  bpTpprgNpRjDQb+u8xai77lHigrU2xqjWut13MS/zm1OqgxcyK7X
  -----END RSA PRIVATE KEY-----
  private_key_type    rsa
  serial_number       03:91:47:5c:b0:65:ff:a4:46:0f:49:4a:05:ee:a6:4c:bf:85:17:1a
  ```
  ```bash
  kubectl exec -it vault-0 -- vault write pki_int/revoke \
  serial_number="03:91:47:5c:b0:65:ff:a4:46:0f:49:4a:05:ee:a6:4c:bf:85:17:1a"
  ```
  ```text
  Key                        Value
  ---                        -----
  revocation_time            1685885129
  revocation_time_rfc3339    2023-06-04T13:25:29.156247169Z
  ```

## PR checklist:
 - [x] Выставлен label с темой домашнего задания
