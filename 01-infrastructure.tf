module "infrastructure" {
  source = "git::https://github.com/statcan/terraform-statcan-azure-cloud-native-environment-infrastructure.git?ref=v1.0.8"

  prefix   = local.prefix
  tags     = local.azure_tags
  location = var.azure_region

  kubernetes_version = var.kubernetes_version

  # Administrative groups
  resource_owners = var.resource_owners

  # Availability zones
  availability_zones = var.azure_availability_zones

  # Networking
  cluster_private_cluster      = false
  cluster_subnet_id            = module.network.aks_system_subnet_id
  cluster_authorized_ip_ranges = concat(["${module.network.egress_ip}/32"], var.cluster_authorized_ip_ranges)

  # Infrastructure pipeline network
  infrastructure_pipeline_allowed_ip_ranges = var.infrastructure_authorized_ip_ranges
  infrastructure_pipeline_subnet_ids        = var.infrastructure_pipeline_subnet_ids

  # Set this to some unusable range
  cluster_docker_bridge_cidr = "127.255.255.1/24"

  # Use the last /16 in our /14 for the service subnet
  cluster_service_cidr   = "${var.network_start.first}.${var.network_start.second + 3}.0.0/16"
  cluster_dns_service_ip = "${var.network_start.first}.${var.network_start.second + 3}.0.10"
  network_policy         = var.network_policy

  # Nodes
  system_node_pool_kubernetes_version     = var.system_node_pool_kubernetes_version
  system_node_pool_enable_auto_scaling    = true
  system_node_pool_vm_size                = var.system_node_pool_vm_size
  system_node_pool_auto_scaling_min_nodes = var.system_node_pool_auto_scaling_min_nodes
  system_node_pool_auto_scaling_max_nodes = var.system_node_pool_auto_scaling_max_nodes

  # We don't want the general node pool, so set the count to 0.
  general_node_pool_kubernetes_version     = var.system_general_node_pool_kubernetes_version
  general_node_pool_enable_auto_scaling    = true
  general_node_pool_vm_size                = var.system_general_node_pool_vm_size
  general_node_pool_auto_scaling_min_nodes = var.system_general_node_pool_auto_scaling_min_nodes
  general_node_pool_auto_scaling_max_nodes = var.system_general_node_pool_auto_scaling_max_nodes
  general_node_pool_max_pods               = var.system_general_node_pool_max_pods
  general_node_pool_labels = {
    "node.statcan.gc.ca/purpose"        = "system"
    "node.statcan.gc.ca/use"            = "general"
    "data.statcan.gc.ca/classification" = "protected-b"
  }
  general_node_pool_taints = [
    "node.statcan.gc.ca/purpose=system:NoSchedule",
    "node.statcan.gc.ca/use=general:NoSchedule",
    "data.statcan.gc.ca/classification=protected-b:NoSchedule"
  ]

  # CSI Drivers
  storage_profile = var.storage_profile

  # SSH Key
  cluster_ssh_key = var.cluster_ssh_key

  # Cluster RBAC
  cluster_users  = var.cluster_users
  cluster_admins = var.cluster_admins
}

# Grant access to the entire Vnet
resource "azurerm_role_assignment" "aks_network_add_aks" {
  scope                = module.network.aks_virtual_network_id
  role_definition_name = "Network Add"
  principal_id         = module.infrastructure.aks_principal_id
}

# Lookup control plane IP
data "dns_a_record_set" "control_plane_ip" {
  host = module.infrastructure.cluster_fqdn
}

resource "azurerm_firewall_policy_rule_collection_group" "aks" {
  name               = "${local.prefix}-fwprcg-aks-control-plane"
  firewall_policy_id = module.network.firewall_policy_id

  priority = 150

  network_rule_collection {
    name     = "aks-control-plane"
    priority = 150
    action   = "Allow"

    rule {
      name                  = "aks-control-plane"
      source_addresses      = module.network.aks_address_space
      destination_addresses = data.dns_a_record_set.control_plane_ip.addrs
      destination_ports     = ["443"]
      protocols             = ["TCP"]
    }
  }
}

module "user_unclassified_node_pool" {
  source = "git::https://github.com/statcan/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.3"

  name                  = "useruc"
  kubernetes_cluster_id = module.infrastructure.kubernetes_cluster_id
  kubernetes_version    = var.user_unclassified_node_pool_kubernetes_version
  node_count            = 1
  #availability_zones    = var.azure_availability_zones
  vm_size  = var.prefixes.environment == "prod" ? "Standard_D64as_v5" : "Standard_D16s_v3"
  max_pods = var.user_unclassified_node_pool_max_pods
  labels = {
    "node.statcan.gc.ca/purpose"        = "user"
    "node.statcan.gc.ca/use"            = "general"
    "data.statcan.gc.ca/classification" = "unclassified"
  }
  taints = [
    "node.statcan.gc.ca/purpose=user:NoSchedule",
    "data.statcan.gc.ca/classification=unclassified:NoSchedule"
  ]
  enable_host_encryption = true
  subnet_id              = module.network.aks_user_unclassified_subnet_id
  tags                   = local.azure_tags

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.user_unclassified_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.user_unclassified_node_pool_auto_scaling_max_nodes
}

