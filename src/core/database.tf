data "azurerm_key_vault" "temporal" {
  name                = "${var.prefix}-${var.env_short}-temporal-test"
  resource_group_name = "${var.prefix}-${var.env_short}-temporal-rg"
}
###################################
# Database Reminder Mysql
###################################
data "azurerm_key_vault_secret" "temporal_mysql_db_server_adm_username" {
  name         = "${var.prefix}-${var.env_short}-TEMPORAL-TEST-MYSQL-DB-ADM-USERNAME"
  key_vault_id = data.azurerm_key_vault.temporal.id
}
data "azurerm_key_vault_secret" "temporal_mysql_db_server_adm_password" {
  name         = "${var.prefix}-${var.env_short}-TEMPORAL-TEST-MYSQL-DB-ADM-PASSWORD"
  key_vault_id = data.azurerm_key_vault.temporal.id
}

resource "azurerm_private_dns_zone" "temporal-test" {
  name                = "temporal.test.mysql.database.azure.com"
  resource_group_name = "${var.prefix}-${var.env_short}-temporal-rg"
}

resource "azurerm_virtual_network" "temporal-vn" {
  name                = "temporal-vn"
  location            = var.location
  resource_group_name = "${var.prefix}-${var.env_short}-temporal-rg"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "temporal-subnet" {
  name                 = "temporal-sn"
  resource_group_name  = "${var.prefix}-${var.env_short}-temporal-rg"
  virtual_network_name = azurerm_virtual_network.temporal-vn.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_mysql_flexible_server" "temporal_mysql_server" {
  name                   = "${var.prefix}-${var.env_short}-temporal-mysql-fn-admin"
  location               = var.location
  resource_group_name    = "${var.prefix}-${var.env_short}-temporal-rg"
  administrator_login    = data.azurerm_key_vault_secret.temporal_mysql_db_server_adm_username.value
  administrator_password = data.azurerm_key_vault_secret.temporal_mysql_db_server_adm_password.value
  backup_retention_days  = 7
  private_dns_zone_id    = azurerm_private_dns_zone.temporal-test.id
  delegated_subnet_id    = azurerm_subnet.temporal-subnet.id
  version                = "8.0.21"
  sku_name               = "B_Standard_B1ms"
  zone                   = "3"
}
