# Architecture

The generated baseline deliberately contains only four layers:

1. `component.cpp` declares identity, version and the required DLL filename.
2. `preferences.*` demonstrates persistent configuration through the foobar2000 SDK.
3. `component.rc` provides a native, keyboard-accessible preferences surface.
4. `component.props`, `build.bat` and `pack_component.bat` define the reproducible Win32/x64 toolchain and package layout.

Add domain code in explicit modules rather than growing the SDK integration files into a monolith. Keep data acquisition, decision logic, persistence and UI presentation separable and independently testable.

The preferences dialog uses foobar2000 dark-mode hooks and dialog units. `WM_DPICHANGED` is handled as a baseline safeguard; larger dialogs should also use `CDialogResize` and be verified at 100, 125, 150 and 200 percent scaling.



## Native resizable dialog policy

Future generated components with resizable Win32 dialogs must implement and test the canonical `lxsdd/dev-infrastructure/STANDARDS/FOOBAR2000-NATIVE-DIALOGS.md` behavior. Do not treat `ui_scaling.h` as a full dialog layout/geometry persistence system: it provides DPI scale detection only. Production resize, sibling painting, foobar cfg window persistence and a real HWND geometry test are project-specific, independently qualified work; each component needs unique GUIDs and no dependency on the template at runtime.
