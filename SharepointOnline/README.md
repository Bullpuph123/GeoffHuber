\# 📁 SharePoint Online Scripts



This folder contains automation related to \*\*SharePoint Online\*\* administration.



---



\## 📂 Folder Overview



| Folder | Description |

|--------|-------------|

| \[`Rename-SharepointSite`](./Rename-SharepointSite) | Automates \*\*renaming a SharePoint Online site\*\* and updating its URL with safety checks and logging. |



---



\## 🧭 `Rename-SharepointSite` at a Glance



The \[`Rename-SharepointSite`](./Rename-SharepointSite) solution is designed to make a risky operation \*\*predictable and repeatable\*\*:



\- ✅ Validates the existing site and new URL

\- ✅ Checks for conflicts (e.g., deleted sites / existing URLs)

\- ✅ Kicks off the \*\*site rename\*\* operation

\- ✅ Optionally supports a \*\*blackout window\*\* so users stay out during changes

\- ✅ Logs progress so you have a paper trail for change control



Typical use case:



> “We’re renaming the \*\*Global Bookkeeper\*\* site to \*\*GB\*\* and need the URL to match.”



This script walks through that process with guardrails so you don’t have to remember every SPO cmdlet and corner case each time.



---



\## 🔧 Requirements (Common)



\- PowerShell (preferably 7+)

\- SharePoint Online Management Shell / module

\- SharePoint admin rights in the tenant



👉 For full parameters, examples, and step-by-step instructions, see the detailed \[`README.md` inside the Rename-SharepointSite folder](./Rename-SharepointSite/README.md).



---



\## 🎨 Conventions \& Notes



\- Scripts are written with:

&nbsp; - Clear prompts and status messages

&nbsp; - Logging suitable for change tickets

&nbsp; - Support for running during planned maintenance windows

\- Keep this parent README as a \*\*landing page\*\*; each subfolder should contain its own detailed README with parameters and examples.



If you add more SharePoint tools later (e.g., site inventory, permissions reporting, bulk library operations), list them here so this page stays your main \*\*“map of the territory.”\*\*



