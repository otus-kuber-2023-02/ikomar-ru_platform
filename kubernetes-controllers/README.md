# Выполнено ДЗ №2

 - [x] Основное ДЗ
 - [x] Задание со *
 - [x] Задание с **

## В процессе сделано:
### Основное задание: 
- Написан манифест для ReplicaSet приложения frontend - `frontend-replicaset.yaml`, 
отработано обновление и масштабирование приложения
  - **вопрос**: _почему обновление ReplicaSet не повлекло обновление запущенных pod?_ Потому что контроллер ReplicaSet 
  управляет только количеством запущенных подов. Для обновления нужно либо удалить запущенные поды вручную, либо 
  пересоздать ReplicaSet 
- Написан манифест для ReplicaSet приложения paymentService - `paymentservice-replicaset.yaml`, собран и загружен 
dockerfile приложения paymentService
- Написан манифест для Deployment приложения paymentService - `paymentservice-deployment.yaml`, отработаны 
обновление и откат приложения
- Написан манифест для Deployment приложения frontend - `paymentservice-deployment.yaml`, отработаны добавление 
readinessProbe

### Дополнительное задание
- Написан манифест для Deployment приложения paymentService в режиме blue-green `paymentservice-deployment-bg.yaml`
- Написан манифест для Deployment приложения paymentService в режиме Reverse Rolling Update 
`paymentservice-deployment-reverse.yaml`
- Найден манифест для запуска DaemonSet с Node Exporter `nodeexporter-daemonset.yaml`
- Доработан манифест для запуска DaemonSet с Node мастер-нодах

## Как запустить проект:
+ Клонировать репозиторий
+ Применить манифесты:

```bash
kubectl apply -f ./kubernetes-controllers/frontend-deployment.yaml
kubectl apply -f ./kubernetes-controllers/frontend-replicaset.yaml
kubectl apply -f ./kubernetes-controllers/node-exporter-daemonset.yaml
kubectl apply -f ./kubernetes-controllers/paymentservice-deployment.yaml
kubectl apply -f ./kubernetes-controllers/paymentservice-deployment-bg.yaml
kubectl apply -f ./kubernetes-controllers/paymentservice-deployment-reverse.yaml
kubectl apply -f ./kubernetes-controllers/paymentservice-replicaset.yaml
```

## Как проверить работоспособность:
 - Перейти по ссылке http://localhost:8000

## PR checklist:
 - [x] Выставлен label с темой домашнего задания
