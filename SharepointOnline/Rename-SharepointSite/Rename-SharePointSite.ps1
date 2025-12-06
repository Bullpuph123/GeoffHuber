[CmdletBinding()]
param (
    [string]$AdminCenterUrl = "https://contoso-admin.sharepoint.com",
    [string]$OldUrl         = "https://contoso.sharepoint.com/sites/SourceSite",
    [string]$NewUrl         = "https://contoso.sharepoint.com/sites/TargetSite",
    [switch]$WhatIf,
    [switch]$SuppressBcsCheck,
    [switch]$SuppressMarketplaceAppCheck,
    [switch]$SuppressWorkflow2013Check,
    [switch]$SuppressAllWarnings,
    [int]$PollIntervalSeconds = 15,
    [int]$MaxPollMinutes      = 30
)

function Write-Status {
    param([string]$Message,[string]$Color="Gray")
    $orig = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Host $Message
    $Host.UI.RawUI.ForegroundColor = $orig
}

function Ensure-SpoModuleLoaded {
    if (-not (Get-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction SilentlyContinue)) {
        Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
    }
}

function Connect-SpoAdminCenter {
    param([string]$Url)
    Connect-SPOService -Url $Url -ErrorAction Stop
}

function Validate-Parameters {
    param([string]$OldUrl,[string]$NewUrl)
    if ($OldUrl -eq $NewUrl) {
        throw "OldUrl and NewUrl cannot be identical."
    }
    Get-SPOSite -Identity $OldUrl -ErrorAction Stop | Out-Null
}

try {
    Ensure-SpoModuleLoaded
    Connect-SpoAdminCenter -Url $AdminCenterUrl
    Validate-Parameters -OldUrl $OldUrl -NewUrl $NewUrl

    $params = @{
        Identity = $OldUrl
        NewSiteUrl = $NewUrl
    }

    if ($SuppressBcsCheck) { $params.SuppressBcsCheck = $true }
    if ($SuppressMarketplaceAppCheck) { $params.SuppressMarketplaceAppCheck = $true }
    if ($SuppressWorkflow2013Check) { $params.SuppressWorkflow2013Check = $true }
    if ($SuppressAllWarnings) { $params.SuppressAllWarnings = $true }

    if ($WhatIf) {
        Start-SPOSiteRename @params -WhatIf
        return
    }

    Start-SPOSiteRename @params
}
catch {
    Write-Error $_
}