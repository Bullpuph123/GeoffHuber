# ProdataKey Cards Toolkit for Entra ID (Azure AD)

PowerShell scripts to manage **ProdataKey security card numbers** stored in **Microsoft Entra ID** Custom Security Attributes (CSA).  
This README covers:

- `Set-ProdataKeyCards.ps1` — Add/replace/append card numbers on a user.
- `Get-ProdataKeyCards.ps1` — Retrieve card numbers for one or many users by UPN/name and/or Office Location.
- `Batch-Set-ProdataKeyCards.ps1` — Bulk apply cards from a CSV by calling the Set script (Append by default).

---

## Requirements

- **PowerShell 7+** (recommended)
- Module: **Microsoft.Graph**
- Entra tenant using **Custom Security Attributes** with a set named **`ProdataKey`** and an attribute **`Cards`** (StringCollection).  
  > The scripts expect `CustomSecurityAttributes.AdditionalProperties.ProdataKey.Cards` to hold the values.

### Graph permissions (delegated)
- Read: `User.Read.All`, `User.ReadBasic.All`, `CustomSecAttributeDefinition.Read.All`, `CustomSecAttributeAssignment.Read.All`
- Write (Set script only): `User.ReadWrite.All`, `CustomSecAttributeAssignment.ReadWrite.All`

The scripts auto-connect using these scopes at first run. You can force a fresh login with `-ForceLogin` and/or specify a tenant with `-TenantId`.

---

## Install the Microsoft Graph module (once)

```powershell
# PowerShell 7+
Install-Module Microsoft.Graph -Scope CurrentUser

# If you downloaded the scripts and see a security prompt:
Unblock-File -Path .\Set-ProdataKeyCards.ps1, .\Get-ProdataKeyCards.ps1, .\Batch-Set-ProdataKeyCards.ps1
```

---

## Common Object Model (Output)

Both **Get** and **Set** work with native PowerShell objects so you can pipe to `Format-Table`, `Format-List`, `Export-Csv`, etc.

```text
DisplayName    string
UPN            string
Mail           string
OfficeLocation string
Cards          string[]   # array of card codes or $null if none
```

---

## Get-ProdataKeyCards.ps1

Retrieve ProdataKey card numbers for one or many users.

### Parameters
- `-Identity <string>`: UPN, exact/partial DisplayName, or partial UPN/Mail.  
  - Tries exact UPN first, then `startswith(displayName, ...)`, then client-side contains on DisplayName/UPN/Mail.
- `-OfficeLocation <string>`: Exact/partial office location.  
  - Tries `startswith(officeLocation, ...)`, then client-side contains.
- `-TenantId <guid or domain>` (optional): Connect to a specific tenant.
- `-ForceLogin` (switch): Force a new Graph login/cache.

> When **both** `-Identity` and `-OfficeLocation` are supplied, results are the **intersection** (users matching both).

### Examples
```powershell
# Exact user by UPN
.\Get-ProdataKeyCards.ps1 -Identity "user@domain.com" | Format-List

# All matches for a partial name
.\Get-ProdataKeyCards.ps1 -Identity "Geoff" | Format-Table -AutoSize

# Everyone in an office (partial match)
.\Get-ProdataKeyCards.ps1 -OfficeLocation "Chico" | ft DisplayName,UPN,OfficeLocation

# Intersection (name + office)
.\Get-ProdataKeyCards.ps1 -Identity "Geoff" -OfficeLocation "Chico"
```

---

## Set-ProdataKeyCards.ps1

Create or update a user's card numbers.

