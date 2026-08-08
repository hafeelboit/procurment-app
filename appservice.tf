resource "azurerm_service_plan" "plan" {
  name                = "asp-proceval"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "westeurope" # Updated to West Europe

  os_type  = "Linux" 
  sku_name = "P0v3"   # Reverted to Premium P0v3 tier
}

resource "azurerm_linux_web_app" "app" {
  name                = var.web_app_name
  location            = "westeurope" # Updated to West Europe
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                               = true # Set back to true (supported and required by P0v3)
    container_registry_use_managed_identity = true

    application_stack {
      docker_image_name = "${azurerm_container_registry.acr.login_server}/${var.docker_image_name}:${var.docker_image_tag}"
    }
  }

  app_settings = {
    WEBSITES_PORT = "8000"

    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.appi.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.appi.connection_string
  }

  depends_on = [
    azurerm_service_plan.plan
  ]
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id

  depends_on = [
    azurerm_linux_web_app.app
  ]
}