module "user_gpu_unclassified_node_pool" {
  source = "git::https://github.com/statcan/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.3"

  name                  = "usergpuuc"
  kubernetes_cluster_id = module.infrastructure.kubernetes_cluster_id
  kubernetes_version    = var.user_gpu_unclassified_node_pool_kubernetes_version
  node_count            = 1
  #availability_zones    = var.azure_gpu_availability_zones
  vm_size = "Standard_NC6s_v3"
  labels = {
    "node.statcan.gc.ca/purpose"        = "user"
    "node.statcan.gc.ca/use"            = "gpu"
    "data.statcan.gc.ca/classification" = "unclassified"
  }
  taints = [
    "node.statcan.gc.ca/purpose=user:NoSchedule",
    "node.statcan.gc.ca/use=gpu:NoSchedule",
    "data.statcan.gc.ca/classification=unclassified:NoSchedule"
  ]
  enable_host_encryption = true
  subnet_id              = module.network.aks_user_unclassified_subnet_id
  tags                   = local.azure_tags

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.user_gpu_unclassified_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.user_gpu_unclassified_node_pool_auto_scaling_max_nodes
}

module "user_protected_b_node_pool" {
  source = "git::https://github.com/statcan/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.3"

  name                  = "userpb"
  kubernetes_cluster_id = module.infrastructure.kubernetes_cluster_id
  kubernetes_version    = var.user_protected_b_node_pool_kubernetes_version
  node_count            = 1
  #availability_zones    = var.azure_availability_zones
  vm_size  = "Standard_D16s_v3"
  max_pods = var.user_protected_b_node_pool_max_pods
  labels = {
    "node.statcan.gc.ca/purpose"        = "user"
    "node.statcan.gc.ca/use"            = "general"
    "data.statcan.gc.ca/classification" = "protected-b"
  }
  taints = [
    "node.statcan.gc.ca/purpose=user:NoSchedule",
    "data.statcan.gc.ca/classification=protected-b:NoSchedule"
  ]
  enable_host_encryption = true
  subnet_id              = module.network.aks_user_protected_b_subnet_id
  tags                   = local.azure_tags

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.user_protected_b_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.user_protected_b_node_pool_auto_scaling_max_nodes
}

module "cloud_main_system_node_pool" {
  source = "git::https://github.com/statcan/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.3"

  name                  = "cloudmainsys"
  kubernetes_cluster_id = module.infrastructure.kubernetes_cluster_id
  kubernetes_version    = var.cloud_main_system_node_pool_kubernetes_version
  node_count            = 1
  #availability_zones    = var.azure_availability_zones
  vm_size = "Standard_D16s_v3"
  labels = {
    "node.statcan.gc.ca/purpose"        = "system"
    "node.statcan.gc.ca/use"            = "cloud-main-system"
    "data.statcan.gc.ca/classification" = "protected-b"
  }
  taints = [
    "node.statcan.gc.ca/purpose=system:NoSchedule",
    "node.statcan.gc.ca/use=cloud-main-system:NoSchedule",
    "data.statcan.gc.ca/classification=protected-b:NoSchedule"
  ]
  enable_host_encryption = true
  subnet_id              = module.network.aks_cloud_main_system_subnet_id
  tags                   = local.azure_tags

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.cloud_main_system_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.cloud_main_system_node_pool_auto_scaling_max_nodes
}

module "user_gpu_protected__node_pool" {
  source = "git::https://github.com/statcan/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.3"

  name                  = "usergpupb"
  kubernetes_cluster_id = module.infrastructure.kubernetes_cluster_id
  kubernetes_version    = var.user_gpu_protected_b_node_pool_kubernetes_version
  node_count            = 1
  #availability_zones    = var.azure_gpu_availability_zones
  vm_size = "Standard_NC6s_v3"
  labels = {
    "node.statcan.gc.ca/purpose"        = "user"
    "node.statcan.gc.ca/use"            = "gpu"
    "data.statcan.gc.ca/classification" = "protected-b"
  }
  taints = [
    "node.statcan.gc.ca/purpose=user:NoSchedule",
    "node.statcan.gc.ca/use=gpu:NoSchedule",
    "data.statcan.gc.ca/classification=protected-b:NoSchedule"
  ]
  enable_host_encryption = true
  subnet_id              = module.network.aks_user_protected_b_subnet_id
  tags                   = local.azure_tags

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.user_gpu_protected_b_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.user_gpu_protected_b_node_pool_auto_scaling_max_nodes
}

