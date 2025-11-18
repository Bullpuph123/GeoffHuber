<# 
.SYNOPSIS
  Set ProdataKey.Cards (Collection(String)) for a user via Microsoft Graph, with validation.
  Supports replace (default) and append (-Append) modes.

.EXAMPLES
  # Replace mode (default): overwrites Cards with exactly these values
  .\Set-ProdataKeyCards.ps1 -UserId "gary.McGaryFace@domain.org" -Cards "111111","A1B2C3"

  # Append mode: adds these card(s) to any existing values
  .\Set-ProdataKeyCards.ps1 -UserId "gary.McGaryFace@domain.org" -Cards "555555" -Append
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$UserId,

  [Parameter(Mandatory)]
  [string[]]$Cards,

  [string]$TenantId,

  [switch]$ForceLogin,

  # When present, add new cards to any existing values instead of replacing
  [switch]$Append
)

$ErrorActionPreference = 'Stop'

# ----- Required write scopes for CSA -----
$RequiredScopes = @(
  "User.Read.All",
  "User.ReadWrite.All",
  "CustomSecAttributeDefinition.Read.All",
  "CustomSecAttributeAssignment.Read.All",
  "CustomSecAttributeAssignment.ReadWrite.All"
)


# --- Normalize helpers ---
function Convert-ToCardArray {
  param($value)
  $arr = @()
  if ($null -eq $value) { return @() }

  if ($value -is [string]) {
    # Allow space/comma separated strings just in case
    $arr = @($value -split '[,\s]+' | Where-Object { $_ })
  } elseif ($value -is [System.Collections.IEnumerable]) {
    if ($value -isnot [string]) { $arr = @($value) }
  } else {
    $arr = @($value)
  }

  # Normalize: trim/uppercase, de-dupe
  return @($arr | ForEach-Object { $_.ToString().Trim().ToUpperInvariant() } | Where-Object { $_ } | Select-Object -Unique)
}


# --- Get existing cards from CSA robustly (covers both SDK shapes) ---
function Get-ExistingCardsFromUser {
  param($userObject)

  # Try common shape: $u.CustomSecurityAttributes.ProdataKey.Cards
  $cardsRaw = $null
  $csa = $userObject.CustomSecurityAttributes
  if ($csa) {
    $pd = $csa.ProdataKey
    if ($pd) { $cardsRaw = $pd.Cards }
  }

  # Try AdditionalProperties shape: $u.CustomSecurityAttributes.AdditionalProperties.ProdataKey.Cards
  if (-not $cardsRaw) {
    $ap = $userObject.CustomSecurityAttributes.AdditionalProperties
    if ($ap -and $ap.ContainsKey('ProdataKey')) {
      $cardsRaw = $ap['ProdataKey']['Cards']
    }
  }

  # If it's a dictionary like @{ values = (...) }
  if ($cardsRaw -is [System.Collections.IDictionary]) {
    if ($cardsRaw.Contains('values')) { $cardsRaw = $cardsRaw['values'] }
  }

  return (Convert-ToCardArray $cardsRaw)
}

  
  

function Get-DynValue {
  param($obj, [string]$key)
  if ($null -eq $obj) { return $null }
  if ($obj -is [System.Collections.IDictionary]) { return $obj[$key] }
  $prop = $obj.PSObject.Properties[$key]
  if ($prop) { return $prop.Value }
  return $null
}

function Ensure-GraphConnection {
  $ctx = $null
  try { $ctx = Get-MgContext -ErrorAction Stop } catch {}
  $needsLogin = $ForceLogin -or -not $ctx -or @($RequiredScopes | Where-Object { $_ -notin ($ctx.Scopes) }).Count -gt 0
  if ($needsLogin) {
    try { Disconnect-MgGraph -ErrorAction SilentlyContinue } catch {}
    if ($TenantId) {
      Connect-MgGraph -TenantId $TenantId -Scopes $RequiredScopes
    } else {
      Connect-MgGraph -Scopes $RequiredScopes
    }
  }
  $ctx = Get-MgContext
  Write-Verbose ("Connected to tenant {0} as {1}. Scopes: {2}" -f $ctx.TenantId, $ctx.Account, ($ctx.Scopes -join ', '))
}

try {
  Import-Module Microsoft.Graph -ErrorAction Stop
} catch {
  Write-Error "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
  return
}

# --------------------------------------------------------------
# Inputs assumed available:
#   $u      = Get-MgUser -UserId $UserId -Property "DisplayName,customSecurityAttributes"
#   $Cards  = incoming values; can be string "333333 444444" or string[] @("333333","444444")
# --------------------------------------------------------------

# --- Normalize inputs and (optionally) merge with existing when -Append ---
Ensure-GraphConnection
# Resolve the user cleanly with a good error message on 404
try {
  $u = Get-MgUser -UserId $UserId -Property "DisplayName,customSecurityAttributes" -ErrorAction Stop
} catch {
  $msg = $_.Exception.Message
  if ($msg -match 'Request_ResourceNotFound' -or $msg -match 'Status: 404') {
    Write-Error "User not found: '$UserId' (404 Request_ResourceNotFound)"
    # Return a non-zero exit so the batch can record 'Skipped' or 'Failed' appropriately
    exit 1
  }
  throw
}

