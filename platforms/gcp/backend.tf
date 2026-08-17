# Фиксируем минимальную версию Terraform и необходимые провайдеры
terraform {
  required_version = ">= 1.15.8"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.44.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.12.0"
    }
  }

  backend "gcs" {
    bucket = "bug-farm-tf-state"
    prefix = "terraform/state"
  }
}

# Инициализация провайдера Google Cloud
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}