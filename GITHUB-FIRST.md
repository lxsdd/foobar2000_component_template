# Migration qualification

The workflow builds Win32 and x64 on fresh GitHub Windows runners using MSVC v145 and C++23 mode (matching the preserved project baseline). It verifies combined component archive paths and PE machine types and emits a commit-bound SHA-256 manifest. No local toolchain is required for this workflow.

Existing SDK/WTL source and SDK-supplied import libraries are preserved as pre-existing, licensed historical dependencies (see SDK license and WTL MS-PL notices); no SDK cache or new third-party bundle was imported by migration.

Template validation generates two identities and checks GUID isolation; a generated probe is built for both architectures. Its package is a validation fixture, not a product release.

Release remains blocked pending exact-candidate acceptance. No release workflow is introduced by this migration.

## Shared policy source

Cross-project policy lives in `lxsdd/dev-infrastructure`, especially `STANDARDS/GITHUB-FIRST.md`, `STANDARDS/RELEASE-POLICY.md` and `STANDARDS/FOOBAR2000-COMPONENT.md`. This repository keeps the concrete build/package implementation needed to make generated repositories standalone; it must not become a second policy authority.
