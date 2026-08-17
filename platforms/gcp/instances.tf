# 1. Генерируем схему кастомизации дискового образа Talos
resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {}
  })
}

# 2. Запрашиваем у Sidero Image Factory прямой URL диска Talos v1.13.8 для GCP
data "talos_image_factory_urls" "this" {
  talos_version = "v1.13.8"
  schematic_id  = talos_image_factory_schematic.this.id
  architecture  = "amd64"
  platform      = "gcp"
}

# 3. Регистрируем Compute Image в проекте GCP из полученного архива
resource "google_compute_image" "talos" {
  name        = "talos-v1-13-8"
  description = "Официальный образ Talos OS v1.13.8 из Image Factory"

  raw_disk {
    source = data.talos_image_factory_urls.this.urls.disk_image
  }

  # Обязательные флаги совместимости GCP для Talos OS (используем GVNIC вместо устаревшего VIRTIO_NET)
  guest_os_features {
    type = "GVNIC"
  }
  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }
}

# 4. Разворачиваем 3 ноды Control Plane в разных зонах
resource "google_compute_instance" "control_plane" {
  count        = 3
  name         = "${var.cluster_name}-cp-${count.index + 1}"
  machine_type = "e2-standard-2"
  zone         = var.zones[count.index % length(var.zones)] # Равномерно распределяем ноды по зонам a, b, c

  boot_disk {
    initialize_params {
      image = google_compute_image.talos.id
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }

  tags = ["control-plane", "talos-node"]

  # Отключаем OS Login, так как у Talos OS нет SSH сервиса и обычных пользователей Linux
  metadata = {
    enable-oslogin = "FALSE"
  }
}