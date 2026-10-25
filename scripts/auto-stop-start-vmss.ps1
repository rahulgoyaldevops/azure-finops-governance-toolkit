<#
.SYNOPSIS
    Automated FinOps Schedule Engine for Non-Production VM Scale Sets.
.DESCRIPTION
    Saves ~65% monthly compute spend by automatically deallocating non-prod
    Virtual Machine Scale Sets outside standard operational hours (Mon-Fri 08:00 - 19:00).
.AUTHOR
    Rahul Goyal — Senior DevOps & Cloud Engineer (14+ Years)
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Stop", "Start")]
    [string]$Action,

    [string]$TagFilter = "Environment",
    [string]$TagValue = "Non-Prod"
)

Write-Host "==> Starting FinOps VMSS Schedule Engine (Action: $Action)..." -ForegroundColor Cyan

$vmssList = Get-AzVmss | Where-Object {
    $_.Tags[$TagFilter] -eq $TagValue -or $_.Tags["AutoShutdown"] -eq "True"
}

foreach ($vmss in $vmssList) {
    if ($Action -eq "Stop") {
        Write-Host "Deallocating VMSS: $($vmss.Name) in RG: $($vmss.ResourceGroupName)..." -ForegroundColor Yellow
        Stop-AzVmss -ResourceGroupName $vmss.ResourceGroupName -VMScaleSetName $vmss.Name -Force -AsJob | Out-Null
    } elseif ($Action -eq "Start") {
        Write-Host "Starting VMSS: $($vmss.Name) in RG: $($vmss.ResourceGroupName)..." -ForegroundColor Green
        Start-AzVmss -ResourceGroupName $vmss.ResourceGroupName -VMScaleSetName $vmss.Name -AsJob | Out-Null
    }
}

Write-Host "==> Action jobs dispatched successfully." -ForegroundColor Green