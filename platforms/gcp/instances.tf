# Запрос у Image Factory актуального URL для дискового образа Talos OS v1.7.0 под GCP
data "talos_image_factory_urls" "this" {
  talos_version = "v1.7.0"
  architecture  = "amd64"
  platform      = "gcp"
}

# Регистрация Compute Image в GCP из полученного .raw.tar.gz
resource "google_compute_image" "talos" {
  name        = "talos-v1-7-0"
  description = "Образ Talos OS v1.7.0 через Image Factory"

  raw_disk {
    source = data.talos_image_factory_urls.this.urls.disk_image
  }

  guest_os_features {
    type = "VIRTIO_NET"
  }
}

# Создание 3 Control Plane ноды без балансировщика для экономии бюджета
resource "google_compute_instance" "control_plane" {
  count        = 3
  name         = "${var.cluster_name}-cp-${count.index + 1}"
  machine_type = "e2-standard-2"
  zone         = var.zones[count.index % length(var.zones)]

  boot_disk {
    initialize_params {
      image = google_compute_image.talos.id
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    # Без внешних IP-адресов ради безопасности
  }

  tags = ["control-plane", "talos-node"]

  metadata = {
    enable-oslogin = "FALSE"
  }
}