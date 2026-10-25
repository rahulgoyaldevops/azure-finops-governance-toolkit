# ============================================================================
# FinOps Governance â€” Mandatory Resource Tagging Policy as Code
# Senior DevOps Engineer: Rahul Goyal
# ============================================================================

variable "mandatory_tags" {
  description = "List of mandatory tags for financial accounting and operational ownership"
  type        = list(string)
  default     = ["Environment", "CostCenter", "Owner", "ApplicationID", "ManagedBy"]
}

resource "azurerm_policy_definition" "enforce_mandatory_tags" {
  for_each     = toset(var.mandatory_tags)
  name         = "finops-enforce-tag-${lower(each.value)}"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "FinOps Governance: Deny deployment without '${each.value}' tag"
  description  = "Prevents untagged cloud resource leakage. Enforces '${each.value}' tag on all deployable resources."

  metadata = jsonencode({
    category = "Cost Governance & FinOps"
    version  = "2.0.0"
    author   = "Rahul Goyal"
  })

  policy_rule = jsonencode({
    if = {
      field  = "[concat('tags[', '${each.value}', ']')]"
      exists = "false"
    }
    then = {
      effect = "deny"
    }
  })
}
