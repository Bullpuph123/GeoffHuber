\# 🔐 Entra Scripts Collection



Welcome to the \*\*Entra\*\* scripts folder.  

This directory contains tools to help automate and standardize work in \*\*Microsoft Entra ID\*\* (Azure AD), especially around admin roles and custom attributes.



---



\## 📂 Folder Overview



| Folder | Description |

|--------|-------------|

| \[`EntraAdminRoleSync`](./EntraAdminRoleSync) | Automates \*\*admin role assignment sync\*\* in Entra ID based on configuration (CSV / groups), with safety checks and logging. |

| \[`EntraRoleManagement`](./EntraRoleManagement) | General \*\*role management utilities\*\* – reporting, exporting role assignments, and helper scripts for troubleshooting and audits. |

| \[`ProdataKeyCards`](./ProdataKeyCards) | Handles \*\*ProdataKey card metadata\*\* in Entra using custom security attributes (assigning card IDs, status flags, and reporting on card usage). |



---



\## 🚀 How to Use (High Level)



> \*\*Prereqs (common across most scripts)\*\*  

> - PowerShell 7+ recommended  

> - Microsoft Graph / Entra modules installed  

> - Appropriate permissions in Entra ID (often \*\*Privileged Role Administrator\*\* or \*\*User Administrator\*\*)



\### 1. EntraAdminRoleSync



\- Syncs Entra admin roles from a source of truth (CSV / groups) to actual \*\*role assignments\*\*.

\- Includes:

&nbsp; - Dry-run / \*\*WhatIf\*\* support

&nbsp; - Logging of changes

&nbsp; - Clear reporting of adds/removes



👉 See the script-specific README inside \[`EntraAdminRoleSync`](./EntraAdminRoleSync) for details.



---



\### 2. EntraRoleManagement



\- Utility scripts to:

&nbsp; - Export current role assignments

&nbsp; - Help with audits and access reviews

&nbsp; - Generate CSVs you can feed into other tools (like the role-sync script)



👉 Check the internal README in \[`EntraRoleManagement`](./EntraRoleManagement) for parameters and examples.



---



\### 3. ProdataKeyCards



\- Manages \*\*ProdataKey\*\* card info in Entra via \*\*custom security attributes\*\*.

\- Typical workflows:

&nbsp; - Import card assignments from a CSV

&nbsp; - Set/remove card IDs and status attributes on users

&nbsp; - Generate reports for facilities / security teams



👉 See the README in \[`ProdataKeyCards`](./ProdataKeyCards) for usage examples.



---



\## 🎯 Conventions



\- 🧪 Use \*\*WhatIf / Confirm\*\* switches where available before making production changes.

\- 📝 Scripts are designed to be:

&nbsp; - Logged

&nbsp; - Re-runnable

&nbsp; - Friendly to change control and audits



If you’re not sure where to start, begin with the \*\*reporting/export\*\* scripts in each folder before running any \*\*change\*\* scripts.



