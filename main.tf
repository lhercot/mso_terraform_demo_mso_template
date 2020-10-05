terraform {
  required_providers {
    mso = {
      source = "CiscoDevNet/mso"
    }
  }
}

provider "mso" {
  # Configuration options
  // Requires ENV variable TF_VAR_mso_username 
  username  = var.mso_username
  // Requires ENV variable TF_VAR_mso_password
  password  = var.mso_password
  // Requires ENV variable TF_VAR_mso_url
  url       = var.mso_url

  insecure  = true
}

data "mso_tenant" "wos" {
  name = var.tenant
  display_name = var.tenant
}

resource "mso_schema" "hybrid_cloud" {
  name          = var.schema_name
  template_name = "Template1"
  tenant_id     = data.mso_tenant.wos.id
}

resource "mso_schema_template_vrf" "vrf1" {
  schema_id     = mso_schema.hybrid_cloud.id
  template      = mso_schema.hybrid_cloud.template_name
  name          = "${var.name_prefix}Hybrid_Cloud_VRF"
  display_name  = "Hybrid Cloud VRF"
}

resource "mso_schema_template_bd" "bd1" {
  schema_id              = mso_schema.hybrid_cloud.id
  template_name          = mso_schema.hybrid_cloud.template_name
  name                   = "${var.name_prefix}BD"
  display_name           = "BD"
  vrf_name               = mso_schema_template_vrf.vrf1.name
  layer2_unknown_unicast = "proxy"
  layer2_stretch = true
}

resource "mso_schema_template_bd_subnet" "bd1_subnet" {
  schema_id = mso_schema.hybrid_cloud.id
  template_name = mso_schema.hybrid_cloud.template_name
  bd_name = mso_schema_template_bd.bd1.name
  ip = var.subnet_gw
  scope = "public"
  shared = true
}

resource "mso_schema_template_anp" "anp" {
  schema_id     = mso_schema.hybrid_cloud.id
  template      = mso_schema.hybrid_cloud.template_name
  name          = "${var.name_prefix}App"
  display_name  = "App"
}

resource "mso_schema_template_anp_epg" "db" {
  schema_id         = mso_schema.hybrid_cloud.id
  template_name     = mso_schema.hybrid_cloud.template_name
  anp_name          = mso_schema_template_anp.anp.name
  name              = "DB"
  display_name      = "DB"
  bd_name           = mso_schema_template_bd.bd1.name
  bd_template_name  = mso_schema.hybrid_cloud.template_name
  vrf_name          = mso_schema_template_vrf.vrf1.name
  vrf_template_name = mso_schema.hybrid_cloud.template_name
}

resource "mso_schema_template_anp_epg" "web" {
  schema_id         = mso_schema.hybrid_cloud.id
  template_name     = mso_schema.hybrid_cloud.template_name
  anp_name          = mso_schema_template_anp.anp.name
  name              = "Web"
  display_name      = "Web"
  bd_name           = mso_schema_template_bd.bd1.name
  bd_template_name  = mso_schema.hybrid_cloud.template_name
  vrf_name          = mso_schema_template_vrf.vrf1.name
  vrf_template_name = mso_schema.hybrid_cloud.template_name
}

resource "mso_schema_template_filter_entry" "any" {
  schema_id          = mso_schema.hybrid_cloud.id
  template_name      = mso_schema.hybrid_cloud.template_name
  name               = "${var.name_prefix}Any"
  display_name       = "Any"
  entry_name         = "Any"
  entry_display_name = "Any"
}

resource "mso_schema_template_filter_entry" "http" {
  schema_id          = mso_schema.hybrid_cloud.id
  template_name      = mso_schema.hybrid_cloud.template_name
  name               = "${var.name_prefix}HTTP"
  display_name       = "HTTP"
  entry_name         = "HTTP"
  entry_display_name = "HTTP"
  ether_type         = "ip"
  ip_protocol        = "tcp"
  destination_from   = "http"
  destination_to     = "http"
}

