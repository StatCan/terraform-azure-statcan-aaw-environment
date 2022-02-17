module "infrastructure" {
  source = "git::https://gitlab.k8s.cloud.statcan.ca/cloudnative/terraform/modules/terraform-statcan-azure-cloud-native-environment-infrastructure.git?ref=v1.0.0"

  prefix   = local.prefix
  tags     = var.azure_tags
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
  system_node_pool_auto_scaling_min_nodes = var.system_node_pool_auto_scaling_min_nodes
  system_node_pool_auto_scaling_max_nodes = var.system_node_pool_auto_scaling_max_nodes

  # We don't want the general node pool, so set the count to 0.
  general_node_pool_kubernetes_version     = var.system_general_node_pool_kubernetes_version
  general_node_pool_enable_auto_scaling    = true
  general_node_pool_auto_scaling_min_nodes = var.system_general_node_pool_auto_scaling_min_nodes
  general_node_pool_auto_scaling_max_nodes = var.system_general_node_pool_auto_scaling_max_nodes
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

  # SSH Key
  cluster_ssh_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLkMdICXrdk8arJjUAKelTeYutZWvmgwzT8LP/GCO8SMCXmRR4ByEeFq4MiSxDve5kUYwqa6ajay3cfGSA8x7YME8fjyNLPBzbL5Ngr5mUMi5SIMzQdx7EP3kZ/HKFpAL7LWs/1LFKqQT7n9IrbiDFBA1OpvemGP0bhlN133AIVSnrVU23Salr1BjaAtmLIAgFs06mLBroYHgwIeZTNSoQlkKW87oCtE0yqXYUaJCaZzG03jjZOtDz+kYnnUyjEDPAwhPeFacr41UoAXf4w0c+KvzYPDX/EwwqbLFzkI619qeE5Q8a57WC8wz7+oXIIypbzbWiNivQOCv77Och++/CL6lnjsSd0kz2Xn1ehkAr+k93nRbWg9uQw9mb+yrKHigwe4mndY0HFnn5vB+kCMw8UzW6EAV5V9vdzrj+/zx+HO0fWaveoD/XYu5RjVcYLk9u39E9b4CU7qWpTBzQcKokMbg4V5Hg692haI9tJ2AxbRpj+ep1YWG2Uo+JTbkT+aq8g/D/NOGo/416YU25P1PwefKHsm0TlNP2Ya0AlkwednLDMUJRkCNpX1hCWoZtW27kLHt/zR/25qufGdAzUZ2gJ7QeOPA2X0AjU/inl/dv0B8xEzvn//F2DXPBrCwxkNMAS9hHFx+O+sa90/4knFG08eLXK54mX9M4TrVUM5vEAw== aaw-dev-cc-00"

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

module "monitoring_node_pool" {
  source = "git::https://gitlab.k8s.cloud.statcan.ca/cloudnative/terraform/modules/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.0"

  name                  = "monitoring"
  kubernetes_cluster_id = module.infrastructure.kubernetes_cluster_id
  kubernetes_version    = var.monitoring_node_pool_kubernetes_version
  node_count            = 1
  availability_zones    = var.azure_availability_zones
  vm_size               = "Standard_E16s_v3"
  labels = {
    "node.statcan.gc.ca/purpose"        = "system"
    "node.statcan.gc.ca/use"            = "monitoring"
    "data.statcan.gc.ca/classification" = "protected-b"
  }
  taints = [
    "node.statcan.gc.ca/purpose=system:NoSchedule",
    "node.statcan.gc.ca/use=monitoring:NoSchedule",
    "data.statcan.gc.ca/classification=protected-b:NoSchedule"
  ]
  enable_host_encryption = true
  subnet_id              = module.network.aks_system_subnet_id

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.monitoring_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.monitoring_node_pool_auto_scaling_max_nodes
}

module "storage_node_pool" {
  source = "git::https://gitlab.k8s.cloud.statcan.ca/cloudnative/terraform/modules/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.0"

  name                  = "storage"
  kubernetes_cluster_id = module.infrastructure.kubernetes_cluster_id
  kubernetes_version    = var.storage_node_pool_kubernetes_version
  node_count            = 1
  availability_zones    = var.azure_availability_zones
  vm_size               = "Standard_E16s_v3"
  labels = {
    "node.statcan.gc.ca/purpose"        = "system"
    "node.statcan.gc.ca/use"            = "storage"
    "data.statcan.gc.ca/classification" = "protected-b"
  }
  taints = [
    "node.statcan.gc.ca/purpose=system:NoSchedule",
    "node.statcan.gc.ca/use=storage:NoSchedule",
    "data.statcan.gc.ca/classification=protected-b:NoSchedule"
  ]
  enable_host_encryption = true
  subnet_id              = module.network.aks_system_subnet_id

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.storage_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.storage_node_pool_auto_scaling_max_nodes
}

module "user_unclassified_node_pool" {
  source = "git::https://gitlab.k8s.cloud.statcan.ca/cloudnative/terraform/modules/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.0"

  name                  = "useruc"
  kubernetes_cluster_id = module.infrastructure.kubernetes_cluster_id
  kubernetes_version    = var.user_unclassified_node_pool_kubernetes_version
  node_count            = 1
  #availability_zones    = var.azure_availability_zones
  vm_size = "Standard_D16s_v3"
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

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.user_unclassified_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.user_unclassified_node_pool_auto_scaling_max_nodes
}

module "user_gpu_unclassified_node_pool" {
  source = "git::https://gitlab.k8s.cloud.statcan.ca/cloudnative/terraform/modules/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.0"

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

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.user_gpu_unclassified_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.user_gpu_unclassified_node_pool_auto_scaling_max_nodes
}

module "user_protected_b_node_pool" {
  source = "git::https://gitlab.k8s.cloud.statcan.ca/cloudnative/terraform/modules/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.0"

  name                  = "userpb"
  kubernetes_cluster_id = module.infrastructure.kubernetes_cluster_id
  kubernetes_version    = var.user_protected_b_node_pool_kubernetes_version
  node_count            = 1
  #availability_zones    = var.azure_availability_zones
  vm_size = "Standard_D16s_v3"
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

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.user_protected_b_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.user_protected_b_node_pool_auto_scaling_max_nodes
}

module "user_gpu_protected__node_pool" {
  source = "git::https://gitlab.k8s.cloud.statcan.ca/cloudnative/terraform/modules/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.0"

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

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.user_gpu_protected_b_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.user_gpu_protected_b_node_pool_auto_scaling_max_nodes
}

module "user_gpufour_protected__node_pool" {
  source = "git::https://gitlab.k8s.cloud.statcan.ca/cloudnative/terraform/modules/terraform-azurerm-kubernetes-cluster-nodepool.git?ref=v1.0.0"

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

  enable_auto_scaling    = true
  auto_scaling_min_nodes = var.user_gpu_four_protected_b_node_pool_auto_scaling_min_nodes
  auto_scaling_max_nodes = var.user_gpu_four_protected_b_node_pool_auto_scaling_max_nodes
}
