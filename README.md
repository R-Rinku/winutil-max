<div align="center">

# ⚡ winutil-MAX

### The Ultimate Windows Optimization, Automation & Tweaking Suite

<img src="MAX.jpg" alt="winutil-MAX - Running Up That Hill" width="700" style="border-radius: 12px; box-shadow: 0 4px 20px rgba(255, 0, 127, 0.4);" />

<br/><br/>

<p align="center">
  <a href="https://github.com/R-Rinku/winutil-max/stargazers">
    <img alt="Stars" src="https://img.shields.io/github/stars/R-Rinku/winutil-max?style=for-the-badge&logo=github&color=ff007f&labelColor=111827">
  </a>
  <a href="https://github.com/R-Rinku/winutil-max/network/members">
    <img alt="Forks" src="https://img.shields.io/github/forks/R-Rinku/winutil-max?style=for-the-badge&logo=github&color=9900ef&labelColor=111827">
  </a>
  <a href="https://github.com/R-Rinku/winutil-max/blob/main/LICENSE">
    <img alt="License" src="https://img.shields.io/github/license/R-Rinku/winutil-max?style=for-the-badge&color=00c853&labelColor=111827">
  </a>
  <a href="https://github.com/R-Rinku/winutil-max/commits/main">
    <img alt="Last Commit" src="https://img.shields.io/github/last-commit/R-Rinku/winutil-max?style=for-the-badge&logo=github&color=ff5722&labelColor=111827">
  </a>
  <a href="https://www.rinkurapria.dev/" target="_blank" rel="noopener">
    <img alt="Portfolio" src="https://img.shields.io/badge/Portfolio-rinkurapria.dev-0070f3?style=for-the-badge">
  </a>
  <a href="https://www.rinkurapria.dev/blog/" target="_blank" rel="noopener">
    <img alt="Blogs" src="https://img.shields.io/badge/Blogs-rinkurapria.dev%2Fblog-111827?style=for-the-badge">
  </a>
</p>

---

</div>

## 🚀 Quick Start

**winutil-MAX** must be run as **Administrator** because it makes system-wide configurations, tweaks registry policies, and manages Windows components.

Launch directly from an elevated Windows PowerShell or Windows Terminal prompt:

```powershell
irm rinkurapria.dev/win | iex
```

*(Direct GitHub fallback)*:
```powershell
irm https://raw.githubusercontent.com/R-Rinku/winutil-max/main/winutil.ps1 | iex
```

---

### 💻 How to Open an Elevated Administrator Terminal

* **Quick Link / WinX Menu**: Right-click the Windows Start button (or press `Win + X`) and choose **Terminal (Admin)** or **PowerShell (Admin)**.
* **Search Menu**: Press `Win + S`, type `PowerShell` or `Terminal`, and press `Ctrl + Shift + Enter`.

---

## ⚙️ Automation / Presets

You can apply predefined configurations directly from the command line without opening the graphical interface:

```powershell
& ([ScriptBlock]::Create((irm rinkurapria.dev/win))) -Preset <PresetName>
```

| Preset | Target User | Description |
| :--- | :--- | :--- |
| **Standard** | General Users | Balanced defaults optimizing telemetry, privacy, and system responsiveness while retaining core compatibility. |
| **Minimal** | Conservative | Light adjustments that leave all optional services intact for maximum enterprise/system application compatibility. |
| **Advanced** | Power Users & Gamers | Deep debloating, aggressive service trimming, telemetry removal, and latency optimizations. |
| **Enterprise** 🛡️ | Work & Production | Dedicated safety mode that restricts bulk AppX removal, Windows Update tampering, and risky system modifications. |

---

## 🌟 Key Features

### 📦 1. Install Tab
* Curated catalog of essential Windows software (Browsers, Development, Gaming, Utilities).
* Supports package installations and upgrades via **WinGet** and **Chocolatey**.
* System inventory detection identifying currently installed software with selective one-click bulk removal.

