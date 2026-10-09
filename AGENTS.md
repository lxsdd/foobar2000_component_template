# Repository rules

## Role

This repository is the concrete, buildable generator/template for new native foobar2000 components. It owns project generation, GUID isolation, generated solution structure, SDK/WTL snapshot wiring, template validation, and the disposable dual-architecture probe.

It is intentionally separate from `lxsdd/dev-infrastructure`.

`lxsdd/dev-infrastructure` is the canonical source for cross-project policy, migration rules, release/candidate invariants, and the shared foobar2000 packaging standard. When a shared rule changes there, this repository should be updated only where concrete template implementation or standalone generated-project behavior must follow that rule.

Generated product repositories must remain standalone and must not require this template or `dev-infrastructure` at build time.

## GitHub-first migration (2026-09-30)

GitHub is canonical for source history and fresh-runner qualification. The migration does not authorize new product behavior or open a research/UI/hardware gate. Preserve all pre-existing safety contracts. Never upload keys, credentials, personal media, SDK caches, or generated build output. Candidate artifacts are bound to the exact commit and SHA-256, retained for 90 days. Runtime acceptance must use those exact bytes. No release is authorized by migration; a future promotion must reuse the accepted candidate without rebuilding and must not overwrite tags/assets.

## foobar2000 packaging contract

For dual-architecture components, the combined `.fb2k-component` layout is binding:

- Win32/x86 DLL at archive root;
- x64 DLL under `x64/`;
- no `x86/` package directory;
- PE machine types must be verified;
- final package SHA-256 must be emitted and commit-bound.

Do not create a competing packaging policy here; follow the canonical standard in `lxsdd/dev-infrastructure/STANDARDS/FOOBAR2000-COMPONENT.md`.


## Future generated GUI window contract

All new project dialog designs follow `lxsdd/dev-infrastructure/STANDARDS/FOOBAR2000-NATIVE-DIALOGS.md`. A DPI helper alone does not make dynamic Win32 dialogs collision-free. Require actual native resource-backed expansion/shrink tests, using the Windows-granted rather than requested client dimensions, and native foobar cfg window geometry persistence with real host verification. Existing generated projects and older binaries must be individually audited; this template policy is not evidence that they were patched. For long-lived browse/preview windows use foobar's `modeless_dialog_manager` with `CreateDialogParamW` only after qualifying HWND-owned lifetime through `WM_NCDESTROY`, shutdown, independent taskbar/minimize behavior, one-instance semantics, stale source snapshots, explicit refresh and real foobar keyboard routing. Do not substitute `WS_MINIMIZEBOX` on a modal dialog.
