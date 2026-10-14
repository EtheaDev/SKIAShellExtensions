# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Delphi (VCL) Windows Shell extensions for Lottie (`.json`, `.lottie`), `.tgs`, `.gif` and `.webp` files, rendered with Skia4Delphi. It builds four things from `Source\`:

| Project | Output | What it is |
|---|---|---|
| `SKIAShellExtensions.dproj` | `Bin64\SKIAShellExtensions.dll` | COM in-process server, 64 bit: Explorer Preview handler and Thumbnail provider |
| `SKIAShellExtensions32.dproj` | `Bin32\SKIAShellExtensions32.dll` | Same `.pas` units built for 32 bit |
| `LottieTextEditor.dproj` | `Bin32\` / `Bin64\LottieTextEditor.exe` | SynEdit-based editor with a live animation preview, multi-tab, single instance |
| `AnimationViewer.dproj` | `Bin32\` / `Bin64\AnimationViewer.exe` | Standalone viewer that reuses the preview form from the DLL |

`SKIAShellExtensionGroup.groupproj` groups them for the IDE. Version control is **SVN** (`.svn`), not git. `Ext\*` (SynEdit, SVGIconImageList + Image32, VCLStyleUtils, StyledComponents, Skia4DelphiExtensions) are third-party/Ethea libraries checked out as separate working copies: don't edit them for project changes. Skia4Delphi itself must be installed in the IDE.

## Build

Toolchain: RAD Studio 37.0 (Delphi 13), `C:\BDS\Studio\37.0\bin\rsvars.bat`. The README declares Delphi 12 or Delphi 13 as supported for manual builds: avoid language/RTL features that exist only in Delphi 13. No linters.

```bat
call "C:\BDS\Studio\37.0\bin\rsvars.bat"
msbuild.exe "Source\SKIAShellExtensions.dproj" /target:Build /p:Platform=Win64 /p:config=release
msbuild.exe "Source\SKIAShellExtensions32.dproj" /target:Build /p:Platform=Win32 /p:config=release
msbuild.exe "Source\LottieTextEditor.dproj" /target:Build /p:Platform=Win64 /p:config=release
msbuild.exe "Source\AnimationViewer.dproj" /target:Build /p:Platform=Win64 /p:config=release
```

`Build.bat` does a full release (it stops at the first failing step; the pause happens only when started from Explorer): Clean;Build of every project/platform, code signing (`D:\ETHEA\Certificate\SignFileWithSectico.bat`), then the Inno Setup installer (`Setup\SKIAShellExtensions.iss` → `Setup\Output\SKIAShellExtensionsSetup.exe`). Don't run it just to check a compile.

### Tests

`Tests\TestLottieScanner.dpr` is a console test of `uLottieColorScanner` (recognition, `FormatColorLike`, round trip). From `Tests\` after `rsvars.bat`: `dcc64 -NSSystem;Winapi TestLottieScanner.dpr`, then `TestLottieScanner.exe [folder of Lottie .json files]`; exit code 0 when every check passes. Run it after any change to the scanner.

Unit search paths are set in each `.dproj` (relative `..\Ext\...`). The EXEs define `VCLSTYLEUTILS;SKIA`; the DLLs don't. `DISABLE_STYLES` is a conditional used in shared units to drop VCL-style code.

### Testing the DLL

The DLL is registered with `regsvr32` (`Bin64\Register64bit.bat`, `Bin32\Register32bit.bat`; `Unregister_Register.cmd` does both, run as administrator). Explorer keeps the DLL loaded: close every Explorer window that used the preview pane before rebuilding, or the link fails because the file is locked. For debugging the preview without Explorer there are host apps under `Debug\Preview Handlers\` (`PreviewHost`, `OpenDialogTest`).

## Architecture

- **COM registration**: `Main.pas` registers the classes in its `initialization` section with different GUIDs for 32 and 64 bit (`{$IFDEF WIN64}`). The preview handler chain is `uPreviewHandler` → `uStreamPreviewHandler`/`uFilePreviewHandler` → `uCommonPreviewHandler.TBasePreviewHandler` (stream or file based, chosen by `USE_TStreamPreviewHandler`) → `uSKIAPreviewHandler.TSKIAPreviewHandler`. Registry/file-extension wiring is in `uPreviewHandlerRegister`, `uThumbnailHandlerRegister`, `uRegistry`. The thumbnail provider (`uSKIAThumbnailHandler`) renders the last frame of the animation.
- **Shared UI between DLL and EXEs**: `PreviewForm.TFrmPreview` (descends from `uPreviewContainer.TPreviewContainer`) is the preview panel hosted by Explorer and is also the main form of `AnimationViewer`. `SettingsForm`, `uSettings`, `DResources` (image lists, icons), `uAbout`, `dlgSearchText` are compiled into both the DLL and the EXEs. Changes there affect Explorer: keep them free of EXE-only dependencies.
- **Editor**: `EditorMainForm.TfrmMain` with `PageControlHook` (tabs with close button), the search/replace dialogs, print preview (`FTestPrintPreview`, `DPageSetup`), `SynEditOptionsDialog`, `uSingleInstance` (forwards the command-line file to a running instance), `GitHubAPI` (checks for and installs new releases; the automatic check runs in background via `uAbout.CheckNewSetupAsync`). Rendering of the five preview images is debounced by `LoadTimer` (never call `AssignLottieTextToImage` from `OnChange`).
- **Color palette** (editor only): `uLottieColorScanner` finds colors by the JSON key path + `ty` of the containing objects (a numeric array alone is not a color), with positions that can span lines; `uColorPaletteBar` is a generic owner-draw control shared with SVGShellExtensions (`uSVGPaletteBar` there). Replacements rewrite only the r,g,b numbers to keep the file's notation.
- **Shared data module**: `dmResources` is a function returning a lazily created instance owned by `DResources`; never create or free it elsewhere.
- **Settings**: `uSettings` — `TSettings` → `TEditorSettings` → `TPreviewSettings`, stored as INI files under `%APPDATA%`: `SKIAPreviewHandler\Settings.ini` (preview) and `LottieTextEditor\Settings.ini` (editor). Theme (light/dark VCL style) follows the Windows preference (see "VCL Styles and Themes").

## VCL Styles and Themes

- Linked styles (`Custom_Styles` of the four dproj): Glow, Sky, Windows Modern, Windows Modern SlateGray, Windows11 Impressive/Modern/Polar Light and Dark. The Windows10 styles are obsolete and were removed; do not add "Windows Modern Dark" (same resource name WINDOWSMODERNDARK of "Windows11 Modern Dark").
- The Theme page of Settings offers every VCL style linked into the executable (`TStyleManager.StyleNames`), except the system style "Windows". Light or dark is decided at run time by `StyleThemeType` in `uSettings.pas`: from the table of StyledComponents (`Vcl.StandardButtonStyles.GetStyleAttributes`, only when it returns an entry with the same name: for an unknown style it returns the attributes of "Windows"), otherwise from the luminance of the `clWindow` color of the style. Worked out on demand and cached (no style is loaded at startup or inside Explorer). There is no hand-kept list: adding a style to the dproj is enough.
- `DefaultStyleName` (`uRegistry.pas`): "Windows11 Modern Light/Dark" on Windows 11, "Windows Modern" / "Windows Modern SlateGray" on older systems, following the Windows light/dark theme.
- `UpdateApplicationStyle` (`EditorMainForm.pas`) applies the style with `TStyleManager.TrySetStyle(..., False)`: a stored style no longer linked falls back to `DefaultStyleName`, then to "Windows Modern", without raising.
- The same styles and code are used by SKIAShellExtensions, SVGShellExtensions, MarkdownShellExtensions and MarkdownHelpViewer: keep them aligned.

## Version Control and Documentation

- Subversion, not Git. The project `.res` files are regenerated by every build (icon and version info from the `.dproj`): they are in `svn:ignore` of `Source` and must not be committed.
- **Every time `README.md` is modified, regenerate `README.htm` with the tool** and commit the two files together; `README.htm` is never edited by hand. From the folder of the repository: `D:\ETHEA\MarkdownProcessor\Cmd\Win64\MarkDownToHTML.exe processfile -in:<repo>\README.md -out:<repo>\README.htm` with full Windows paths (from Git Bash the backslashes are lost: run it from PowerShell or cmd), in safe mode, i.e. without `-unsafe`. Raw HTML in `README.md` is dropped in safe mode (it becomes `<!-- raw HTML omitted -->`): use the Markdown syntax, also for images, and write HTML examples as code between backticks.

## Related project

`D:\ETHEA\SVGShellExtensions` is the sister project with the same structure (SVG Text Editor). Features and fixes are often ported from there; `ANALISI_PALETTE_LOTTIE.md` (Italian) is the analysis of the port of SVGShellExtensions r177–r198 and of the Lottie color palette, done in version 1.8.0. Use `svn diff -c <rev>` in that folder to see a specific change.

## Release

Update the version in the `.dproj` files, `README.md` "Latest Version" plus Release Notes, and `Setup\SKIAShellExtensions.iss`; then regenerate `README.htm` from `README.md` with MarkDownToHTML (see "Version Control and Documentation").
