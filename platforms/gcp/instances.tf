# ============================================================
# 1. ГЕНЕРАЦИЯ СХЕМАТИКИ TALOS
# ============================================================
# Создаёт схематику для Image Factory — по сути, это "рецепт"
# сборки кастомного образа Talos. Пока пустой, но в будущем
# можно добавить системные модули (например, для RAID,
# дополнительных драйверов и т.д.)
resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {}
  })
}

# ============================================================
# 2. ПОЛУЧЕНИЕ URL ОБРАЗА ИЗ FACTORY
# ============================================================
# Запрашиваем у Image Factory актуальную ссылку на .raw.tar.gz
# для GCP. Версия берётся из переменной, что позволяет легко
# обновлять Talos.
data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version # Например, "v1.8.3"
  schematic_id  = talos_image_factory_schematic.this.id
  architecture  = "amd64"
  platform      = "gcp"
}

# ============================================================
# 3. БАКЕТ ДЛЯ ХРАНЕНИЯ ОБРАЗОВ
# ============================================================
# Создаём GCS-бакет, куда будем сохранять скачанный образ.
# Имя должно быть глобально уникальным.
resource "google_storage_bucket" "images" {
  name          = "bug-farm-talos-images-${var.project_id}" # Уникальность через project_id
  location      = var.region
  force_destroy = true # Разрешает удаление бакета, даже если в нём есть файлы

  lifecycle {
    prevent_destroy = false
  }
}

# ============================================================
# 4. УМНАЯ ЗАГРУЗКА ОБРАЗА (СКАЧИВАЕТ ТОЛЬКО ПРИ НЕОБХОДИМОСТИ)
# ============================================================
# Этот ресурс скачивает образ ТОЛЬКО если его нет в GCS.
# Благодаря triggers, перезагрузка происходит только при
# изменении версии Talos или URL образа.
resource "null_resource" "download_talos_image" {
  # Триггеры — если изменится что-то из списка, ресурс пересоздастся
  triggers = {
    # При смене версии Talos — скачаем новый образ
    talos_version = var.talos_version
    # При смене schematic (если добавим кастомизацию) — тоже перескачаем
    schematic_id = talos_image_factory_schematic.this.id
    # Сам URL образа — на случай, если factory выдаст другой путь
    image_url = data.talos_image_factory_urls.this.urls.disk_image
  }

  # Это команда, которая выполняется локально (на GitHub Actions runner)
  provisioner "local-exec" {
    command = <<-EOT
      # Определяем переменные для удобства
      BUCKET="${google_storage_bucket.images.name}"
      IMAGE_FILE="talos-gcp-amd64.raw.tar.gz"
      IMAGE_URL="${data.talos_image_factory_urls.this.urls.disk_image}"

      # Проверяем, есть ли образ в GCS
      echo "🔍 Проверяем наличие образа в gs://$BUCKET/$IMAGE_FILE..."
      if gsutil -q stat "gs://$BUCKET/$IMAGE_FILE"; then
        echo "✅ Образ уже существует в GCS. Пропускаем загрузку."
      else
        echo "📥 Образ не найден. Скачиваем с factory.talos.dev..."
        curl -L -o "$IMAGE_FILE" "$IMAGE_URL"

        echo "☁️ Загружаем в GCS..."
        gsutil cp "$IMAGE_FILE" "gs://$BUCKET/$IMAGE_FILE"

        # Чистим за собой
        rm -f "$IMAGE_FILE"
        echo "✅ Образ успешно загружен в GCS"
      fi
    EOT
  }

  # Убеждаемся, что бакет уже создан
  depends_on = [google_storage_bucket.images]
}

# ============================================================
# 5. РЕГИСТРАЦИЯ ОБРАЗА В GCP
# ============================================================
# Создаём ресурс google_compute_image, который ссылается на
# наш файл в GCS. GCP сам скачает его оттуда при создании VM.
resource "google_compute_image" "talos" {
  name        = "talos-img-${replace(var.talos_version, ".", "-")}" # Уникальное имя с версией и без точек
  description = "Образ Talos OS ${var.talos_version} через Image Factory"

  raw_disk {
    # Используем URL из GCS (не прямой URL factory!)
    source = "gs://${google_storage_bucket.images.name}/talos-gcp-amd64.raw.tar.gz"
  }

  # Обязательные фичи для GCP
  guest_os_features {
    type = "GVNIC" # Google Virtual NIC — для лучшей производительности
  }
  guest_os_features {
    type = "UEFI_COMPATIBLE" # Поддержка UEFI загрузки
  }

  # Ждём, пока загрузка завершится
  depends_on = [null_resource.download_talos_image]
}

# ============================================================
# 6. СОЗДАНИЕ CONTROL PLANE НОД
# ============================================================
# Создаём 3 виртуальные машины для управления кластером.
# Распределяем по разным зонам для отказоустойчивости.
resource "google_compute_instance" "control_plane" {
  count        = 3
  name         = "${var.cluster_name}-cp-${count.index + 1}"
  machine_type = "e2-standard-2"                            # 2 vCPU, 8 GB RAM
  zone         = var.zones[count.index % length(var.zones)] # Циклично по зонам

  boot_disk {
    initialize_params {
      image = google_compute_image.talos.id # Используем созданный образ
      size  = 30
      type  = "pd-balanced" # Сбалансированный SSD
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id # Подключаем к приватной сети
  }

  # Теги для файрволов и идентификации
  tags = ["control-plane", "talos-node"]

  metadata = {
    # Отключаем OS Login, т.к. Talos управляется через API
    enable-oslogin = "FALSE"
  }

  # Убеждаемся, что образ создан до VM
  depends_on = [google_compute_image.talos]
}