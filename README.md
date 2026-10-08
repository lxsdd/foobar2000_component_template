# foobar2000 Component Template

A reusable, validated starting point for native foobar2000 v2.x components on Windows.

## Baseline

- foobar2000 SDK 2026-10-01, vendored per generated repository
- WTL, vendored per generated repository
- Visual Studio/MSBuild with toolset v145
- C++23 for component code; SDK projects retain their upstream settings
- Release Win32 and x64 builds
- Unicode, native foobar2000 dark-mode hooks and per-monitor DPI handling
- deterministic `.fb2k-component` package layout
- fresh component, configuration and preferences GUIDs per generated project

The template intentionally contains no Smart Tempo code, GUIDs, algorithms, telemetry, UI text or build dependency.

## Relationship to shared infrastructure

This repository is the concrete, buildable generator/template for new foobar2000 components. It intentionally remains separate from `lxsdd/dev-infrastructure`.

- `foobar2000_component_template` owns project generation, GUID isolation, generated solution structure, SDK/WTL snapshot wiring and the disposable dual-architecture probe build.
- `dev-infrastructure` owns cross-project GitHub-first policy, migration rules, release/candidate invariants and the canonical shared foobar2000 package-verification standard.

Generated product repositories must be standalone: they must not require this template or `dev-infrastructure` at build time. Shared standards may be copied/adapted into generated repositories only where needed for standalone CI, while `dev-infrastructure` remains the policy source of truth.

## Create a component

```powershell
.\create_component.ps1 `
  -ComponentId foo_example `
  -DisplayName 'Example Component' `
  -Description 'A concise user-facing description.' `
  -Destination C:\foobar2000_dev\foo_example
```

The destination must be absent or empty. The generator validates its result and initializes an independent `main` Git repository unless `-SkipGitInit` is supplied.

## Verify the template

```powershell
.\tests\test_template.ps1
.\tests\test_template.ps1 -Build
```

The first command generates two projects and verifies identity isolation. The second additionally performs Win32/x64 release builds and packages a disposable probe component.

## Required project workflow

1. Generate the new repository from this template.
2. Build and package the untouched baseline.
3. Commit that generated baseline before implementing domain features.
4. Write a project-specific architecture and acceptance contract.
5. Implement in small, testable slices without modifying the generic template retrospectively.
6. Feed only generally reusable improvements back into this template through its own tested change.

For the next planned project, use `Duplicate Inspector` / `foo_duplicate_inspector` only after this template has passed its independent build-and-package smoke test.

