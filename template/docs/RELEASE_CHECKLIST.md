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
- [ ] UI is checked in light and dark mode at 100, 125, 150 and 200 percent DPI.
- [ ] Keyboard navigation, focus order, tooltips and cancellation behavior are checked.
- [ ] Standard logs remain concise and contain no diagnostic flood.
- [ ] Git worktree is clean; release commit and annotated tag identify the packaged source exactly.

