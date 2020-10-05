
variable "name_prefix" {
  type = string
  default = "TF-"
  description = "A prefix that will be added to all the object names"
}

variable "tenant" {
  type = string
  default = "WoS"
  description = "The MSO tenant to use for this configuration"
}

variable "schema_name" {
  type = string
  default = "terraform_hybrid_cloud"
  description = "The name of the MSO schema to be created"
}

variable "subnet_gw" {
  type = string
  default = "10.101.10.254/24"
  description = "The subnet gateway address with mask"
}

variable "mso_username" {}
variable "mso_password" {}
variable "mso_url" {}