function Write-Info($msg)  { Write-Host "[*] $msg" -ForegroundColor Cyan }
function Write-Add($msg)   { Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Remove($msg){ Write-Host "[-] $msg" -ForegroundColor Yellow }
function Write-Warn($msg)  { Write-Host "[!] $msg" -ForegroundColor Magenta }
function Write-Err($msg)   { Write-Host "[X] $msg" -ForegroundColor Red }

$groupPrefix = "ENTRA-adminroles-"

function ProcessGroup {
    param(
        [string]$GroupName,
        [array]$CurrentUsers
    )

    Write-Info "Processing group: $GroupName"

    # -------------------------------------------------------
    # Retrieve or create the group
    # -------------------------------------------------------
    $existingGroup = (
        Invoke-MgGraphRequest -Method GET -Uri "/beta/groups?`$filter=displayName eq '$GroupName'&`$select=id"
    ).value

    if (-not $existingGroup) {
        Write-Warn "Group does not exist — creating $GroupName"

        $body = @{
            displayName     = $GroupName
            mailEnabled     = $false
            mailNickname    = $GroupName.Replace(" ","_")
            securityEnabled = $true
        }

        $groupId = (Invoke-MgGraphRequest -Method POST -Uri "/beta/groups" -Body $body).id
        Write-Add "Created group with ID: $groupId"
    }
    else {
        $groupId = $existingGroup.id
        Write-Info "Group exists. ID: $groupId"
    }

    # -------------------------------------------------------
    # Retrieve existing group members
    # -------------------------------------------------------
    Write-Info "Retrieving current members…"

    $existingUsers = @()
    $uri = "/beta/groups/$groupId/members?`$select=id&`$top=999"

    do {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri
        $existingUsers += $response.value.id
        $uri = $response.'@odata.nextLink'
    } while ($uri)

    Write-Info "Existing members: $($existingUsers.Count)"

# -------------------------------------------------------
# SAFE LIST COMPARISON — GUARANTEED NO NULL ERRORS
# -------------------------------------------------------

# Always force arrays, but remove nulls
$CurrentUsers  = @($CurrentUsers | Where-Object { $_ })
$existingUsers = @($existingUsers | Where-Object { $_ })

$add    = @()
$remove = @()

# Only compare if there is at least one REAL value
if ($CurrentUsers.Count -gt 0 -or $existingUsers.Count -gt 0) {

    $diff = Compare-Object `
        -ReferenceObject $CurrentUsers `
        -DifferenceObject $existingUsers `
        -PassThru

    if ($diff) {
        $add    = $diff | Where-Object { $_.SideIndicator -eq '<=' }
        $remove = $diff | Where-Object { $_.SideIndicator -eq '=>' }
    }
}


    Write-Add    "Users to ADD: $($add.Count)"
    Write-Remove "Users to REMOVE: $($remove.Count)"

    # -------------------------------------------------------
    # ADD MEMBERS — SAFE BATCHING
    # -------------------------------------------------------
    if ($add.Count -gt 0) {
        Write-Add "Adding users to group…"

        $bindList = $add | ForEach-Object {
            "https://graph.microsoft.com/beta/directoryObjects/$_"
        }

        for ($i=0; $i -lt $bindList.Count; $i += 20) {
            $batch = $bindList[$i..([Math]::Min($i+19, $bindList.Count-1))]
            Write-Add "Adding batch of $($batch.Count) users…"

            Invoke-MgGraphRequest -Method PATCH -Uri "/beta/groups/$groupId" -Body @{
                "members@odata.bind" = $batch
            }
        }
    }

    # -------------------------------------------------------
    # REMOVE MEMBERS
    # -------------------------------------------------------
    if ($remove.Count -gt 0) {
        Write-Remove "Removing users from group…"

        foreach ($u in $remove) {
            Write-Remove "Removing $u"
            Invoke-MgGraphRequest -Method DELETE -Uri "/beta/groups/$groupId/members/$u/`$ref"
        }
    }

    Write-Info "Completed group: $GroupName"
    Write-Host ""
}

# =====================================================================
# Connect
# =====================================================================
Connect-MgGraph -NoWelcome -Scopes "Group.ReadWrite.All","Directory.Read.All","RoleManagement.Read.All"

# =====================================================================
# Find groups that already exist
# =====================================================================
$global:groups = (
    Invoke-MgGraphRequest -Method GET -Uri "/beta/groups?`$filter=startswith(displayName,'$groupPrefix')&`$select=displayName"
).value.displayName

Write-Info "Found $($groups.Count) existing admin role groups"

# =====================================================================
# Get privileged roles
# =====================================================================
Write-Info "Collecting privileged role assignments…"

$privileged = (
    Invoke-MgGraphRequest -Method GET -Uri "/beta/roleManagement/directory/roleAssignments?`$expand=roleDefinition&`$filter=roleDefinition/isPrivileged eq true&`$select=principalId"
).value.principalId |
    Select-Object -Unique |
    ForEach-Object {
        Invoke-MgGraphRequest -Method GET -Uri "/beta/directoryObjects/$_" |
            Where-Object { $_.'@odata.type' -in ('#microsoft.graph.user', '#microsoft.graph.group') }
    } |
    Select-Object -ExpandProperty id

ProcessGroup -GroupName ($groupPrefix + "privileged") -CurrentUsers $privileged

# =====================================================================
# Non-privileged roles
# =====================================================================
Write-Info "Collecting non-privileged role assignments…"

$nonprivileged = (
    Invoke-MgGraphRequest -Method GET -Uri "/beta/roleManagement/directory/roleAssignments?`$expand=roleDefinition&`$filter=roleDefinition/isPrivileged eq false&`$select=principalId"
).value.principalId |
    Select-Object -Unique |
    ForEach-Object {
        Invoke-MgGraphRequest -Method GET -Uri "/beta/directoryObjects/$_" |
            Where-Object { $_.'@odata.type' -in ('#microsoft.graph.user', '#microsoft.graph.group') }
    } |
    Select-Object -ExpandProperty id

ProcessGroup -GroupName ($groupPrefix + "nonprivileged") -CurrentUsers $nonprivileged

# =====================================================================
# ALL roles
# =====================================================================
$all = ($privileged + $nonprivileged) | Select-Object -Unique
ProcessGroup -GroupName ($groupPrefix + "all") -CurrentUsers $all
