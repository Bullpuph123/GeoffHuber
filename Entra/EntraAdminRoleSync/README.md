# README -- Entra Admin Role Sync Utility

🌟 **Entra Admin Role Sync Utility**\
Located in:

    /entra/EntraAdminRoleSync/

Primary script:

    Entra-AdminRoleSync.ps1

This PowerShell automation synchronizes Entra (Azure AD) role
assignments into three standardized security groups for security
governance, conditional access, auditing, and compliance workflows.

------------------------------------------------------------------------

## ✨ Features & Capabilities

### 🔍 **1. Automatically Collects Entra Role Assignments**

The script uses Microsoft Graph to pull: - **Privileged admin roles** -
**Non-privileged roles** - **All roles (combined)**

It includes: - Users\
- Groups\
Skips: - Applications\
- Managed Identities

------------------------------------------------------------------------

### 🛠️ **2. Automatically Creates & Maintains Three Security Groups**

Inside your tenant, the script will create (if missing):

  -----------------------------------------------------------------------
  Group Name                              Meaning
  --------------------------------------- -------------------------------
  `ENTRA-adminroles-privileged`           Users/groups with privileged
                                          roles

  `ENTRA-adminroles-nonprivileged`        Users/groups with
                                          non-privileged roles

  `ENTRA-adminroles-all`                  Union of all role holders
  -----------------------------------------------------------------------

These are: - **Security-enabled** - **Mail-disabled** -
**Governance-ready**

------------------------------------------------------------------------

### 🔁 **3. Safe, Intelligent Membership Syncing**

The script: - Compares current group membership vs. expected
membership - Adds missing users in **safe batches of 20** - Removes
users who no longer hold roles - Output is **colorful**, **clear**, and
**fully verbose**

------------------------------------------------------------------------

### 🧱 **4. Bulletproof Null-Safe Logic**

This version includes: - Null-safe array coercion - Clean filtering to
avoid `$null` Compare-Object crashes - Stable membership sync even when
role assignments temporarily return empty sets

------------------------------------------------------------------------

## 🎨 Console Output Color Legend

  Color         Meaning
  ------------- ---------------------
  **Cyan**      General information
  **Green**     Added members
  **Yellow**    Removed members
  **Magenta**   Warnings
  **Red**       Errors

------------------------------------------------------------------------

## 📦 Requirements

-   PowerShell **7+**
-   Microsoft.Graph PowerShell SDK
-   Graph Scopes:
    -   `Group.ReadWrite.All`
    -   `Directory.Read.All`
    -   `RoleManagement.Read.All`

### First-time permission authentication may be required.

------------------------------------------------------------------------

## 🚀 Usage

### Run the sync:

``` powershell
.\Entra-AdminRoleSync.ps1
```

### If Graph authentication expires:

``` powershell
Disconnect-MgGraph
Connect-MgGraph -Scopes "Group.ReadWrite.All","Directory.Read.All","RoleManagement.Read.All"
```

------------------------------------------------------------------------

## 🧪 Example Output

    [*] Processing group: ENTRA-adminroles-privileged
    [*] Group exists. ID: 98055d1e-71c9-48ce-8595-0030bafd757f
    [*] Existing members: 1
    [+] Users to ADD: 0
    [-] Users to REMOVE: 0
    [*] Completed group: ENTRA-adminroles-privileged

------------------------------------------------------------------------

## 🔐 Security Notes

-   No role assignments are altered --- only **group membership**.
-   Groups can be used in:
    -   Conditional Access\
    -   SIEM/SOAR rules\
    -   Compliance / Audit reports\
    -   Administrative dashboards

------------------------------------------------------------------------

## 📘 Summary

`Entra-AdminRoleSync.ps1` is an enterprise-grade Identity Governance
automation tool that: - Keeps admin-related groups accurate\
- Reduces human error\
- Improves visibility\
- Strengthens governance and compliance\
- Works reliably in any size environment

Perfect for secure baseline operations and IAM automation.
