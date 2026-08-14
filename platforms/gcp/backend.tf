# Фиксируем минимальную версию Terraform и необходимые провайдеры
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Удаленный backend для хранения состояния инфраструктуры GCP.
  # Этот бакет создается в GCP один раз вручную или отдельным скриптом.
  backend "gcs" {
    bucket = "bug-farm-tfstate-gcp" # Уникальное имя бакета в GCP
    prefix = "platforms/gcp"        # Путь к файлу состояния внутри бакета
  }
}