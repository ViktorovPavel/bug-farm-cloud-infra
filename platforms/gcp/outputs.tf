# Вывод внутренних IP-адресов нод Control Plane для дальнейшей настройки через talosctl
output "control_plane_ips" {
  value       = google_compute_instance.control_plane[*].network_interface[0].network_ip
  description = "Внутренние IP-адреса Control Plane нод в подсети VPC"
}