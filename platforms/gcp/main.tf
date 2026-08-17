# 1. Создаем изолированную виртуальную сеть (VPC)
resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false # Отключаем авто-создание подсетей для точного контроля CIDR
}

# 2. Создаем приватную подсеть для размещения всех нод кластера
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-nodes-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# 3. Настраиваем Firewall: разрешаем весь внутренний межнодовый трафик (Control Plane <-> Worker / Control Plane <-> Control Plane)
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

  # Ограничиваем правило только диапазоном нашей подсети
  source_ranges = [google_compute_subnetwork.subnet.ip_cidr_range]
}

# 4. Настраиваем Firewall: доступ из внешнего мира ТОЛЬКО через туннель Google IAP (Identity-Aware Proxy)
# Служебная подсеть GCP для IAP туннелирования: 35.235.240.0/20
resource "google_compute_firewall" "allow_iap" {
  name    = "${var.cluster_name}-allow-iap"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "50000"] # Port 50000 — порт Talos API для администрирования через talosctl
  }

  source_ranges = ["35.235.240.0/20"]
}