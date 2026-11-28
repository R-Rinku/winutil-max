<div align="center">

# ⚡ Winutil-MAX

### The Ultimate Windows Optimization, Automation & Tweaking Suite
*(Stranger Things / Max Mayfield Edition)*

<br/>

<img src="assets/winutil_max_splash.jpg" alt="Winutil-MAX - Running Up That Hill" width="360" style="border-radius: 14px; box-shadow: 0 8px 30px rgba(229, 9, 20, 0.55);" />

<br/><br/>

<p align="center">
  <a href="https://winutil.rinkurapria.dev/" target="_blank" rel="noopener">
    <img alt="Documentation" src="https://img.shields.io/badge/Docs-winutil.rinkurapria.dev-b997ff?style=for-the-badge">
  </a>
  <a href="https://github.com/R-Rinku/winutil-max/stargazers">
    <img alt="Stars" src="https://img.shields.io/github/stars/R-Rinku/winutil-max?style=for-the-badge&logo=github&color=ff007f&labelColor=111827">
  </a>
  <a href="https://github.com/R-Rinku/winutil-max/network/members">
    <img alt="Forks" src="https://img.shields.io/github/forks/R-Rinku/winutil-max?style=for-the-badge&logo=github&color=9900ef&labelColor=111827">
  </a>
  <a href="https://github.com/R-Rinku/winutil-max/blob/main/LICENSE">
    <img alt="License" src="https://img.shields.io/github/license/R-Rinku/winutil-max?style=for-the-badge&color=00c853&labelColor=111827">
  </a>
  <a href="https://www.rinkurapria.dev/" target="_blank" rel="noopener">
    <img alt="Portfolio" src="https://img.shields.io/badge/Portfolio-rinkurapria.dev-0070f3?style=for-the-badge">
  </a>
</p>

