# ============================================================================
# FinOps & Security Policy: Deny Unapproved Public IP Creation
# Architect: Rahul Goyal
# ============================================================================

resource "azurerm_policy_definition" "deny_public_ip" {
  name         = "finops-deny-public-ips"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "FinOps Governance: Deny Public IP creation in workload spoke subscriptions"
  description  = "Restricts Public IP creation to prevent both security exposure and rogue egress/allocation billing."

  metadata = jsonencode({
    category = "Cost Governance & Security"
    version  = "1.1.0"
    author   = "Rahul Goyal"
  })

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Network/publicIPAddresses"
    }
    then = {
      effect = "deny"
    }
  })
}