$incoming = @(Convert-ToCardArray $Cards)


if ($Append) {
  $existing = Get-ExistingCardsFromUser -userObject $u


  # Announce duplicates
  foreach ($dup in $incoming) {
    if ($existing -contains $dup) { Write-Host "Value '$dup' already exists; skipping." }
  }

  # Keep only new items, then merge arrays (no string concatenation)
	$incomingFiltered = @($incoming | Where-Object { $existing -notcontains $_ })

	$final = @()
	$final += $existing
	$final += $incomingFiltered
	$final = @($final | Select-Object -Unique)

} else {
  # Replace mode (default)
  $final = @($incoming)
}

Write-Host "cards (incoming): $($incoming -join ' ')"
Write-Host "merged/final:     $($final -join ' ')"
$Cards = @($final)   # keep as array
                      # keep as array

Ensure-GraphConnection

# ---- Clean + VALIDATE input cards ----
# Normalize: trim spaces, uppercase
$cardsNorm = $Cards | ForEach-Object { ($_.ToString().Trim()).ToUpperInvariant() } | Where-Object { $_ }

# Validate: exactly 6 alphanumeric chars (A–Z, 0–9)
$pattern = '^[A-Z0-9]{6}$'
$invalid = $cardsNorm | Where-Object { $_ -notmatch $pattern }
if ($invalid.Count) {
  throw ("Invalid card number(s): {0}. Each must be EXACTLY 6 alphanumeric characters (A–Z, 0–9)." -f ($invalid -join ', '))
}

# De-duplicate after normalization
$cardsFinal = @($cardsNorm | Select-Object -Unique)
if (-not $cardsFinal -or $cardsFinal.Count -eq 0) {
  throw "No valid card numbers were provided after validation."
}

# ---- Optional: sanity check definition ----
try {
  $def = Get-MgDirectoryCustomSecurityAttributeDefinition -Filter "attributeSet eq 'ProdataKey'" -ErrorAction Stop
  if (-not $def -or $def.Count -eq 0) { throw "Attribute 'Cards' in set 'ProdataKey' not found." }
  if ($def.Status -ne "Available") { throw "Attribute 'ProdataKey.Cards' is not 'Available' (status: $($def.Status))." }
  if ($def.Type -ne "String") { throw "Expected Type 'String' but found '$($def.Type)'." }
} catch {
  Write-Warning "Could not verify attribute definition. Proceeding anyway. Details: $($_.Exception.Message)"
}

# ---- If -Append: load current cards and merge ----
#$mergedCards = $cardsFinal
if ($Append) {
  Write-Verbose "Append mode: retrieving current ProdataKey.Cards values for $UserId..."
  $mergedCards = @($final) 
}

# ---- Build CSA payload (replace or append result) ----
# $final already holds the list you want to write (array or single string)

# 1) Make $final itself an array (covers single-item case)
$final = @($final)

# 2) Build a guaranteed array for JSON serialization
$payloadCards = @()
$payloadCards += $final            # <- prevents scalar collapse

$customSecurityAttributes = @{
  "ProdataKey" = @{
    "@odata.type"      = "#Microsoft.DirectoryServices.CustomSecurityAttributeValue"
    "Cards@odata.type" = "#Collection(String)"
    "Cards"            = $payloadCards
  }
}


# ---- Write ----
try {
  Update-MgUser -UserId $UserId -CustomSecurityAttributes $customSecurityAttributes -ErrorAction Stop
  $modeText = $(if ($Append) { "appended (merged)" } else { "replaced" })
  Write-Host "✔ Successfully $modeText ProdataKey.Cards for $UserId => $($payloadCards -join ', ')"
} catch {
  if ($_.Exception.Message -match "Authorization_RequestDenied|Insufficient privileges|403") {
    Write-Error "403 Forbidden: Your token lacks write permission OR you're not listed as an 'Allowed assigner' on the 'ProdataKey' set. Ensure:
    - Scopes include CustomSecAttributeAssignment.ReadWrite.All
    - The 'ProdataKey' set → 'Who can assign values?' includes you (or a group you're in)
    - You're targeting the correct tenant."
  } else {
    throw
  }
}

# ---- Read-back to confirm ----
try {
  $u = Get-MgUser -UserId $UserId -Property "DisplayName,customSecurityAttributes"

  # Read-back using the more common shape
  $cardsRead = $null
  $csa = $u.CustomSecurityAttributes.AdditionalProperties
  if ($csa) {
    $pd = $u.CustomSecurityAttributes.AdditionalProperties.ProdataKey
    if ($pd) { $cardsRead = $u.CustomSecurityAttributes.AdditionalProperties.ProdataKey.Cards }
  }


  [pscustomobject]@{
    User  = $u.DisplayName
    UPN   = $UserId
    Cards = $cardsRead
  } | Format-List
  Write-Host "✔ Successful Readback"
} catch {
  Write-Warning "Write succeeded but read-back failed: $($_.Exception.Message)"
}
