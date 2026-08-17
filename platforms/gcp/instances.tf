# 1. Генерация схематики Talos (с системным расширением для GCP)
resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = [
          "siderolabs/gcp-guest-agent"
        ]
      }
    }
  })
}

# 2. Запрос у Image Factory актуального URL для дискового образа Talos OS v1.13.8 под GCP
data "talos_image_factory_urls" "this" {
  talos_version = "v1.13.8"
  schematic_id  = talos_image_factory_schematic.this.id
  architecture  = "amd64"
  platform      = "gcp"
}

# 3. Регистрация Compute Image в GCP из полученного .raw.tar.gz
resource "google_compute_image" "talos" {
  name        = "talos-v1-13-8"
  description = "Образ Talos OS v1.13.8 через Image Factory"

  raw_disk {
    source = data.talos_image_factory_urls.this.urls.disk_image
  }

  guest_os_features {
    type = "VIRTIO_NET"
  }
}

# 4. Создание 3 Control Plane нод без балансировщика для экономии бюджета
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