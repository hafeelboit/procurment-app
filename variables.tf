variable "location" {}
variable "resource_group_name" {}

variable "acr_name" {}
variable "log_analytics_name" {}
variable "app_insights_name" {}
variable "key_vault_name" {}

variable "service_plan_name" {}
variable "web_app_name" {}

variable "docker_image_name" {}
variable "docker_image_tag" {}

variable "sqlsvcadmin" {
  type        = string
  description = "The administrator username for the SQL server"
}

variable "sql_password" {
  type        = string
  description = "The administrator password for the SQL server"
  sensitive   = true
}
