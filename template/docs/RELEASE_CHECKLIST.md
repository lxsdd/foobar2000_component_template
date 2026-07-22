# Release checklist

- [ ] User-visible version, resource version and package version agree.
- [ ] `validate_project.ps1` passes.
- [ ] Release Win32 and x64 rebuild successfully.
- [ ] The `.fb2k-component` contains the root Win32 DLL and `x64` DLL.
- [ ] A clean foobar2000 profile loads the component without console errors.
- [ ] Preferences survive restart and reset correctly.
- [ ] UI is checked in light and dark mode at 100, 125, 150 and 200 percent DPI.
- [ ] Keyboard navigation, focus order, tooltips and cancellation behavior are checked.
- [ ] Standard logs remain concise and contain no diagnostic flood.
- [ ] Git worktree is clean; release commit and annotated tag identify the packaged source exactly.

