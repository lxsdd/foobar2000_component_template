# Template contract

## Included

- Reproducible SDK/toolchain and solution wiring
- Win32/x64 release output and foobar2000 package layout
- Component identity and Windows resource versioning
- Unique GUID generation
- Minimal persistent preferences example
- Native dialog, keyboard, dark-mode and DPI baseline
- Mandatory cross-project **resizable native foobar window** qualification: stable per-window foobar cfg geometry; actual OS-clamped WM_SIZE client deltas; coordinated collision-free sibling layout with proper repaint; real HWND/UI tests and installed-host close/reopen acceptance (canonical policy: `lxsdd/dev-infrastructure/STANDARDS/FOOBAR2000-NATIVE-DIALOGS.md`).
- Structural validation and disposable smoke tests
- Build and release documentation

## Excluded

- Domain services, business rules and database schemas
- Component-specific commands, context menus or playback callbacks
- Logging frameworks and telemetry fields
- Test data copied from another plugin
- Release notes, branding and licenses for project-specific code

## Invariants

- Every generated component implementing writes must check the *live approved postimage* immediately before a write-capable foobar SDK call and perform **zero writes** if unchanged. Compare physical textual tags, ReplayGain, CUE bytes, artwork/sidecars, metadata-only changes and file operations separately. Do not update file timestamps for no-op operations. A partial virtual subsong `file_info` is not proof of complete physical tags. Add regression tests proving zero writer calls, not merely final equality. See the canonical `dev-infrastructure/STANDARDS/FOOBAR2000-NOOP-WRITES.md` policy (internal).

- A generated project never references the template or Smart Tempo at build time.
- A generated project owns its SDK/WTL snapshot and Git history.
- Persistent and service GUIDs are never copied between components.
- Generic template changes are validated by two-project identity tests and one complete build/package smoke test.
- Template-provided simple Preferences panels do not imply every generated component already contains an atomic resize adapter. Projects that **introduce resizable dialogs** must implement and qualify one before release; do not copy product-specific GUIDs/Win32 geometry blindly.
- Project-specific fixes are not backported unless they are demonstrably generic.

