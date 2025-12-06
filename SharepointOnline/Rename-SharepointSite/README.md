# 🚀 Rename-SharePointSite.ps1  
### A Complete, Safe, and Automated SharePoint Online Site URL Rename Script  
**Author:** Geoffrey Huber 
**Version:** 1.0  
**Created:** 2025-11-26  

---

## 🌈 Overview  
This script provides a **safe**, **validated**, and **automated** way to rename a SharePoint Online site using Microsoft's `Start-SPOSiteRename` cmdlet.  

It includes:

- ✔ Full pre‑rename validation  
- ✔ Optional **`-WhatIf` safe test mode**  
- ✔ Status polling until completion  
- ✔ Optional suppression flags for known SPO rename blockers  
- ✔ Color‑coded console output  
- ✔ PowerShell 5.1 & PowerShell 7 support  

---

## 📦 Prerequisites  

### 🟦 Microsoft Requirements  
Before running this script, ensure the following:

1. **SharePoint Online Admin Role** (or Global Admin)
2. Modern SharePoint Admin Center URL:
   - `https://<tenant>-admin.sharepoint.com`
3. SharePoint Online Management Shell PowerShell module:  
   ```powershell
   Install-Module Microsoft.Online.SharePoint.PowerShell -Scope AllUsers
   ```

---

## 🖥 PowerShell Compatibility  

### ✔ Windows PowerShell 5.1 (Recommended)  
Fully supported.

### ✔ PowerShell 7.x  
You must import the SPO module using Windows compatibility:

```powershell
Import-Module Microsoft.Online.SharePoint.PowerShell -UseWindowsPowerShell
```

---

## 🛠 What This Script Does  

1. Loads the SPO module  
2. Connects securely to the SPO Admin Center  
3. Performs a **ValidationOnly** check  
4. Optionally performs a **WhatIf simulation**  
5. Executes the rename  
6. Polls progress with `Get-SPOSiteRenameState`  
7. Displays clear status messages and color-coded results  

---

## 🧪 Examples  

### 🟩 **1. Safe Test Run (Recommended First Step)**  
Simulates the rename without making changes:

```powershell
.\Rename-SharePointSite.ps1 `
    -OldUrl "https://contoso.sharepoint.com/sites/GlobalBookkeeperTeam" `
    -NewUrl "https://contoso.sharepoint.com/sites/GB" `
    -WhatIf
```

---

### 🟦 **2. Perform Actual Rename (Live Change)**  
After validation succeeds:

```powershell
.\Rename-SharePointSite.ps1 `
    -OldUrl "https://contoso.sharepoint.com/sites/GlobalBookkeeperTeam" `
    -NewUrl "https://contoso.sharepoint.com/sites/GB"
```

---

### 🟧 **3. Rename With Warning Suppression Flags**  
Used for known SPO rename blockers (BCS, Apps, Workflow 2013):

```powershell
.\Rename-SharePointSite.ps1 `
    -OldUrl "https://contoso.sharepoint.com/sites/LegacySite" `
    -NewUrl "https://contoso.sharepoint.com/sites/NewSite" `
    -SuppressBcsCheck `
    -SuppressWorkflow2013Check
```

---

### 🟥 **4. Running in PowerShell 7**  
```powershell
Import-Module Microsoft.Online.SharePoint.PowerShell -UseWindowsPowerShell

.\Rename-SharePointSite.ps1 -OldUrl ... -NewUrl ...
```

---

## 📝 Parameters  

| Parameter | Description |
|----------|-------------|
| `-AdminCenterUrl` | SPO admin center URL |
| `-OldUrl` | Existing site URL |
| `-NewUrl` | New URL to apply |
| `-WhatIf` | Performs a safe, simulated rename |
| `-SuppressBcsCheck` | Skips BCS dependency check |
| `-SuppressWorkflow2013Check` | Skips Workflow 2013 warnings |
| `-SuppressMarketplaceAppCheck` | Skips app marketplace warnings |
| `-SuppressAllWarnings` | Silences all non-critical warnings |
| `-PollIntervalSeconds` | Seconds between rename status checks |
| `-MaxPollMinutes` | Maximum monitoring duration |

---

## 🔍 Logging & Output  
The script uses color-coded console messages for:

- 🟩 Success  
- 🟨 Warnings  
- 🟥 Errors  
- 🔵 Info  

---

## 📜 Recommended Rename Flow  

1. **Run with `-WhatIf`**  
2. **Run validation only** (automatically done by script)  
3. **Run live rename**  
4. **Monitor status** (script polls automatically)  
5. **Verify site access after rename**  

---

## 📂 Repository Placement (SVN)  
This file should be committed alongside:  

```
/SVN/PowerShell/Rename-SharePointSite/
    Rename-SharePointSite.ps1
    README.md   ← (this file)
```

---

## 🧾 Change Log  

**1.0 — Initial release**  
- Added WhatIf support  
- Added validation and polling  
- Color output  
- PowerShell 7 compatibility  

---

## 🎉 Done!  
Use this safely to rename SPO sites with confidence.  
If you need packaging in ZIP, HTML documentation, or a versioned release tag, I can generate that too.  