resource "mso_schema_template_filter_entry" "https" {
  schema_id          = mso_schema.hybrid_cloud.id
  template_name      = mso_schema.hybrid_cloud.template_name
  name               = mso_schema_template_filter_entry.http.name
  display_name       = mso_schema_template_filter_entry.http.display_name
  entry_name         = "HTTPs"
  entry_display_name = "HTTPs"
  ether_type         = "ip"
  ip_protocol        = "tcp"
  destination_from   = "https"
  destination_to     = "https"
}

resource "mso_schema_template_filter_entry" "ssh" {
  schema_id          = mso_schema.hybrid_cloud.id
  template_name      = mso_schema.hybrid_cloud.template_name
  name               = "${var.name_prefix}SSH"
  display_name       = "SSH"
  entry_name         = "SSH"
  entry_display_name = "SSH"
  ether_type         = "ip"
  ip_protocol        = "tcp"
  destination_from   = "ssh"
  destination_to     = "ssh"
}

resource "mso_schema_template_filter_entry" "icmp" {
  schema_id          = mso_schema.hybrid_cloud.id
  template_name      = mso_schema.hybrid_cloud.template_name
  name               = "${var.name_prefix}ICMP"
  display_name       = "ICMP"
  entry_name         = "ICMP"
  entry_display_name = "ICMP"
  ether_type         = "ip"
  ip_protocol        = "icmp"
}
resource "mso_schema_template_filter_entry" "mysql" {
  schema_id          = mso_schema.hybrid_cloud.id
  template_name      = mso_schema.hybrid_cloud.template_name
  name               = "${var.name_prefix}MySQL"
  display_name       = "MySQL"
  entry_name         = "MySQL"
  entry_display_name = "MySQL"
  ether_type         = "ip"
  ip_protocol        = "tcp"
  destination_from   = "3306"
  destination_to     = "3306"
}

resource "mso_schema_template_contract" "contract_internet_web" {
  schema_id                = mso_schema.hybrid_cloud.id
  template_name            = mso_schema.hybrid_cloud.template_name
  contract_name            = "${var.name_prefix}Internet-to-Web"
  display_name             = "Internet-to-Web"
  filter_relationships     = {
    filter_schema_id     = mso_schema.hybrid_cloud.id
    filter_name          = mso_schema_template_filter_entry.http.name
    filter_template_name = mso_schema.hybrid_cloud.template_name
  }
  directives               = ["none"]
}

resource "mso_schema_template_contract_filter" "contract_internet_web_ssh" {
  schema_id     = mso_schema.hybrid_cloud.id
  template_name = mso_schema.hybrid_cloud.template_name
  contract_name = mso_schema_template_contract.contract_internet_web.contract_name
  filter_name   = mso_schema_template_filter_entry.ssh.name
  filter_type   = "bothWay"
  directives    = ["none"]
}

resource "mso_schema_template_contract_filter" "contract_internet_web_icmp" {
  schema_id     = mso_schema.hybrid_cloud.id
  template_name = mso_schema.hybrid_cloud.template_name
  contract_name = mso_schema_template_contract.contract_internet_web.contract_name
  filter_name   = mso_schema_template_filter_entry.icmp.name
  filter_type   = "bothWay"
  directives    = ["none"]
}

resource "mso_schema_template_contract" "contract_vms_internet" {
  schema_id              = mso_schema.hybrid_cloud.id
  template_name          = mso_schema.hybrid_cloud.template_name
  contract_name          = "${var.name_prefix}VMs-to-Internet"
  display_name           = "VMs-to-Internet"
  filter_relationships   = {
    filter_schema_id     = mso_schema.hybrid_cloud.id
    filter_name          = mso_schema_template_filter_entry.any.name
    filter_template_name = mso_schema.hybrid_cloud.template_name
  }
  directives             = ["none"]
}

resource "mso_schema_template_contract_filter" "contract_vms_internet_icmp" {
  schema_id     = mso_schema.hybrid_cloud.id
  template_name = mso_schema.hybrid_cloud.template_name
  contract_name = mso_schema_template_contract.contract_vms_internet.contract_name
  filter_name   = mso_schema_template_filter_entry.icmp.name
  filter_type   = "bothWay"
  directives    = ["none"]
}

