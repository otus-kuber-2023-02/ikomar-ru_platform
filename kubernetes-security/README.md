# Выполнено ДЗ №1

 - [x] Основное ДЗ
 - [ ] Задание со *

## В процессе сделано:
### Основное задание
#### Task01
+ Создан аккаунт bob
+ Связан аккаунт bob и default роль admin
+ Создан аккаунт dave без ролей
#### Task02
+ Создан namespace prometheus
+ Создан аккаунт carol
+ Создана роль pod-reader
+ Связана роль pod-reader со всеми аккаунтами в пространстве prometheus
#### Task03
+ Создан namespace dev
+ Создан аккаунт jane
+ Связан аккаунт jane и роль admin в пространстве dev
+ Создан аккаунт ken
+ Связан аккаунт ken и роль view в пространстве dev

## Как запустить проект:
+ Клонировать репозиторий
+ Применить манифесты:

```bash
kubectl apply -f kubernetes-security/task01/01-bob.yaml
kubectl apply -f kubernetes-security/task01/02-dave.yaml
kubectl apply -f kubernetes-security/task02/01-carol.yaml
kubectl apply -f kubernetes-security/task03/01-ns-dev.yaml
kubectl apply -f kubernetes-security/task03/02-jane.yaml
kubectl apply -f kubernetes-security/task03/03-ken.yaml
```

## PR checklist:
 - [x] Выставлен label с темой домашнего задания
