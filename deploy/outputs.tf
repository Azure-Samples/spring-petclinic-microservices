output "app_insights_id" {
  value = azurerm_application_insights.appinsights.id
  description = "Application insights id for Azure Spring Cloud deployed instance. Terraform provider doesn't support yet linking ASC to AppInsights"
}
