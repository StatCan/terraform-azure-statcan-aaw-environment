module "network" {
  source = "git::https://gitlab.k8s.cloud.statcan.ca/cloudnative/aaw/modules/terraform-azure-statcan-aaw-network.git?ref=v1.3.1"

  prefix             = local.prefix
  location           = var.azure_region
  tags               = var.azure_tags
  availability_zones = var.azure_availability_zones

  ddos_protection_plan_id = var.ddos_protection_plan_id

  start    = var.network_start
  dns_zone = var.dns_zone

  ingress_general_private_ip                  = var.ingress_general_private_ip
  ingress_kubeflow_private_ip                 = var.ingress_kubeflow_private_ip
  ingress_authenticated_private_ip            = var.ingress_authenticated_private_ip
  ingress_protected_b_private_ip              = var.ingress_protected_b_private_ip
  ingress_allowed_sources                     = var.ingress_allowed_sources
  cloud_main_firewall_ip                      = var.cloud_main_firewall_ip
  cloud_main_address_prefix                   = var.cloud_main_address_prefix
  management_cluster_https_ingress_gateway_ip = var.management_cluster_https_ingress_gateway_ip
  cloud_main_gitlab_ssh_ip                    = var.cloud_main_gitlab_ssh_ip
}
