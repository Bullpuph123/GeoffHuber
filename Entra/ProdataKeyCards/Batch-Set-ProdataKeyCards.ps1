<#
.SYNOPSIS
  Batch apply ProdataKey card numbers to users from a CSV by calling Set-ProdataKeyCards.ps1.

.DESCRIPTION
  Reads a CSV with columns:
    - UPN   : User principal name (e.g., user@domain.com)
    - Cards : One or more card codes separated by comma, semicolon, or whitespace
  For each row, calls Set-ProdataKeyCards.ps1 with either -Append (default) or replace mode.

.PARAMETER CsvPath
  Path to CSV file.

.PARAMETER Mode
  'Append' (default) or 'Replace' (overwrite).

.PARAMETER SetScriptPath
  Path to Set-ProdataKeyCards.ps1. Defaults to the same folder as this script.

.PARAMETER TenantId
  Optional: tenant id or domain to pass through to the Set script.

.PARAMETER ForceLogin
  Optional: forces a fresh Graph login for the Set script.

.PARAMETER DryRun
  Optional: show what would be done without calling the Set script.

.EXAMPLE
  # Default: APPEND any cards listed in the CSV
  .\Batch-Set-ProdataKeyCards.ps1 -CsvPath .\cards.csv

.EXAMPLE
  # REPLACE any existing cards with exactly what's in the CSV
  .\Batch-Set-ProdataKeyCards.ps1 -CsvPath .\cards.csv -Mode Replace

.EXAMPLE
  # Custom path to Set script
  .\Batch-Set-ProdataKeyCards.ps1 -CsvPath .\cards.csv -SetScriptPath "C:\Entra\Reports\Set-ProdataKeyCards.ps1"

.EXAMPLE
  # Dry run (no changes)
  .\Batch-Set-ProdataKeyCards.ps1 -CsvPath .\cards.csv -DryRun
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory, Position=0)]
  [ValidateNotNullOrEmpty()]
  [string]$CsvPath,

  [Parameter(Position=1)]
  [ValidateSet('Append','Replace')]
  [string]$Mode = 'Append',

  [Parameter(Position=2)]
  [string]$SetScriptPath = "$(Split-Path -Parent $PSCommandPath)\Set-ProdataKeyCards.ps1",

  [Parameter(Position=3)]
  [string]$TenantId,

  [switch]$ForceLogin,

  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Required delegated scopes for Custom Security Attributes (CSA) work
$RequiredScopes = @(
  'User.Read.All',
  'User.ReadWrite.All',
  'CustomSecAttributeDefinition.Read.All',
  'CustomSecAttributeAssignment.Read.All',
  'CustomSecAttributeAssignment.ReadWrite.All'
)

if (-not (Test-Path -LiteralPath $CsvPath)) {
  throw "CSV not found: $CsvPath"
}

if (-not (Test-Path -LiteralPath $SetScriptPath)) {
  throw "Set-ProdataKeyCards.ps1 not found at: $SetScriptPath"
}

# Helper: parse Cards string into array
function Parse-Cards([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return @() }
  # split on comma, semicolon, or whitespace
  $parts = $s -split '[,\s;]'
  return @($parts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() })
}

# --- Added: show informational messages and provide fast existence check ---
$InformationPreference = 'Continue'  # so Write-Information is visible without -Verbose


function Ensure-GraphScopes {
  param([string]$TenantId)

  $ctx = $null
  try { $ctx = Get-MgContext -ErrorAction Stop } catch {}

  $have = @()
  if ($ctx -and $ctx.Scopes) { $have = $ctx.Scopes }

  $missing = @()
  if (-not $ctx) {
    $missing = $RequiredScopes
  } else {
    $missing = $RequiredScopes | Where-Object { $_ -notin $have }
  }

  if (-not $ctx -or $missing.Count -gt 0) {
    Write-Host "Connecting to Microsoft Graph and requesting scopes: $($RequiredScopes -join ', ')" -ForegroundColor Cyan
    if ($TenantId) {
      Connect-MgGraph -TenantId $TenantId -Scopes $RequiredScopes -NoWelcome | Out-Null
    } else {
      Connect-MgGraph -Scopes $RequiredScopes -NoWelcome | Out-Null
    }

    # (Optional) If your CSA calls use beta, uncomment:
    # Select-MgProfile -Name beta

    # Re-check to be sure we have everything
    $ctx = Get-MgContext
    $have = $ctx.Scopes
    $stillMissing = $RequiredScopes | Where-Object { $_ -notin $have }
    if ($stillMissing.Count -gt 0) {
      throw "Missing Graph permissions after connect: $($stillMissing -join ', ')"
    }
  }

  # Warm-up to avoid the first-call stall
  try { Get-MgUser -Top 1 -Property Id | Out-Null } catch { }
}


