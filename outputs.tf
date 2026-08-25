output "ansible_control_public_ip" {
  description = "Public IP of Ansible Control Server"
  value       = azurerm_public_ip.ansible_control.ip_address
}

output "ansible_control_private_ip" {
  description = "Private IP of Ansible Control Server"
  value       = azurerm_network_interface.ansible_control.private_ip_address
}

output "target_server_names" {
  description = "Ubuntu target server names"
  value       = azurerm_linux_virtual_machine.ubuntu[*].name
}

output "target_server_private_ips" {
  description = "Private IPs of Ubuntu target servers"
  value       = azurerm_network_interface.target[*].ip_configuration[0].private_ip_address
}

output "target_server_public_ips" {
  description = "Public IPs of Ubuntu target servers"
  value       = azurerm_public_ip.target[*].ip_address
}