### Parameters
- `-UserId <string>`: UPN or objectId of the target user.
- `-Cards <string[]>`: One or more card codes. (Validation enforced by the script's rules.)
- `-Append` (switch): If present, merges with existing values; otherwise **replaces**.
- `-TenantId <guid or domain>` (optional).
- `-ForceLogin` (switch).

### Examples
```powershell
# Replace with exactly these cards
.\Set-ProdataKeyCards.ps1 -UserId "user@domain.com" -Cards "123456","A1B2C3"

# Append a new card, preserve existing
.\Set-ProdataKeyCards.ps1 -UserId "user@domain.com" -Cards "555555" -Append

# Force a new login session
.\Set-ProdataKeyCards.ps1 -UserId "user@domain.com" -Cards "444444" -ForceLogin
```

---

## Batch-Set-ProdataKeyCards.ps1

Bulk-apply cards from a CSV by calling the Set script.  
**Default mode is `Append`.** Use `-Mode Replace` to overwrite existing values exactly.

### CSV format
The CSV must contain:
- `UPN`  — user principal name (e.g., user@domain.com)  
- `Cards` — one or more codes separated by **comma**, **semicolon**, or **whitespace**

**Example `cards.csv`:**
```csv
UPN,Cards
geoff.huber@domain.org,111111
gary.McGaryFace@domain.org,555555 666666
jane.doe@domain.org,A1B2C3;D4E5F6
```

### Parameters
- `-CsvPath <string>` (required): Path to the CSV file.
- `-Mode <Append|Replace>` (default: **Append**): Append or replace mode when calling the Set script.
- `-SetScriptPath <string>` (optional): Path to `Set-ProdataKeyCards.ps1`. Defaults to the **same folder** as this batch script.
- `-TenantId <string>` (optional): Passed through to the Set script.
- `-ForceLogin` (switch): Forces fresh Graph login in the Set script.
- `-DryRun` (switch): Prints what would be done; no changes made.

### Examples
```powershell
# Append (default)
.\Batch-Set-ProdataKeyCards.ps1 -CsvPath .\cards.csv

# Replace (overwrite existing cards with exactly what's in CSV)
.\Batch-Set-ProdataKeyCards.ps1 -CsvPath .\cards.csv -Mode Replace

# Custom path to Set script
.\Batch-Set-ProdataKeyCards.ps1 -CsvPath .\cards.csv -SetScriptPath "C:\Entra\Reports\Set-ProdataKeyCards.ps1"

# Preview only
.\Batch-Set-ProdataKeyCards.ps1 -CsvPath .\cards.csv -DryRun
```

### Behavior & Notes
- The batch script splits `Cards` by **comma**, **semicolon**, or **whitespace** into an array before calling the Set script.
- Rows with missing `UPN` or no `Cards` are skipped and logged in the summary output.
- Results are emitted as objects with per-row status (`OK`, `ERROR`, `DRYRUN`).
- Ensure all scripts are unblocked before first run:
  ```powershell
  Unblock-File .\Set-ProdataKeyCards.ps1, .\Get-ProdataKeyCards.ps1, .\Batch-Set-ProdataKeyCards.ps1
  ```

---

## Tips & Behavior

- **Auto-connect to Graph**: Both **Get** and **Set** validate the current `Get-MgContext` and call `Connect-MgGraph` with the required scopes when needed. Use `-TenantId` or `-ForceLogin` to control the session.
- **CSA Path**: The cards are read/written at `CustomSecurityAttributes.AdditionalProperties.ProdataKey.Cards`.
- **Pipeline-friendly**: `Get-ProdataKeyCards.ps1` accepts pipeline input for `-Identity` (e.g., `"hub" | .\Get-ProdataKeyCards.ps1`). Both scripts output/consume objects for easy formatting or export.
- **Performance**: Server-side filters use `startswith(...)` for speed. When no match is found, the script falls back to a broader client-side contains search (may enumerate users).

---

## Troubleshooting

- **Security warning when running scripts**  
  ```powershell
  Unblock-File -Path .\Get-ProdataKeyCards.ps1, .\Set-ProdataKeyCards.ps1, .\Batch-Set-ProdataKeyCards.ps1
  ```
- **Module not found**  
  ```powershell
  Install-Module Microsoft.Graph -Scope CurrentUser
  Import-Module Microsoft.Graph
  ```
- **Permissions/consent**  
  If you get authorization errors, make sure an administrator has granted (or you accept) the delegated scopes listed above.
- **Attribute not found**  
  Verify the Custom Security Attribute set `ProdataKey` and attribute `Cards` exist and are `Available` with type `StringCollection`.

---

## Changelog

- **2025-09-24**  
  - Added `Get-ProdataKeyCards.ps1` with `-Identity` and `-OfficeLocation` search (intersection supported).  
  - Added `Batch-Set-ProdataKeyCards.ps1` (bulk update from CSV; Append default) and example `cards.csv`.  
  - Consolidated README for Set, Get, and Batch workflows.
