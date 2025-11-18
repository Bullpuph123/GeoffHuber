<#
.SYNOPSIS
  Retrieve ProdataKey.Cards for one or more users (supports UPN, display name, partial matches, or OfficeLocation).
.DESCRIPTION
  - Search by:
      * -Identity: Exact UPN, exact/partial DisplayName, or partial UPN/Mail.
      * -OfficeLocation: Exact or partial Office Location.
    If both are provided, the result is the intersection (users matching both).
  - Outputs objects with properties: DisplayName, UPN, Mail, OfficeLocation, Cards (array).
  - Pipe-friendly for Format-Table, Format-List, Export-Csv, etc.
.EXAMPLES
  .\Get-ProdataKeyCards.ps1 -Identity "gary.McGaryFace@domain.org"
  .\Get-ProdataKeyCards.ps1 -Identity "Geoff"
  .\Get-ProdataKeyCards.ps1 -OfficeLocation "Chico"
  .\Get-ProdataKeyCards.ps1 -Identity "Geoff" -OfficeLocation "Chico" | Format-Table -AutoSize
  "hub" | .\Get-ProdataKeyCards.ps1 | Format-List
#>

[CmdletBinding()]
param(
  [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
  [string]$Identity,

  [Parameter(Position=1)]
  [string]$OfficeLocation,

  [Parameter(Position=2)]
  [string]$TenantId,

  [switch]$ForceLogin
)

begin {
  $ErrorActionPreference = 'Stop'

  # Required scopes for reading users and custom security attributes
  $RequiredScopes = @(
  "User.Read.All",
  "User.ReadWrite.All",
  "CustomSecAttributeDefinition.Read.All",
  "CustomSecAttributeAssignment.Read.All"
)


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

  # Import Graph module if needed
  if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    try { Import-Module Microsoft.Graph -ErrorAction Stop } catch {
      Write-Error "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
      break
    }
  }

  Ensure-GraphConnection
}

process {
  # If neither parameter is provided (including pipeline), bail out.
  if (-not $PSBoundParameters.ContainsKey('Identity') -and -not $PSBoundParameters.ContainsKey('OfficeLocation')) {
    Write-Error "Please provide -Identity (UPN / name / partial) and/or -OfficeLocation."
    return
  }

  $prop = "DisplayName,UserPrincipalName,Mail,OfficeLocation,CustomSecurityAttributes"
  $identityMatches = @()
  $officeMatches   = @()

  # ---------- Identity-based search ----------
  if ($PSBoundParameters.ContainsKey('Identity') -and $Identity) {
    # 1) Try exact UPN/userId lookup first
    try {
      $u = Get-MgUser -UserId $Identity -Property $prop -ErrorAction Stop
      if ($u) { $identityMatches += $u }
    } catch {}

    # 2) If no exact match, try server-side startswith on displayName
    if ($identityMatches.Count -eq 0) {
      try {
        $filter = "startswith(displayName,'{0}')" -f ($Identity -replace "'","''")
        $matches = Get-MgUser -Filter $filter -Property $prop -All -ErrorAction SilentlyContinue
        if ($matches) { $identityMatches += $matches }
      } catch {}
    }

    # 3) Client-side contains fallback across DisplayName, UPN, Mail
    if ($identityMatches.Count -eq 0) {
      try {
        $all = Get-MgUser -Property $prop -All
        if ($all) {
          $pattern = $Identity
          $identityMatches += $all | Where-Object {
            ($_.DisplayName -and ($_.DisplayName -like "*$pattern*")) -or
            ($_.UserPrincipalName -and ($_.UserPrincipalName -like "*$pattern*")) -or
            ($_.Mail -and ($_.Mail -like "*$pattern*"))
          }
        }
      } catch {}
    }
  }

  # ---------- OfficeLocation-based search ----------
  if ($PSBoundParameters.ContainsKey('OfficeLocation') -and $OfficeLocation) {
    # Try server-side startswith on officeLocation
    try {
      $filter = "startswith(officeLocation,'{0}')" -f ($OfficeLocation -replace "'","''")
      $matches = Get-MgUser -Filter $filter -Property $prop -All -ErrorAction SilentlyContinue
      if ($matches) { $officeMatches += $matches }
    } catch {}

    # Client-side contains fallback for officeLocation
    if ($officeMatches.Count -eq 0) {
      try {
        $all = if ($identityMatches.Count -gt 0) { $identityMatches } else { Get-MgUser -Property $prop -All }
        if ($all) {
          $pattern = $OfficeLocation
          $officeMatches += $all | Where-Object {
            $_.OfficeLocation -and ($_.OfficeLocation -like "*$pattern*")
          }
        }
      } catch {}
    }
  }

  # ---------- Combine results ----------
  $users = @()

  if ($Identity -and $OfficeLocation) {
    # Intersection of identityMatches and officeMatches by UPN
    $left  = $identityMatches | Group-Object -Property UserPrincipalName -AsHashTable -AsString
    foreach ($o in $officeMatches) {
      if ($left.ContainsKey([string]$o.UserPrincipalName)) {
        $users += $o
      }
    }
  } elseif ($Identity) {
    $users = $identityMatches
  } elseif ($OfficeLocation) {
    $users = $officeMatches
  }

  if (-not $users -or $users.Count -eq 0) {
    Write-Warning ("No users found matching " + (@(
      ($Identity) ? "Identity='$Identity'" : $null,
      ($OfficeLocation) ? "OfficeLocation='$OfficeLocation'" : $null
    ) | Where-Object { $_ } -join " AND "))
    return
  }

  # Deduplicate by UPN
  $users = $users | Sort-Object -Property UserPrincipalName -Unique

  foreach ($u in $users) {
    $cards = $null
    try {
      if ($u.CustomSecurityAttributes -and $u.CustomSecurityAttributes.AdditionalProperties) {
        $pd = $u.CustomSecurityAttributes.AdditionalProperties.ProdataKey
        if ($pd -and $pd.Cards) {
          $cards = @($pd.Cards)
        }
      }
    } catch {}

    [pscustomobject]@{
     # DisplayName    = $u.DisplayName
      UPN            = $u.UserPrincipalName
     # Mail           = $u.Mail
      OfficeLocation = $u.OfficeLocation
      Cards          = $cards
    }
  }
}
