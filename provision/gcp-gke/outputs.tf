output "region" {
  value = var.region
}

output "kubernetes_cluster_name" {
  value = module.gke.name
}

output "kubernetes_endpoint" {
  sensitive = true
  value     = module.gke.endpoint
}

output "client_token" {
  sensitive = true
  value     = base64encode(data.google_client_config.default.access_token)
}

output "ca_certificate" {
  sensitive = true
  value = module.gke.ca_certificate
}

output "service_account" {
  value = module.gke.service_account
}
