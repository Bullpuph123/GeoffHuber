\# 🔐 Entra PowerShell Automation Library



\*A curated collection of PowerShell scripts for Microsoft Entra ID,

role governance, and identity lifecycle automation.\*



------------------------------------------------------------------------



\## 🚀 Overview



This folder contains production-ready automation used for managing

Microsoft Entra roles, administrative access, and security-related

identity attributes.



All scripts in this collection follow these standards:



\-   Clean, modular structure  

\-   Colorful console output  

\-   CSV-driven automation where applicable  

\-   WhatIf / safety-first execution  

\-   Logging and error handling  

\-   Detailed per-folder READMEs  



------------------------------------------------------------------------



\# 📁 Folder Structure



&nbsp;   /Entra

&nbsp;       /EntraAdminRoleSync

&nbsp;           Entra-AdminRoleSync.ps1       → Sync Entra admin roles into structured groups

&nbsp;           README.md



&nbsp;       /EntraRoleManagement

&nbsp;           Get-UserRoles.ps1             → Enumerate Entra roles for a user

&nbsp;           Remove-UserRoles.ps1          → Remove Entra roles cleanly

&nbsp;           README.md



&nbsp;       /ProdataKeyCards

&nbsp;           Batch-Set-ProdataKeyCards.ps1 → Batch set PDK card attributes using CSV

&nbsp;           Get-ProdataKeyCards.ps1       → Query card attributes

&nbsp;           Set-ProdataKeyCards.ps1       → Update card attributes for single user

&nbsp;           cards.csv                     → Sample import format

&nbsp;           README.md



------------------------------------------------------------------------



\# 🧭 Script Categories



\### 🔐 \*\*Entra Admin Role Sync\*\*



Tools that synchronize privileged role assignments into structured

security groups for compliance, reporting, and automation.



Typical use cases:



\-   Standardizing admin access

\-   Preparing for audits

\-   Enforcing least-privilege by design



---



\### 🛡️ \*\*Entra Role Management\*\*



Utility scripts that retrieve, assign, and remove Entra role

assignments using Microsoft Graph.



Designed so Helpdesk and IT Ops can:



\-   View current user role assignments

\-   Remove elevated access safely

\-   Perform targeted role cleanup



---



\### 🏷️ \*\*ProdataKey Card Automation\*\*



Automation for managing ProdataKey card values stored as Entra

custom security attributes.



Supports:



\-   CSV-based bulk imports

\-   Attribute corrections

\-   Access reporting for facilities and security



------------------------------------------------------------------------



\# 📘 Requirements



These scripts may require one or more of the following:



\-   PowerShell 5.1 or PowerShell 7+  

\-   Microsoft Graph PowerShell SDK  

\-   Entra role permissions appropriate to the action  

\-   CSV import files for bulk actions  



------------------------------------------------------------------------



✅ \*\*Start by opening the README inside each subfolder for full

parameter documentation and real-world examples.\*\*



