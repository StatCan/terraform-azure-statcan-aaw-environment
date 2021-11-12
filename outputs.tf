output "prefix" {
  value = local.prefix
}

output "azure_region" {
  value = var.azure_region
}

output "azure_tags" {
  value = var.azure_tags
}

output "kubeconfig" {
  value = module.infrastructure.kubeconfig
}

output "cluster_resource_group_name" {
  value = module.infrastructure.cluster_resource_group_name
}

output "cluster_node_resource_group" {
  value = module.infrastructure.cluster_node_resource_group_name
}

output "kubernetes_identity_object_id" {
  value = module.infrastructure.kubernetes_identity.0.object_id
}

output "hub_virtual_network_id" {
  value = module.network.hub_virtual_network_id
}

output "hub_virtual_network_name" {
  value = module.network.hub_virtual_network_name
}

output "hub_virtual_network_resource_group_name" {
  value = module.network.hub_virtual_network_resource_group_name
}

output "aks_load_balancers_subnet_id" {
  value = module.network.aks_load_balancers_subnet_id
}

output "aks_load_balancers_subnet_name" {
  value = module.network.aks_load_balancers_subnet_name
}

output "aks_load_balancers_address_space" {
  value = module.network.aks_load_balancers_address_space
}

output "aks_address_space" {
  value = module.network.aks_address_space
}

output "aks_system_subnet_id" {
  value = module.network.aks_system_subnet_id
}

output "aks_system_address_space" {
  value = module.network.aks_system_address_space
}

output "dns_zone" {
  value = var.dns_zone
}

output "dns_zone_id" {
  value = module.network.dns_zone_id
}

output "dns_zone_resource_group_name" {
  value = module.network.dns_zone_resource_group_name
}

output "dns_zone_subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

output "dns_zone_name_servers" {
  value = module.network.dns_zone_name_servers
}

output "firewall_policy_id" {
  value = module.network.firewall_policy_id
}

output "firewall_route_table_name" {
  value = module.network.firewall_route_table_name
}

output "firewall_route_table_resource_group_name" {
  value = module.network.firewall_route_table_resource_group_name
}

output "firewall_route_table_id" {
  value = module.network.firewall_route_table_id
}
