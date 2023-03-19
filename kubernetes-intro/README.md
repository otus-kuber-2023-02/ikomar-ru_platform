# Выполнено ДЗ №1

 - [x] Основное ДЗ
 - [x] Задание со *

## В процессе сделано:
 - Основное задание:
   - Изучены способы контроля контейнеров
   - Собран образ с nginx
   - Написан манифест для запуска собранного образа web-pod.yaml
   - Вопрос. Почему все pod в namespace kube-system восстановились после удаления?
   
        `kubectl describe deployments coredns -n kube-system` - coredns это деплоймент с 2 репликами ReplicaSet. ReplicaSet
        автоматически поддерживает указанное число реплик.

        Остальные поды контролируются через DaemonSet. DaemonSet автоматически поддерживает экземпляр пода на каждой ноде.
 - Дополнительное задание:
   - Написан манифест для запуска собранного образа frontend-pod-healthy.yaml
   - Вопрос. Почему не поднимается под?
   
     Под не запускался из-за отсутствия необходимых переменных среды.

## Как запустить проект:
+ Клонировать репозиторий
+ Применить манифесты:

```bash
kubectl apply -f ./kubernetes-intro/web-pod.yaml
kubectl apply -f ./kubernetes-intro/frontend-pod-healthy.yaml
```

## Как проверить работоспособность:
 - Перейти по ссылке http://localhost:8000

## PR checklist:
 - [x] Выставлен label с темой домашнего задания