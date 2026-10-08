# __DISPLAY_NAME__

__DESCRIPTION__

This project was generated from the reusable foobar2000 Component Template.

## Requirements

- Windows 10 or newer
- foobar2000 v2.x
- Visual Studio with MSVC toolset v145 and the Windows 10/11 SDK
- PowerShell 7 or Windows PowerShell 5.1

The repository vendors foobar2000 SDK 2026-10-01 and WTL, so no paths to another component repository are required.

## Build

```powershell
.\validate_project.ps1
.\build.bat
.\pack_component.bat
```

The package is written to `build\<component-id>_<version>.fb2k-component` and contains both Win32 and x64 binaries.

## Development contract

- Keep component-specific code under `src\__COMPONENT_ID__`.
- Generate a new GUID for every persistent configuration value and every exposed foobar2000 service.
- Keep standard logging concise; put diagnostic detail behind an explicit verbose setting.
- Treat DPI scaling, keyboard access, native dark mode and foobar2000 lifecycle rules as requirements, not later polish.
- Run the validator, both release builds and packaging before tagging a release.

See [Architecture](docs/ARCHITECTURE.md), [Building](docs/BUILDING.md) and the [Release checklist](docs/RELEASE_CHECKLIST.md).
