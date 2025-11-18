param()

function Write-Color {
    param(
        [string]$Text,
        [string]$Color = "White",
        [switch]$Bold
    )
    if ($Bold) { Write-Host ("[*] " + $Text) -ForegroundColor $Color }
    else       { Write-Host $Text -ForegroundColor $Color }
}

# Connect if needed
if (-not (Get-MgContext)) {
    Write-Color "Connecting to Microsoft Graph…" "Cyan" -Bold
    Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory","Directory.ReadWrite.All" | Out-Null
}

# Collect piped input
$rolesToRemove = foreach ($i in $input) { $i }

if ($rolesToRemove.Count -eq 0) {
    Write-Color "No roles were piped into Remove-UserRoles.ps1" "Red" -Bold
    return
}

$userUPN      = $rolesToRemove[0].UserPrincipalName
$userObjectId = $rolesToRemove[0].UserObjectId

Write-Host ""
Write-Color "====================================================" White
Write-Color "       REMOVING ROLES FOR: $userUPN" Green -Bold
Write-Color "====================================================" White
Write-Host ""

$results = @()

foreach ($role in $rolesToRemove) {

    $roleName = $role.RoleName
    $roleDefId = $role.RoleId   # This is the RoleDefinitionId in Graph v2

    # Fancy Role Card
    Write-Host "┌──────────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host ("│  Removing Role: ") -ForegroundColor DarkGray -NoNewline
    Write-Host ($roleName.PadRight(32)) -ForegroundColor Yellow -NoNewline
    Write-Host "│" -ForegroundColor DarkGray

    Write-Host ("│  Role Definition ID: ") -ForegroundColor DarkGray -NoNewline
    Write-Host ($roleDefId.PadRight(26)) -ForegroundColor Cyan -NoNewline
    Write-Host "│" -ForegroundColor DarkGray

    Write-Host "└──────────────────────────────────────────────┘" -ForegroundColor DarkGray
    Write-Host ""

    # GRAPH SDK v2: Find Role Assignment
    $assignment = Get-MgRoleManagementDirectoryRoleAssignment |
        Where-Object {
            $_.PrincipalId -eq $userObjectId -and
            $_.RoleDefinitionId -eq $roleDefId
        }

    if (-not $assignment) {
        Write-Color "No active role assignment found for $roleName" Yellow -Bold
        $results += [PSCustomObject]@{
            User = $userUPN
            RoleName = $roleName
            RoleId = $roleDefId
            Status = "No Assignment Found"
            Timestamp = (Get-Date)
        }
        continue
    }

    # Remove Assignment
    try {
        Remove-MgRoleManagementDirectoryRoleAssignment `
            -UnifiedRoleAssignmentId $assignment.Id `
            -ErrorAction Stop

        Write-Color "SUCCESS removing $roleName" Green -Bold
        $status = "Removed"
    }
    catch {
        Write-Color "ERROR removing $roleName : $_" Red -Bold
        $status = "Failed - $($_.Exception.Message)"
    }

    $results += [PSCustomObject]@{
        User = $userUPN
        RoleName = $roleName
        RoleId = $roleDefId
        Status = $status
        Timestamp = (Get-Date)
    }

    Write-Host ""
}

# ----------------------------
# HTML REPORT CREATION
# ----------------------------

$timestamp = (Get-Date -Format "yyyy-MM-dd-HHmm")
$safeUPN   = $userUPN.Replace("@","_").Replace(".","-")
$fileName  = "UserRoleRemoval-$safeUPN-$timestamp.html"
$outputPath = Join-Path (Get-Location) $fileName

$html = @"
<!DOCTYPE html>
<html>
<head>
<title>Role Removal Report for $userUPN</title>
<style>
body { font-family: Arial; background: #f4f4f8; padding: 20px; }
.card {
    background: white;
    border-radius: 12px;
    padding: 20px;
    margin-bottom: 15px;
    box-shadow: 0 4px 10px rgba(0,0,0,0.15);
}
.success { color: green; font-weight: bold; }
.fail { color: red; font-weight: bold; }
.none { color: #555; font-weight: bold; }
.role { font-size: 20px; font-weight: bold; color: #1a5276; }
</style>
</head>
<body>
<h1>Role Removal Report</h1>
<h2>User: $userUPN</h2>
<p>Generated: $(Get-Date)</p>
"@

foreach ($entry in $results) {
    $css = switch ($entry.Status) {
        "Removed" { "success" }
        "No Assignment Found" { "none" }
        default { "fail" }
    }

$html += @"
<div class='card'>
<b class='role'>Role:</b> $($entry.RoleName)<br>
<b>Role ID:</b> $($entry.RoleId)<br>
<b>Status:</b> <span class='$css'>$($entry.Status)</span><br>
<b>Timestamp:</b> $($entry.Timestamp)<br>
</div>
"@
}


$html += "</body></html>"

$html | Out-File -FilePath $outputPath -Encoding UTF8

Write-Color "HTML report saved to: $outputPath" Cyan -Bold
Write-Color "Done!" Green -Bold
