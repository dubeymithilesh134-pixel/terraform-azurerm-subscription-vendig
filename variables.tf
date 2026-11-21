###############################################################################
# variables.tf
# Inputs for the Azure Subscription Vending module.
# Numbering (#1..#19) matches the subscription_details sheet.
# Mandatory = no default. Recommended / optional = safe default.
###############################################################################

# ----------------------------- MANDATORY -------------------------------------

# 1 - Mandatory
variable "subscription_name" {
  description = "Display name of the subscription. Example: corp-prod-finops-01"
  type        = string

  validation {
    condition     = length(trimspace(var.subscription_name)) >= 3 && length(var.subscription_name) <= 64
    error_message = "subscription_name must be between 3 and 64 characters."
  }
}

# 2 - Mandatory
variable "billing_scope_id" {
  description = "Billing scope used to create the subscription. Example: /providers/Microsoft.Billing/billingAccounts/<id>/enrollmentAccounts/<id> (EA), or .../billingProfiles/<id>/invoiceSections/<id> (MCA)."
  type        = string

  validation {
    condition     = can(regex("^/providers/Microsoft\\.Billing/billingAccounts/.+", var.billing_scope_id))
    error_message = "billing_scope_id must start with /providers/Microsoft.Billing/billingAccounts/."
  }
}

# 3 - Mandatory
variable "workload" {
  description = "Subscription workload type. Allowed: Production or DevTest."
  type        = string

  validation {
    condition     = contains(["Production", "DevTest"], var.workload)
    error_message = "workload must be either \"Production\" or \"DevTest\"."
  }
}

# 4 - Mandatory
variable "management_group_id" {
  description = "Target management group. Accepts the short name (corp-production) or the full ID (/providers/Microsoft.Management/managementGroups/corp-production)."
  type        = string

  validation {
    condition     = length(trimspace(var.management_group_id)) > 0
    error_message = "management_group_id must not be empty."
  }
}

# 5 - Mandatory
variable "tags" {
  description = "Base tags applied to the subscription. Example: { Environment = \"Prod\", CostCenter = \"1234\" }. Governance tags below (environment, cost_center, ...) are merged on top."
  type        = map(string)

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags is mandatory - provide at least one tag (e.g. Environment, CostCenter)."
  }
}

# ----------------------------- RECOMMENDED -----------------------------------

# 6 - Recommended
variable "subscription_alias" {
  description = "Alias name of the subscription (ARM alias resource name). Defaults to subscription_name when null. Example: corp-prod-finops-01"
  type        = string
  default     = null
}

# 7 - Recommended
variable "subscription_owner_id" {
  description = "Entra ID object ID (user / group / SPN) granted Owner on the new subscription."
  type        = string
  default     = null

  validation {
    condition     = var.subscription_owner_id == null || can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.subscription_owner_id))
    error_message = "subscription_owner_id must be a valid GUID (Entra object ID)."
  }
}

# 8 - Useful for multi-tenant scenarios
variable "subscription_tenant_id" {
  description = "Tenant GUID the subscription must belong to. If set, the module fails when the authenticated tenant differs (guards multi-tenant mistakes). Null = skip check."
  type        = string
  default     = null

  validation {
    condition     = var.subscription_tenant_id == null || can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.subscription_tenant_id))
    error_message = "subscription_tenant_id must be a valid GUID."
  }
}

# 9 - Recommended
variable "budget_amount" {
  description = "Monthly budget in subscription billing currency. 0 = no budget created. Example: 5000"
  type        = number
  default     = 0

  validation {
    condition     = var.budget_amount >= 0
    error_message = "budget_amount cannot be negative."
  }
}

# 10 - Recommended
variable "budget_notification_emails" {
  description = "Email addresses notified on budget thresholds. Example: [\"finops-dl@contoso.com\"]. Required for the budget to be created."
  type        = list(string)
  default     = []
}

# 11 - Recommended
variable "rbac_assignments" {
  description = "Extra RBAC assignments on the subscription. role = Owner / Contributor / Reader (or any built-in/custom role name). Example: [{ principal_id = \"<objectId>\", role = \"Reader\" }]"
  type = list(object({
    principal_id = string
    role         = string
  }))
  default = []
}

# 12 - Recommended
variable "policy_assignment_ids" {
  description = "Policy definition or initiative (policy set) resource IDs to assign at subscription scope."
  type        = list(string)
  default     = []
}

# 13 - Recommended
variable "environment" {
  description = "Environment name. Allowed: dev, test, uat, prod. Written to the 'Environment' tag."
  type        = string
  default     = null

  validation {
    condition     = var.environment == null || contains(["dev", "test", "uat", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, uat, prod."
  }
}

# 14 - Mandatory (per governance sheet) - kept optional-with-null here so the
# no-code form doesn't hard-block; enforced by the precondition in main.tf.
variable "cost_center" {
  description = "Cost center code. Example: CC12345. Written to the 'CostCenter' tag. MANDATORY per governance sheet."
  type        = string
  default     = null
}

# 15 - Recommended
variable "application_id" {
  description = "Application ID / project code. Example: APP00123. Written to the 'ApplicationId' tag."
  type        = string
  default     = null
}

# 16 - Mandatory (per governance sheet)
variable "business_owner" {
  description = "Business owner (owner / DL). Written to the 'BusinessOwner' tag. MANDATORY per governance sheet."
  type        = string
  default     = null
}

# 17 - Mandatory (per governance sheet)
variable "technical_owner" {
  description = "Technical owner (platform / app owner). Written to the 'TechnicalOwner' tag. MANDATORY per governance sheet."
  type        = string
  default     = null
}

# 18 - Depending on governance
variable "data_classification" {
  description = "Data classification. Example: Internal or Confidential. Written to the 'DataClassification' tag."
  type        = string
  default     = null
}

# 19 - Only where applicable
variable "reseller_id" {
  description = "Partner / reseller ID. Only for CSP / reseller-billed subscriptions. Written to the 'ResellerId' tag."
  type        = string
  default     = null
}