### 🛠️ 2. Tweaks Tab
* **Essential Debloat**: Removes Cortana, telemetry tracking, advertising IDs, background telemetry diagnostics, and diagnostic tracking services.
* **Performance Enhancements**: Enable ultimate performance power plans, disable mouse acceleration, optimize NTFS timestamps, and configure dark themes.
* **DNS Selector**: Test and apply privacy-respecting DNS providers (Cloudflare, Quad9, Google, AdGuard) with a built-in DHCP restore function.
* **System Restore Safeguard**: Automatically creates a Windows System Restore point prior to executing changes.

### 🗂️ 3. Config Tab (Enhanced with MAX Utilities)
* **[MAX] Smart Bulk Name Modifier**:
  * Powerful interactive bulk renamer for files and folders.
  * Real-time before/after preview grid with change highlights.
  * Search and replace, regular expressions (Regex), case conversions (UPPERCASE, lowercase, Title Case), sequence numbering with custom padding, and prefix/suffix insertions.
  * Auto-elevates permissions to rename restricted directory contents.
* **[MAX] Take Full Ownership**:
  * Integrates a *"Take Full Ownership"* option into the Windows Explorer right-click context menu.
  * Takes ownership using `takeown` and grants administrators full control with `icacls`.
  * Safe toggle to add or remove context menu keys with protection preventing accidental bricking of critical system root directories.
* **Features & Tools**: One-click toggles for Hyper-V, WSL2, Windows Sandbox, Legacy Control Panel, and Group Policy Editor (gpedit.msc) on Windows Home editions.

### 🔄 4. Updates Tab
* **Recommended (Security Only)**: Delays feature updates by 2-3 years while keeping essential security and definition patches running seamlessly.
* **Default**: Restores out-of-the-box Windows Update behavior.
* **Disable Updates**: Completely pauses and blocks automatic update services and triggers for air-gapped or dedicated workstations.

### 💿 5. MicroWin (Windows 11 Creator)
* Strips unwanted bloatware directly from official Windows 11 ISOs.
* Bypasses Windows 11 hardware checks (TPM 2.0, Secure Boot, RAM, CPU requirements) and online Microsoft Account requirements during OOBE setup.
* Injects storage controllers and mass-storage drivers directly into `boot.wim` and `install.wim`.

---

## 🎨 Visual Aesthetics & Stranger Things Theme

**winutil-MAX** features a dedicated visual splash window before loading the interface:
- Displays **Max Mayfield** with her iconic Walkman headphones.
- Clean neon dark theme with custom drop shadows and progress indicator.
- Automatically transitions into the main GUI without spawning extra terminal windows.

---

## 💻 Local Execution & Development

To test or develop locally:

```powershell
# Clone the repository
git clone https://github.com/R-Rinku/winutil-max.git
cd winutil-max

# Compile and launch the utility
.\Run.ps1

# Or compile winutil.ps1 without launching
.\Run.ps1 -CompileOnly
```

### Running Tests
The project includes a comprehensive Pester test suite:
```powershell
Import-Module Pester -RequiredVersion 5.8.0 -Force
Invoke-Pester -Path 'pester/*.Tests.ps1' -Output Detailed -CI
```

---

## ⚠️ Disclaimer

All scripts, tweaks, and configurations are provided **as-is**, without warranty of any kind. You are responsible for reviewing and understanding all actions before applying them to your machine. Always create a System Restore point or full system backup before applying deep tweaks.

---

## 👤 Author & Credits

- **Creator & Maintainer**: **Rinku Rapria**
  - Portfolio: [rinkurapria.dev](https://www.rinkurapria.dev/)
  - Technical Blogs: [rinkurapria.dev/blog](https://www.rinkurapria.dev/blog/) / [dnslabs.tech](https://www.dnslabs.tech/)
  - GitHub: [@R-Rinku](https://github.com/R-Rinku)
- **Original Inspiration**: [Chris Titus Tech (WinUtil)](https://github.com/ChrisTitusTech/winutil)
