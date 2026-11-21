###############################################################################
# main.tf
# Azure Subscription Vending: creates the subscription, places it in a
# management group, applies tags, owner/RBAC, policy and budget.
###############################################################################

data "azurerm_client_config" "current" {}

locals {
  # Accept short MG name or full resource ID.
  management_group_id = startswith(var.management_group_id, "/providers/Microsoft.Management/managementGroups/") ? var.management_group_id : "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"

  # Alias defaults to the subscription name.
  subscription_alias = coalesce(var.subscription_alias, var.subscription_name)

  # Governance tags (only non-null values). Merged OVER the base tags so the
  # explicit governance inputs win.
  governance_tags = {
    for k, v in {
      Environment        = var.environment
      CostCenter         = var.cost_center
      ApplicationId      = var.application_id
      BusinessOwner      = var.business_owner
      TechnicalOwner     = var.technical_owner
      DataClassification = var.data_classification
      ResellerId         = var.reseller_id
    } : k => v if v != null && v != ""
  }

  tags = merge(var.tags, local.governance_tags)

  # Owner + additional RBAC, keyed for stable for_each.
  rbac_assignments = merge(
    var.subscription_owner_id == null ? {} : {
      "Owner-${var.subscription_owner_id}" = {
        principal_id = var.subscription_owner_id
        role         = "Owner"
      }
    },
    { for a in var.rbac_assignments : "${a.role}-${a.principal_id}" => a }
  )

  policy_assignments = { for id in var.policy_assignment_ids : basename(id) => id }

  create_budget = var.budget_amount > 0 && length(var.budget_notification_emails) > 0

  subscription_id   = azurerm_subscription.this.subscription_id
  subscription_path = "/subscriptions/${azurerm_subscription.this.subscription_id}"
}

# ---------------------------------------------------------------------------
# 1. Subscription (alias + billing scope + workload + tags)
# ---------------------------------------------------------------------------
resource "azurerm_subscription" "this" {
  alias             = local.subscription_alias
  subscription_name = var.subscription_name
  billing_scope_id  = var.billing_scope_id
  workload          = var.workload
  tags              = local.tags

  lifecycle {
    # Governance mandatory tags (sheet rows 14, 16, 17).
    precondition {
      condition     = var.cost_center != null && var.business_owner != null && var.technical_owner != null
      error_message = "cost_center, business_owner and technical_owner are mandatory per governance."
    }

    # Multi-tenant guard (sheet row 8).
    precondition {
      condition     = var.subscription_tenant_id == null || lower(var.subscription_tenant_id) == lower(data.azurerm_client_config.current.tenant_id)
      error_message = "Authenticated tenant does not match subscription_tenant_id."
    }
  }
}

# ---------------------------------------------------------------------------
# 2. Management group placement
# ---------------------------------------------------------------------------
resource "azurerm_management_group_subscription_association" "this" {
  management_group_id = local.management_group_id
  subscription_id     = local.subscription_path
}

# ---------------------------------------------------------------------------
# 3. RBAC (owner + extra assignments)
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "this" {
  for_each = local.rbac_assignments

  scope                = local.subscription_path
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id

  depends_on = [azurerm_management_group_subscription_association.this]
}

# ---------------------------------------------------------------------------
# 4. Policy / initiative assignments
# ---------------------------------------------------------------------------
resource "azurerm_subscription_policy_assignment" "this" {
  for_each = local.policy_assignments

  # Assignment name max length is 64.
  name                 = substr(each.key, 0, 64)
  subscription_id      = local.subscription_path
  policy_definition_id = each.value

  # Needed by policies with deployIfNotExists / modify effects.
  identity {
    type = "SystemAssigned"
  }
  location = "centralindia"

  depends_on = [azurerm_management_group_subscription_association.this]
}

# ---------------------------------------------------------------------------
# 5. Monthly budget + notifications at 80% / 100% actual and 100% forecast
# ---------------------------------------------------------------------------
resource "azurerm_consumption_budget_subscription" "this" {
  count = local.create_budget ? 1 : 0

  name            = "budget-${var.subscription_name}"
  subscription_id = local.subscription_path
  amount          = var.budget_amount
  time_grain      = "Monthly"

  time_period {
    # Must be the first day of a month; set once at creation.
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.budget_notification_emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.budget_notification_emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = var.budget_notification_emails
  }

  lifecycle {
    # timestamp() changes every run; keep the original start date.
    ignore_changes = [time_period]
  }

  depends_on = [azurerm_management_group_subscription_association.this]
}