resource "mso_schema_template_contract" "contract_web_db" {
  schema_id              = mso_schema.hybrid_cloud.id
  template_name          = mso_schema.hybrid_cloud.template_name
  contract_name          = "${var.name_prefix}Web-to-DB"
  display_name           = "Web-to-DB"
  filter_relationships   = {
    filter_schema_id     = mso_schema.hybrid_cloud.id
    filter_name          = mso_schema_template_filter_entry.mysql.name
    filter_template_name = mso_schema.hybrid_cloud.template_name
  }
  directives             = ["none"]
}

resource "mso_schema_template_contract_filter" "contract_web_db_icmp" {
  schema_id     = mso_schema.hybrid_cloud.id
  template_name = mso_schema.hybrid_cloud.template_name
  contract_name = mso_schema_template_contract.contract_web_db.contract_name
  filter_name   = mso_schema_template_filter_entry.icmp.name
  filter_type   = "bothWay"
  directives    = ["none"]
}

resource "mso_schema_template_l3out" "on_prem_l3out" {
  schema_id         = mso_schema.hybrid_cloud.id
  template_name     = mso_schema.hybrid_cloud.template_name
  l3out_name        = "On-Prem"
  display_name      = "On-Prem"
  vrf_name          = mso_schema_template_vrf.vrf1.name
  vrf_template_name = mso_schema.hybrid_cloud.template_name
}

resource "mso_schema_template_external_epg" "extepg_cloud_internet" {
  schema_id         = mso_schema.hybrid_cloud.id
  template_name     = mso_schema.hybrid_cloud.template_name
  external_epg_name = "Cloud-Internet"
  display_name      = "Cloud-Internet"
  external_epg_type = "cloud"
  vrf_name          = mso_schema_template_vrf.vrf1.name
  vrf_template_name = mso_schema.hybrid_cloud.template_name
  anp_name          = mso_schema_template_anp.anp.name
  selector_name     = "Internet"
  selector_ip       = "0.0.0.0/0"
  site_id           = [ 
    data.mso_site.aws.id,
    data.mso_site.azure.id,
    data.mso_site.on_premises.id
  ]
  depends_on = [
    mso_rest.aws_site,
    mso_rest.azure_site,
    mso_schema_site.on_premises_shared
  ]
}

resource "mso_schema_template_external_epg" "extepg_on_prem_internet" {
  schema_id         = mso_schema.hybrid_cloud.id
  template_name     = mso_schema.hybrid_cloud.template_name
  external_epg_name = "On-Prem-Internet"
  display_name      = "On-Prem-Internet"
  external_epg_type = "on-premise"
  vrf_name          = mso_schema_template_vrf.vrf1.name
  vrf_template_name = mso_schema.hybrid_cloud.template_name
  l3out_name        = mso_schema_template_l3out.on_prem_l3out.l3out_name
}

resource "mso_schema_template_external_epg_subnet" "extepg_on_prem_internet_subnet1" {
  schema_id         = mso_schema.hybrid_cloud.id
  template_name     = mso_schema.hybrid_cloud.template_name
  external_epg_name =  mso_schema_template_external_epg.extepg_on_prem_internet.external_epg_name
  ip                = "0.0.0.0/0"
  name              = "Internet"
  scope             = ["shared-rtctrl", "export-rtctrl"]
  aggregate         = ["shared-rtctrl", "export-rtctrl"]
}

resource "mso_schema_template_external_epg_contract" "extepg_cloud_internet_c1" {
  schema_id         = mso_schema.hybrid_cloud.id
  template_name     = mso_schema.hybrid_cloud.template_name
  contract_name     = mso_schema_template_contract.contract_internet_web.contract_name
  external_epg_name = mso_schema_template_external_epg.extepg_cloud_internet.external_epg_name
  relationship_type = "consumer"
}

