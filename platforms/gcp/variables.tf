# Идентификатор проекта в Google Cloud
variable "project_id" {
  type        = string
  description = "Идентификатор проекта в Google Cloud (Project ID)"
}

# Основной регион размещения ресурсов
variable "region" {
  type        = string
  default     = "europe-west3" # Франкфурт — оптимально по задержкам
  description = "Регион размещения ресурсов GCP"
}

# Зона доступности по умолчанию
variable "zone" {
  type        = string
  default     = "europe-west3-a"
  description = "Зона доступности внутри выбранного региона"
}

# Список зон для отказоустойчивого размещения Control Plane нод
variable "zones" {
  type        = list(string)
  default     = ["europe-west3-a", "europe-west3-b", "europe-west3-c"]
  description = "Список зон для размещения Control Plane нод"
}

# Префикс для наименования ресурсов
variable "cluster_name" {
  type        = string
  default     = "bug-farm-gcp"
  description = "Имя кластера и префикс для всех создаваемых ресурсов"
}