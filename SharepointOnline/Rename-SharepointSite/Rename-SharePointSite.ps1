<#
=========================================================================================
 Script Name : Rename-SharePointSite.ps1
 Author      : Geoffrey Huber 
 Created     : 2025-11-26
 Version     : 1.0
=========================================================================================
 SUMMARY
    This script safely renames a SharePoint Online site using Start-SPOSiteRename.
    It supports PowerShell 5.1 and PowerShell 7 (via -UseWindowsPowerShell).
    The script includes:
        • Full validation check before rename
        • WhatIf support for safe testing
        • Optional suppression of BCS, Marketplace App, and Workflow warnings
        • Status polling using Get-SPOSiteRenameState
        • Clear color-coded console output and error handling
        
 DESCRIPTION
    Microsoft 365 allows changing a site’s URL using Start-SPOSiteRename. 
    This process must be validated before the rename, and certain dependencies
    (workflows, BCS connections, marketplace apps, hub site settings, etc.)
    can block the operation.

    This script:
       1. Loads the SharePoint Online Management Module
       2. Connects to the tenant's Admin Center URL
       3. Performs a validation-only check
       4. Optionally runs with -WhatIf to simulate the rename
       5. Executes the rename if validation passes
       6. Monitors the rename job until complete (or timeout)

    This script is built specifically for:
       • PowerShell 5.1 (recommended for SPO module)
       • PowerShell 7 using:
            Import-Module Microsoft.Online.SharePoint.PowerShell -UseWindowsPowerShell

 REQUIREMENTS
    • Must have the SPO Admin Role or higher
    • Must run as a global admin or SharePoint admin
    • Requires SharePoint Online Management Shell module:
        Install-Module Microsoft.Online.SharePoint.PowerShell -Scope AllUsers
    • Must authenticate to the SPO Admin Center (e.g., https://tenant-admin.sharepoint.com)

 PARAMETERS
    -AdminCenterUrl  
        The URL of the tenant’s SPO Admin Center.
        Default: https://contoso-admin.sharepoint.com

    -OldUrl
        Fully qualified existing site URL.

    -NewUrl
        Fully qualified new site URL (only the “site name” portion changes).

    -WhatIf
        Performs validation and simulated rename without changing anything.

    -SuppressBcsCheck
        Prevents BCS (Business Connectivity Services) dependency warnings.

    -SuppressMarketplaceAppCheck
        Prevents Marketplace App dependency warnings.

    -SuppressWorkflow2013Check
        Suppresses Workflow 2013 dependency warnings.

    -SuppressAllWarnings
        Suppresses all rename warnings (not errors).

    -PollIntervalSeconds
        How often to check rename status.

    -MaxPollMinutes
        Maximum time the script will wait for rename completion.

=========================================================================================
 USAGE EXAMPLES
=========================================================================================

 EXAMPLE 1: Validate and run WhatIf (safe test)
 ----------------------------------------------
    .\Rename-SharePointSite.ps1 `
        -OldUrl "https://contoso.sharepoint.com/sites/GlobalBookkeeperTeam" `
        -NewUrl "https://contoso.sharepoint.com/sites/GB" `
        -WhatIf

 EXAMPLE 2: Validate first, then rename the site
 -----------------------------------------------
    .\Rename-SharePointSite.ps1 `
        -OldUrl "https://contoso.sharepoint.com/sites/GlobalBookkeeperTeam" `
        -NewUrl "https://contoso.sharepoint.com/sites/GB"

 EXAMPLE 3: Rename while suppressing BCS and Workflow warnings
 -------------------------------------------------------------
    .\Rename-SharePointSite.ps1 `
        -OldUrl "https://contoso.sharepoint.com/sites/OldSite" `
        -NewUrl "https://contoso.sharepoint.com/sites/NewSite" `
        -SuppressBcsCheck `
        -SuppressWorkflow2013Check

 EXAMPLE 4: Run directly in PowerShell 7
 ---------------------------------------
    # Import SPO module via Windows PowerShell compatibility layer
    Import-Module Microsoft.Online.SharePoint.PowerShell -UseWindowsPowerShell

    # Run script normally
    .\Rename-SharePointSite.ps1 -OldUrl ... -NewUrl ...

=========================================================================================
 CHANGE LOG
=========================================================================================
 1.0 – Initial script creation with WhatIf support, validation pass, polling, and error handling.

=========================================================================================
#>

[CmdletBinding()]
param (
    # Your tenant-specific defaults; override on the command line if needed
    [string]$AdminCenterUrl = "https://contoso-admin.sharepoint.com",
    [string]$OldUrl         = "https://contoso.sharepoint.com/sites/GlobalBookkeeperTeam",
    [string]$NewUrl         = "https://contoso.sharepoint.com/sites/GB",

    # Script-level WhatIf (passes through to Start-SPOSiteRename)
    [switch]$WhatIf,

    # Optional suppression switches (for BCS/workflow/app checks, known 2025 issues)
    [switch]$SuppressBcsCheck,
    [switch]$SuppressMarketplaceAppCheck,
    [switch]$SuppressWorkflow2013Check,
    [switch]$SuppressAllWarnings,

    # Polling behavior for Get-SPOSiteRenameState
    [int]$PollIntervalSeconds = 30,
    [int]$MaxPollMinutes      = 15
)

function Write-Status {
    param(
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    Write-Host ("[{0}] {1}" -f ((Get-Date).ToString("HH:mm:ss")), $Message) -ForegroundColor $Color
}

Write-Status "Checking for SharePoint Online module (Microsoft.Online.SharePoint.PowerShell)..." "Cyan"

try {
    if (-not (Get-Module -Name Microsoft.Online.SharePoint.PowerShell -ListAvailable)) {
        throw "Module 'Microsoft.Online.SharePoint.PowerShell' is not installed. Install it with: Install-Module Microsoft.Online.SharePoint.PowerShell -Scope AllUsers"
    }

    Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
    Write-Status "SharePoint Online module loaded." "Green"
}
catch {
    Write-Status "Failed to load SPO module: $($_.Exception.Message)" "Red"
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Status "Hint: SPO module is Windows PowerShell-only. Run this script in Windows PowerShell 5.1, or import via 'Import-Module Microsoft.Online.SharePoint.PowerShell -UseWindowsPowerShell' from PowerShell 7 (Windows-only)." "Yellow"
    }
    return
}

# Connect to SPO
try {
    Write-Status "Connecting to SharePoint Online admin center: $AdminCenterUrl" "Cyan"
    Connect-SPOService -Url $AdminCenterUrl -ErrorAction Stop
    Write-Status "Connected to SharePoint Online." "Green"
}
catch {
    Write-Status "Failed to connect to SPO admin center: $($_.Exception.Message)" "Red"
    return
}

# Build base parameter set for Start-SPOSiteRename
$baseParams = @{
    Identity   = $OldUrl
    NewSiteUrl = $NewUrl
}

if ($SuppressBcsCheck)              { $baseParams['SuppressBcsCheck']          = $true }
if ($SuppressMarketplaceAppCheck)   { $baseParams['SuppressMarketplaceAppCheck'] = $true }
if ($SuppressWorkflow2013Check)     { $baseParams['SuppressWorkflow2013Check']  = $true }
if ($SuppressAllWarnings)           { $baseParams['SuppressAllWarnings']        = $true }

# --- WHATIF PATH: no changes, simulate rename ---

if ($WhatIf) {
    try {
        Write-Status "Running Start-SPOSiteRename in ValidationOnly mode (no changes)..." "Yellow"
        $validationParams = $baseParams.Clone()
        $validationParams['ValidationOnly'] = $true

        Start-SPOSiteRename @validationParams -ErrorAction Stop
        Write-Status "Validation succeeded. Rename *could* proceed with these parameters." "Green"

        Write-Status "Simulating rename with Start-SPOSiteRename -WhatIf (no changes will be made)..." "Yellow"
        $whatIfParams = $baseParams.Clone()
        $whatIfParams['WhatIf'] = $true

        Start-SPOSiteRename @whatIfParams -ErrorAction Stop
        Write-Status "WhatIf simulation completed. No site address was changed." "Green"
    }
    catch {
        Write-Status "Validation or WhatIf simulation failed: $($_.Exception.Message)" "Red"
    }
    return
}

# --- REAL RENAME PATH ---

# 1. ValidationOnly pre-check
try {
    Write-Status "Running Start-SPOSiteRename -ValidationOnly pre-check..." "Yellow"
    $validationParams = $baseParams.Clone()
    $validationParams['ValidationOnly'] = $true

    $validationResult = Start-SPOSiteRename @validationParams -ErrorAction Stop
    Write-Status "Validation succeeded. Proceeding with site rename..." "Green"
}
catch {
    Write-Status "Validation FAILED. Site address cannot be changed: $($_.Exception.Message)" "Red"
    Write-Status "Fix the reported issue (BCS, workflows, hub site, retention, etc.) and re-run." "Red"
    return
}

# 2. Start actual rename
try {
    Write-Status "Starting site rename from:`n  $OldUrl`n  -> $NewUrl" "Yellow"
    $renameResult = Start-SPOSiteRename @baseParams -ErrorAction Stop
    Write-Status "Rename job submitted successfully." "Green"
}
catch {
    Write-Status "Failed to start site rename: $($_.Exception.Message)" "Red"
    return
}

# 3. Poll Get-SPOSiteRenameState for status
Write-Status "Checking rename status with Get-SPOSiteRenameState..." "Cyan"

$deadline = (Get-Date).AddMinutes($MaxPollMinutes)
$status   = $null

do {
    try {
        # First try by old URL; if that fails (e.g., post-rename), fall back to new URL
        try {
            $stateObj = Get-SPOSiteRenameState -Identity $OldUrl -ErrorAction Stop
        }
        catch {
            $stateObj = Get-SPOSiteRenameState -Identity $NewUrl -ErrorAction Stop
        }

        $status = $stateObj.State
        Write-Status "Current rename state: $status" "Cyan"

        if ($status -in @('Success','Failed','Suspended','Canceling','Canceled')) {
            break
        }
    }
    catch {
        Write-Status "Error checking rename state: $($_.Exception.Message)" "Red"
        break
    }

    Start-Sleep -Seconds $PollIntervalSeconds

} while ((Get-Date) -lt $deadline)

if ($status -eq 'Success') {
    Write-Status "Site rename completed successfully." "Green"
    Write-Status "New site URL: $NewUrl" "Green"
}
elseif ($status) {
    Write-Status "Rename finished with state: $status. Review details in the SharePoint admin center (Active sites → site details)." "Yellow"
}
else {
    Write-Status "Rename status is unknown (timed out or error). Verify the site in the SharePoint admin center." "Yellow"
}
