# Release checklist

- [ ] User-visible version, resource version and package version agree.
- [ ] `validate_project.ps1` passes.
- [ ] Release Win32 and x64 rebuild successfully.
- [ ] The `.fb2k-component` contains the root Win32 DLL and `x64` DLL.
- [ ] A clean foobar2000 profile loads the component without console errors.
- [ ] Preferences survive restart and reset correctly.
- [ ] Every new resizable dialog stores and restores its own normal geometry using a unique per-window foobar cfg GUID, with screen/work-area/DPI validation; closing without resize causes no unnecessary preference rewrite.
- [ ] Native resize moves related buttons/fields in a coordinated collision-free layout using actual WM_SIZE client dimensions, with child/sibling clipping, correct redraw, and no visual ghosts.
- [ ] Production resource-backed Win32 tests cover expand/shrink, button non-overlap, tab switching, 100/125/150/200% DPI and OS-clamped virtual desktop sizes.
- [ ] Installed foobar accepts resize → tab switch → Close/reopen → application restart; the exact SHA-bound candidate and UI result are documented.
- [ ] Native EDIT text and nearby themed button caption have a qualified optical baseline at 100–200% DPI, and the Review action COMBOBOX's collapsed **rcItem** aligns with its neighboring buttons. **Map `GetComboBoxInfo.rcItem` from COMBOBOX client coordinates to desktop before comparing with button `GetWindowRect`**, and map screen positions back to dialog client before `SetWindowPos`. Tests verify both transforms on real HWNDs and rerun the aligner after resize to prove no cumulative drift.
- [ ] Primary search/browse results use one row per entity (recording/release), with separate selected-row field details rather than one master row per attribute.
- [ ] Native ListView selected-detail tests insert a real row and read back **all subitems** (Field, Original, Proposed, Status), verify adequate caption/header spacing and complete visible labels/headers.
- [ ] Double-click/Enter on a verified result invokes the same guarded read-only action as the explicit load button. Never activate on stale source selection or a loaded result.
- [ ] If a browser window is long-running, prefer a nonblocking **modeless** window with minimize/restore; never add Minimize to an otherwise owner-blocking modal dialog as a purported workaround. Modeless lifetime, one-instance policy, foobar app shutdown and keyboard navigation require separate SDK/real-host qualification.
- [ ] For modeless windows, check `CreateDialogParamW`, `modeless_dialog_manager::g_add/g_remove` pairing, HWND-state ownership until `WM_NCDESTROY`, failed-init cleanup, `initquit` teardown and same-window reactivation. Native HWND tests verify Tab through `IsDialogMessage`, independent taskbar/Alt-Tab, minimize/maximize/restore and Close; installed foobar proves playlist/playback are not blocked.
- [ ] A changed playlist/track selection does not replace pending comparisons without consent. Before each action, stale physical metadata, file identity, CUE and rules snapshots fail closed. Explicit refresh discards old decisions and online candidates. No background provider lookups or media writes.


- [ ] UI is checked in light and dark mode at 100, 125, 150 and 200 percent DPI.
- [ ] Keyboard navigation, focus order, tooltips and cancellation behavior are checked.
- [ ] Standard logs remain concise and contain no diagnostic flood.
- [ ] Git worktree is clean; release commit and annotated tag identify the packaged source exactly.

