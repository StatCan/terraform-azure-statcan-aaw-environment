variable "prefixes" {
  type = object({
    application = string
    environment = string
    location    = string
    num         = string
  })

  description = "List of prefixes for use in object naming."
}

variable "azure_region" {
  description = "Azure region to store resources in."
}

variable "azure_tags" {
  type        = map(string)
  description = "Tags for use on Azure resources."
}

variable "azure_availability_zones" {
  type        = list(string)
  description = "List of availability zones for Azure resources."
}

variable "azure_gpu_availability_zones" {
  type        = list(string)
  description = "List of availability zones for Azure resources."
}

variable "ddos_protection_plan_id" {
  description = "DDOS Protection Plan ID"
  sensitive   = true
}

variable "network_start" {
  type = object({
    first  = number
    second = number
  })
  description = "Starting octect for network resources. This module uses a /14"
}

variable "dns_zone" {
  description = "DNS zone for the environment"
}

variable "resource_owners" {
  type        = list(string)
  description = "List of owners of the Azure resources"
}

##
## CLUSTER
##
variable "infrastructure_authorized_ip_ranges" {
  type        = list(string)
  description = "Authorized IP ranges concerning the infrastructure pipeline. Generally, this should only be the IP addresses where terraform is being executed."

  default = []
}


variable "infrastructure_pipeline_subnet_ids" {
  type        = list(string)
  description = "Subnet ID of infrastructure pipeline"

  default = []
}

variable "cluster_authorized_ip_ranges" {
  description = "Authorized IP ranges for connecting to the cluster control plane."
  default     = null
}

variable "ingress_general_private_ip" {
  description = "Private IP of the general ingress"
  default     = null
}

variable "ingress_kubeflow_private_ip" {
  description = "Private IP of the kubeflow ingress"
  default     = null
}

variable "ingress_authenticated_private_ip" {
  description = "Private IP of the authenticated ingress"
  default     = null
}

variable "ingress_protected_b_private_ip" {
  description = "Private IP of the protected b ingress"
  default     = null
}

variable "ingress_allowed_sources" {
  type        = list(string)
  description = "Source IPs which are allowed to connect to the ingress gateway"
  default     = ["*"]
}

variable "system_node_pool_kubernetes_version" {
  description = "Kubernetes version for the system node pool"

  default = null
}

variable "system_node_pool_auto_scaling_min_nodes" {
  type    = number
  default = 0
}

variable "system_node_pool_auto_scaling_max_nodes" {
  type    = number
  default = 5
}

variable "system_general_node_pool_kubernetes_version" {
  description = "Kubernetes version for the system general node pool"

  default = null
}

variable "system_general_node_pool_auto_scaling_min_nodes" {
  type    = number
  default = 0
}

variable "system_general_node_pool_auto_scaling_max_nodes" {
  type    = number
  default = 5
}

variable "monitoring_node_pool_kubernetes_version" {
  description = "Kubernetes version for the monitoring node pool"

  default = null
}

variable "monitoring_node_pool_auto_scaling_min_nodes" {
  type    = number
  default = 0
}

variable "monitoring_node_pool_auto_scaling_max_nodes" {
  type    = number
  default = 3
}

variable "storage_node_pool_kubernetes_version" {
  description = "Kubernetes version for the storage node pool"

  default = null
}

variable "storage_node_pool_auto_scaling_min_nodes" {
  type    = number
  default = 0
}

variable "storage_node_pool_auto_scaling_max_nodes" {
  type    = number
  default = 3
}

variable "user_unclassified_node_pool_kubernetes_version" {
  description = "Kubernetes version for the user unclassified node pool"

  default = null
}

variable "user_unclassified_node_pool_auto_scaling_min_nodes" {
  type    = number
  default = 0
}

variable "user_unclassified_node_pool_auto_scaling_max_nodes" {
  type    = number
  default = 3
}

variable "user_gpu_unclassified_node_pool_kubernetes_version" {
  description = "Kubernetes version for the user unclassified GPU node pool"

  default = null
}

variable "user_gpu_unclassified_node_pool_auto_scaling_min_nodes" {
  type    = number
  default = 0
}

