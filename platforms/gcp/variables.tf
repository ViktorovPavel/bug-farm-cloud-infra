variable "project_id" {
  type        = string
  description = "Идентификатор проекта в Google Cloud (Project ID)"
}

variable "region" {
  type        = string
  default     = "europe-west3" # Франкфурт — оптимально по задержкам из Восточной Европы
  description = "Регион размещения ресурсов GCP"
}

variable "zone" {
  type        = string
  default     = "europe-west3-a"
  description = "Зона доступности внутри выбранного региона"
}

variable "cluster_name" {
  type        = string
  default     = "bug-farm-gcp"
  description = "Имя кластера и префикс для всех создаваемых ресурсов"
}