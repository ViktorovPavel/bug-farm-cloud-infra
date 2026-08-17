# Фиксируем минимальную версию Terraform и необходимые провайдеры
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    # Официальный провайдер Talos для автогенерации URL к образу из Image Factory
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.7"
    }
  }

  # Удаленный backend для хранения состояния инфраструктуры GCP.
  backend "gcs" {
    bucket = "bug-farm-tfstate-gcp" # Уникальное имя бакета в GCP
    prefix = "platforms/gcp"        # Путь к файлу состояния внутри бакета
  }
}

# Инициализация провайдера Google Cloud
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}