> **Credit & Attribution:** **Winutil-MAX** is built upon [Chris Titus Tech's WinUtil](https://github.com/ChrisTitusTech/winutil) ([official docs](https://winutil.christitus.com/)). We rely on upstream WinUtil maintainers for core engine improvements while adding MAX-exclusive utilities on top. Support Chris Titus at the [Official CTT Store](https://cttstore.com/products/windows-toolbox).

---

</div>

## 🚀 Quick Launch (One-Liner)

Open an elevated **PowerShell** or **Windows Terminal** (*Run as Administrator*) and run:

```powershell
irm rinkurapria.dev/win | iex
```

*(Direct GitHub URL fallback)*:
```powershell
irm https://raw.githubusercontent.com/R-Rinku/winutil-max/main/winutil.ps1 | iex
```

*(Dev / Pre-Release Channel)*:
```powershell
irm rinkurapria.dev/windev | iex
```
```powershell
irm https://raw.githubusercontent.com/R-Rinku/winutil-max/refs/heads/main/windev.ps1 | iex
```

---

## ✨ What's New in winutil-MAX

* **📼 Stranger Things (Max Mayfield) Theme**:
  * Visual splash screen featuring Max Mayfield with Walkman headphones before GUI startup.
  * Deep charcoal void (`#111116`) paired with neon synthwave magenta (`#FF007F`) borders, glowing highlights, and retro accents.
  * Streamlined launch: opens directly inside your active console window with only 1 main GUI window (no duplicate terminal popups).

* **🚀 MAX Tab**:
  * **🏷️ Smart Bulk Name Modifier**: Interactive bulk file & folder renaming utility with instant before-and-after live preview, regex, and numbering.
  * **📂 OneDrive Sync Exclusion Manager**: Exclude developer folders (`node_modules`, `.git`, `dist`, `build`, caches) and file patterns from OneDrive cloud sync while keeping them intact locally.
  * **🔑 Take Full Ownership**: One-click integration to add or remove *"Take Full Ownership"* in the Explorer context menu with system directory safeguards (scripts organized in `scripts/take-ownership/`).
  * **🔒 BitLocker Startup Password (No TPM / Dual-Boot Safe)**: Enables Group Policy for pre-boot Startup Passwords without requiring TPM. Essential for dual-boot systems where another Windows installation already utilizes the TPM, eliminating PCR conflicts and recovery key lockouts.
  * **🤖 AI & Developer Toolkits**: 1-click install & launcher for Claude Code CLI and OmniRoute AI Gateway.
  * **⚡ MAX Turbo & Maintenance**: Quick DNS/RAM/Temp clean, Windows Super God Mode desktop tool, Ultimate Performance power plan, and DISM/SFC system repair.

* **🛡️ Enterprise Mode Safety Preset**:
  * Dedicated enterprise profile locking down risky tweaks (blocks bulk AppX removal, prevents Windows Update service tampering, and safeguards system components).

---

## ⚙️ Command Line Presets

Run directly without the GUI to automate setup:

```powershell
& ([ScriptBlock]::Create((irm rinkurapria.dev/win))) -Preset <PresetName>
```

| Preset | Purpose |
| :--- | :--- |
| **Standard** | Balanced optimization for everyday workstations and personal PCs. |
| **Minimal** | Essential light tweaks keeping all optional services and features intact. |
| **Advanced** | Deep system debloat, aggressive telemetry removal, and latency optimizations. |
| **Enterprise** 🛡️ | Restricts high-risk actions for work and enterprise environments. |

---

## 💻 Local Usage

```powershell
# Clone the repository
git clone https://github.com/R-Rinku/winutil-max.git
cd winutil-max

# Compile and launch GUI
.\Compile.ps1 -Run

# Or compile only
.\Compile.ps1
```

---

## 🔍 Features, Search Index & Capabilities

| Capability | Category | Details & SEO Keywords |
| :--- | :--- | :--- |
| **BitLocker without TPM** | Security & Dual-Boot | Pre-boot startup password (`manage-bde -pw`), dual-boot Windows safe, no TPM PCR sealing conflicts, bypass TPM requirement. |
| **OneDrive Sync Exclusion** | Storage & Dev | Exclude specific directories (`node_modules`, `.venv`, `.git`, temporary builds) from OneDrive sync while keeping local files. |
| **Smart Bulk Renamer** | Power Utilities | Batch file rename, directory clean, regex pattern matching, sequence numbering, live preview before commit. |
| **Take Full Ownership** | System Administration | Windows Explorer context menu right-click integration, recursive ownership takeover with system file safeguards. |
| **Super God Mode** | Windows Shell | Direct shortcuts to 1000+ deep Windows settings, hidden applets, control panel GUIDs, god mode links. |
| **AI Toolkit** | Developer Tools | Anthropic Claude Code terminal assistant, OmniRoute AI router gateway, one-click launcher. |
| **Windows Debloat & Privacy**| Performance & Tweaks | Disable telemetry, Cortana, Recall, Edge background processes, OneDrive uninstall, Windows Search indexing toggle. |
| **Ultimate Performance Plan**| Gaming & Latency | Unlock hidden Windows Ultimate Performance power profile for low input latency and maximum CPU responsiveness. |

---

## 🤖 Automation, CI/CD & Dependency Bots

- **Documentation Deployment**: Pushes to `docs/` on `main` automatically build and deploy the Astro/Starlight site to **[winutil.rinkurapria.dev](https://winutil.rinkurapria.dev)** via `.github/workflows/docs.yaml`.
- **Automated Releases**: `winutil.ps1` is compiled and validated automatically by GitHub Actions — never commit `winutil.ps1` directly to `main`.
- **Dependabot (`github-actions`)**: Dependabot monitors `.github/workflows/` and opens automated pull requests when official GitHub Actions (such as `astral-sh/setup-uv` or `actions/checkout`) release updates. Merge bot PRs only after CI checks pass.

---

## 👤 Credits & Links

- **Official Documentation**: [winutil.rinkurapria.dev](https://winutil.rinkurapria.dev)
- **Maintained by**: [Rinku Rapria](https://www.rinkurapria.dev/) ([@R-Rinku](https://github.com/R-Rinku))
- **Upstream WinUtil**: [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil) | [CTT Store](https://cttstore.com/products/windows-toolbox)
