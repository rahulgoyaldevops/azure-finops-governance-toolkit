<div align="center">

# 💰 Azure FinOps & Governance Toolkit

[![Azure](https://img.shields.io/badge/Azure-Cost_Management-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![FinOps](https://img.shields.io/badge/FinOps-Certified-00C853?style=for-the-badge)](https://www.finops.org/)
[![Terraform](https://img.shields.io/badge/Terraform-Policy_as_Code-623CE4?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![PowerShell](https://img.shields.io/badge/PowerShell-Automation-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://docs.microsoft.com/en-us/powershell/)

**Automated cost optimization, governance policies, and FinOps practices for enterprise Azure environments.**

*Saving real money in production — not just dashboards.*

</div>

---

## 🎯 The Problem

> Azure costs spiral out of control when teams provision resources without guardrails.
> Idle VMs run 24/7, unattached disks accumulate, oversized instances waste budget,
> and nobody knows who owns what. This toolkit fixes that.

## 💡 FinOps Lifecycle

```
┌──────────────────────────────────────────────────────────────────┐
│                        FinOps Framework                           │
│                                                                   │
│  ┌────────────┐      ┌─────────────┐      ┌────────────────┐    │
│  │  INFORM    │─────▶│  OPTIMIZE   │─────▶│   OPERATE      │    │
│  │            │      │             │      │                │    │
│  │ • Tagging  │      │ • Right-    │      │ • Reserved     │    │
│  │   Enforce  │      │   sizing    │      │   Instances    │    │
│  │ • Cost     │      │ • Idle VM   │      │ • Auto Start/  │    │
│  │   Alerts   │      │   cleanup   │      │   Stop         │    │
│  │ • Budget   │      │ • Orphaned  │      │ • Scheduled    │    │
│  │   Tracking │      │   disks     │      │   Scaling      │    │
│  │ • Show-    │      │ • Log       │      │ • Commitment   │    │
│  │   back     │      │   ingestion │      │   Management   │    │
│  │            │      │   tuning    │      │                │    │
│  └────────────┘      └─────────────┘      └────────────────┘    │
│                                                                   │
│  🔄 Continuous: Review → Optimize → Govern → Repeat              │
└──────────────────────────────────────────────────────────────────┘
```

## 📁 Repository Structure

```
azure-finops-governance-toolkit/
│
├── scripts/
│   ├── find-idle-resources.ps1          # Detect idle VMs (CPU < 5% for 14 days)
│   ├── find-unattached-disks.ps1        # Find orphaned managed disks
│   ├── find-oversized-vms.ps1           # Identify VMs using < 20% capacity
│   ├── auto-start-stop-vms.ps1          # Schedule VM start/stop (non-prod)
│   ├── cleanup-old-snapshots.ps1        # Remove snapshots older than N days
│   └── tag-compliance-report.ps1        # Report resources missing required tags
│
├── policies/
│   ├── terraform/
│   │   ├── require-tags.tf              # Enforce mandatory tagging policy
│   │   ├── allowed-vm-sizes.tf          # Restrict VM SKUs per environment
│   │   ├── deny-public-ip.tf           # Block public IP creation
│   │   ├── enforce-https.tf             # Require HTTPS on storage/web
│   │   └── allowed-regions.tf           # Restrict to approved Azure regions
│   │
│   └── azure-policy/
│       ├── tagging-initiative.json       # Azure Policy initiative for tagging
│       ├── cost-management.json          # Cost-related policy definitions
│       └── security-baseline.json        # CIS security baseline policies
│
├── dashboards/
│   ├── cost-overview.json               # Azure Dashboard — cost by resource group
│   ├── idle-resources.json              # Dashboard — idle/underutilized resources
│   └── tag-compliance.json              # Dashboard — tagging compliance %
│
├── alerts/
│   ├── budget-alert.tf                  # Terraform — budget threshold alerts
│   ├── anomaly-detection.tf             # Cost anomaly alert rules
│   └── resource-creation-alert.tf       # Alert on untagged resource creation
│
├── docs/
│   ├── FINOPS_PRACTICES.md              # FinOps implementation guide
│   ├── TAGGING_STANDARD.md              # Enterprise tagging convention
│   └── COST_REVIEW_RUNBOOK.md           # Weekly cost review process
│
└── README.md
```

## 🔍 Cost Optimization Scripts

### Find Idle Virtual Machines
```powershell
# Identifies VMs with average CPU < 5% over the last 14 days
# These are candidates for shutdown, resize, or decommission

$idleVMs = Get-AzVM -Status | Where-Object {
    $_.PowerState -eq 'VM running'
} | ForEach-Object {
    $metrics = Get-AzMetric -ResourceId $_.Id `
        -MetricName "Percentage CPU" `
        -StartTime (Get-Date).AddDays(-14) `
        -EndTime (Get-Date) `
        -AggregationType Average
    
    $avgCPU = ($metrics.Data | Measure-Object -Property Average -Average).Average
    
    if ($avgCPU -lt 5) {
        [PSCustomObject]@{
            VMName       = $_.Name
            ResourceGroup = $_.ResourceGroupName
            Size         = $_.HardwareProfile.VmSize
            AvgCPU       = [math]::Round($avgCPU, 2)
            MonthlyCost  = "Check Azure Pricing Calculator"
            Action       = "Candidate for shutdown/resize"
        }
    }
}

$idleVMs | Format-Table -AutoSize
```

### Find Unattached Managed Disks
```powershell
# Orphaned disks = wasted money. Find and clean them up.

$unattachedDisks = Get-AzDisk | Where-Object {
    $_.DiskState -eq 'Unattached'
} | Select-Object Name, ResourceGroupName, DiskSizeGB, 
    @{N='MonthlyCostEstUSD';E={$_.DiskSizeGB * 0.04}}, # ~$0.04/GB/month for Standard
    TimeCreated

Write-Host "Found $($unattachedDisks.Count) unattached disks"
Write-Host "Estimated monthly waste: `$$(($unattachedDisks | Measure-Object -Property MonthlyCostEstUSD -Sum).Sum)"
$unattachedDisks | Format-Table -AutoSize
```

## 🏷️ Tagging Standard

| Tag Key | Required | Example | Purpose |
|:--|:--|:--|:--|
| `Environment` | ✅ Yes | `Production`, `UAT`, `Dev` | Environment identification |
| `CostCenter` | ✅ Yes | `CC-12345` | Chargeback/showback |
| `Owner` | ✅ Yes | `rahul.goyal@company.com` | Accountability |
| `Application` | ✅ Yes | `payment-gateway` | Application mapping |
| `ManagedBy` | ✅ Yes | `Terraform`, `Manual` | IaC tracking |
| `ExpiryDate` | ⚠️ Conditional | `2025-12-31` | For temporary resources |
| `DataClassification` | ⚠️ Conditional | `Confidential`, `Public` | Security classification |

## 📊 Key Metrics Tracked

| Metric | Target | Tool |
|:--|:--|:--|
| Idle VM % | < 5% of total VMs | PowerShell script |
| Unattached disk count | 0 | PowerShell script |
| Tag compliance % | > 95% | Azure Policy |
| Reserved instance coverage | > 70% | Azure Cost Management |
| Month-over-month cost change | < 10% growth | Budget alerts |
| Cost per application | Trending down | Showback reports |

## 🚀 Quick Start

```bash
# Clone the repo
git clone https://github.com/rahulgoyaldevops/azure-finops-governance-toolkit.git

# Run idle resource detection
Connect-AzAccount
./scripts/find-idle-resources.ps1

# Deploy tagging policies via Terraform
cd policies/terraform
terraform init && terraform apply
```

---

<div align="center">

**Built by [Rahul Goyal](https://github.com/rahulgoyaldevops)** — Enterprise Cloud Architect | 14+ Years

*"The cloud bill is a technical problem, not just a finance problem."*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Rahul_Goyal-0A66C2?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/rahulgoyaldevops/)

</div>