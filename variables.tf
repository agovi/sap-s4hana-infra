variable "rgname" {
  description = "Name of the resource group to deploy the resources"
}
variable "location" {
  description = "Specify Azure Region to deploy the resources (eg WestEurope, NorthEurope)"
}
variable "adminuser" {
  description = "Username for logging in to the Virtual Machines"
  default     = "azureuser"
}

variable "adminpassword" {
  description = "Password for logging in to the VMs"
}

variable "sshkeypath" {
  description = "Path for the SSH keys to be used for passwordless login to Linux VMs (eg ~/.ssh/id_rsa.pub)"
  //default     = "~/.ssh/id_rsa.pub"
}
variable "tags" {
  description = "A map of tags to the deployed resources. Empty by default."
  type        = map(string)
  default     = {}
}

variable "vnetprefix" {
  type        = list
  description = "Address prefix for the VNET"

}
variable "sapappsubnet" {
  description = "Address prefix for SAP app subnet"
}

variable "sapdbsubnet" {
  description = "Address prefix for SAP DB subnet"
}

variable "bastionsubnet" {
  description = "Address prefix for AzureBastion subnet"
}

variable "appvmname" {
  description = "Name of the VM to be created"
}

variable "appvmsize" {
  description = "Size of the VM to be created"
}

variable "dbvmname" {
  description = "Name of the VM to be created"
}

variable "dbvmsize" {
  description = "Size of the VM to be created"
}

variable "luns" {
  type        = list
  description = "Number of luns required"
  default     = [0, 1, 2, 3, 4, 5, 6, 7, 8]
}

variable "cache_settings" {
  type        = list
  description = "Cache settings for luns"
  default     = ["None", "None", "None", "None", "None", "None", "None", "ReadOnly", "ReadWrite"]
}

variable "disksizes" {
  type        = list
  description = "Disk sizes"
  default     = [128, 128, 128, 128, 128, 128, 128, 512, 128]
}

variable "waflag" {
  type        = list
  description = "Disk sizes"
  default     = ["false", "false", "false", "false", "false", "false", "false", "false", "false", "false"]
}

