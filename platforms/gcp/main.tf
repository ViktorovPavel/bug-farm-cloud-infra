# Инициализация провайдера Google Cloud
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# 1. Создаем приватное виртуальное облако (VPC)
resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false # Явный контроль за сетевыми диапазонами
}

# 2. Создаем подсеть для размещения нод Talos Linux
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-nodes-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# 3. Файрвол: Разрешаем весь внутренний трафик между нодами кластера
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.cluster_name}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }

  # Разрешаем трафик только внутри нашей подсеть 10.10.0.0/24
  source_ranges = [google_compute_subnetwork.subnet.ip_cidr_range]
}

# 4. Файрвол: Разрешаем доступ через Google IAP (Identity-Aware Proxy)
# Диапазон 35.235.240.0/20 зарезервирован Google для туннелирования
resource "google_compute_firewall" "allow_iap" {
  name    = "${var.cluster_name}-allow-iap"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "50000"] # 50000 - порт Talos API (talosctl)
  }

  # Источник — только проверенные прокси-серверы Google IAP
  source_ranges = ["35.235.240.0/20"]
}