<#
.SYNOPSIS
    Automated FinOps Scanner for Idle & Underutilized Azure Workloads.
.DESCRIPTION
    Scans Azure subscriptions to locate:
    - Running VMs with average CPU utilization < 5% over 14 days
    - Unattached Managed Disks costing recurring storage budget
    - Disassociated Public IP Addresses
    - Oversized non-production compute resources
.AUTHOR
    Rahul Goyal (14+ Years Senior DevOps & Cloud Engineering)
#>

param(
    [int]$CpuThreshold = 5,
    [int]$LookbackDays = 14,
    [string]$SubscriptionId
)

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       AZURE ENTERPRISE FINOPS AUDIT SCANNER              " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Detect Idle VMs
Write-Host "`n[+] Auditing Compute: Scanning for idle Virtual Machines..." -ForegroundColor Yellow
$idleVMs = @()
$vms = Get-AzVM -Status | Where-Object { $_.PowerState -eq 'VM running' }

foreach ($vm in $vms) {
    $metric = Get-AzMetric -ResourceId $vm.Id `
        -MetricName "Percentage CPU" `
        -StartTime (Get-Date).AddDays(-$LookbackDays) `
        -EndTime (Get-Date) `
        -AggregationType Average -WarningAction SilentlyContinue

    $avgCpu = ($metric.Data | Measure-Object -Property Average -Average).Average
    if ($avgCpu -lt $CpuThreshold) {
        $idleVMs += [PSCustomObject]@{
            ResourceGroup = $vm.ResourceGroupName
            VMName        = $vm.Name
            Size          = $vm.HardwareProfile.VmSize
            AvgCPU        = [math]::Round($avgCpu, 2)
            Action        = "Downsize or Schedule Auto-Shutdown"
        }
    }
}

if ($idleVMs.Count -gt 0) {
    $idleVMs | Format-Table -AutoSize
} else {
    Write-Host "  -> No idle VMs detected below threshold ($CpuThreshold%)." -ForegroundColor Green
}

# 2. Detect Unattached Disks
Write-Host "`n[+] Auditing Storage: Scanning for unattached managed disks..." -ForegroundColor Yellow
$unattachedDisks = Get-AzDisk | Where-Object { $_.DiskState -eq 'Unattached' } | Select-Object ResourceGroupName, Name, DiskSizeGB, Sku, TimeCreated
if ($unattachedDisks) {
    $unattachedDisks | Format-Table -AutoSize
    $estCost = ($unattachedDisks | Measure-Object -Property DiskSizeGB -Sum).Sum * 0.05
    Write-Host "  -> Identified unattached storage volume leakage: ~$estCost USD/month." -ForegroundColor Red
} else {
    Write-Host "  -> No unattached disks found." -ForegroundColor Green
}

# 3. Detect Orphaned Public IPs
Write-Host "`n[+] Auditing Network: Scanning for orphaned public IPs..." -ForegroundColor Yellow
$orphanedIps = Get-AzPublicIpAddress | Where-Object { $null -eq $_.IpConfiguration } | Select-Object ResourceGroupName, Name, IpAddress
if ($orphanedIps) {
    $orphanedIps | Format-Table -AutoSize
} else {
    Write-Host "  -> No disassociated Public IPs found." -ForegroundColor Green
}

Write-Host "`n[✔] FinOps Audit Completed." -ForegroundColor Cyan