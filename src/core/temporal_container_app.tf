resource "azurerm_log_analytics_workspace" "temporal_log_analytics" {
  name                = "temporal-log-analytics"
  location            = var.location
  resource_group_name = "${var.prefix}-${var.env_short}-temporal-rg"
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "temporal_container_app_env" {
  resource_group_name        = "${var.prefix}-${var.env_short}-temporal-rg"
  location                   = var.location
  name                       = "${var.prefix}-${var.env_short}-temporal-container-app-env"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.temporal_log_analytics.id
}

resource "azurerm_container_app" "temporal_container_app" {
  name                         = "temporal-fn-admin-example"
  container_app_environment_id = azurerm_container_app_environment.temporal_container_app_env.id
  resource_group_name          = "${var.prefix}-${var.env_short}-temporal"
  revision_mode                = "Single"

  template {
    container {
      name = "temporal-cluster"
      // linux/amd64 image
      image  = "temporalio/server@sha256:55a4cab7ad719b4b678e575226558c7a89bdec1f33839b65de2bcd3e0e03a2d4"
      cpu    = 0.25
      memory = "1Gi"
      // MYSQL VARIABLES
      env {
        name  = "DB"
        value = "mysql"
      }
      env {
        name  = "MYSQL_SEEDS"
        value = azurerm_mysql_flexible_server.temporal_mysql_server.fqdn
      }
      env {
        name        = "MYSQL_USER"
        secret_name = data.azurerm_key_vault_secret.temporal_mysql_db_server_adm_username.value
      }
      env {
        name        = "MYSQL_PWD"
        secret_name = data.azurerm_key_vault_secret.temporal_mysql_db_server_adm_password.value
      }
      env {
        name  = "DB_PORT"
        value = 3306
      }
      env {
        name  = "AUTO_SETUP"
        value = "true"
      }
    }

    container {
      name   = "temporal-worker-fn-admin"
      image  = "ghcr.io/arcogabbo/io-functions-admin-temporal@sha256:a145c262282333e739b3149e7e31ed9993b2912646b2723ebd1cf3cdeaf0a3ef"
      cpu    = 0.50
      memory = "0.5Gi"
    }

    /* container { */
    /*   // TEMPORAL WEB-UI */
    /*   name = "temporal-ui" */
    /*   // linux/amd64 image */
    /*   image  = "temporalio/ui@sha256:d97ef6fa98d5f77950054b7ea5f1a18b291657a78bf30191ba2c2fb5fcc23d9f" */
    /*   cpu    = 0.25 */
    /*   memory = "0.5Gi" */
    /* } */
  }
}