module "user_gpufour_protected__node_pool" {
  source = "git::https://github.com/statcan/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.3"

  name                  = "usergpu4pb"
  kubernetes_cluster_id = module.infrastructure.kubernetes_cluster_id
  kubernetes_version    = var.user_gpu_protected_b_node_pool_kubernetes_version
  node_count            = 1
  #availability_zones    = var.azure_gpu_availability_zones
  vm_size = "Standard_NC24s_v3"
  labels = {
    "node.statcan.gc.ca/purpose"        = "user"
    "node.statcan.gc.ca/use"            = "gpu-4"
    "data.statcan.gc.ca/classification" = "protected-b"
  }
  taints = [
    "node.statcan.gc.ca/purpose=user:NoSchedule",
    "node.statcan.gc.ca/use=gpu-4:NoSchedule",
    "data.statcan.gc.ca/classification=protected-b:NoSchedule"
  ]
  enable_host_encryption = true
  subnet_id              = module.network.aks_user_protected_b_subnet_id
  tags                   = local.azure_tags

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.user_gpu_four_protected_b_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.user_gpu_four_protected_b_node_pool_auto_scaling_max_nodes
}

module "user_gpufour_unclassified__node_pool" {
  source = "git::https://github.com/statcan/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.3"

  name                  = "usergpu4uc"
  kubernetes_cluster_id = module.infrastructure.kubernetes_cluster_id
  kubernetes_version    = var.user_gpu_protected_b_node_pool_kubernetes_version
  node_count            = 1
  #availability_zones    = var.azure_gpu_availability_zones
  vm_size = "Standard_NC24s_v3"
  labels = {
    "node.statcan.gc.ca/purpose"        = "user"
    "node.statcan.gc.ca/use"            = "gpu-4"
    "data.statcan.gc.ca/classification" = "unclassified"
  }
  taints = [
    "node.statcan.gc.ca/purpose=user:NoSchedule",
    "node.statcan.gc.ca/use=gpu-4:NoSchedule",
    "data.statcan.gc.ca/classification=unclassified:NoSchedule"
  ]
  enable_host_encryption = true
  subnet_id              = module.network.aks_user_unclassified_subnet_id
  tags                   = local.azure_tags

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.user_gpu_four_unclassified_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.user_gpu_four_unclassified_node_pool_auto_scaling_max_nodes
}

// Unclassified compute-optimized node pool
module "user_compute_optimized_unclassified_node_pool" {
  source = "git::https://github.com/statcan/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.3"

  name                  = "usercpu72uc"
  kubernetes_cluster_id = module.infrastructure.kubernetes_cluster_id
  kubernetes_version    = var.user_gpu_unclassified_node_pool_kubernetes_version
  node_count            = 1 // this gets overwritten
  #availability_zones    = var.azure_gpu_availability_zones
  vm_size = "Standard_F72s_v2"
  labels = {
    "node.statcan.gc.ca/purpose"        = "user"
    "node.statcan.gc.ca/use"            = "cpu-72"
    "data.statcan.gc.ca/classification" = "unclassified"
  }
  taints = [
    "node.statcan.gc.ca/purpose=user:NoSchedule",
    "node.statcan.gc.ca/use=cpu-72:NoSchedule",
    "data.statcan.gc.ca/classification=unclassified:NoSchedule"
  ]
  enable_host_encryption = true
  subnet_id              = module.network.aks_user_unclassified_subnet_id
  tags                   = local.azure_tags

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.user_cpu_seventy_two_unclassified_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.user_cpu_seventy_two_unclassified_node_pool_auto_scaling_max_nodes
}

// Pro-B compute-optimized node pool
module "user_compute_optimized_protected_node_pool" {
  source = "git::https://github.com/statcan/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.3"

  name                  = "usercpu72pb"
  kubernetes_cluster_id = module.infrastructure.kubernetes_cluster_id
  // Assumption: we are using same k8s version as other node pools, that's why we're referencing another version here.
  kubernetes_version = var.user_gpu_protected_b_node_pool_kubernetes_version
  node_count         = 1
  #availability_zones    = var.azure_gpu_availability_zones
  vm_size = "Standard_F72s_v2"
  labels = {
    "node.statcan.gc.ca/purpose"        = "user"
    "node.statcan.gc.ca/use"            = "cpu-72"
    "data.statcan.gc.ca/classification" = "protected-b"
  }
  taints = [
    "node.statcan.gc.ca/purpose=user:NoSchedule",
    "node.statcan.gc.ca/use=cpu-72:NoSchedule",
    "data.statcan.gc.ca/classification=protected-b:NoSchedule"
  ]
  enable_host_encryption = true
  subnet_id              = module.network.aks_user_protected_b_subnet_id
  tags                   = local.azure_tags

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.user_cpu_seventy_two_protected_b_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.user_cpu_seventy_two_protected_b_node_pool_auto_scaling_max_nodes
}
