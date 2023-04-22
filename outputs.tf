#==================================================================================
#OUTPUTS
#==================================================================================

output "public_ip_address_vm02" {
  value = azurerm_public_ip.public_ip_vm02.ip_address
  description = "Output the assigned public IP address of the newly created VM"  
}