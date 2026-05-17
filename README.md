# tiny11 Studio

**Modular Windows 11 Image Builder** - A GUI wrapper for [tiny11builder](https://github.com/ntdevlabs/tiny11builder) that gives you granular control over what stays and what goes.

## Features

- **4-Step Wizard** - Source > Mode > Customize > Build
- **Modular Catalog** - 84 items across 10 categories, each individually togglable
- **Risk Indicators** - Every item tagged as Safe, Moderate, or Dangerous
- **Two Build Modes** - Regular (serviceable) or Core (maximum reduction)
- **Preset Profiles** - Minimal, Balanced, Gaming, Privacy - or create your own
- **i18n Support** - English, Portuguese (BR), Spanish
- **Single EXE** - Compile everything into one portable executable
- **Dark Theme** - Catppuccin Mocha-inspired WPF interface

## Requirements

- Windows 10/11
- PowerShell 5.1+
- Administrator privileges (for DISM operations)
- Windows 11 ISO file

## Quick Start

### Run from source
```powershell
# Clone the repo
git clone https://github.com/erickofs/tiny11-studio.git
cd tiny11-studio

# Run (requires admin)
powershell -ExecutionPolicy Bypass -File tiny11-studio.ps1
```

### Build standalone EXE
```powershell
# Merged script only
powershell -ExecutionPolicy Bypass -File build.ps1 -SkipExe

# Full EXE (requires ps2exe module)
powershell -ExecutionPolicy Bypass -File build.ps1
```

## Project Structure

```
tiny11-studio/
  assets/          # Icon and XAML layout
  catalog/         # Removal catalog (84 items) + JSON schema
  lang/            # i18n strings (en, pt-br, es)
  lib/             # Core libraries
    build-engine.ps1      # ISO modification orchestration
    i18n.ps1              # Localization system
    profile-manager.ps1   # Profile save/load/merge
    scan-iso.ps1          # ISO analysis and DISM enumeration
    submodule-manager.ps1 # Upstream script management
  profiles/        # Preset configuration profiles
  tiny11-studio.ps1 # Main entry point
  build.ps1        # Build pipeline (merge + compile)
```

## Catalog Categories

| Category | Items | Description |
|---|---|---|
| Bloatware Apps | 35 | Third-party and preinstalled apps |
| Microsoft Apps | 8 | Edge, OneDrive, Teams, Copilot |
| Xbox and Gaming | 6 | Xbox services and overlays |
| Telemetry and Ads | 6 | Tracking and advertising |
| Hardware Bypasses | 6 | TPM, CPU, RAM, Secure Boot |
| OOBE Bypasses | 1 | Local account setup |
| Features to Disable | 6 | Reserved Storage, BitLocker, Chat |
| Prevent Reinstallation | 4 | Block auto-reinstall of removed apps |
| Scheduled Tasks | 5 | Telemetry task removal |
| Core Mode Extras | 4 | Defender, WU, WinSxS, WinRE |

## Credits

- **tiny11builder** by [ntdevlabs](https://github.com/ntdevlabs/tiny11builder) - The upstream scripts that power the actual ISO modifications
- **tiny11 Studio** by [erickofs](https://github.com/erickofs) - This GUI wrapper and modular catalog

## License

MIT License - See [LICENSE](LICENSE) for details.

This is an independent project and is not affiliated with or endorsed by ntdevlabs or Microsoft.