resource "mso_schema_template_external_epg_contract" "extepg_cloud_internet_c2" {
  schema_id         = mso_schema.hybrid_cloud.id
  template_name     = mso_schema.hybrid_cloud.template_name
  contract_name     = mso_schema_template_contract.contract_vms_internet.contract_name
  external_epg_name = mso_schema_template_external_epg.extepg_cloud_internet.external_epg_name
  relationship_type = "provider"
}

resource "mso_schema_template_external_epg_contract" "extepg_on_prem_internet_c1" {
  schema_id         = mso_schema.hybrid_cloud.id
  template_name     = mso_schema.hybrid_cloud.template_name
  contract_name     = mso_schema_template_contract.contract_internet_web.contract_name
  external_epg_name = mso_schema_template_external_epg.extepg_on_prem_internet.external_epg_name
  relationship_type = "consumer"
}

resource "mso_schema_template_external_epg_contract" "extepg_on_prem_internet_c2" {
  schema_id         = mso_schema.hybrid_cloud.id
  template_name     = mso_schema.hybrid_cloud.template_name
  contract_name     = mso_schema_template_contract.contract_vms_internet.contract_name
  external_epg_name = mso_schema_template_external_epg.extepg_on_prem_internet.external_epg_name
  relationship_type = "provider"
}

resource "mso_schema_template_anp_epg_contract" "epg_web_c1" {
  schema_id              = mso_schema.hybrid_cloud.id
  template_name          = mso_schema.hybrid_cloud.template_name
  anp_name               = mso_schema_template_anp.anp.name
  epg_name               = mso_schema_template_anp_epg.web.name
  contract_name          = mso_schema_template_contract.contract_internet_web.contract_name
  contract_template_name = mso_schema.hybrid_cloud.template_name
  relationship_type      = "provider"
}

resource "mso_schema_template_anp_epg_contract" "epg_web_c2" {
  schema_id              = mso_schema.hybrid_cloud.id
  template_name          = mso_schema.hybrid_cloud.template_name
  anp_name               = mso_schema_template_anp.anp.name
  epg_name               = mso_schema_template_anp_epg.web.name
  contract_name          = mso_schema_template_contract.contract_vms_internet.contract_name
  contract_template_name = mso_schema.hybrid_cloud.template_name
  relationship_type      = "consumer"
}

resource "mso_schema_template_anp_epg_contract" "epg_web_c3" {
  schema_id              = mso_schema.hybrid_cloud.id
  template_name          = mso_schema.hybrid_cloud.template_name
  anp_name               = mso_schema_template_anp.anp.name
  epg_name               = mso_schema_template_anp_epg.web.name
  contract_name          = mso_schema_template_contract.contract_web_db.contract_name
  contract_template_name = mso_schema.hybrid_cloud.template_name
  relationship_type      = "consumer"
}

resource "mso_schema_template_anp_epg_contract" "epg_db_c1" {
  schema_id              = mso_schema.hybrid_cloud.id
  template_name          = mso_schema.hybrid_cloud.template_name
  anp_name               = mso_schema_template_anp.anp.name
  epg_name               = mso_schema_template_anp_epg.db.name
  contract_name          = mso_schema_template_contract.contract_web_db.contract_name
  contract_template_name = mso_schema.hybrid_cloud.template_name
  relationship_type      = "provider"
}

resource "mso_schema_template_anp_epg_contract" "epg_db_c2" {
  schema_id              = mso_schema.hybrid_cloud.id
  template_name          = mso_schema.hybrid_cloud.template_name
  anp_name               = mso_schema_template_anp.anp.name
  epg_name               = mso_schema_template_anp_epg.db.name
  contract_name          = mso_schema_template_contract.contract_vms_internet.contract_name
  contract_template_name = mso_schema.hybrid_cloud.template_name
  relationship_type      = "consumer"
}

resource "mso_schema_template_anp_epg_selector" "web" {
  schema_id     = mso_schema.hybrid_cloud.id
  template_name = mso_schema.hybrid_cloud.template_name
  anp_name      = mso_schema_template_anp.anp.name
  epg_name      = mso_schema_template_anp_epg.web.name
  name          = "Web"
  expressions {
    key         = "Custom:EPG"
    operator    = "equals"
    value       = "Web"
  }
}