variable "user_gpu_unclassified_node_pool_auto_scaling_max_nodes" {
  type    = number
  default = 3
}

variable "cloud_main_system_node_pool_kubernetes_version" {
  description = "Kubernetes version for the cloud main system node pool"

  default = null
}

variable "cloud_main_system_node_pool_auto_scaling_min_nodes" {
  type    = number
  default = 0
}

variable "cloud_main_system_node_pool_auto_scaling_max_nodes" {
  type    = number
  default = 3
}

variable "user_protected_b_node_pool_kubernetes_version" {
  description = "Kubernetes version for the user Protected B node pool"

  default = null
}

variable "user_protected_b_node_pool_auto_scaling_min_nodes" {
  type    = number
  default = 0
}

variable "user_protected_b_node_pool_auto_scaling_max_nodes" {
  type    = number
  default = 3
}

variable "user_gpu_protected_b_node_pool_kubernetes_version" {
  description = "Kubernetes version for the user GPU Protected B node pool"

  default = null
}

variable "user_gpu_protected_b_node_pool_auto_scaling_min_nodes" {
  type    = number
  default = 0
}

variable "user_gpu_protected_b_node_pool_auto_scaling_max_nodes" {
  type    = number
  default = 3
}

variable "user_gpu_four_protected_b_node_pool_auto_scaling_min_nodes" {
  type    = number
  default = 0
}

variable "user_gpu_four_protected_b_node_pool_auto_scaling_max_nodes" {
  type    = number
  default = 1
}

variable "user_gpu_four_unclassified_node_pool_auto_scaling_min_nodes" {
  type    = number
  default = 0
}

variable "user_gpu_four_unclassified_node_pool_auto_scaling_max_nodes" {
  type    = number
  default = 1
}

variable "user_cpu_seventy_two_unclassified_node_pool_auto_scaling_min_nodes" {
  type    = number
  default = 0
}

variable "user_cpu_seventy_two_unclassified_node_pool_auto_scaling_max_nodes" {
  type    = number
  default = 1
}

variable "user_cpu_seventy_two_protected_b_node_pool_auto_scaling_min_nodes" {
  type    = number
  default = 0
}

variable "user_cpu_seventy_two_protected_b_node_pool_auto_scaling_max_nodes" {
  type    = number
  default = 1
}

variable "user_unclassified_node_pool_max_pods" {
  type    = number
  default = 60
}

variable "user_protected_b_node_pool_max_pods" {
  type    = number
  default = 60
}

variable "network_policy" {
  description = "Network policy provider to use"

  default = "azure"
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use"

  default = "1.17.16"
}

variable "storage_profile" {
  type = object({
    blob_driver_enabled         = bool
    disk_driver_enabled         = bool
    disk_driver_version         = string
    file_driver_enabled         = bool
    snapshot_controller_enabled = bool
  })

  description = "The Storage Profile object to be used for the AKS Cluster"

  default = {
    blob_driver_enabled         = false
    disk_driver_enabled         = true
    disk_driver_version         = "v1"
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }
}

# RBAC
variable "cluster_users" {
  type        = list(string)
  description = "List of users/groups who can pull kubeconfig"

  default = []
}

variable "cluster_admins" {
  type        = list(string)
  description = "List of users/groups who can pull admin kubeconfig"

  default = []
}

variable "cluster_ssh_key" {
  description = "The SSH key for Kubernetes to use"
  sensitive   = true
}

# Cloud Main Networking Variables
variable "cloud_main_firewall_ip" {
  description = "IP of cloud main firewall"
  default     = null
}

variable "cloud_main_address_prefix" {
  description = "IP prefix for cloud main addresses."
  default     = null
}

variable "management_cluster_https_ingress_gateway_ip" {
  description = "IP of cloud main (Management cluster) ingress gateway for HTTPs traffic."
  default     = null
}

variable "cloud_main_gitlab_ssh_ip" {
  description = "IP of cloud main gitlab for ssh (gitlab-ssh.cloud.statcan.ca)"
  default     = null
}

