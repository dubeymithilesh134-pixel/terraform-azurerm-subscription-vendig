###############################################################################
# outputs.tf
###############################################################################

output "subscription_id" {
  description = "GUID of the newly created subscription."
  value       = azurerm_subscription.this.subscription_id
}

output "subscription_resource_id" {
  description = "Full resource ID: /subscriptions/<guid>."
  value       = "/subscriptions/${azurerm_subscription.this.subscription_id}"
}

output "subscription_name" {
  description = "Display name of the subscription."
  value       = azurerm_subscription.this.subscription_name
}

output "subscription_alias" {
  description = "Alias used to create the subscription."
  value       = azurerm_subscription.this.alias
}

output "tenant_id" {
  description = "Tenant the subscription belongs to."
  value       = azurerm_subscription.this.tenant_id
}

output "management_group_id" {
  description = "Management group the subscription was placed in."
  value       = azurerm_management_group_subscription_association.this.management_group_id
}

output "applied_tags" {
  description = "Final merged tags on the subscription."
  value       = azurerm_subscription.this.tags
}

output "rbac_assignment_ids" {
  description = "Role assignment IDs created on the subscription."
  value       = { for k, v in azurerm_role_assignment.this : k => v.id }
}

output "policy_assignment_ids" {
  description = "Policy assignment IDs created on the subscription."
  value       = { for k, v in azurerm_subscription_policy_assignment.this : k => v.id }
}

output "budget_id" {
  description = "Budget resource ID (null when no budget was created)."
  value       = try(azurerm_consumption_budget_subscription.this[0].id, null)
}
