resource "azurerm_resource_group" "basics" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_group" "example" {
  name                = var.container_group_name
  location            = azurerm_resource_group.basics.location
  resource_group_name = azurerm_resource_group.basics.name
  ip_address_type     = "Public"
  dns_name_label      = "${var.prefix}-${var.container_group_name}"
  os_type             = "Linux"

  container {
    name   = "inspectorgadget"
    image  = "jelledruyts/inspectorgadget:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}

