module "temporal_test" {
  source = "git::https://github.com/pagopa/terraform-azurerm-v3//container_app_environment?ref=v6.2.2"

}

resource "azurerm_container_app_environment" "temporal_container_app_env" {
  resource_group_name        = "io-d-temporal"
  location                   = var.location
  name                       = "io-${var.env_short}-temporal-container-app-env"
  log_analytics_workspace_id = var.log_analytics_workspace_id
}

resource "azurerm_container_app" "temporal_container_app" {
  name                         = "temporal_example"
  container_app_environment_id = azurerm_container_app_environment.temporal_container_app_env.id
  resource_group_name          = "io-d-temporal"
  revision_mode                = "Single"

  template {
    container {
      name   = "temporal-cluster"
      image  = "temporalio/server:1.20.1.0"
      cpu    = 0.25
      memory = "0.5Gi"
    }

    container {
      name   = "temporal-worker-fn-admin"
      image  = "CHANGEME"
      cpu    = 0.50
      memory = "0.5Gi"
    }
  }
}