function Test-UserExists {
  param([Parameter(Mandatory)][string]$UserId)
  try {
    Get-MgUser -UserId $UserId -Property Id -ErrorAction Stop | Out-Null
    return $true
  } catch {
    $m = $_.Exception.Message
    if ($m -match 'Request_ResourceNotFound' -or $m -match 'Status:\s*404') { return $false }
    throw  # unexpected errors should bubble up to your existing handler
  }
}



# Read CSV
$rows = Import-Csv -LiteralPath $CsvPath

# --- Added: prevent the first real row from "hanging" doing module/auth JIT ---
#Connect-Graph-IfNeeded

Ensure-GraphScopes -TenantId $TenantId



if (-not $rows -or $rows.Count -eq 0) {
  throw "CSV contains no rows."
}

$results = New-Object System.Collections.Generic.List[object]
$ok = 0; $fail = 0; $i = 0
# --- Added ---
$skipped = 0


foreach ($row in $rows) {
  $i++
  $userId = $row.UPN
  $cardsRaw = $row.Cards
  
  # --- Added: visible progress so it never looks "stuck" ---
  $percent = [int](($i / [math]::Max(1,$rows.Count)) * 100)
  Write-Progress -Activity "Assigning ProdataKey.Cards" -Status ("Row {0} of {1} — {2}" -f $i,$rows.Count,$userId) -PercentComplete $percent
  Write-Information ("[{0}/{1}] Working on {2}" -f $i,$rows.Count,$userId)

  # Guard AFTER values are set, and check cardsRaw (not cards)
  if ([string]::IsNullOrWhiteSpace($userId) -or [string]::IsNullOrWhiteSpace($cardsRaw)) {
    $skipped++
    $results.Add([pscustomobject]@{ Row=$i; UPN=$userId; Mode=$Mode; Status='SKIPPED'; Message='Missing UPN or Cards' })
    Write-Warning ("[{0}/{1}] Skipped (missing UPN or Cards): {2}" -f $i,$rows.Count,$userId)
    continue
  }


  $cards = Parse-Cards $cardsRaw

  if ($cards.Count -eq 0) {
    $fail++; $results.Add([pscustomobject]@{ Row=$i; UPN=$userId; Mode=$Mode; Status='ERROR'; Message='No Cards provided' })
    Write-Warning "Row $i ($userId): No Cards provided. Skipping."
    continue
  }

  # Build args for Set script
  $splat = @{
    UserId = $userId
    Cards  = $cards
  }
  if ($TenantId)   { $splat.TenantId   = $TenantId }
  if ($ForceLogin) { $splat.ForceLogin = $true }

  $modeNote = if ($Mode -eq 'Append') { '-Append' } else { '(Replace)' }

  if ($DryRun) {
    Write-Host "[DRY-RUN] Would call: `"$SetScriptPath`" -UserId `"$userId`" -Cards $($cards -join ', ') $modeNote"
    $ok++; $results.Add([pscustomobject]@{ Row=$i; UPN=$userId; Mode=$Mode; Status='DRYRUN'; Message='Skipped by DryRun' })
    continue
  }
  
  # --- Added: 404-safe existence check so the batch continues ---
  if (-not (Test-UserExists -UserId $userId)) {
    $skipped++
    $results.Add([pscustomobject]@{
      Row    = $i; UPN=$userId; Mode=$Mode; Status='SKIPPED'; Message='UserNotFound (404)'
    })
    Write-Warning ("[{0}/{1}] Skipped (user not found): {2}" -f $i,$rows.Count,$userId)
    continue
  }

  try {
    if ($Mode -eq 'Append') {
      & $SetScriptPath @splat -Append
    } else {
      & $SetScriptPath @splat
    }
    $ok++; $results.Add([pscustomobject]@{ Row=$i; UPN=$userId; Mode=$Mode; Status='OK'; Message='Applied' })
  } catch {
    $fail++; $results.Add([pscustomobject]@{ Row=$i; UPN=$userId; Mode=$Mode; Status='ERROR'; Message=$_.Exception.Message })
    Write-Error "Row $i ($userId): $($_.Exception.Message)"
  }
}

Write-Host ""
Write-Host "Completed. Success: $ok  Skipped: $skipped  Failed: $fail  Total: $($rows.Count)"

$results
