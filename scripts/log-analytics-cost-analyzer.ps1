<#
.SYNOPSIS
    Azure Log Analytics Table Ingestion Cost Profiler.
.DESCRIPTION
    Queries Log Analytics workspaces to pinpoint runaway telemetry data ingestion
    and unoptimized diagnostic logs driving up billing.
.AUTHOR
    Rahul Goyal (14+ Years)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspaceId,

    [int]$LookbackDays = 7
)

$kqlQuery = @"
Usage
| where TimeGenerated > ago(${LookbackDays}d)
| where DataType !in ('Heartbeat', 'Operation')
| summarize IngestedGB = sum(Quantity) / 1024 by DataType
| extend EstCostUSD = round(IngestedGB * 2.30, 2)
| sort by IngestedGB desc
| take 10
"@

Write-Host "==> Auditing Workspace $WorkspaceId for Top Ingestion Cost Contributors..." -ForegroundColor Cyan
Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $kqlQuery | Select-Object -ExpandProperty Results | Format-Table -AutoSize