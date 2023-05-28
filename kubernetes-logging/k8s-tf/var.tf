variable "cluster_name" {
  description = "Имя кластера k8s"
  default     = "k8s-otus"
}
variable "network_id" {
  description = "Облачная сеть (используем default)"
  default     = "enp02k4ifo4p5ndu0d15"
}
variable "k8s_version" {
  description = "Версия Kubernetes"
  default     = "1.24"
}
variable "zone" {
  description = "Зона доступности"
  default = "ru-central1-b"
}
variable "subnet_id" {
  description = "Подсеть (используем default-ru-central1-b)"
  default = "e2l3a8ho8nun654f6bee"
}
variable "service_account_id" {
  description = "Сервисный аккаунт для ресурсов"
  default     = "ajebdf109kiq85a9v9ks"
}
variable "node_service_account_id" {
  description = "Сервисный аккаунт для узлов"
  default     = "ajejqfkrfmbo16one8mf"
}


variable "cloud_id" {
  description = "Cloud"
  default     = "b1g7vl9ofg6pq269b87f"
}
variable "folder_id" {
  description = "Folder"
  default     = "b1g4eqcgv9u4pfhp54tt"
}
variable "platform_id" {
  description = "платформа для узлов"
  # https://cloud.yandex.ru/docs/compute/concepts/vm-platforms
  default     = "standard-v2"
}
variable "cores" {
  description = "vCPU"
  default     = 2
}
variable "memory" {
  description = "RAM"
  default     = 4
}
variable "disk_type" {
  description = "Тип диска"
  default     = "network-hdd"
}
variable "disk" {
  description = "Размер диска"
  default     = 64
}
variable "public_key_path" {
  description = "SSH-ключ"
  default     = "test.pub"
}
variable "core_fraction" {
  description = "Гарантированная доля vCPU"
  default     = 5
}
variable "count_of_workers" {
  description = "Кол-во узлов"
  default     = 1
}
