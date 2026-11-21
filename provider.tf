###############################################################################
# provider.tf
# Provider + version constraints for the Azure Subscription Vending module.
#
# Authentication: Federated credentials (OIDC) via TFE/HCP Terraform
# "Dynamic Provider Credentials". NO client secret anywhere.
#
# Set these on the workspace / project-level Variable Set (environment vars):
#   TFC_AZURE_PROVIDER_AUTH = true
#   TFC_AZURE_RUN_CLIENT_ID = <app registration / UAMI client id>
#   ARM_TENANT_ID           = <tenant guid>
#   ARM_SUBSCRIPTION_ID     = <any existing "home" subscription guid>
# (For self-hosted TFE also set TFC_AZURE... / audience as per your TFE setup.)
#
# On the Entra app / UAMI add a Federated Credential:
#   Issuer   : https://<your-tfe-hostname>
#   Subject  : organization:<ORG>:project:<PROJECT>:workspace:<WORKSPACE>:run_phase:<plan|apply>
#   Audience : api://AzureADTokenExchange
# No-code creates a new workspace per request, so a fixed subject won't match
# new workspaces. Use a flexible federated credential (claims matching
# expression, e.g. subject starts with organization:<ORG>:project:<PROJECT>:)
# or pre-create the workspaces.
#
# Identity permissions required:
#   - Billing role "Azure subscription creator" on the billing scope
#   - "Management Group Contributor" on the target management group
#   - Owner / User Access Administrator on the new subscription
#     (inherited from the management group)
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  # Federated (OIDC) auth. TFE injects the token / client id via the
  # TFC_AZURE_* variables above.
  use_oidc = true

  # Subscription is created by this module, so don't auto-register RPs
  # against the "home" subscription.
  resource_provider_registrations = "none"
}
