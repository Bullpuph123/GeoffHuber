# 📁 SharePoint Online PowerShell Automation Library

*A focused collection of PowerShell tools for safe SharePoint Online
administration and site lifecycle operations.*

------------------------------------------------------------------------

## 🚀 Overview

This folder contains automation built specifically for **SharePoint
Online tenant administration**, with an emphasis on:

-   Safe operational changes\
-   Pre-change validation\
-   Blackout window enforcement\
-   Logging for change control\
-   Human-readable console output

------------------------------------------------------------------------

# 📁 Folder Structure

``` text
/SharepointOnline
    /Rename-SharepointSite
        Rename-SharePointSite.ps1     → Safely renames a SharePoint Online site and URL
        README.md                     → Full execution guide and change workflow
```

------------------------------------------------------------------------

# 🧭 Script Categories

## 🔄 SharePoint Site Rename Automation

Tools designed to make high-risk SharePoint changes predictable and
repeatable.

The **Rename-SharepointSite** solution supports:

-   Validation of existing site and target URL\
-   Checks against deleted site conflicts\
-   Maintenance window enforcement\
-   Safe execution of Rename-SPOSite\
-   Logging suitable for change management\
-   Clear rollback visibility

Typical use case:

> Renaming the **Global Bookkeeper** SharePoint site to **GB** with full
> audit visibility and zero guesswork.

------------------------------------------------------------------------

# 📘 Requirements

These scripts may require:

-   PowerShell 5.1 or PowerShell 7+\
-   SharePoint Online Management Shell\
-   SharePoint Administrator permissions\
-   Tenant-level rename permissions

------------------------------------------------------------------------

✅ **Always review the README inside each script folder before execution
in production.**
