resource "azurerm_mssql_server" "sql" {
  name                         = "proc-sql-server"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = "Central US" # Keep this line, REMOVE the old one
  version                      = "12.0"
  administrator_login          = var.sql_admin
  administrator_login_password = var.sql_password
}


resource "azurerm_mssql_database" "db" {
  name      = "procurementdb"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "S0"
}

resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "allow-azure"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
