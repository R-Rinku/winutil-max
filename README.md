<div align="center">

# ⚡ winutil-MAX

### The Ultimate Windows Optimization, Automation & Tweaking Suite
*(Stranger Things / Max Mayfield Edition)*

<br/>

<img src="MAX.jpg" alt="winutil-MAX - Running Up That Hill" width="300" style="border-radius: 12px; box-shadow: 0 4px 15px rgba(255, 0, 127, 0.45);" />

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
  <a href="https://www.rinkurapria.dev/" target="_blank" rel="noopener">
    <img alt="Portfolio" src="https://img.shields.io/badge/Portfolio-rinkurapria.dev-0070f3?style=for-the-badge">
  </a>
</p>

> **Credit & Attribution:** **winutil-MAX** is an enhanced, customized edition of [Chris Titus Tech's WinUtil](https://github.com/ChrisTitusTech/winutil). All credit for the foundational WinUtil engine belongs to **Chris Titus** and the upstream community. This fork introduces custom automation tools, enterprise safeguards, and a complete Stranger Things (Max Mayfield) aesthetic.

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

---

## ✨ What's New in winutil-MAX

* **📼 Stranger Things (Max Mayfield) Theme**:
  * Visual splash screen featuring Max Mayfield with Walkman headphones before GUI startup.
  * Deep charcoal void (`#111116`) paired with neon synthwave magenta (`#FF007F`) borders, glowing highlights, and retro accents.
  * Streamlined launch: opens directly inside your active console window with only 1 main GUI window (no duplicate terminal popups).

* **🏷️ [MAX] Smart Bulk Name Modifier** *(under Config tab)*:
  * Interactive bulk file & folder renaming utility with instant before-and-after live preview.
  * Real-time search & replace, Regular Expressions (Regex), case transformation (UPPERCASE, lowercase, Title Case), sequence numbering with custom padding, and prefix/suffix insertions.
  * Automatically handles elevation permissions to rename restricted folder items.

* **🔑 [MAX] Take Full Ownership** *(under Config tab)*:
  * One-click integration to add or remove *"Take Full Ownership"* in the Windows Explorer context menu.
  * Automatically grants administrators full permission via `takeown` and `icacls`.
  * Built-in safeguards preventing accidental execution on critical OS root directories.

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

# Compile and launch
.\Run.ps1

# Or compile only
.\Run.ps1 -CompileOnly
```

---

## ⚠️ Disclaimer

Provided **as-is** without warranty. Review changes before applying them. Use Enterprise Mode when operating on production machines.

---

## 👤 Credits & Links

- **Maintained by**: [Rinku Rapria](https://www.rinkurapria.dev/) ([@R-Rinku](https://github.com/R-Rinku))
- **Original WinUtil**: [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil)
