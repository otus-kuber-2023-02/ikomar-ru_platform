# Выполнено ДЗ №8

 - [x] Основное ДЗ
 - [] Задание со *

## В процессе сделано:
### Основное задание: 
Созданы манифесты в папке kubernetes-operator/deploy:
+ service-account.yml
+ role.yml
+ role-binding.yml
+ deploy-operator.yml
+ cr.yml
+ crd.yml

Вывод команды  `kubectl get jobs`:
```bash
ikomar@ikomar-server:~/ikomar-ru_platform$ kubectl get jobs 
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           20s        5m19s
restore-mysql-instance-job   1/1           63s        99s
```
Вывод приложения при запущенном MySQL:
```bash
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
```

## Как запустить проект:
+ Клонировать репозиторий
+ Применить манифесты

## Как проверить работоспособность:
 - Применить манифесты

## PR checklist:
 - [x] Выставлен label с темой домашнего задания
