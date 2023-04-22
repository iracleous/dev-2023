#VARIABLES
#==================================================================================
variable "vmname" {
  type = string
  default = "default_vmname"
 }

 variable "prefix" {
  type = string
  default = "Default_prefix"
}

variable "location" {
  type = string
  description = "Location of the resource group and the rest of the resources"
  validation {
    condition = length(var.location) > 4
    error_message = "Location should be above 4 characters."
  }
}

variable "username" {
  type = string
  default = ""
 }

 variable "password" {
    type = string
    default = ""

 }


#==================================================================================
