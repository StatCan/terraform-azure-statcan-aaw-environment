module "network" {
  source = "git::https://github.com/statcan/terraform-azure-statcan-aaw-network.git?ref=v0.3.13"

  prefix             = local.prefix
  location           = var.azure_region
  tags               = var.azure_tags
  availability_zones = var.azure_availability_zones

  ddos_protection_plan_id = var.ddos_protection_plan_id

  start    = var.network_start
  dns_zone = var.dns_zone

  ingress_general_private_ip       = var.ingress_general_private_ip
  ingress_kubeflow_private_ip      = var.ingress_kubeflow_private_ip
  ingress_authenticated_private_ip = var.ingress_authenticated_private_ip
  ingress_protected_b_private_ip   = var.ingress_protected_b_private_ip
}
