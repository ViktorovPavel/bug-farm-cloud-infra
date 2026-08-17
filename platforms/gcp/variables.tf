# Идентификатор проекта в GCP (обязательный параметр без дефолта)
variable "project_id" {
  type        = string
  description = "Идентификатор проекта в Google Cloud (Project ID)"
}

# Регион размещения всех основных сетевых ресурсов и нод
variable "region" {
  type        = string
  default     = "europe-west3" # Франкфурт — минимальная задержка до Восточной Европы
  description = "Регион размещения ресурсов GCP"
}

# Основная зона доступности по умолчанию
variable "zone" {
  type        = string
  default     = "europe-west3-a"
  description = "Основная зона доступности внутри выбранного региона"
}

# Список зон для равномерного распределения Control Plane нод по дата-центрам
variable "zones" {
  type        = list(string)
  default     = ["europe-west3-a", "europe-west3-b", "europe-west3-c"]
  description = "Список зон для отказоустойчивого размещения Control Plane"
}

# Общий префикс для именования ресурсов кластера
variable "cluster_name" {
  type        = string
  default     = "bug-farm-gcp"
  description = "Имя кластера и префикс для всех создаваемых ресурсов"
}