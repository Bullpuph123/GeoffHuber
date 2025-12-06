# 🧰 GeoffHuber PowerShell Automation Library

*A curated collection of PowerShell scripts for Entra ID, Role
Management, Automation, and Infrastructure Ops.*

------------------------------------------------------------------------

## 🚀 Overview

This repository contains a growing library of production-ready
PowerShell scripts used across identity, security, automation, and
operational tooling.\
Each folder contains purpose-built modules and utilities with:

-   Clean, well-organized structures\
-   Colorful console output\
-   HTML reporting\
-   Error-handling and logging\
-   Clear examples and usage notes

You are welcome to use, adapt, and contribute improvements.

------------------------------------------------------------------------

# 📁 Repository Structure

    /Entra
        /EntraAdminRoleSync
            Entra-AdminRoleSync.ps1       → Sync Entra admin roles into structured groups
            README.md

    	/EntraRoleManagement
            Get-UserRoles.ps1                 → Enumerate Entra roles for a user
            Remove-UserRoles.ps1              → Remove user Entra roles cleanly
            README.md

    	/ProdataKeyCards
            Batch-Set-ProdataKeyCards.ps1     → Batch set card attributes using CSV input
            Get-ProdataKeyCards.ps1           → Query card attributes
            Set-ProdataKeyCards.ps1           → Update card attributes for a single user
            cards.csv                         → Sample CSV format
            README.md

   /SharepointOnline
   	/Rename-SharepointSite
 	    Rename-SharepointSite.ps1
	    README.md
------------------------------------------------------------------------

# 🧭 Script Categories

### 🔐 **Entra Admin Role Sync**

Tools that synchronize role assignments into structured admin groups,
useful for compliance, visibility, and automation.

### 🛡️ **Entra Role Management**

Scripts that retrieve, add, or remove Microsoft Entra role assignments
using the Microsoft Graph PowerShell SDK.

### 🏷️ **ProdataKey Card Automation**

Automation that reads/writes PDK card values stored in Active Directory
extension attributes.

------------------------------------------------------------------------

# 📘 Requirements

These scripts may require one or more of the following:

-   PowerShell 5.1 or PowerShell 7+\
-   Microsoft Graph PowerShell SDK\
-   RSAT Active Directory Module\
-   Entra role permissions appropriate to the action
