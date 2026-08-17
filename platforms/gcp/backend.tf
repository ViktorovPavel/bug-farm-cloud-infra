# Фиксируем минимальную версию Terraform и необходимые провайдеры
terraform {
  required_version = ">= 1.15.8"

  required_providers {
    # Официальный провайдер Google Cloud для управления ресурсами GCP
    google = {
      source  = "hashicorp/google"
      version = "~> 7.44.0"
    }
    # Провайдер Sidero Labs для генерации конфигураций и образов Talos OS
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.12.0"
    }
  }

  # Хранение состояния (tfstate) в бакете Google Cloud Storage
  backend "gcs" {
    bucket = "bug-farm-tf-state"
    prefix = "terraform/state"
  }
}

# Инициализируем провайдер Google с привязкой к проекту, региону и дефолтной зоне
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}