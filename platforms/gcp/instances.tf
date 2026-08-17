# 1. Ресурс для генерации схематики Talos OS
resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {}
  })
}

# 2. Запрос у Image Factory актуального URL для дискового образа Talos OS v1.13.8 под GCP
data "talos_image_factory_urls" "this" {
  schematic_id = talos_image_factory_schematic.this.id
  architecture = "amd64"
  platform     = "gcp"
}

# 3. Регистрация Compute Image в GCP из полученного .raw.tar.gz
resource "google_compute_image" "talos" {
  name        = "talos-img"
  description = "Образ Talos OS через Image Factory"

  raw_disk {
    source = data.talos_image_factory_urls.this.urls.disk_image
  }

  # Используем фичу GVNIC (Google Virtual NIC) для совместимости с GCP
  guest_os_features {
    type = "GVNIC"
  }
  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }
}

# 4. Создание 3 Control Plane нод в GCP
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
  }

  tags = ["control-plane", "talos-node"]

  metadata = {
    enable-oslogin = "FALSE"
  }
}