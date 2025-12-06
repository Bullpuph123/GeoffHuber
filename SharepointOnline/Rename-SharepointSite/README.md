# 🚀 Rename-SharePointSite.ps1

A safe, validated, and fully automated SharePoint Online site URL rename
script.

## ✅ Features

-   Validation-only mode
-   WhatIf simulation
-   Warning suppression flags
-   PowerShell 5.1 & 7 support
-   Status polling and color output

## 📦 Requirements

-   SharePoint Online Admin role
-   Microsoft.Online.SharePoint.PowerShell module

## 🧪 Example

``` powershell
.\Rename-SharePointSite.ps1 `
  -AdminCenterUrl "https://contoso-admin.sharepoint.com" `
  -OldUrl "https://contoso.sharepoint.com/sites/SourceSite" `
  -NewUrl "https://contoso.sharepoint.com/sites/TargetSite" `
  -WhatIf
```

## 📂 Files

-   Rename-SharePointSite.ps1
-   README.md
