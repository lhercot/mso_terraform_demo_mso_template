output "db_gateway" {
  value = split("/", var.subnet_gw)[0]
  description = "The gateway IP address for On-premises network"
}