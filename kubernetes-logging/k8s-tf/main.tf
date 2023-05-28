# https://terraform-eap.website.yandexcloud.net/docs/providers/yandex/index.html

resource "yandex_kubernetes_cluster" "k8s-cluster" {
  name       = var.cluster_name
  network_id = var.network_id

  master {
    version = var.k8s_version
    zonal {
      zone      = var.zone
      subnet_id = var.subnet_id
    }
    public_ip = true
  }

  service_account_id      = var.service_account_id
  node_service_account_id = var.service_account_id

  release_channel         = "RAPID"
  network_policy_provider = "CALICO"
}

resource "yandex_kubernetes_node_group" "default-pool" {
  cluster_id = yandex_kubernetes_cluster.k8s-cluster.id
  version    = var.k8s_version
  name       = "default-pool"

  instance_template {
    platform_id = var.platform_id
    network_interface {
      # публичный адрес
      nat        = true
      subnet_ids = [var.subnet_id]
    }
    scheduling_policy {
      # прерываемая ВМ
      preemptible = true
    }
    resources {
      cores  = var.cores
      memory = var.memory
      core_fraction = var.core_fraction
    }

    boot_disk {
      type = var.disk_type
      size = var.disk
    }

    container_runtime {
      type = "containerd"
    }

    metadata = {
      ssh-keys = "appuser:${file(var.public_key_path)}"
    }
  }
  scale_policy {
    fixed_scale {
      size = 1
    }
  }
  maintenance_policy {
    auto_upgrade = true
    maintenance_window {
      day        = "saturday"
      start_time = "01:00"
      duration = "1h"
    }
    auto_repair = true
  }
  deploy_policy {
    max_expansion   = 2
    max_unavailable = 0
  }

}

resource "yandex_kubernetes_node_group" "infra-pool" {
  cluster_id = yandex_kubernetes_cluster.k8s-cluster.id
  version    = var.k8s_version
  name       = "infra-pool"
  node_taints = ["node-role=infra:NoSchedule"]

  instance_template {
    platform_id = var.platform_id
    network_interface {
      # публичный адрес
      nat        = true
      subnet_ids = [var.subnet_id]
    }
    scheduling_policy {
      # прерываемая ВМ
      preemptible = true
    }
    resources {
      cores  = var.cores
      memory = var.memory
      core_fraction = var.core_fraction
    }

    boot_disk {
      type = var.disk_type
      size = var.disk
    }

    container_runtime {
      type = "containerd"
    }

    metadata = {
      ssh-keys = "appuser:${file(var.public_key_path)}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3  # var.count_of_workers
    }
  }

  provisioner "local-exec" {
    command = "yc managed-kubernetes cluster get-credentials $CLUSTER_NAME --external --force --folder-id $FOLDER_ID"
    environment = {
      CLUSTER_NAME = var.cluster_name
      FOLDER_ID    =  var.folder_id
    }
  }
}


