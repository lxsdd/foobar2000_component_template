# Building

`build.bat` locates MSBuild through `vswhere.exe`, rebuilds Release Win32 and Release x64, verifies both DLLs and emits a freshness marker.

`pack_component.bat` refuses missing or stale builds, then creates the foobar2000 package layout:

```text
__COMPONENT_ID__.dll
x64/__COMPONENT_ID__.dll
```

Set `FB2K_INCREMENTAL_BUILD=1` only for local iteration. Release validation should use the default clean rebuild.

Do not upgrade the SDK, WTL, toolset or language standard implicitly while implementing a feature. Treat dependency updates as isolated changes with a fresh build and compatibility audit.

