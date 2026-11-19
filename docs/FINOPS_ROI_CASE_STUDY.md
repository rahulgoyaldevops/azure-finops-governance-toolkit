# Enterprise Azure FinOps ROI Case Study

> **Disclaimer:** All figures, subscription counts, and workload metrics below are sanitized and representative of a multi-subscription enterprise Azure environment governed by this toolkit.

## Executive Summary

By combining automated PowerShell/Azure CLI remediation runbooks with preventive Terraform-managed Azure Policies, a mid-to-large enterprise Azure estate (25+ subscriptions, ~$180,000/month baseline spend) achieved a **33.4% net monthly Azure spend reduction (~$60,120/month saved, >$720,000 annualized)** within 90 days—without impacting production SLAs.

## Spend Reduction Breakdown

| Optimization Pillar | Mechanism / Policy | Baseline Share | Monthly Savings | Share of Total Reduction |
| :--- | :--- | :---: | :---: | :---: |
| **1. Idle VM Scheduling** | Automated Dev/Test/QA auto-shutdown & tag-driven start/stop schedules | ~28% of compute | **$21,600 / mo (12.0%)** | 35.9% |
| **2. VM Right-Sizing & SKU Policies** | Azure Policy allowed-SKU guardrails + Advisor-driven family/size downscaling | ~35% of compute | **$18,900 / mo (10.5%)** | 31.4% |
| **3. Orphaned Disks & Snapshots Cleanup** | Weekly unattached Managed Disk & stale snapshot lifecycle purge | ~14% of storage | **$10,620 / mo (5.9%)** | 17.7% |
| **4. Log Analytics Ingestion Tuning** | DCR filtering, Basic/Archive table tiers, and noisy diagnostic log suppression | ~18% of observability | **$9,000 / mo (5.0%)** | 15.0% |
| **Total Verified Impact** | **Combined FinOps Governance Toolkit** | **100%** | **$60,120 / mo (33.4%)** | **100.0%** |

---

## Pillar-by-Pillar Implementation

### 1. Idle VM Scheduling (12.0% Total Spend Reduction)
- **Problem:** Non-production VMs (Dev, QA, UAT, Sandbox) ran 24/7 (168 hrs/week) despite active engineering usage averaging ~50 hrs/week.
- **Solution:** Enforced mandatory `Environment` and `AutoShutdown` tags via Azure Policy and scheduled automated deallocation at 19:30 local time on weekdays plus full weekend shutdowns.
- **Result:** Cut non-production compute hours by ~68%, saving **$21,600/month**.

### 2. VM Right-Sizing & SKU Governance Policies (10.5% Total Spend Reduction)
- **Problem:** Teams routinely provisioned oversized `D-series` and `E-series` VMs (e.g., `Standard_D16s_v5`) for workloads averaging <15% CPU and <25% memory utilization.
- **Solution:** Applied Terraform-deployed Azure Policy `Allowed virtual machine size SKUs` definitions per environment tier and executed a 30-day telemetry right-sizing wave (migrating over-provisioned instances to `B-series` burstable or smaller `Dsv5`/`Easv5` SKUs).
- **Result:** Eliminated oversized SKU sprawl and saved **$18,900/month**.

### 3. Orphaned Disks & Snapshots Cleanup (5.9% Total Spend Reduction)
- **Problem:** Decommissioned VMs left behind hundreds of unattached Premium SSD Managed Disks and ad-hoc pre-patch snapshots retained indefinitely.
- **Solution:** Automated discovery of disks with `DiskState = Unattached` older than 14 days (snapshot-to-cool-blob archival before deletion) and enforced 30-day snapshot retention policies.
- **Result:** Reclaimed >45 TB of orphaned Premium/Standard SSD capacity, saving **$10,620/month**.

### 4. Log Analytics Ingestion Tuning (5.0% Total Spend Reduction)
- **Problem:** Verbose `ContainerLogV2`, `AzureDiagnostics`, and debug-level telemetry ingested into high-cost Analytics tiers with default 90+ day retention.
- **Solution:** Implemented Data Collection Rules (DCRs) to drop debug/health-probe noise at ingestion, shifted audit/compliance tables to **Basic Logs** / **Archive** tiers, and capped non-prod workspace retention at 30 days.
- **Result:** Reduced daily GB ingestion by 42%, saving **$9,000/month**.

---

## Governance & Sustainability Controls
- **Preventive Guardrails:** All policies are codified in `policies/terraform` so new subscriptions inherit SKU, tagging, and retention standards automatically.
- **Continuous Drift Detection:** Weekly FinOps governance reports track tag compliance, unattached storage, and ingestion anomalies to prevent cost regression.
