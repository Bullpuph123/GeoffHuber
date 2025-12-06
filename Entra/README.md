\# 🗂️ \*\*Entra Automation – Folder Structure\*\*

\*Visual map of all tools in this library\*



---



\## 📁 `/Entra` (Root)



\### 🔐 `/EntraAdminRoleSync`

> \*\*Automated admin role governance\*\*



| File | Purpose |

|------|--------|

| \*\*`Entra-AdminRoleSync.ps1`\*\* | 🔄 Sync Entra admin roles into structured security groups |

| `README.md` | 📘 Full documentation \& usage |



---



\### 🛡️ `/EntraRoleManagement`

> \*\*User-focused role inspection \& cleanup\*\*



| File | Purpose |

|------|--------|

| \*\*`Get-UserRoles.ps1`\*\* | 🔍 Enumerate Entra roles for a user |

| \*\*`Remove-UserRoles.ps1`\*\* | 🧹 Remove Entra roles cleanly and safely |

| `README.md` | 📘 Full documentation \& usage |



---



\### 🏷️ `/ProdataKeyCards`

> \*\*Physical access \& card attribute automation\*\*



| File | Purpose |

|------|--------|

| \*\*`Batch-Set-ProdataKeyCards.ps1`\*\* | 📥 Batch set PDK card attributes using CSV |

| \*\*`Get-ProdataKeyCards.ps1`\*\* | 📊 Query card attributes |

| \*\*`Set-ProdataKeyCards.ps1`\*\* | 🎯 Update card attributes for a single user |

| \*\*`cards.csv`\*\* | 📄 Sample import format |

| `README.md` | 📘 Full documentation \& usage |



---



\# 🧭 \*\*Script Categories \& Use Cases\*\*



---



\## 🔐 \*\*Entra Admin Role Sync\*\*

> \*Structured, auditable, and repeatable admin role governance\*



Tools that synchronize privileged role assignments into structured  

security groups for \*\*compliance, reporting, and automation\*\*.



\### ✅ Typical Use Cases

\- ✅ Standardizing admin access  

\- ✅ Preparing for audits  

\- ✅ Enforcing \*\*least-privilege by design\*\*



---



\## 🛡️ \*\*Entra Role Management\*\*

> \*Day-to-day identity operations for IT \& Helpdesk\*



Utility scripts that retrieve, assign, and remove Entra role  

assignments using \*\*Microsoft Graph\*\*.



\### ✅ Designed So IT Can:

\- ✅ View current user role assignments  

\- ✅ Remove elevated access safely  

\- ✅ Perform targeted role cleanup  



---



\## 🏷️ \*\*ProdataKey Card Automation\*\*

> \*Identity meets physical access control\*



Automation for managing ProdataKey card values stored as Entra  

\*\*custom security attributes\*\*.



\### ✅ Supports:

\- ✅ CSV-based bulk imports  

\- ✅ Attribute corrections  

\- ✅ Facilities \& security reporting  



---



\# 📘 \*\*Requirements\*\*

> \*Applies across most scripts in this library\*



✅ \*\*PowerShell 5.1 or PowerShell 7+\*\*  

✅ \*\*Microsoft Graph PowerShell SDK\*\*  

✅ \*\*Entra role permissions appropriate to the action\*\*  

✅ \*\*CSV import files for bulk operations\*\*



---



> ✅ \*\*Always start by opening the `README.md` inside each subfolder for full  

> parameter documentation and real-world execution examples.\*\*



