resource "azurerm_log_analytics_workspace" "law" {
  name                = var.log_analytics_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku = "PerGB2018"
}

resource "azurerm_application_insights" "appi" {
  name                = var.app_insights_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  workspace_id     = azurerm_log_analytics_workspace.law.id
  application_type = "web"
}