# Фиксируем минимальную версию Terraform и необходимые провайдеры
terraform {
  required_providers {
    # Официальный провайдер Google Cloud
    google = {
      source = "hashicorp/google"
    }
    # Провайдер Sidero Labs для генерации конфигураций и образов Talos OS
    talos = {
      source = "siderolabs/talos"
    }
  }

  # Удаленный backend для хранения состояния инфраструктуры GCP.
  # Возвращаем оригинальные имя бакета и префикс из GCP
  backend "gcs" {
    bucket = "bug-farm-tfstate-gcp" # Уникальное имя бакета в GCP
    prefix = "platforms/gcp"        # Путь к файлу состояния внутри бакета
  }
}

# Инициализируем провайдер Google с привязкой к проекту, региону и зоне
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}