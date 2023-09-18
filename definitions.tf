locals {

  // The naming convention of resources within
  // this environment is:
  //
  //   $app-$env-$region-$type-$num
  //
  // The common prefix is $app-$env-$region
  // which this local variable provides.
  prefix = "${var.prefixes.application}-${var.prefixes.environment}-${var.prefixes.location}-${var.prefixes.num}"

  // Azure tags
  azure_tags = merge(
    var.azure_tags,
    {
      ModuleName    = "terraform-azure-statcan-aaw-environment",
      ModuleVersion = "2.3.7",
    }
  )
}

data "azurerm_client_config" "current" {}
