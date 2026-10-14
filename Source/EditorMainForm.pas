{******************************************************************************}
{                                                                              }
{       SKIA Shell Extensions: Shell extensions for animated files             }
{       (Preview Panel, Thumbnail Icon, File Editor)                           }
{                                                                              }
{       Copyright (c) 2022-2026 (Ethea S.r.l.)                                 }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/SKIAShellExtensions                        }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit EditorMainForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, ImgList, Contnrs,
  SynEdit, ActnList, Menus, ToolWin,
  StdActns, SynEditHighlighter,
  DResources, SynEditPrint, SynEditOptionsDialog, ActnCtrls, ActnMan,
  ActnMenus, SynCompletionProposal, SynEditTypes, SynEditMiscClasses,
  SynEditSearch, XPStyleActnCtrls, System.Actions, SVGIconImage, Vcl.Buttons,
  Vcl.CategoryButtons, Vcl.WinXCtrls, System.ImageList, Vcl.VirtualImageList,
  uSettings
  , System.UITypes
  , Vcl.PlatformVclStylesActnCtrls
  {$IFNDEF NO_VCL_STYLES}
  , Vcl.Styles.Fixes
  , Vcl.Styles.FormStyleHooks
  , Vcl.Styles.OwnerDrawFix
  , Vcl.Styles.Utils.ScreenTips
  , Vcl.Styles.Utils.SysStyleHook
  , Vcl.Styles.Utils
  , Vcl.Styles.Utils.SysControls
  , Vcl.Styles.UxTheme
  , Vcl.Styles.Hooks
  , Vcl.Styles.Utils.Forms
  , Vcl.Styles.Utils.ComCtrls
  , Vcl.Styles.Utils.StdCtrls
  , Vcl.Styles.Ext
  {$ENDIF}
  , uDragDropUtils
  , Vcl.Skia.AnimatedImageEx
  , Vcl.StyledButton
  , Vcl.StyledToolbar
  , Vcl.ButtonStylesAttributes
  , Vcl.StyledButtonGroup
  , Vcl.StyledCategoryButtons
  , PageControlHook
  , uLottieColorScanner
  , uColorPaletteBar
  ;

const
  SET_FILE_NAME = 'HiglightSettings';
  SV_COLLAPSED_WIDTH = 42;
  SV_COLLAPSED_WIDTH_WITH_SCROLLBARS = 60;
  TABSHEET_IMAGE = 'lottie-logo';

resourcestring
  PALETTE_TITLE = 'COLOR PALETTE (%d)';
  PALETTE_DOCUMENT = 'Document';
  PALETTE_CUSTOM = 'Custom';
  PALETTE_EMPTY = 'No colors found in the animation';
  PALETTE_ADD_HINT = 'Add a custom color...';
  PALETTE_HINT_OCCURRENCES = 'Occurrences: %d';
  PALETTE_HINT_PROPERTIES = 'Used in: %s';
  PALETTE_HINT_ALPHA = 'Opacity: %s';
  PALETTE_INFO_COUNT = '%s - %d occurrences';
  PALETTE_INFO_POSITION = '%s - %d of %d';
  PALETTE_INFO_UNUSED = '%s - not used in the animation';
  PALETTE_HINT_CUSTOM = 'Custom color';
  PALETTE_REPLACED = 'Color values replaced: %d';
  PALETTE_NO_COLOR_AT_CARET = 'Place the caret on a color value to replace it';

type
  TEditingFile = class
  private
    FFileName : string;
    FFileAge: TDateTime;
    FExtension: string;
    procedure ReadFromFile;
    procedure SaveToFile;
    function GetFileName: string;
    function GetName: string;
    procedure SetFileName(const Value: string);
    procedure LoadFromFile(const AFileName: string);
    function GetImageName: string;
    procedure UpdateTabSheetCaption;
  public
    EditFileType: TEditFileType;
    SynEditor: TSynEdit;
    TabSheet: TTabSheet;
    constructor Create(const EditFileName : string);
    property FileName: string read GetFileName write SetFileName; //with full path
    property Name: string read GetName; //only name of file
    //Timestamp of the file as it was last read or written, compared by the
    //file-changed timer
    property FileTimestamp: TDateTime read FFileAge write FFileAge;
    property ImageName: string read GetImageName;
    property Extension : string read FExtension;
  end;

  TfrmMain = class(TForm, IDragDrop)
    OpenDialog: TFileOpenDialog;
    ActionList: TActionList;
    acOpenFile: TAction;
    acSave: TAction;
    SaveDialog: TFileSaveDialog;
    acEditCut: TEditCut;
    acEditCopy: TEditCopy;
    acEditPaste: TEditPaste;
    acEditSelectAll: TEditSelectAll;
    acEditUndo: TEditUndo;
    popEditor: TPopupMenu;
    CopyMenuItem: TMenuItem;
    CutMenuItem: TMenuItem;
    PasteMenuItem: TMenuItem;
    Sep2MenuItem: TMenuItem;
    acSearch: TAction;
    acReplace: TAction;
    SearchMenuItem: TMenuItem;
    ReplaceMenuItem: TMenuItem;
    acQuit: TAction;
    acNewFile: TAction;
    acAbout: TAction;
    acClose: TAction;
    acCloseAll: TAction;
    acSaveAll: TAction;
    acSearchAgain: TAction;
    actnPrint: TAction;
    PrinterSetupDialog: TPrinterSetupDialog;
    PrintDialog: TPrintDialog;
    SynEditPrint: TSynEditPrint;
    actnPrinterSetup: TAction;
    actnPrintPreview: TAction;
    actnPageSetup: TAction;
    actnEditOptions: TAction;
    actnEnlargeFont: TAction;
    actnReduceFont: TAction;
    actnSaveAs: TAction;
    StatusBar: TStatusBar;
    actnColorSettings: TAction;
    actnFormatJSON: TAction;
    SynEditSearch: TSynEditSearch;
    ImagePanel: TPanel;
    RightSplitter: TSplitter;
    panelPreview: TPanel;
    SV: TSplitView;
    catMenuItems: TStyledCategoryButtons;
    panlTop: TPanel;
    lblTitle: TLabel;
    SettingsToolBar: TStyledToolbar;
    ColorSettingsToolButton: TStyledToolButton;
    EditOptionsToolButton: TStyledToolButton;
    VirtualImageList: TVirtualImageList;
    actMenu: TAction;
    MenuButtonToolbar: TStyledToolbar;
    MenuToolButton: TStyledToolButton;
    PageSetupToolButton: TStyledToolButton;
    PrinterSetupToolButton: TStyledToolButton;
    AboutToolButton: TStyledToolButton;
    QuitToolButton: TStyledToolButton;
    SepToolButton: TStyledToolButton;
    FlowPanel: TFlowPanel;
    BackgroundTrackBar: TTrackBar;
    BackgroundGrayScaleLabel: TLabel;
    OpenRecentAction: TAction;
    RecentPopupMenu: TPopupMenu;
    SaveMenuItem: TMenuItem;
    CloseMenuItem: TMenuItem;
    Sep1MenuItem: TMenuItem;
    SelectAllMenuItem: TMenuItem;
    ReformatTextMenuItem: TMenuItem;
    ImagePreviewPanel: TPanel;
    ExportToPNGAction: TAction;
    N1: TMenuItem;
    CloseAllMenuItem: TMenuItem;
    ExporttoPNGMenuItem: TMenuItem;
    StatusPanel: TPanel;
    StatusImage: TSVGIconImage;
    StatusStaticText: TStaticText;
    StatusSplitter: TSplitter;
    VirtualImageList20: TVirtualImageList;
    PlayAction: TAction;
    PlayInverseAction: TAction;
    StopAction: TAction;
    PlayerPanel: TPanel;
    PlayerToolBar: TStyledToolBar;
    ToolButtonPlay: TStyledToolButton;
    ToolButtonPause: TStyledToolButton;
    LoopToggleSwitch: TToggleSwitch;
    TrackBar: TTrackBar;
    RunLabel: TLabel;
    PauseAction: TAction;
    ToolButtonStop: TStyledToolButton;
    ToolButtonPlayInverse: TStyledToolButton;
    CheckFileChangedTimer: TTimer;
    ClientPanel: TPanel;
    LoadTimer: TTimer;
    PaletteSplitter: TSplitter;
    PalettePanel: TPanel;
    PaletteHeaderPanel: TPanel;
    PaletteTitleLabel: TLabel;
    PaletteToolBar: TStyledToolbar;
    PalettePrevToolButton: TStyledToolButton;
    PaletteNextToolButton: TStyledToolButton;
    PaletteInfoLabel: TLabel;
    acPalettePrev: TAction;
    acPaletteNext: TAction;
    PalettePopupMenu: TPopupMenu;
    ReplaceAllColorMenuItem: TMenuItem;
    SelectAllColorMenuItem: TMenuItem;
    CopyColorMenuItem: TMenuItem;
    PaletteSepMenuItem: TMenuItem;
    AddCustomColorMenuItem: TMenuItem;
    RemoveCustomColorMenuItem: TMenuItem;
    PaletteColorDialog: TColorDialog;
    procedure PlayActionExecute(Sender: TObject);
    procedure StopActionExecute(Sender: TObject);
    procedure WMGetMinMaxInfo(var Message: TWMGetMinMaxInfo); message WM_GETMINMAXINFO;
    procedure acOpenFileExecute(Sender: TObject);
    procedure acSaveExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ShowSRDialog(aReplace: boolean);
    procedure DoSearchReplaceText(AReplace: boolean;
      ABackwards: boolean);
    procedure acSearchExecute(Sender: TObject);
    procedure acReplaceExecute(Sender: TObject);
    procedure acQuitExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure acNewFileExecute(Sender: TObject);
    procedure acSearchUpdate(Sender: TObject);
    procedure acReplaceUpdate(Sender: TObject);
    procedure acCloseExecute(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure acSaveUpdate(Sender: TObject);
    procedure acCloseAllUpdate(Sender: TObject);
    procedure acCloseAllExecute(Sender: TObject);
    procedure acSaveAllUpdate(Sender: TObject);
    procedure acSaveAllExecute(Sender: TObject);
    procedure acAboutExecute(Sender: TObject);
    procedure acSearchAgainExecute(Sender: TObject);
    procedure acSearchAgainUpdate(Sender: TObject);
    procedure actnPrinterSetupExecute(Sender: TObject);
    procedure actnPrintPreviewExecute(Sender: TObject);
    procedure actnPrintExecute(Sender: TObject);
    procedure actnPageSetupExecute(Sender: TObject);
    procedure actnEditOptionsExecute(Sender: TObject);
    procedure actnEditingUpdate(Sender: TObject);
    procedure actnFontExecute(Sender: TObject);
    procedure actnSaveAsExecute(Sender: TObject);
    procedure ActionListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure actnColorSettingsExecute(Sender: TObject);
    procedure actnColorSettingsUpdate(Sender: TObject);
    procedure actnFormatJSONExecute(Sender: TObject);
    procedure actionForFileUpdate(Sender: TObject);
    procedure HistoryListClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure actMenuExecute(Sender: TObject);
    procedure BackgroundTrackBarChange(Sender: TObject);
    procedure acEditUndoExecute(Sender: TObject);
    procedure SVOpened(Sender: TObject);
    procedure SVClosed(Sender: TObject);
    procedure SVClosing(Sender: TObject);
    procedure SVOpening(Sender: TObject);
    procedure ActionListExecute(Action: TBasicAction; var Handled: Boolean);
    procedure catMenuItemsMouseLeave(Sender: TObject);
    procedure catMenuItemsMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure catMenuItemsGetHint(Sender: TObject; const Button: TButtonItem;
      const Category: TButtonCategory; var HintStr: string;
      var Handled: Boolean);
    procedure RecentPopupMenuPopup(Sender: TObject);
    procedure OpenRecentActionExecute(Sender: TObject);
    procedure ExportToPNGActionExecute(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormAfterMonitorDpiChanged(Sender: TObject; OldDPI,
      NewDPI: Integer);
    procedure FormBeforeMonitorDpiChanged(Sender: TObject; OldDPI,
      NewDPI: Integer);
    procedure acEditCutExecute(Sender: TObject);
    procedure acEditCopyExecute(Sender: TObject);
    procedure acEditPasteExecute(Sender: TObject);
    procedure acEditSelectAllExecute(Sender: TObject);
    procedure acEditUndoUpdate(Sender: TObject);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure TrackBarChange(Sender: TObject);
    procedure LoopToggleSwitchClick(Sender: TObject);
    procedure SkAnimatedImageExMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PauseActionExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure acEditCopyUpdate(Sender: TObject);
    procedure PageControlMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure TabSheetCloseButtonClick(Sender: TObject);
    procedure PlayInverseActionExecute(Sender: TObject);
    procedure CheckFileChangedTimerTimer(Sender: TObject);
    procedure AppDeactivate(Sender: TObject);
    procedure AppActivate(Sender: TObject);
    procedure LoadTimerTimer(Sender: TObject);
    procedure acPaletteNavigateExecute(Sender: TObject);
    procedure acPaletteNavigateUpdate(Sender: TObject);
    procedure ReplaceAllColorMenuItemClick(Sender: TObject);
    procedure SelectAllColorMenuItemClick(Sender: TObject);
    procedure CopyColorMenuItemClick(Sender: TObject);
    procedure AddCustomColorMenuItemClick(Sender: TObject);
    procedure RemoveCustomColorMenuItemClick(Sender: TObject);
  private
    PageControl: TPageControlEx;
    FEditingInProgress: Boolean;
    //Text of the Lottie animation last handed to the preview images, to skip a
    //rendering that would produce exactly the same result.
    FRenderedLottieText: string;
    FirstAction: Boolean;
    SkAnimatedImageEx: TSkAnimatedImageEx;
    SkAnimatedImageEx16: TSkAnimatedImageEx;
    SkAnimatedImageEx32: TSkAnimatedImageEx;
    SkAnimatedImageEx48: TSkAnimatedImageEx;
    SkAnimatedImageEx96: TSkAnimatedImageEx;
    MinFormWidth, MinFormHeight, MaxFormWidth, MaxFormHeight: Integer;
    FProcessingFiles: Boolean;
    FEditorSettings: TEditorSettings;
    CurrentDir: string;
    EditFileList: TObjectList;
    fSearchFromCaret: boolean;
    gbSearchBackwards: boolean;
    gbSearchCaseSensitive: boolean;
    gbSearchFromCaret: boolean;
    gbSearchSelectionOnly: boolean;
    gbSearchTextAtCaret: boolean;
    gbSearchWholeWords: boolean;
    gsSearchText: string;
    gsSearchTextHistory: string;
    gsReplaceText: string;
    gsReplaceTextHistory: string;
    FEditorOptions: TSynEditorOptionsContainer;
    FFontSize: Integer;
    FDropTarget: TDropTarget;
    //Color palette of the current editor
    FPaletteBar: TColorPaletteBar;
    FColorOccurrences: TLottieColorOccurrences;
    FColorPalette: TLottiePalette;
    //Editor and text last scanned, to skip a scan with the same result
    FPaletteEditor: TSynEdit;
    FPaletteText: string;
    //Palette entry whose occurrences are highlighted (-1 = none), position of
    //the current occurrence in its list (-1 = none reached yet) and the editor
    //holding the indicators
    FPaletteMatchEntry: Integer;
    FPaletteMatchPos: Integer;
    FPaletteMatchColor: TAlphaColor;
    FHighlightedEditor: TSynEdit;
    //Where the caret was before the first click of a double click
    FClickEditor: TSynEdit;
    FClickCaretOccurrence: Integer;
    //Swatch under the mouse when the palette context menu was opened
    FPopupHit: TColorPaletteHit;
    FCustomColors: TArray<TAlphaColor>;
    //Text changed after the last scan: the positions are not reliable until
    //the debounced rescan, so the caret is not matched against them
    FPaletteStale: Boolean;
    //Occurrence under the editor caret (-1 = none)
    FCaretOccurrence: Integer;
    procedure PauseAnimations;
    procedure StopAnimations;
    procedure StartAnimations(const AFromBegin: Boolean;
      APlayInverse: Boolean = False);
    // implement IDragDrop
    function DropAllowed(const FileNames: array of string): Boolean;
    procedure Drop(const FileNames: array of string);
    procedure CloseSplitViewMenu;
    procedure UpdateHighlighters;
    procedure UpdateFromSettings(AEditor: TSynEdit);
    function DialogPosRect: TRect;
    procedure AdjustCompactWidth;
    procedure AdjustViewerWidth(const ACenter: Boolean = False);
    function OpenFile(const FileName: string;
      const ARaiseError: Boolean = True): Boolean;
    function AddEditingFile(const EditingFile: TEditingFile): Integer;
    procedure RemoveEditingFile(EditingFile: TEditingFile);
    function CurrentEditFile: TEditingFile;
    function CurrentEditor: TSynEdit;
    function ModifiedCount: integer;
    procedure InitSynEditPrint;
    procedure InitEditorOptions;
    procedure InitDialog(const ADialog: TCustomFileDialog; const ADefaultFolder: string);
    procedure SetSynEditPrintProperties(SynEditPrint : TSynEditPrint);
    procedure UpdateEditorsOptions;
    function CurrentEditorState : string;
    procedure UpdateStatusBarPanels;
    procedure AddOpenedFile(const AFileName: string);
    procedure AssignLottieTextToImage;
    procedure SynEditChange(Sender: TObject);
    procedure SynEditEnter(Sender: TObject);
    procedure UpdateHighlighter(ASynEditor: TSynEdit);
    procedure ApplyStyleToGutter(AGutter: TSynGutter);
    procedure SetEditorFontSize(const Value: Integer);
    procedure LoadOpenedFiles;
    function CanAcceptFileName(const AFileName: string): Boolean;
    function AcceptedExtensions: string;
    function CreateAnimatedImageEx(const AParent: TWinControl; const ALeft,
      ATop, AWidth, AHeight: Integer; const AHint: string): TSkAnimatedImageEx;
    procedure UpdatePlayerControls;
    procedure SkAnimatedImageAnimationProcess(Sender: TObject);
    procedure UpdateRunLabel;
    procedure ConfirmChanges(EditingFile: TEditingFile);
    procedure UpdateTabsheetImage(ATabSheet: TTabSheet; AModified: Boolean);
    procedure UpdateRightSplitterPos;
    property EditorFontSize: Integer read FFontSize write SetEditorFontSize;
    procedure CreatePageControl;
    procedure CreatePaletteBar;
    procedure UpdatePaletteVisibility;
    procedure UpdateColorPalette(const AForce: Boolean = False);
    function PaletteEntryHint(const AEntry: TLottiePaletteEntry): string;
    procedure PaletteSwatchClick(Sender: TObject;
      ASection: TColorPaletteSection; AIndex: Integer);
    procedure HighlightPaletteEntry(const AEntry: Integer);
    procedure ClearPaletteHighlight;
    procedure GotoPaletteOccurrence(const APos: Integer);
    procedure UpdatePaletteInfo;
    procedure UpdatePaletteCaret;
    procedure SynEditStatusChange(Sender: TObject; Changes: TSynStatusChanges);
    function ColorDescription(const AColor: TAlphaColor): string;
    function SwatchColor(const ASection: TColorPaletteSection;
      const AIndex: Integer): TAlphaColor;
    function GetSelectedPaletteColor(out AColor: TAlphaColor): Boolean;
    procedure FocusCurrentEditor;
    procedure SavePaletteClickTarget;
    procedure PaletteSwatchDblClick(Sender: TObject;
      ASection: TColorPaletteSection; AIndex: Integer);
    procedure PaletteAddClick(Sender: TObject);
    procedure PaletteBarContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    function OccurrenceStart(const AOccurrence: TLottieColorOccurrence): TBufferCoord;
    function OccurrenceEnd(const AOccurrence: TLottieColorOccurrence): TBufferCoord;
    function ReplaceColorOccurrences(const AOccurrences: TArray<Integer>;
      const AColor: TAlphaColor): Integer;
    function ExecutePaletteColorDialog(var AColor: TAlphaColor): Boolean;
    function IndexOfCustomColor(const AColor: TAlphaColor): Integer;
    procedure LoadCustomColors;
    procedure SaveCustomColors;
    procedure AddCustomColor(const AColor: TAlphaColor);
    procedure UpdateCustomColorItems;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWindowHandle(const Params: TCreateParams); override;
    procedure DestroyWindowHandle; override;
    procedure WMCopyData(var Msg: TWMCopyData); message WM_COPYDATA;
  public
    procedure ManageExceptions(Sender: TObject; E: Exception);
  end;

var
  frmMain: TfrmMain;

implementation

uses
  Vcl.Themes
  , System.IOUtils
  , System.StrUtils
  , Winapi.ShellAPI
  , uMisc
  , Xml.XMLDoc
  , dlgReplaceText
  , dlgSearchText
  , dlgConfirmReplace
  , uAbout
  , FTestPrintPreview
  , DPageSetup
  , FSynHighlightProp
  , Math
  , Winapi.SHFolder
  , SettingsForm
  , uSingleInstance
  , uRegistry
  , Vcl.StyledTaskDialog
  , System.Generics.Collections
  , SynDWrite
  , Vcl.Clipbrd
  ;

{$R *.dfm}

const
  //Indicator marking the occurrences of the color selected in the palette
  PALETTE_INDICATOR_ID: TGUID = '{94CFE19C-9F1D-40DC-A2FE-CAC2EBBA2BBD}';

  STATUSBAR_PANEL_FONTNAME = 0;
  STATUSBAR_PANEL_FONTSIZE = 1;
  STATUSBAR_PANEL_CARET = 2;
  STATUSBAR_PANEL_MODIFIED = 3;
  STATUSBAR_PANEL_STATE = 4;
  STATUSBAR_MESSAGE = 5;

function DoubleQuote(const AValue: string): string;
begin
  Result := '"'+AValue+'"';
end;

//Applies the style and returns the one actually applied. TrySetStyle with
//False instead of SetStyle: a style name saved in Settings.ini that is no
//longer linked into the editor (e.g. removed in a newer version) raised an
//exception at startup.
function UpdateApplicationStyle(const VCLStyleName: string): string;
begin
  if StyleServices.Enabled then
  begin
    Result := VCLStyleName;
    if not TStyleManager.TrySetStyle(Result, False) then
    begin
      //Style no longer linked: use the default one, light or dark like the
      //Windows theme, and "Windows Modern" only as a last resort
      Result := DefaultStyleName;
      if not TStyleManager.TrySetStyle(Result, False) then
      begin
        Result := 'Windows Modern';
        TStyleManager.TrySetStyle(Result, False);
      end;
    end;
  end
  else
    Result := 'Windows';
end;

{ TEditingFile }

procedure TEditingFile.ReadFromFile;
begin
  LoadFromFile(FileName);
end;

constructor TEditingFile.Create(const EditFileName: string);
begin
  inherited Create;
  {$IFNDEF NO_VCL_STYLES}
  if not IsStyleHookRegistered(TCustomSynEdit, TScrollingStyleHook) then
    TStyleManager.Engine.RegisterStyleHook(TCustomSynEdit, TScrollingStyleHook);
  {$ENDIF}

  FileName := EditFileName;
  Fextension := ExtractFileExt(FileName);
end;

function TEditingFile.GetFileName: string;
begin
  Result := FFileName;
end;

function TEditingFile.GetImageName: string;
begin
  Result := TABSHEET_IMAGE;
end;

function TEditingFile.GetName: string;
begin
  Result := ExtractFileName(FFileName);
end;

procedure TEditingFile.UpdateTabSheetCaption;
begin
  if TabSheet <> nil then
  begin
    TabSheet.Caption := Name+'      '; //Spaces for Close Button space
    TabSheet.Hint := FFileName;
    TabSheet.ShowHint := True;
  end;
end;

procedure TEditingFile.SetFileName(const Value: string);
var
  Ext : string;
begin
  FFileName := Value;
  Ext := ExtractFileExt(FFileName);
  EditFileType := dmResources.GetEditFileType(Ext);
  UpdateTabSheetCaption;
end;

procedure TEditingFile.LoadFromFile(const AFileName: string);
begin
  try
    //Try loading UTF-8 file
    SynEditor.Lines.LoadFromFile(AFileName, TEncoding.UTF8);
  except
    on E: EEncodingError do
    begin
      //Try to load ANSI file
      SynEditor.Lines.LoadFromFile(AFileName, TEncoding.ANSI);
    end
    else
      raise;
  end;
  //NB: loading the content leaves an undo entry behind, so the first Ctrl+Z
  //emptied the file just opened - and left Modified True, so a save right
  //after would have written an empty file over the document.
  //TSynUndoPlugin.LinesInserted pushes a TSynLinesInsertedUndoItem for the
  //lines the load inserts, and the ClearUndo that TCustomSynEdit.ListCleared
  //would normally perform never runs on a still-empty buffer.
  SynEditor.ClearUndo;
  SynEditor.Modified := False;
  SynEditor.OnChange(SynEditor);
  FileAge(AFileName, FFileAge);
end;

procedure TEditingFile.SaveToFile;
begin
  SynEditor.Lines.SaveToFile(Self.FileName);
  SynEditor.Modified := False;
  FileAge(Self.FileName, FFileAge);
  SynEditor.OnChange(SynEditor);
end;

{ TfrmMain }

procedure TfrmMain.acOpenFileExecute(Sender: TObject);
var
  i : integer;
begin
  if OpenDialog.Execute then
  begin
    for i := 0 to OpenDialog.Files.Count -1 do
      OpenFile(OpenDialog.Files[i], False);
  end;
  AssignLottieTextToImage;
end;

function TfrmMain.CanAcceptFileName(const AFileName: string): Boolean;
begin
  //NB: this was a Pos() substring search over AcceptedExtensions, which is
  //case-sensitive - a file named "anim.JSON" was refused - and which also
  //matched partial extensions (".js" was accepted).
  //IsFileNameWithExt compares the whole extension with SameText.
  Result := IsFileNameWithExt(AFileName, GetSupportedExtensions(True));
end;

function TfrmMain.AcceptedExtensions: string;
begin
  //Check file extension
  Result := GetFileExtensionsList(GetSupportedExtensions(True));
end;

function TfrmMain.OpenFile(const FileName : string;
  const ARaiseError: Boolean = True): Boolean;
var
  EditingFile: TEditingFile;
  I, J: Integer;
  LErrorMsg: string;
  LCreated: Boolean;
begin
  Screen.Cursor := crHourGlass;
  Try
    FProcessingFiles := True;
    if FileExists(FileName) then
    begin
      if not CanAcceptFileName(FileName) then
        raise Exception.CreateFmt('Cannot open file with extensions different from "%s"',
          [AcceptedExtensions]);

      //looking for the file already opened
      EditingFile := nil;
      I := -1;
      LCreated := False;
      for J := 0 to EditFileList.Count -1 do
      begin
        if SameText(FileName, TEditingFile(EditFileList.Items[J]).FileName) then
        begin
          EditingFile := TEditingFile(EditFileList.Items[J]);
          I := J;
          PageControl.ActivePageIndex := I;
          break;
        end;
      end;
      //searching EditingFile object
      Try
        if not Assigned(EditingFile) then
        begin
          EditingFile := TEditingFile.Create(FileName);
          LCreated := True;
          //Add file to list
          I := AddEditingFile(EditingFile);
        end;

        //Opens the file
        EditingFile.ReadFromFile;

        Result := True;
      Except
        //NB: clean up only what this call actually created.
        //"I >= 0" alone was ambiguous in both directions: it was also >= 0 for
        //a file that was already open, so a failing reload closed the user's
        //existing tab; and when AddEditingFile raised, I was still -1 while the
        //object had already been put into the owning EditFileList, making
        //EditingFile.Free a second free.
        if LCreated then
        begin
          if I >= 0 then
            RemoveEditingFile(EditingFile)
          else
            EditingFile.Free;
        end;
        raise;
      End;
      AddOpenedFile(FileName);
    end
    else
    begin
      Result := False;
      if ARaiseError then
      begin
        LErrorMsg := Format(FILE_NOT_FOUND,[FileName]);
        StatusBar.Panels[STATUSBAR_MESSAGE].Text := LErrorMsg;
        Raise EFilerError.Create(LErrorMsg);
      end;
    end;
  Finally
    FProcessingFiles := False;
    Screen.Cursor := crDefault;
  End;
end;

procedure TfrmMain.OpenRecentActionExecute(Sender: TObject);
var
  LRect: TRect;
  LPoint: TPoint;
begin
  LRect := catMenuItems.Categories[0].Items[2].Bounds;
  LPoint.X := LRect.Right;
  LPoint.Y := LRect.Bottom+LRect.Height;
  LPoint   := ClientToScreen(LPoint);
  RecentPopupMenu.Popup(LPoint.X, LPoint.Y);
end;

procedure TfrmMain.acSaveExecute(Sender: TObject);
begin
  CurrentEditFile.SaveToFile;
end;

procedure TfrmMain.AppActivate(Sender: TObject);
begin
  CheckFileChangedTimerTimer(CheckFileChangedTimer);
end;

procedure TfrmMain.AppDeactivate(Sender: TObject);
begin
  CheckFileChangedTimer.Enabled := False;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(EditFileList);
  FreeAndNil(SynEditPrint);
  FreeAndNil(FEditorSettings);
  FreeAndNil(FEditorOptions);
  inherited;
end;

procedure TfrmMain.FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  if Shift = [ssCtrl] then
  begin
    actnReduceFont.Execute;
    Handled := True;
  end;
end;

procedure TfrmMain.FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  if Shift = [ssCtrl] then
  begin
    actnEnlargeFont.Execute;
    Handled := True;
  end;
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  AdjustCompactWidth;
  AdjustViewerWidth;
end;

procedure TfrmMain.ShowSRDialog(aReplace: boolean);
var
  dlg: TTextSearchDialog;
begin
  if AReplace then
    dlg := TTextReplaceDialog.Create(Self)
  else
    dlg := TTextSearchDialog.Create(Self);
  with dlg do
  try
    // assign search options
    SearchBackwards := gbSearchBackwards;
    SearchCaseSensitive := gbSearchCaseSensitive;
    SearchFromCursor := gbSearchFromCaret;
    SearchInSelectionOnly := gbSearchSelectionOnly;
    // start with last search text
    SearchText := gsSearchText;
    if gbSearchTextAtCaret then
    begin
      // if something is selected search for that text
      if CurrentEditor.SelAvail and (CurrentEditor.BlockBegin.Line = CurrentEditor.BlockEnd.Line) then
        SearchText := CurrentEditor.SelText
      else
        SearchText := CurrentEditor.GetWordAtRowCol(CurrentEditor.CaretXY);
    end;
    SearchTextHistory := gsSearchTextHistory;
    if AReplace then
      with dlg as TTextReplaceDialog do
      begin
        ReplaceText := gsReplaceText;
        ReplaceTextHistory := gsReplaceTextHistory;
      end;
    SearchWholeWords := gbSearchWholeWords;
    if ShowModal = mrOK then
    begin
      gbSearchBackwards := SearchBackwards;
      gbSearchCaseSensitive := SearchCaseSensitive;
      gbSearchFromCaret := SearchFromCursor;
      gbSearchSelectionOnly := SearchInSelectionOnly;
      gbSearchWholeWords := SearchWholeWords;
      gsSearchText := SearchText;
      gsSearchTextHistory := SearchTextHistory;
      if AReplace then
        with dlg as TTextReplaceDialog do
        begin
          gsReplaceText := ReplaceText;
          gsReplaceTextHistory := ReplaceTextHistory;
        end;
      fSearchFromCaret := gbSearchFromCaret;
      if gsSearchText <> '' then
      begin
        DoSearchReplaceText(AReplace, gbSearchBackwards);
        fSearchFromCaret := TRUE;
      end;
    end;
  finally
    dlg.Free;
  end;
end;

procedure TfrmMain.SVClosed(Sender: TObject);
begin
  // When TSplitView is closed, adjust ButtonOptions and Width
  catMenuItems.ButtonOptions := catMenuItems.ButtonOptions - [boShowCaptions];
  actMenu.Hint := 'Expand';
end;

procedure TfrmMain.SVClosing(Sender: TObject);
begin
  if SV.Opened then
    SV.OpenedWidth := SV.Width;
end;

procedure TfrmMain.TabSheetCloseButtonClick(Sender: TObject);
begin
  PageControl.ActivePage := Sender as TTabSheet;
  acClose.Execute;
end;

procedure TfrmMain.SkAnimatedImageExMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  LSize: Integer;
  LSkAnimatedImageEx: TSkAnimatedImageEx;
begin
  LSkAnimatedImageEx := Sender as TSkAnimatedImageEx;
  LSize := Min(LSkAnimatedImageEx.Width, LSkAnimatedImageEx.Height);
  LSkAnimatedImageEx.Hint := Format('%dx%d',[LSize, LSize]);
end;

procedure TfrmMain.StartAnimations(const AFromBegin: Boolean;
  APlayInverse: Boolean = False);
begin
  SkAnimatedImageEx.StartAnimation(AFromBegin, APlayInverse);
  SkAnimatedImageEx16.StartAnimation(AFromBegin, APlayInverse);
  SkAnimatedImageEx32.StartAnimation(AFromBegin, APlayInverse);
  SkAnimatedImageEx48.StartAnimation(AFromBegin, APlayInverse);
  SkAnimatedImageEx96.StartAnimation(AFromBegin, APlayInverse);
end;

procedure TfrmMain.PauseAnimations;
begin
  SkAnimatedImageEx.PauseAnimation;
  SkAnimatedImageEx16.PauseAnimation;
  SkAnimatedImageEx32.PauseAnimation;
  SkAnimatedImageEx48.PauseAnimation;
  SkAnimatedImageEx96.PauseAnimation;
end;

procedure TfrmMain.StopAnimations;
begin
  SkAnimatedImageEx.StopAnimation;
  SkAnimatedImageEx16.StopAnimation;
  SkAnimatedImageEx32.StopAnimation;
  SkAnimatedImageEx48.StopAnimation;
  SkAnimatedImageEx96.StopAnimation;
end;

procedure TfrmMain.SVOpened(Sender: TObject);
begin
  // When not animating, change size of catMenuItems when TSplitView is opened
  catMenuItems.ButtonOptions := catMenuItems.ButtonOptions + [boShowCaptions];
  actMenu.Hint := 'Collapse';
end;

procedure TfrmMain.SVOpening(Sender: TObject);
begin
  // When animating, change size of catMenuItems at the beginning of open
  catMenuItems.ButtonOptions := catMenuItems.ButtonOptions + [boShowCaptions];
end;

procedure TfrmMain.DestroyWindowHandle;
begin
  FreeAndNil(FDropTarget);
  inherited;
end;

function TfrmMain.DialogPosRect: TRect;
begin
  GetWindowRect(Self.Handle, Result);
end;

procedure TfrmMain.DoSearchReplaceText(AReplace: boolean;
  ABackwards: boolean);
var
  Options: TSynSearchOptions;
begin
  if AReplace then
    Options := [ssoPrompt, ssoReplace, ssoReplaceAll]
  else
    Options := [];
  if ABackwards then
    Include(Options, ssoBackwards);
  if gbSearchCaseSensitive then
    Include(Options, ssoMatchCase);
  if not fSearchFromCaret then
    Include(Options, ssoEntireScope);
  if gbSearchSelectionOnly then
    Include(Options, ssoSelectedOnly);
  if gbSearchWholeWords then
    Include(Options, ssoWholeWord);
  if CurrentEditor.SearchReplace(gsSearchText, gsReplaceText, Options) = 0 then
  begin
    MessageBeep(MB_ICONASTERISK);
    if ssoBackwards in Options then
      CurrentEditor.BlockEnd := CurrentEditor.BlockBegin
    else
      CurrentEditor.BlockBegin := CurrentEditor.BlockEnd;
    CurrentEditor.CaretXY := CurrentEditor.BlockBegin;
  end;

  if ConfirmReplaceDialog <> nil then
    ConfirmReplaceDialog.Free;
end;

procedure TfrmMain.Drop(const FileNames: array of string);
var
  i: Integer;
begin
  for i := 0 to Length(FileNames)-1 do
  begin
    if CanAcceptFileName(FileNames[i]) then
      OpenFile(FileNames[i], False);
  end;
  AssignLottieTextToImage;
end;

function TfrmMain.DropAllowed(const FileNames: array of string): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to Length(FileNames)-1 do
  begin
    Result := CanAcceptFileName(FileNames[i]);
    if Result then
      Break;
  end;
end;

procedure TfrmMain.ExportToPNGActionExecute(Sender: TObject);
var
  LFileName: string;
begin
  LFileName := ChangeFileExt(CurrentEditFile.FileName, '.png');
end;

procedure TfrmMain.acSearchExecute(Sender: TObject);
begin
  ShowSRDialog(false);
end;

procedure TfrmMain.acReplaceExecute(Sender: TObject);
begin
  ShowSRDialog(true);
end;

procedure TfrmMain.acQuitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  LFileList: TStringList;
  I: Integer;
  LCurrentFileName: string;
  LEditingFile: TEditingFile;
begin
  LFileList := TStringList.Create;
  try
    //Save Opened File list, based on Pages
    for I := 0 to PageControl.PageCount -1 do
    begin
      LEditingFile := TEditingFile(PageControl.Pages[I].Tag);
      //Confirm save changes
      //NB: ConfirmChanges raises EAbort when the user chooses Cancel. Catching
      //it here and refusing the close is what makes that button mean anything.
      //Returning caNone also leaves the settings untouched: the session is not
      //over.
      try
        ConfirmChanges(LEditingFile);
      except
        on EAbort do
        begin
          Action := caNone;
          Exit;
        end;
      end;
      LFileList.Add(LEditingFile.FileName);
    end;
    if CurrentEditFile <> nil then
      LCurrentFileName := CurrentEditFile.FileName
    else
      LCurrentFileName := '';
    FEditorSettings.UpdateOpenedFiles(LFileList, LCurrentFileName);
    //Palette height is stored at 96 DPI
    FEditorSettings.ColorPaletteHeight := MulDiv(PalettePanel.Height,
      Screen.DefaultPixelsPerInch, CurrentPPI);
    FEditorSettings.WriteSettings(nil, FEditorOptions);
  finally
    LFileList.Free;
  end;
end;

procedure TfrmMain.LoadOpenedFiles;
var
  I: Integer;
  LFileName: string;
  LCurrentPage: TTabSheet;
  LCurrentFileName: string;
begin
  LCurrentPage := nil;
  LCurrentFileName := FEditorSettings.CurrentFileName;
  PageControl.Hide;
  try
    for I := 0 to FEditorSettings.OpenedFileList.Count-1 do
    begin
      LFileName := FEditorSettings.OpenedFileList.Strings[I];
      if OpenFile(LFileName, False) and SameText(LFileName, LCurrentFileName) then
        //NB: the settings index is not the page index - a remembered file that
        //no longer opens creates no page - so using I here activated the wrong
        //tab. OpenFile always leaves the file's own page active, so take the
        //page from the PageControl instead.
        LCurrentPage := PageControl.ActivePage;
    end;
    if Assigned(LCurrentPage) then
    begin
      PageControl.ActivePage := LCurrentPage;
      AssignLottieTextToImage;
    end;
  finally
    PageControl.Show;
  end;
end;

procedure TfrmMain.LoadTimerTimer(Sender: TObject);
begin
  //Debounced rendering: this fires LoadTimer.Interval ms after the last
  //keystroke. Before, the rendering sat in SynEditChange and every keystroke
  //reloaded the animation in all five preview images.
  LoadTimer.Enabled := False;
  if FEditingInProgress then
  begin
    FEditingInProgress := False;
    AssignLottieTextToImage;
  end;
end;

procedure TfrmMain.LoopToggleSwitchClick(Sender: TObject);
begin
  SkAnimatedImageEx.AnimationLoop := LoopToggleSwitch.State = tssOn;
  SkAnimatedImageEx16.AnimationLoop := LoopToggleSwitch.State = tssOn;
  SkAnimatedImageEx32.AnimationLoop := LoopToggleSwitch.State = tssOn;
  SkAnimatedImageEx48.AnimationLoop := LoopToggleSwitch.State = tssOn;
  SkAnimatedImageEx96.AnimationLoop := LoopToggleSwitch.State = tssOn;
end;

function TfrmMain.CreateAnimatedImageEx(const AParent: TWinControl;
  const ALeft, ATop, AWidth, AHeight: Integer;
  const AHint: string): TSkAnimatedImageEx;
begin
  Result := TSkAnimatedImageEx.Create(Self);
  try
    Result.AlignWithMargins := True;
    Result.Parent := AParent;
    if (ALeft = -1) then
      Result.Align := alClient
    else
      Result.SetBounds(ALeft, ATop, AWidth, AHeight);
    Result.OnMouseMove := SkAnimatedImageExMouseMove;
    Result.Hint := AHint;
  except
    Result.Free;
    raise;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  FileVersionStr: string;
begin
  CreatePageControl;

  //To check Application Focus
  Application.OnActivate := AppActivate;
  Application.OnDeactivate := AppDeactivate;

  //Initialize AnimatedTaskDialog font size and use of CommandLinks
  Screen.MessageFont.Size := Round(Screen.MessageFont.Size*1.2);
  InitializeStyledTaskDialogs(True, Screen.MessageFont, True);

  //Build animated preview images
  SkAnimatedImageEx   := CreateAnimatedImageEx(ImagePanel, -1,-1,-1,-1,'96x96');
  SkAnimatedImageEx.OnAnimationProcess := SkAnimatedImageAnimationProcess;

  SkAnimatedImageEx16 := CreateAnimatedImageEx(FlowPanel ,  3, 3,24,24,'24x24');
  SkAnimatedImageEx32 := CreateAnimatedImageEx(FlowPanel , 33, 3,36,36,'36x36');
  SkAnimatedImageEx48 := CreateAnimatedImageEx(FlowPanel , 75, 3,48,48,'48x48');
  SkAnimatedImageEx96 := CreateAnimatedImageEx(FlowPanel ,129, 3,96,96,'96x96');

  //Build opened-files list
  EditFileList := TObjectList.Create(True);
  FEditorOptions := TSynEditorOptionsContainer.create(self);
  FEditorSettings := TEditorSettings.CreateSettings(nil, FEditorOptions);
  {$IFNDEF NO_VCL_STYLES}
  if not IsStyleHookRegistered(TCustomSynEdit, TScrollingStyleHook) then
    TStyleManager.Engine.RegisterStyleHook(TCustomSynEdit, TScrollingStyleHook);
  {$ENDIF}

  if (Trim(FEditorSettings.StyleName) <> '') and not SameText('Windows', FEditorSettings.StyleName) then
    TStyleManager.TrySetStyle(FEditorSettings.StyleName, False);

  //Double font for title
  lblTitle.Font.Size := lblTitle.Font.Size * 2;

  //Bold font for image preview panel
  ImagePreviewPanel.Font.Style := ImagePreviewPanel.Font.Style + [fsBold];

  //Version
  FileVersionStr := uMisc.GetFileVersion(GetModuleLocation());
  Application.Title := Application.Title + ' (Ver.'+FileVersionStr+')';
  Caption := Application.Title;

  WindowState := wsMaximized;

  UpdateFromSettings(nil);

  //Color palette under the editor
  CreatePaletteBar;

  //Explicit attach imagelist
  ActionList.Images := VirtualImageList;

  //staring folder
  CurrentDir := IncludeTrailingPathDelimiter(TPath.GetDocumentsPath);

  //Initialize print output
  InitSynEditPrint;

  //Update all editor options
  UpdateEditorsOptions;
end;

procedure TfrmMain.acNewFileExecute(Sender: TObject);
var
  NewExt, LNewFileName: string;
  EditingFile : TEditingFile;
  LCount: Integer;
begin
  NewExt := 'lottie';

  //Create object to manage new file
  LCount := 0;
  LNewFileName := Format('%s%s.%s', [CurrentDir,'New',NewExt]);
  while FileExists(LNewFileName) do
  begin
    Inc(LCount);
    LNewFileName := Format('%s%s(%d).%s', [CurrentDir,'New',LCount,NewExt]);
  end;

  EditingFile := TEditingFile.Create(LNewFileName);
  Try
    AddEditingFile(EditingFile);
  Except
    //NB: ownership passes to EditFileList only when AddEditingFile succeeds,
    //so freeing here is correct exactly in the failure case. SetFocus moved
    //out of the Try: it runs after the transfer, and a failure there must not
    //free an object the owning list already holds.
    EditingFile.Free;
    raise;
  End;
  if Assigned(EditingFile.SynEditor) and EditingFile.SynEditor.CanFocus then
    EditingFile.SynEditor.SetFocus;
end;

procedure TfrmMain.acSearchUpdate(Sender: TObject);
begin
  acSearch.Enabled := (CurrentEditor <> nil) and (CurrentEditor.Text <> '');
end;

procedure TfrmMain.acReplaceUpdate(Sender: TObject);
begin
  acReplace.Enabled := (CurrentEditor <> nil) and (CurrentEditor.Text <> '')
    and not CurrentEditor.ReadOnly;
end;

procedure TfrmMain.acCloseExecute(Sender: TObject);
begin
  RemoveEditingFile(CurrentEditFile);
end;

procedure TfrmMain.acEditCopyExecute(Sender: TObject);
begin
  CurrentEditor.CopyToClipboard;
end;

procedure TfrmMain.acEditCopyUpdate(Sender: TObject);
begin
  acEditCopy.Enabled := (CurrentEditFile <> nil) and
    (CurrentEditFile.SynEditor.SelEnd - CurrentEditFile.SynEditor.SelStart > 0);
end;

procedure TfrmMain.acEditCutExecute(Sender: TObject);
begin
  CurrentEditor.CutToClipboard;
end;

procedure TfrmMain.acEditPasteExecute(Sender: TObject);
begin
  CurrentEditor.PasteFromClipboard;
end;

procedure TfrmMain.acEditSelectAllExecute(Sender: TObject);
begin
  CurrentEditor.SelectAll;
end;

procedure TfrmMain.acEditUndoExecute(Sender: TObject);
begin
  if CurrentEditor <> nil then
    CurrentEditor.Undo;
end;

procedure TfrmMain.acEditUndoUpdate(Sender: TObject);
begin
  acEditUndo.Enabled := (CurrentEditor <> nil) and CurrentEditor.Modified;
end;

procedure TfrmMain.UpdateTabsheetImage(ATabSheet: TTabSheet;
  AModified: Boolean);
begin
  if AModified then
    ATabSheet.ImageName := TABSHEET_IMAGE
  else
    ATabSheet.ImageName := TABSHEET_IMAGE+'-gray';
end;

procedure TfrmMain.SynEditChange(Sender: TObject);
begin
  if (Sender = CurrentEditor) and not FProcessingFiles then
  begin
    FEditingInProgress := True;
    //Restart the debounce countdown. The animation is deliberately NOT
    //reloaded here: that happens in LoadTimerTimer once typing has paused.
    //Assigning False then True is the way to restart a TTimer: assigning True
    //to an already-enabled timer is a no-op, so it would not reset it.
    LoadTimer.Enabled := False;
    LoadTimer.Enabled := True;
    FPaletteStale := True;
    UpdateTabsheetImage(pageControl.ActivePage, CurrentEditor.Modified);
  end;
end;

procedure TfrmMain.SynEditEnter(Sender: TObject);
begin
  CloseSplitViewMenu;
end;

procedure TfrmMain.UpdateRunLabel;
begin
  RunLabel.Caption := SkAnimatedImageEx.ProgressPercentage.ToString+' %';
end;

procedure TfrmMain.TrackBarChange(Sender: TObject);
begin
  SkAnimatedImageEx.ProgressPercentage := TrackBar.Position;
  SkAnimatedImageEx16.ProgressPercentage := TrackBar.Position;
  SkAnimatedImageEx32.ProgressPercentage := TrackBar.Position;
  SkAnimatedImageEx48.ProgressPercentage := TrackBar.Position;
  SkAnimatedImageEx96.ProgressPercentage := TrackBar.Position;
  UpdateRunLabel;
end;

procedure TfrmMain.SkAnimatedImageAnimationProcess(Sender: TObject);
var
  LPos: Integer;
begin
  TrackBar.OnChange := nil;
  Try
    LPos := SkAnimatedImageEx.ProgressPercentage;
    if LPos <> TrackBar.Position then
    begin
      TrackBar.Position := LPos;
      UpdateRunLabel;
    end;
  Finally
    TrackBar.OnChange := TrackBarChange;
  End;
end;

procedure TfrmMain.StopActionExecute(Sender: TObject);
begin
  StopAnimations;
end;

procedure TfrmMain.PauseActionExecute(Sender: TObject);
begin
  PauseAnimations;
end;

procedure TfrmMain.PlayActionExecute(Sender: TObject);
begin
  StartAnimations(False);
end;

procedure TfrmMain.PlayInverseActionExecute(Sender: TObject);
begin
  StartAnimations(False, True);
end;

function TfrmMain.AddEditingFile(const EditingFile: TEditingFile): Integer;
var
  LTabSheet: TTabSheet;
  LEditor: TSynEdit;
begin
  //Create the Tabsheet page associated to the file
  LTabSheet := nil;
  Try
    LTabSheet := TTabSheet.Create(self);
    LTabSheet.PageControl := PageControl;
    //Use TAG of tabsheet to store the object pointer
    LTabSheet.Tag := NativeInt(EditingFile);
    LTabSheet.Imagename := TABSHEET_IMAGE+'-gray';
    LTabSheet.Parent := PageControl;
    LTabSheet.TabVisible := True;
    EditingFile.TabSheet := LTabSheet;
    EditingFile.UpdateTabSheetCaption;

    //Create the SynEdit object editor into the TabSheet that is the owner
    LEditor := TSynEdit.Create(LTabSheet);
    LEditor.OnChange := SynEditChange;
    LEditor.OnStatusChange := SynEditStatusChange;
    LEditor.OnEnter := SynEditEnter;
    LEditor.MaxUndo := 5000;
    LEditor.Align := alClient;
    LEditor.Parent := LTabSheet;
    LEditor.SearchEngine := SynEditSearch;
    LEditor.PopupMenu := popEditor;

    //Assign user preferences to the editor
    FEditorOptions.AssignTo(LEditor);
    EditingFile.SynEditor := LEditor;
    UpdateFromSettings(LEditor);
    UpdateHighlighter(LEditor);

    LEditor.Visible := True;

    //Show the tabsheet
    LTabSheet.Visible := True;
  Except
    //NB: LEditor is owned by LTabSheet (see TSynEdit.Create above), so freeing
    //the TabSheet destroys the editor as well - the LEditor.Free that used to
    //follow operated on a dangling pointer. EditingFile is deliberately not
    //touched here: it is not in EditFileList yet, so the caller remains its
    //sole owner and can free it exactly once.
    EditingFile.SynEditor := nil;
    EditingFile.TabSheet := nil;
    LTabSheet.Free;
    raise;
  End;

  //Everything succeeded: from now on EditFileList owns the object.
  //NB: the insertion used to happen before the Try, so any failure left a
  //dangling entry in an owning list while the caller freed the object too.
  Result := EditFileList.Add(EditingFile);

  //Make the Tabsheet the current page
  PageControl.ActivePage := LTabSheet;

  //and call "change" of pagecontrol
  PageControl.OnChange(PageControl);
end;

procedure TfrmMain.AssignLottieTextToImage;
var
  LLottieText: string;
  LSavedCursor: TCursor;
begin
  if FProcessingFiles then
    Exit;
  //The palette has its own check of the text already scanned
  UpdateColorPalette;
  //Assign Lottie animation
  try
    if CurrentEditor <> nil then
    begin
      LLottieText := CurrentEditor.Lines.Text;
      //NB: skip the whole reload when the content is the one already
      //displayed. AssignLottieTextToImage is reached from the page change,
      //from drag and drop, from WM_COPYDATA, from the file-changed timer and
      //from the debounce timer, so the same text was frequently loaded twice
      //in a row, restarting the animation.
      if LLottieText = FRenderedLottieText then
      begin
        StatusBar.Panels[STATUSBAR_MESSAGE].Text := CurrentEditFile.FileName;
        Exit;
      end;
      LSavedCursor := Screen.Cursor;
      Screen.Cursor := crHourGlass;
      try
        //Cleared first: if loading raises, the next call must retry
        FRenderedLottieText := '';
        SkAnimatedImageEx.LottieText := LLottieText;
        SkAnimatedImageEx16.LottieText := LLottieText;
        SkAnimatedImageEx32.LottieText := LLottieText;
        SkAnimatedImageEx48.LottieText := LLottieText;
        SkAnimatedImageEx96.LottieText := LLottieText;
        FRenderedLottieText := LLottieText;
      finally
        Screen.Cursor := LSavedCursor;
      end;
      StatusBar.Panels[STATUSBAR_MESSAGE].Text := CurrentEditFile.FileName;
      if Assigned(FEditorSettings) and FEditorSettings.AutoPlay then
        StartAnimations(True)
      else
        StopAnimations;
    end
    else
    begin
      SkAnimatedImageEx.LottieText := '';
      SkAnimatedImageEx16.LottieText := '';
      SkAnimatedImageEx32.LottieText := '';
      SkAnimatedImageEx48.LottieText := '';
      SkAnimatedImageEx96.LottieText := '';
      FRenderedLottieText := '';
    end;
    StatusImage.ImageIndex := 40;
    StatusStaticText.Caption := LOTTIE_PARSING_OK;
  except
    on E: Exception do
    begin
      StatusImage.ImageIndex := 39;
      StatusStaticText.Caption := E.Message;
    end;
  end;
end;

procedure TfrmMain.BackgroundTrackBarChange(Sender: TObject);
var
  LValue: byte;
begin
  LValue := BackgroundTrackBar.Position;
  BackgroundGrayScaleLabel.Caption := Format(
    Background_Grayscale_Caption,
    [LValue * 100 div 255]);
  ImagePanel.Color := RGB(LValue, LValue, LValue);
  FEditorSettings.LightBackground := BackgroundTrackBar.Position;
end;

procedure TfrmMain.PageControlChange(Sender: TObject);
begin
  CloseSplitViewMenu;
  //Setting the Editor caption as the actual file opened
  if CurrentEditFile <> nil then
  begin
    Caption := Application.Title+' - '+CurrentEditFile.FileName;
    if (CurrentEditFile.SynEditor.CanFocus) then
      CurrentEditFile.SynEditor.SetFocus;
  end;
  AssignLottieTextToImage;
end;

procedure TfrmMain.PageControlMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  LhintPause: Integer;
  LTabIndex: Integer;
begin
  inherited;
  LTabIndex := PageControl.IndexOfTabAt(X, Y);
  if (LTabIndex >= 0) and (PageControl.Hint <> PageControl.Pages[LTabIndex].Hint) then
  begin
    LHintPause := Application.HintPause;
    try
      if PageControl.Hint <> '' then
        Application.HintPause := 0;
      Application.CancelHint;
      PageControl.Hint := PageControl.Pages[LTabIndex].Hint;
      PageControl.ShowHint := true;
    finally
      Application.HintPause := LHintPause;
    end;
  end;
end;

procedure TfrmMain.acSaveUpdate(Sender: TObject);
begin
  acSave.Enabled := (CurrentEditor <> nil) and (CurrentEditor.Modified);
end;

procedure TfrmMain.CheckFileChangedTimerTimer(Sender: TObject);
var
  LFileAge: TDateTime;
begin
  CheckFileChangedTimer.Enabled := False;
  Try
    //Check if opened files are changed on Disk
    for var I := 0 to EditFileList.Count -1 do
    begin
      var LEditFile := TEditingFile(EditFileList.items[I]);
      if FileAge(LEditFile.FileName, LFileAge) then
      begin
        if LFileAge <> LEditFile.FileTimestamp then
        begin
          var LConfirm := StyledMessageDlg(Format(FILE_CHANGED_RELOAD,[LEditFile.FileName]),
            mtWarning, [mbYes, mbNo], 0);
          if LConfirm = mrYes then
          begin
            LEditFile.ReadFromFile;
            UpdateTabsheetImage(LEditFile.TabSheet, False);
            SynEditChange(LEditFile.SynEditor);
          end
          else
            LEditFile.FileTimestamp := LFileAge;
        end;
      end;
    end;
  Finally
    CheckFileChangedTimer.Enabled := True;
  End;
end;

procedure TfrmMain.CloseSplitViewMenu;
begin
  SV.Close;
  Screen.Cursor := crDefault;
end;

procedure TfrmMain.CreateParams(var Params: TCreateParams);
begin
  inherited;
  // Custom window-class name so a second instance can locate us via
  // FindWindow() and forward command-line files via WM_COPYDATA.
  StrPLCopy(Params.WinClassName, cLottieTextEditorWindowClass,
    Length(Params.WinClassName) - 1);
end;

procedure TfrmMain.CreateWindowHandle(const Params: TCreateParams);
begin
  inherited;
  FDropTarget := TDropTarget.Create(WindowHandle, Self);
end;

procedure TfrmMain.WMCopyData(var Msg: TWMCopyData);
const
  //A Windows path with the \\?\ prefix can reach 32767 characters.
  MAX_COPYDATA_BYTES = (32767 + 1) * SizeOf(Char);
var
  LFileName: string;
  LChars: Integer;
begin
  Msg.Result := 0;
  if (Msg.CopyDataStruct = nil) or
     (Msg.CopyDataStruct.dwData <> cLottieTextEditorCopyDataOpenFile) or
     (Msg.CopyDataStruct.cbData = 0) or
     (Msg.CopyDataStruct.lpData = nil) then
    Exit;

  // Payload is a null-terminated PChar (UnicodeString). cbData is in bytes.
  //NB: cbData is chosen by the sender: bound the size, then cut at the first
  //#0 instead of trusting the declared length.
  if Msg.CopyDataStruct.cbData > MAX_COPYDATA_BYTES then
    Exit;
  LChars := (Msg.CopyDataStruct.cbData div SizeOf(Char));
  if LChars > 0 then Dec(LChars); // drop the trailing #0
  SetString(LFileName, PChar(Msg.CopyDataStruct.lpData), LChars);
  LChars := Pos(#0, LFileName);
  if LChars > 0 then
    SetLength(LFileName, LChars - 1);

  if FileExists(LFileName) then
  begin
    OpenFile(LFileName, False);
    AssignLottieTextToImage;
  end;

  // Bring our window to the foreground (the sender called
  // AllowSetForegroundWindow so SetForegroundWindow is allowed).
  if IsIconic(Handle) then
    ShowWindow(Handle, SW_RESTORE)
  else
    ShowWindow(Handle, SW_SHOW);
  SetForegroundWindow(Handle);

  Msg.Result := 1;
end;

function TfrmMain.CurrentEditFile: TEditingFile;
begin
  if (PageControl.ActivePage <> nil) then
    Result := TEditingFile(PageControl.ActivePage.Tag)
  else
    Result := nil;
end;

function TfrmMain.CurrentEditor: TSynEdit;
begin
  if CurrentEditFile <> nil then
    Result := CurrentEditFile.SynEditor else
    Result := nil;
end;

procedure TfrmMain.ConfirmChanges(EditingFile: TEditingFile);
var
  LConfirm: integer;
begin
  //Confirm save changes
  //NB: SynEditor is assigned inside AddEditingFile, so the failure path
  //OpenFile -> except -> RemoveEditingFile can reach here with it still nil.
  if Assigned(EditingFile.SynEditor) and EditingFile.SynEditor.Modified then
  begin
    //NB: mbCancel added. The Abort branch below existed but was unreachable
    //without it, so closing with unsaved changes could not be called off.
    LConfirm := StyledMessageDlg(Format(CONFIRM_CHANGES,[EditingFile.FileName]),
      mtWarning, [mbYes, mbNo, mbCancel], 0);
    if LConfirm = mrYes then
      EditingFile.SaveToFile
    else if LConfirm = mrCancel then
      Abort;
    //if LConfirm = mrNo continue without saving
  end;
end;

procedure TfrmMain.RemoveEditingFile(EditingFile: TEditingFile);
var
  I: Integer;
  LPos: Integer;
  LTabSheet: TTabSheet;
  LPageIndex: Integer;
begin
  LPos := -1;
  for I := 0 to EditFileList.Count -1 do
  begin
    if EditFileList.Items[I] = EditingFile then
    begin
      LPos := I;
      Break;
    end;
  end;
  if LPos = -1 then
    raise EComponentError.Create(CLOSING_PROBLEMS);

  //Confirm save changes: raises EAbort if the user chooses Cancel, which
  //leaves the file open - EAbort is silent by design.
  ConfirmChanges(EditingFile);

  //NB: take the page from the object instead of PageControl.Pages[LPos]:
  //indexing one collection with the other's index breaks without a sound.
  LTabSheet := EditingFile.TabSheet;
  if Assigned(LTabSheet) then
    LPageIndex := LTabSheet.PageIndex
  else
    LPageIndex := -1;

  //The editor is about to be destroyed: forget the palette references to it
  if FHighlightedEditor = EditingFile.SynEditor then
    FHighlightedEditor := nil;
  if FPaletteEditor = EditingFile.SynEditor then
    FPaletteEditor := nil;
  if FClickEditor = EditingFile.SynEditor then
    FClickEditor := nil;

  //Delete the file from the Opened-List. EditFileList owns the object, so this
  //frees the TEditingFile; the SynEdit belongs to the TabSheet, not to it.
  EditFileList.Delete(LPos);

  //Delete the TabSheet, which destroys the editor it owns
  LTabSheet.Free;

  //Activate the page that slid into the removed one's place, or the last one
  //(closing the first page activated none)
  if (PageControl.PageCount > 0) and (LPageIndex >= 0) then
  begin
    if LPageIndex >= PageControl.PageCount then
      LPageIndex := PageControl.PageCount - 1;
    PageControl.ActivePageIndex := LPageIndex;
  end;

  //Force "change" of Page
  if Assigned(PageControl.OnChange) then
    PageControl.OnChange(PageControl);
end;

procedure TfrmMain.acCloseAllUpdate(Sender: TObject);
begin
  acCloseAll.Enabled := EditFileList.Count > 0;
end;

procedure TfrmMain.acCloseAllExecute(Sender: TObject);
begin
  FProcessingFiles := True;
  try
    while EditFileList.Count > 0 do
      RemoveEditingFile(TEditingFile(EditFileList.items[0]));
  finally
    FProcessingFiles := False;
    AssignLottieTextToImage;
    UpdateStatusBarPanels;
  end;
end;

procedure TfrmMain.acSaveAllUpdate(Sender: TObject);
begin
  acSaveAll.Enabled := ModifiedCount > 0;
end;

function TfrmMain.ModifiedCount: integer;
var
  i : integer;
  LEditFile: TEditingFile;
begin
  Result := 0;
  for i := 0 to EditFileList.Count -1 do
  begin
    LEditFile := TEditingFile(EditFileList.items[i]);
    if Assigned(LEditFile.SynEditor) and LEditFile.SynEditor.Modified then
    begin
      Inc(Result);
    end;
  end;
end;

procedure TfrmMain.acSaveAllExecute(Sender: TObject);
var
  i : integer;
  LEditFile: TEditingFile;
  LErrors: TStringList;
begin
  //NB: a single failing file must not abort the loop, otherwise every modified
  //file after it silently stays unsaved while the error dialog names only one.
  //Collect the failures and report them together at the end.
  LErrors := TStringList.Create;
  try
    for i := 0 to EditFileList.Count -1 do
    begin
      LEditFile := TEditingFile(EditFileList.items[i]);
      if Assigned(LEditFile.SynEditor) and LEditFile.SynEditor.Modified then
      begin
        try
          LEditFile.SaveToFile;
        except
          on E: Exception do
            LErrors.Add(Format('%s: %s', [LEditFile.FileName, E.Message]));
        end;
      end;
    end;
    if LErrors.Count > 0 then
      raise Exception.CreateFmt(FILES_NOT_SAVED, [sLineBreak + LErrors.Text]);
  finally
    LErrors.Free;
  end;
end;

procedure TfrmMain.acAboutExecute(Sender: TObject);
begin
  ShowAboutForm(DialogPosRect, Title_LottieTextEditor, False);
end;

procedure TfrmMain.acSearchAgainExecute(Sender: TObject);
begin
  gbSearchFromCaret := True;
  DoSearchReplaceText(False, gbSearchBackwards);
end;

procedure TfrmMain.acSearchAgainUpdate(Sender: TObject);
begin
  acSearchAgain.Enabled := gsSearchText <> '';
end;

procedure TfrmMain.InitSynEditPrint;
var
  AFont: TFont;
begin
  AFont := TFont.Create;
  Try
    with SynEditPrint.Header do begin
        {First line, default font, left aligned}
      Add(PAGE_HEADER_FIRST_LINE_LEFT, nil, taLeftJustify, 1);
        {First line, default font, right aligned}
      Add(PAGE_HEADER_FIRST_LINE_RIGHT, nil, taRightJustify, 1);
      AFont.Assign(DefaultFont);
      AFont.Size := 6;
    end;
    with SynEditPrint.Footer do begin
      AFont.Assign(DefaultFont);
      Add(PAGE_FOOTER_FIRST_LINE_LEFT, nil, taRightJustify, 1);
      AFont.Size := 6;
      Add(PAGE_FOOTER_FIRST_LINE_RIGHT, AFont, taLeftJustify, 1);
    end;
  Finally
    AFont.Free;
  End;
end;

procedure TfrmMain.actnPrinterSetupExecute(Sender: TObject);
begin
  PrinterSetupDialog.Execute;
end;

procedure TfrmMain.actnPrintPreviewExecute(Sender: TObject);
begin
  SetSynEditPrintProperties(SynEditPrint);
  with TestPrintPreviewDlg do
  begin
    SynEditPrintPreview.SynEditPrint := SynEditPrint;
    ShowModal;
  end;
end;

procedure TfrmMain.actnPrintExecute(Sender: TObject);
begin
  SetSynEditPrintProperties(SynEditPrint);
  if PrintDialog.Execute then
  begin
    SynEditPrint.Print;
  end;
end;

procedure TfrmMain.actnPageSetupExecute(Sender: TObject);
begin
  SetSynEditPrintProperties(PageSetupDlg.SynEditPrint);
  PageSetupDlg.SetValues(SynEditPrint);
  if PageSetupDlg.ShowModal = mrOk then
    PageSetupDlg.GetValues(SynEditPrint);
end;

procedure TfrmMain.SetEditorFontSize(const Value: Integer);
begin
  if (CurrentEditor <> nil) and (Value >= MinfontSize) and (Value <= MaxfontSize) then
  begin
    CurrentEditor.Font.Height := -Round(Value * Self.ScaleFactor);
    FEditorSettings.FontSize := Value;
  end;
  FFontSize := Value;
end;

procedure TfrmMain.SetSynEditPrintProperties(SynEditPrint : TSynEditPrint);
begin
  SynEditPrint.SynEdit := CurrentEditor;
  SynEditPrint.Title := CurrentEditFile.FFileName;
  SynEditPrint.Highlighter := dmResources.SynJSONSyn;
end;

procedure TfrmMain.actnEditOptionsExecute(Sender: TObject);
var
  LEditOptionsDialog: TSynEditOptionsDialog;
begin
  if CurrentEditor <> nil then
    FEditorOptions.Assign(CurrentEditor);
  LEditOptionsDialog := TSynEditOptionsDialog.Create(nil);
  try
    if LEditOptionsDialog.Execute(FEditorOptions) then
    begin
      UpdateEditorsOptions;
    end;
  finally
    LEditOptionsDialog.Free;
  end;
end;

procedure TfrmMain.UpdateEditorsOptions;
var
  i : integer;
  EditingFile : TEditingFile;
begin
  FEditorSettings.FontName := FEditorOptions.Font.Name;
  EditorFontSize := FEditorOptions.Font.Size;

  for i := 0 to EditFileList.Count -1 do
  begin
    EditingFile := TEditingFile(EditFileList.items[i]);
    FEditorOptions.AssignTo(EditingFile.SynEditor);
  end;
  Statusbar.Panels[STATUSBAR_PANEL_FONTNAME].Text := FEditorOptions.Font.Name;
  Statusbar.Panels[STATUSBAR_PANEL_FONTSIZE].Text := IntToStr(FEditorOptions.Font.Size);
end;

procedure TfrmMain.UpdateFromSettings(AEditor: TSynEdit);
var
  LStyle: TStyledButtonDrawType;
begin
  FEditorSettings.StyleName := UpdateApplicationStyle(FEditorSettings.StyleName);
  if AEditor <> nil then
  begin
    FEditorSettings.ReadSettings(AEditor.Highlighter, self.FEditorOptions);
    AEditor.ReadOnly := False;
  end
  else
    FEditorSettings.ReadSettings(nil, self.FEditorOptions);

  //Rounded Buttons for StyledButtons
  if FEditorSettings.ButtonDrawRounded then
    LStyle := btRounded
  else
    LStyle := btRoundRect;
  TStyledButton.RegisterDefaultRenderingStyle(LStyle);

  //Rounded Buttons for StyledToolbars
  if FEditorSettings.ToolbarDrawRounded then
    LStyle := btRounded
  else
    LStyle := btRoundRect;
  TStyledToolbar.RegisterDefaultRenderingStyle(LStyle);
  SettingsToolBar.StyleDrawType := LStyle;
  PaletteToolBar.StyleDrawType := LStyle;

  //Rounded Buttons for menus: StyledCategories and StyledButtonGroup
  if FEditorSettings.MenuDrawRounded then
    LStyle := btRounded
  else
    LStyle := btRoundRect;
  TStyledCategoryButtons.RegisterDefaultRenderingStyle(LStyle);
  TStyledButtonGroup.RegisterDefaultRenderingStyle(LStyle);
  catMenuItems.StyleDrawType := LStyle;
  MenuButtonToolbar.StyleDrawType := LStyle;

  if FEditorSettings.FontSize >= MinfontSize then
    EditorFontSize := FEditorSettings.FontSize
  else
    EditorFontSize := MinfontSize;
  InitEditorOptions;
  UpdateEditorsOptions;
  UpdateHighlighter(AEditor);
  BackgroundTrackBar.Position := FEditorSettings.LightBackground;
  LoopToggleSwitch.State := TToggleSwitchState(Ord(FEditorSettings.PlayInLoop));
  if FEditorSettings.AutoPlay and SkAnimatedImageEx.CanPlayAnimation then
    StartAnimations(False)
  else if not FEditorSettings.AutoPlay and SkAnimatedImageEx.CanStopAnimation then
    StopAnimations;
end;

//SynEdit is NOT VCL-style aware: TSynGutter.Create leaves Color at the raw
//clBtnFace system colour, BorderColor at clWindow and the gutter font at its
//default. Under a dark style the gutter therefore stayed light grey with dark
//numbers, while the text area looked right only because UpdateHighlighter
//stamps StyleServices.GetSystemColor(clWindow) onto every highlighter
//attribute. This does the same job for the gutter. No user preference is
//overridden: the settings never stored any of these colours.
procedure TfrmMain.ApplyStyleToGutter(AGutter: TSynGutter);
begin
  if AGutter = nil then
    Exit;
  AGutter.Color := StyleServices.GetSystemColor(clBtnFace);
  AGutter.BorderColor := StyleServices.GetSystemColor(clWindow);
  AGutter.Font.Color := StyleServices.GetSystemColor(clWindowText);
  AGutter.GradientStartColor := StyleServices.GetSystemColor(clWindow);
  AGutter.GradientEndColor := StyleServices.GetSystemColor(clBtnFace);
end;

procedure TfrmMain.UpdateHighlighter(ASynEditor: TSynEdit);
var
  LBackgroundColor: TColor;
begin
  if ASynEditor = nil then
    Exit;
  LBackgroundColor := StyleServices.GetSystemColor(clWindow);
  ASynEditor.Highlighter := dmResources.GetSynHighlighter(
    FEditorSettings.UseDarkStyle, LBackgroundColor);
  //Assign custom colors to the Highlighter
  FEditorSettings.ReadSettings(ASynEditor.Highlighter, self.FEditorOptions);
  //NB: the highlighter attributes cover the text area only, so the gutter
  //needs the active style applied to it explicitly. Done here as well as in
  //InitEditorOptions because UpdateHighlighters refreshes every open editor
  //without going through the options container.
  ApplyStyleToGutter(ASynEditor.Gutter);
  ASynEditor.Font.Color := StyleServices.GetSystemColor(clWindowText);
  //Occurrences of the color selected in the palette: re-registered here so
  //the frame follows the active style
  ASynEditor.Indicators.RegisterSpec(PALETTE_INDICATOR_ID,
    TSynIndicatorSpec.New(sisRoundedFilledRectangle,
    D2D1ColorF(StyleServices.GetSystemColor(clHighlight)),
    D2D1ColorF(StyleServices.GetSystemColor(clHighlight), 0.2), []));
end;

procedure TfrmMain.UpdateHighlighters;
var
  LEditingFile: TEditingFile;
  I: Integer;
begin
  for i := 0 to EditFileList.Count -1 do
  begin
    LEditingFile := EditFileList.Items[i] as TEditingFile;
    UpdateHighlighter(LEditingFile.SynEditor);
  end;
end;

procedure TfrmMain.actnEditingUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := CurrentEditFile <> nil;
end;

procedure TfrmMain.actnFontExecute(Sender: TObject);
begin
  if Sender = actnEnlargeFont then
    EditorFontSize := FEditorOptions.Font.Size+1
  else if Sender = actnReduceFont then
    EditorFontSize := FEditorOptions.Font.Size-1
  else
    Exit;
  FEditorOptions.Font.Size := EditorFontSize;
  UpdateEditorsOptions;
end;

procedure TfrmMain.InitEditorOptions;
begin
  with FEditorOptions do
  begin
    Font.Name := FEditorSettings.FontName;
    Font.Size := EditorFontSize;
    TabWidth := 2;
    WantTabs := False;
    Options := Options - [eoSmartTabs];
    Gutter.Font.Name := Font.Name;
    Gutter.Font.Size := Font.Size;
    //Colours taken from the active VCL style. These reach every open editor
    //through FEditorOptions.AssignTo, which does Gutter.Assign and copies
    //Font and Color as well.
    Font.Color := StyleServices.GetSystemColor(clWindowText);
    Color := StyleServices.GetSystemColor(clWindow);
    ApplyStyleToGutter(Gutter);
  end;
end;

procedure TfrmMain.InitDialog(const ADialog: TCustomFileDialog;
  const ADefaultFolder: string);
var
  LExtensions: TArray<string>;
begin
  ADialog.DefaultFolder := ADefaultFolder;
  LExtensions := GetSupportedExtensions(True);
  for var I := Low(LExtensions) to High(LExtensions) do
  begin
    // Add File Filters
    with ADialog.FileTypes.Add do
    begin
      DisplayName := FILES_TYPE;
      FileMask := '*'+LExtensions[I];
    end;
  end;
end;

procedure TfrmMain.actnSaveAsExecute(Sender: TObject);
begin
  SaveDialog.FileName := CurrentEditFile.FileName;
  if SaveDialog.Execute then
  begin
    if CurrentEditFile.FileName <> SaveDialog.FileName then
    begin
      CurrentEditFile.FileName := SaveDialog.FileName;
    end;
    CurrentEditFile.SaveToFile;

    //call the "onchange" event of PageControl
    PageControl.OnChange(PageControl);
  end;
end;

procedure TfrmMain.RecentPopupMenuPopup(Sender: TObject);
var
  I: Integer;
  LMenuItem: TMenuItem;
  LFileName: string;
begin
  RecentPopupMenu.Items.Clear;
  for I := 0 to FEditorSettings.HistoryFileList.Count -1 do
  begin
    LFileName := FEditorSettings.HistoryFileList.Strings[I];
    if FileExists(LFileName) then
    begin
      LMenuItem := TMenuItem.Create(nil);
      if Length(LFileName) > 100 then
        LMenuItem.Caption := Copy(LFileName,1,20)+'...'+RightStr(LFileName, 80)
      else
        LMenuItem.Caption := LFileName;
      LMenuItem.Hint := LFileName;
      LMenuItem.OnClick := HistoryListClick;
      RecentPopupMenu.Items.Add(LMenuItem);
    end;
  end;
end;

function TfrmMain.CurrentEditorState: string;
begin
  if CurrentEditor = nil then
    Result := ''
  else if CurrentEditor.ReadOnly then
    Result := STATE_READONLY
  else if CurrentEditor.InsertMode then
    Result := STATE_INSERT
  else
    Result := STATE_OVERWRITE;
end;

procedure TfrmMain.UpdateStatusBarPanels;
var
  ptCaret: TBufferCoord;
begin
  if CurrentEditor <> nil then
  begin
    ptCaret := CurrentEditor.CaretXY;
    StatusBar.Panels[STATUSBAR_PANEL_CARET].Text := Format(' %6d:%3d ', [ptCaret.Line, ptCaret.Char]);
    if CurrentEditor.Modified then
      StatusBar.Panels[STATUSBAR_PANEL_MODIFIED].Text := SMODIFIED
    else
      StatusBar.Panels[STATUSBAR_PANEL_MODIFIED].Text := SUNMODIFIED;
    StatusBar.Panels[STATUSBAR_PANEL_STATE].Text := CurrentEditorState;
  end
  else
  begin
    StatusBar.Panels[STATUSBAR_PANEL_CARET].Text := '';
    StatusBar.Panels[STATUSBAR_PANEL_MODIFIED].Text := '';
    StatusBar.Panels[STATUSBAR_PANEL_STATE].Text := '';
    StatusBar.Panels[STATUSBAR_MESSAGE].Text := '';
  end;
end;

procedure TfrmMain.WMGetMinMaxInfo(var Message: TWMGetMinMaxInfo);
var
  LMinMaxInfo: PMinMaxInfo;
begin
  if not (csReading in ComponentState) then
  begin
    LMinMaxInfo := Message.MinMaxInfo;
    with LMinMaxInfo^ do
    begin
      with ptMinTrackSize do
      begin
        if MinFormWidth > 0 then X := MinFormWidth;
        if MinFormHeight > 0 then Y := MinFormHeight;
      end;
      with ptMaxTrackSize do
      begin
        if MaxFormWidth > 0 then X := MaxFormWidth;
        if MaxFormHeight > 0 then Y := MaxFormHeight;
      end;
      ConstrainedResize(ptMinTrackSize.X, ptMinTrackSize.Y, ptMaxTrackSize.X,
        ptMaxTrackSize.Y);
    end;
  end;
  inherited;
end;

procedure TfrmMain.ActionListExecute(Action: TBasicAction;
  var Handled: Boolean);
begin
  if (Action <> actMenu) and (Action <> OpenRecentAction) then
    CloseSplitViewMenu;
  Handled := False;
end;

procedure TfrmMain.UpdatePlayerControls;
begin
  PlayAction.Enabled := SkAnimatedImageEx.CanPlayAnimation or
    SkAnimatedImageEx.AnimationRunningInverse;
  PlayInverseAction.Enabled := SkAnimatedImageEx.CanPlayAnimation or
    SkAnimatedImageEx.AnimationRunningNormal;
  PauseAction.Enabled := SkAnimatedImageEx.CanPauseAnimation;
  StopAction.Enabled := SkAnimatedImageEx.CanStopAnimation;
  LoopToggleSwitch.Enabled := SkAnimatedImageEx.AnimationLoaded;
  LoopToggleSwitch.State := TToggleSwitchState(Ord(SkAnimatedImageEx.Loop));
  TrackBar.Enabled := SkAnimatedImageEx.AnimationLoaded;
end;

procedure TfrmMain.ActionListUpdate(Action: TBasicAction;
  var Handled: Boolean);
var
  InitialDir: string;
  LFileName: TFileName;
begin
  UpdateStatusBarPanels;
  UpdatePlayerControls;
  if not FirstAction then
  begin
    FirstAction := True;

    //Restore previously-opened files only if the user opted in (Settings:
    //"Remember current session at next run").
    if FEditorSettings.RestoreLastSession then
      LoadOpenedFiles;

    //Initialize Open and Save Dialog with application path
    LFileName := ParamStr(1);
    if LFileName <> '' then
    begin
      //Load file passed at command line
      InitialDir := ExtractFilePath(LFileName);
      OpenFile(LFileName);
      AssignLottieTextToImage;
    end
    else
      InitialDir := '.';

    InitDialog(OpenDialog, InitialDir);
    InitDialog(SaveDialog, InitialDir);

    ImagePanel.Visible := True;
    UpdateRightSplitterPos;

    //Check for new version available.
    //NB: the HTTP call runs in background. Performing it here, inside an
    //action-update handler, froze the UI at startup whenever the network was
    //slow or unreachable.
    if FEditorSettings.IsTimeToCheckNewVersion then
      CheckNewSetupAsync(
        procedure(ACurrentVersion, ANewVersion: string)
        begin
          if StyledMessageDlg(Format(NewVersionAvailable,
            [ACurrentVersion, ANewVersion]),
            TMsgDlgType.mtWarning,
            [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo, TMsgDlgBtn.mbCancel], 0) = mrYes then
            ShowAboutForm(DialogPosRect, Title_LottieTextEditor, True);
        end);
  end;
end;

procedure TfrmMain.actMenuExecute(Sender: TObject);
begin
  if SV.Opened then
    CloseSplitViewMenu
  else
    SV.Open;
end;

procedure TfrmMain.actnColorSettingsExecute(Sender: TObject);
begin
  if CurrentEditor <> nil then
  begin
    if ShowSettings(DialogPosRect,
      Title_LottieTextEditor,
      CurrentEditor, FEditorSettings, True) then
    begin
      FEditorSettings.WriteSettings(CurrentEditor.Highlighter, FEditorOptions);
      UpdateFromSettings(CurrentEditor);
      UpdateHighlighters;
      UpdatePaletteVisibility;
    end;
  end;
end;

procedure TfrmMain.actnColorSettingsUpdate(Sender: TObject);
begin
  actnColorSettings.Enabled := (CurrentEditor <> nil) and (CurrentEditor.Highlighter <> nil);
end;

procedure TfrmMain.actnFormatJSONExecute(Sender: TObject);
var
  OldText, NewText : string;
begin
  //format JSON text
  OldText := CurrentEditor.Text;
  NewText := ReformatJSON(OldText);
  if OldText <> NewText then
  begin
    CurrentEditor.Lines.Text := NewText;
    CurrentEditor.Modified := True;
    SynEditChange(CurrentEditor);
  end;
end;

procedure TfrmMain.actionForFileUpdate(Sender: TObject);
begin
  (Sender As TAction).Enabled := (CurrentEditor <> nil)
    and not CurrentEditor.ReadOnly;
end;

procedure TfrmMain.AddOpenedFile(const AFileName: string);
var
  i : integer;
begin
  //Add the opened file to the opened-file list
  i := FEditorSettings.HistoryFileList.IndexOf(AFileName);
  if i >= 0 then
    FEditorSettings.HistoryFileList.Delete(i);
  //max 15 items
  if FEditorSettings.HistoryFileList.Count > 15 then
    FEditorSettings.HistoryFileList.Delete(14);
  //add the last opened-file at first position
  FEditorSettings.HistoryFileList.Insert(0, AFileName);
end;

procedure TfrmMain.AdjustViewerWidth(const ACenter: Boolean = False);
begin
  if CurrentEditFile <> nil then
  begin
    if ACenter then
    begin
      ImagePanel.Width :=
        (Self.Width - catMenuItems.Width) div 2;
    end
    else
    begin
      var LViewerWidth := ImagePanel.Width;
      var LMinWidth := Self.Width div 6;
      var LMaxWidth := Self.Width - LMinWidth;
      if LViewerWidth < LMinWidth then
        ImagePanel.Width := LMinWidth
      else if LViewerWidth > LMaxWidth then
        ImagePanel.Width := LMaxWidth;
    end;
    UpdateRightSplitterPos;
  end;
end;

procedure TfrmMain.UpdateRightSplitterPos;
begin
  if ImagePanel.Visible then
    RightSplitter.Left := ImagePanel.Left - RightSplitter.Width;
  RightSplitter.Visible := ImagePanel.Visible;
end;

procedure TfrmMain.AdjustCompactWidth;
begin
  //Change size of compact view because Scrollbars appears
  if (Height / ScaleFactor) > 900 then
    SV.CompactWidth := Round(SV_COLLAPSED_WIDTH * ScaleFactor)
  else
    SV.CompactWidth := Round(SV_COLLAPSED_WIDTH_WITH_SCROLLBARS * ScaleFactor);
  if (ImagePanel.Width > PageControl.Width) then
    ImagePanel.Width := width div 3;
end;

procedure TfrmMain.FormAfterMonitorDpiChanged(Sender: TObject; OldDPI,
  NewDPI: Integer);
begin
  LockWindowUpdate(0);
end;

procedure TfrmMain.FormBeforeMonitorDpiChanged(Sender: TObject; OldDPI,
  NewDPI: Integer);
begin
  LockWindowUpdate(Handle);
end;

procedure TfrmMain.catMenuItemsGetHint(Sender: TObject;
  const Button: TButtonItem; const Category: TButtonCategory;
  var HintStr: string; var Handled: Boolean);
var
  LActionDisabled: Boolean;
begin
  inherited;
  if not Assigned(Button) then
    Exit;
  if Button.Action is TAction then
    LActionDisabled := not TAction(Button.Action).Enabled
  else if Button.Action is TFileAction then
    LActionDisabled := not TFileAction(Button.Action).Enabled
  else
    LActionDisabled := False;
  if LActionDisabled then
  begin
    HintStr := '';
    Handled := True;
  end;
end;

procedure TfrmMain.catMenuItemsMouseLeave(Sender: TObject);
begin
  inherited;
  Screen.cursor := crDefault;
end;

procedure TfrmMain.catMenuItemsMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  LButton: TButtonItem;
begin
  inherited;

  LButton := catMenuItems.GetButtonAt(X,Y)  ;
  if Assigned(LButton) and Assigned(LButton.Action) then
  begin
    if (LButton.Action is TAction) then
    begin
      TAction(LButton.Action).Update;
      if TAction(LButton.Action).Enabled then
        Screen.Cursor := crHandPoint
      else
        Screen.Cursor := crNo;
    end
    else if LButton.Action is TFileAction then
    begin
      TFileAction(LButton.Action).Update;
      if TFileAction(LButton.Action).Enabled then
        Screen.Cursor := crHandPoint
      else
        Screen.Cursor := crNo;
    end;
  end
  else
    Screen.Cursor := crDefault;
end;

procedure TfrmMain.HistoryListClick(Sender: TObject);
var
  LFileName : string;
begin
  LFilename := (Sender as TMenuItem).Hint;
  //Load the selected file
  OpenFile(LFileName);
  AssignLottieTextToImage;
  if (CurrentEditor <> nil) and (CurrentEditor.CanFocus) then
    (CurrentEditor.SetFocus);
  CloseSplitViewMenu;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  BackgroundTrackBarChange(nil);
end;

procedure TfrmMain.ManageExceptions(Sender: TObject; E: Exception);
begin
  //This is an event-handler for exceptions that replace Delphi standard handler
  if E is EAccessViolation then
  begin
    if StyledTaskMessageDlg(STR_UNEXPECTED_ERROR,
      Format('Unexpected Error: %s%s',[sLineBreak,E.Message]),
      TMsgDlgType.mtError,
      [TMsgDlgBtn.mbOK, TMsgDlgBtn.mbAbort], 0) = mrAbort then
    Application.Terminate;
  end
  else
  begin

    StyledTaskMessageDlg(STR_ERROR,
      Format('Error: %s%s',[sLineBreak,E.Message]),
      TMsgDlgType.mtError,
      //NB: mbHelp removed. The .dpr sets Application.HelpFile to '', so the
      //Help button was shown and did nothing at all.
      [TMsgDlgBtn.mbOK], 0);
  end;
end;

procedure TfrmMain.CreatePaletteBar;
begin
  FPaletteBar := TColorPaletteBar.Create(Self);
  FPaletteBar.Parent := PalettePanel;
  FPaletteBar.Align := alClient;
  FPaletteBar.DocumentCaption := PALETTE_DOCUMENT;
  FPaletteBar.CustomCaption := PALETTE_CUSTOM;
  FPaletteBar.EmptyText := PALETTE_EMPTY;
  FPaletteBar.AddHint := PALETTE_ADD_HINT;
  FPaletteBar.OnSwatchClick := PaletteSwatchClick;
  FPaletteBar.OnSwatchDblClick := PaletteSwatchDblClick;
  FPaletteBar.OnAddClick := PaletteAddClick;
  FPaletteBar.OnContextPopup := PaletteBarContextPopup;
  FPaletteBar.PopupMenu := PalettePopupMenu;
  FPaletteMatchEntry := -1;
  FPaletteMatchPos := -1;
  FCaretOccurrence := -1;
  FClickCaretOccurrence := -1;
  PaletteTitleLabel.Font.Style := PaletteTitleLabel.Font.Style + [fsBold];
  PaletteTitleLabel.Caption := Format(PALETTE_TITLE, [0]);
  PalettePanel.Height := MulDiv(FEditorSettings.ColorPaletteHeight,
    CurrentPPI, Screen.DefaultPixelsPerInch);
  LoadCustomColors;
  UpdatePaletteVisibility;
end;

procedure TfrmMain.UpdatePaletteVisibility;
begin
  PalettePanel.Visible := FEditorSettings.ShowColorPalette;
  PaletteSplitter.Visible := PalettePanel.Visible;
  if PalettePanel.Visible then
  begin
    //A bottom-aligned splitter must stay above its panel
    PaletteSplitter.Top := PalettePanel.Top - PaletteSplitter.Height;
    UpdateColorPalette(True);
  end
  else
  begin
    //Nothing must stay highlighted by a hidden palette
    ClearPaletteHighlight;
    FPaletteEditor := nil;
  end;
end;

function TfrmMain.ColorDescription(const AColor: TAlphaColor): string;
var
  R, G, B: Integer;
begin
  //Hex, bytes and the Lottie notation (components from 0 to 1)
  R := (AColor shr 16) and $FF;
  G := (AColor shr 8) and $FF;
  B := AColor and $FF;
  Result := Format('%s  rgb(%d, %d, %d)  [%s, %s, %s]',
    [TLottieColorScanner.ColorToHex(OpaqueColor(AColor)), R, G, B,
     FormatFloat('0.###', R / 255, TFormatSettings.Invariant),
     FormatFloat('0.###', G / 255, TFormatSettings.Invariant),
     FormatFloat('0.###', B / 255, TFormatSettings.Invariant)]);
end;

function TfrmMain.PaletteEntryHint(const AEntry: TLottiePaletteEntry): string;
var
  LAlphas: string;
  I: Integer;
begin
  Result := ColorDescription(AEntry.Color) + sLineBreak +
    Format(PALETTE_HINT_OCCURRENCES, [AEntry.Count]) + sLineBreak +
    Format(PALETTE_HINT_PROPERTIES, [string.Join(', ', AEntry.PropertyNames)]);
  //Occurrences of the same RGB with a different alpha share the swatch
  if (Length(AEntry.Alphas) > 1) or
    ((Length(AEntry.Alphas) = 1) and (AEntry.Alphas[0] <> 255)) then
  begin
    LAlphas := '';
    for I := 0 to High(AEntry.Alphas) do
    begin
      if LAlphas <> '' then
        LAlphas := LAlphas + ', ';
      LAlphas := LAlphas + IntToStr(Round(AEntry.Alphas[I] * 100 / 255)) + '%';
    end;
    Result := Result + sLineBreak + Format(PALETTE_HINT_ALPHA, [LAlphas]);
  end;
end;

function TfrmMain.SwatchColor(const ASection: TColorPaletteSection;
  const AIndex: Integer): TAlphaColor;
begin
  Result := FPaletteBar.Items(ASection)[AIndex].Color;
end;

function TfrmMain.GetSelectedPaletteColor(out AColor: TAlphaColor): Boolean;
var
  LSelected: TColorPaletteHit;
begin
  LSelected := FPaletteBar.Selected;
  Result := LSelected.IsSwatch and
    (LSelected.Index <= High(FPaletteBar.Items(LSelected.Section)));
  if Result then
    AColor := SwatchColor(LSelected.Section, LSelected.Index)
  else
    AColor := 0;
end;

procedure TfrmMain.UpdateColorPalette(const AForce: Boolean = False);
var
  LEditor: TSynEdit;
  LText: string;
  LItems: TColorPaletteItems;
  LSelected: TColorPaletteHit;
  LSelectedColor: TAlphaColor;
  LHadDocumentSelection: Boolean;
  I: Integer;
begin
  if not Assigned(FPaletteBar) or not PalettePanel.Visible then
    Exit;
  LEditor := CurrentEditor;
  if LEditor <> nil then
    LText := LEditor.Lines.Text
  else
    LText := '';
  if not AForce and (LEditor = FPaletteEditor) and (LText = FPaletteText) then
  begin
    //The typing ended with the text already scanned (e.g. undo): the
    //positions are reliable again
    if FPaletteStale then
    begin
      FPaletteStale := False;
      UpdatePaletteCaret;
    end;
    Exit;
  end;
  //Keep the selected document color selected, if it is still in the document
  LSelected := FPaletteBar.Selected;
  LHadDocumentSelection := (LEditor = FPaletteEditor) and LSelected.IsSwatch and
    (LSelected.Section = psDocument) and (LSelected.Index <= High(FColorPalette));
  if LHadDocumentSelection then
    LSelectedColor := FColorPalette[LSelected.Index].Color
  else
    LSelectedColor := 0;
  FPaletteEditor := LEditor;
  FPaletteText := LText;
  FPaletteStale := False;
  try
    FColorOccurrences := TLottieColorScanner.Scan(LText);
  except
    //A wrong document must never stop the editing: just show no colors
    FColorOccurrences := nil;
  end;
  FColorPalette := TLottieColorScanner.BuildPalette(FColorOccurrences);
  SetLength(LItems, Length(FColorPalette));
  for I := 0 to High(FColorPalette) do
  begin
    LItems[I].Color := FColorPalette[I].Color;
    LItems[I].Count := FColorPalette[I].Count;
    LItems[I].Hint := PaletteEntryHint(FColorPalette[I]);
  end;
  if LSelected.Section = psDocument then
    FPaletteBar.Select(psDocument, -1);
  FPaletteBar.SetItems(psDocument, LItems);
  if LHadDocumentSelection then
    FPaletteBar.Select(psDocument,
      TLottieColorScanner.IndexOfColor(FColorPalette, LSelectedColor));
  PaletteTitleLabel.Caption := Format(PALETTE_TITLE, [Length(FColorPalette)]);
  //The positions have changed: highlight again the occurrences of the
  //selected color (document or custom), or remove the highlight if the color
  //is not in the document
  if GetSelectedPaletteColor(LSelectedColor) then
    HighlightPaletteEntry(TLottieColorScanner.IndexOfColor(FColorPalette, LSelectedColor))
  else
    ClearPaletteHighlight;
  UpdatePaletteCaret;
end;

procedure TfrmMain.SynEditStatusChange(Sender: TObject;
  Changes: TSynStatusChanges);
begin
  if (Sender = CurrentEditor) and
    (Changes * [scAll, scCaretX, scCaretY] <> []) then
    UpdatePaletteCaret;
end;

procedure TfrmMain.UpdatePaletteCaret;
var
  LEditor: TSynEdit;
  LEntry, LPos: Integer;
begin
  if not Assigned(FPaletteBar) or not PalettePanel.Visible then
    Exit;
  LEditor := CurrentEditor;
  FCaretOccurrence := -1;
  LEntry := -1;
  //While typing the positions are stale: the marker is refreshed by the
  //rescan, which calls this method again
  if (LEditor <> nil) and (LEditor = FPaletteEditor) and not FPaletteStale then
  begin
    FCaretOccurrence := TLottieColorScanner.OccurrenceAt(FColorOccurrences,
      LEditor.CaretY, LEditor.CaretX);
    if FCaretOccurrence >= 0 then
      LEntry := TLottieColorScanner.IndexOfColor(FColorPalette,
        FColorOccurrences[FCaretOccurrence].Color);
  end;
  FPaletteBar.CaretIndex := LEntry;
  if LEntry >= 0 then
  begin
    FPaletteBar.ScrollIntoView(psDocument, LEntry);
    //Caret on an occurrence of the highlighted color: navigation goes on
    //from there
    if LEntry = FPaletteMatchEntry then
    begin
      LPos := TArray.IndexOf<Integer>(FColorPalette[LEntry].Occurrences,
        FCaretOccurrence);
      if (LPos >= 0) and (LPos <> FPaletteMatchPos) then
      begin
        FPaletteMatchPos := LPos;
        UpdatePaletteInfo;
      end;
    end;
  end;
end;

procedure TfrmMain.ClearPaletteHighlight;
begin
  if Assigned(FHighlightedEditor) then
    FHighlightedEditor.Indicators.Clear(PALETTE_INDICATOR_ID);
  FHighlightedEditor := nil;
  FPaletteMatchEntry := -1;
  FPaletteMatchPos := -1;
  UpdatePaletteInfo;
end;

function TfrmMain.OccurrenceStart(const AOccurrence: TLottieColorOccurrence): TBufferCoord;
begin
  Result := BufferCoord(AOccurrence.CharStart, AOccurrence.Line);
end;

function TfrmMain.OccurrenceEnd(const AOccurrence: TLottieColorOccurrence): TBufferCoord;
begin
  Result := BufferCoord(AOccurrence.CharEnd, AOccurrence.EndLine);
end;

procedure TfrmMain.HighlightPaletteEntry(const AEntry: Integer);
var
  LEditor: TSynEdit;
  LOccurrence: TLottieColorOccurrence;
  LCount, LLine, LFirstChar, LLastChar: Integer;
  I: Integer;
begin
  LEditor := CurrentEditor;
  if (LEditor = nil) or (AEntry < 0) or (AEntry > High(FColorPalette)) then
  begin
    ClearPaletteHighlight;
    Exit;
  end;
  if Assigned(FHighlightedEditor) then
    FHighlightedEditor.Indicators.Clear(PALETTE_INDICATOR_ID);
  for I in FColorPalette[AEntry].Occurrences do
  begin
    LOccurrence := FColorOccurrences[I];
    //A formatted array spans more lines: one indicator for each line
    for LLine := LOccurrence.Line to Min(LOccurrence.EndLine, LEditor.Lines.Count) do
    begin
      if LLine = LOccurrence.Line then
        LFirstChar := LOccurrence.CharStart
      else
        LFirstChar := 1;
      if LLine = LOccurrence.EndLine then
        LLastChar := LOccurrence.CharEnd
      else
        LLastChar := Length(LEditor.Lines[LLine - 1]) + 1;
      if LLastChar > LFirstChar then
        LEditor.Indicators.Add(LLine, TSynIndicator.New(
          PALETTE_INDICATOR_ID, LFirstChar, LLastChar));
    end;
  end;
  FHighlightedEditor := LEditor;
  //Same color after a rescan: keep the position, within the new count. The
  //color is compared, not the index, which a rescan may change
  LCount := FColorPalette[AEntry].Count;
  if (FPaletteMatchEntry < 0) or (FColorPalette[AEntry].Color <> FPaletteMatchColor) then
    FPaletteMatchPos := -1
  else if FPaletteMatchPos >= LCount then
    FPaletteMatchPos := LCount - 1;
  FPaletteMatchEntry := AEntry;
  FPaletteMatchColor := FColorPalette[AEntry].Color;
  UpdatePaletteInfo;
end;

procedure TfrmMain.GotoPaletteOccurrence(const APos: Integer);
var
  LEditor: TSynEdit;
  LOccurrence: TLottieColorOccurrence;
  LStart, LEnd: TBufferCoord;
begin
  LEditor := CurrentEditor;
  if (LEditor = nil) or (FPaletteMatchEntry < 0) or
    (APos < 0) or (APos >= FColorPalette[FPaletteMatchEntry].Count) then
    Exit;
  FPaletteMatchPos := APos;
  LOccurrence := FColorOccurrences[FColorPalette[FPaletteMatchEntry].Occurrences[APos]];
  LStart := OccurrenceStart(LOccurrence);
  LEnd := OccurrenceEnd(LOccurrence);
  //Select the value, so the current occurrence stands out from the others
  LEditor.SetCaretAndSelection(LEnd, LStart, LEnd, True, True);
  UpdatePaletteInfo;
end;

procedure TfrmMain.UpdatePaletteInfo;
var
  LHex: string;
  LColor: TAlphaColor;
begin
  if (FPaletteMatchEntry >= 0) and (FPaletteMatchEntry <= High(FColorPalette)) then
  begin
    LHex := TLottieColorScanner.ColorToHex(FColorPalette[FPaletteMatchEntry].Color);
    if FPaletteMatchPos < 0 then
      PaletteInfoLabel.Caption := Format(PALETTE_INFO_COUNT,
        [LHex, FColorPalette[FPaletteMatchEntry].Count])
    else
      PaletteInfoLabel.Caption := Format(PALETTE_INFO_POSITION,
        [LHex, FPaletteMatchPos + 1, FColorPalette[FPaletteMatchEntry].Count]);
  end
  else if Assigned(FPaletteBar) and GetSelectedPaletteColor(LColor) then
    //A custom color not used in the document
    PaletteInfoLabel.Caption := Format(PALETTE_INFO_UNUSED,
      [TLottieColorScanner.ColorToHex(OpaqueColor(LColor))])
  else
    PaletteInfoLabel.Caption := '';
end;

procedure TfrmMain.FocusCurrentEditor;
begin
  if (CurrentEditor <> nil) and CurrentEditor.CanFocus then
    CurrentEditor.SetFocus;
end;

procedure TfrmMain.SavePaletteClickTarget;
begin
  //The first click of a double click moves the caret to the clicked color:
  //the double click must act where the caret was before it
  FClickEditor := CurrentEditor;
  FClickCaretOccurrence := -1;
  if FClickEditor = nil then
    Exit;
  FClickCaretOccurrence := FCaretOccurrence;
end;

procedure TfrmMain.PaletteSwatchClick(Sender: TObject;
  ASection: TColorPaletteSection; AIndex: Integer);
var
  LEntry: Integer;
begin
  //Bring positions up to date with the text typed since the last scan
  UpdateColorPalette;
  SavePaletteClickTarget;
  LEntry := TLottieColorScanner.IndexOfColor(FColorPalette, SwatchColor(ASection, AIndex));
  if LEntry < 0 then
    //A custom color not used in the document: nothing to highlight
    ClearPaletteHighlight
  else if LEntry = FPaletteMatchEntry then
    //Clicking again the same color moves to its next occurrence
    acPaletteNext.Execute
  else
  begin
    HighlightPaletteEntry(LEntry);
    GotoPaletteOccurrence(0);
  end;
  FocusCurrentEditor;
end;

procedure TfrmMain.PaletteSwatchDblClick(Sender: TObject;
  ASection: TColorPaletteSection; AIndex: Integer);
var
  LEditor: TSynEdit;
  LColor: TAlphaColor;
begin
  LEditor := CurrentEditor;
  if (LEditor = nil) or (LEditor <> FClickEditor) or LEditor.ReadOnly then
    Exit;
  LColor := SwatchColor(ASection, AIndex);
  if (FClickCaretOccurrence >= 0) and (FClickCaretOccurrence <= High(FColorOccurrences)) then
    //The caret was on a color: replace it
    ReplaceColorOccurrences([FClickCaretOccurrence], LColor)
  else
    //NB: unlike SVG nothing is inserted: in JSON a color written alone, out
    //of its property, has no meaning
    StatusBar.Panels[STATUSBAR_MESSAGE].Text := PALETTE_NO_COLOR_AT_CARET;
  FClickCaretOccurrence := -1;
  FocusCurrentEditor;
end;

function TfrmMain.ReplaceColorOccurrences(const AOccurrences: TArray<Integer>;
  const AColor: TAlphaColor): Integer;
var
  LEditor: TSynEdit;
  LIndexes: TArray<Integer>;
  LOccurrence: TLottieColorOccurrence;
  LNewColor: TAlphaColor;
  LNewText: string;
  LStart, LEnd, LLastStart, LLastEnd: TBufferCoord;
  I: Integer;
begin
  Result := 0;
  LEditor := CurrentEditor;
  if (LEditor = nil) or LEditor.ReadOnly or (Length(AOccurrences) = 0) then
    Exit;
  LIndexes := Copy(AOccurrences);
  TArray.Sort<Integer>(LIndexes);
  LEditor.BeginUndoBlock;
  try
    //From the last to the first, so the positions still to replace are not
    //moved by the replacements already done
    for I := High(LIndexes) downto 0 do
    begin
      LOccurrence := FColorOccurrences[LIndexes[I]];
      if LOccurrence.EndLine > LEditor.Lines.Count then
        Continue;
      //New RGB, with the alpha of the value being replaced
      LNewColor := (AColor and $00FFFFFF) or
        (TAlphaColor(AlphaOf(LOccurrence.Color)) shl 24);
      LNewText := TLottieColorScanner.FormatColorLike(LNewColor, LOccurrence);
      if LNewText = LOccurrence.RawText then
        Continue;
      LStart := OccurrenceStart(LOccurrence);
      LEnd := OccurrenceEnd(LOccurrence);
      LEditor.SetCaretAndSelection(LEnd, LStart, LEnd, False);
      //Never write over text that is not the scanned value any more
      if LEditor.SelText <> LOccurrence.RawText then
        Continue;
      LEditor.SelText := LNewText;
      LLastStart := LStart;
      //The caret is left after the inserted text
      LLastEnd := LEditor.CaretXY;
      Inc(Result);
    end;
  finally
    LEditor.EndUndoBlock;
  end;
  if Result > 0 then
  begin
    //Leave the first replaced value selected
    LEditor.SetCaretAndSelection(LLastEnd, LLastStart, LLastEnd, True);
    UpdateColorPalette;
    StatusBar.Panels[STATUSBAR_MESSAGE].Text := Format(PALETTE_REPLACED, [Result]);
  end
  else
    LEditor.SetCaretAndSelection(LEditor.CaretXY, LEditor.CaretXY,
      LEditor.CaretXY, False);
end;

function TfrmMain.ExecutePaletteColorDialog(var AColor: TAlphaColor): Boolean;
var
  LCount, I: Integer;
  LValue: string;
  LDialogColor: Integer;
begin
  PaletteColorDialog.Color := AlphaColorToColor(AColor);
  //The custom colors of the dialog show the first custom colors of the palette
  LCount := Min(Length(FCustomColors), 16);
  PaletteColorDialog.CustomColors.Clear;
  for I := 0 to LCount - 1 do
    PaletteColorDialog.CustomColors.Add(Format('Color%s=%.6x',
      [Chr(Ord('A') + I), Integer(AlphaColorToColor(FCustomColors[I]))]));
  Result := PaletteColorDialog.Execute(Handle);
  if not Result then
    Exit;
  AColor := ColorToAlphaColor(PaletteColorDialog.Color);
  //Colors added to the custom colors of the dialog become custom colors of
  //the palette too
  for I := 0 to 15 do
  begin
    LValue := PaletteColorDialog.CustomColors.Values['Color' + Chr(Ord('A') + I)];
    if (LValue = '') or not TryStrToInt('$' + LValue, LDialogColor) then
      Continue;
    if (I < LCount) and (TColor(LDialogColor) = AlphaColorToColor(FCustomColors[I])) then
      Continue; //slot unchanged
    if (I >= LCount) and (LDialogColor = $FFFFFF) then
      Continue; //empty slot
    AddCustomColor(ColorToAlphaColor(TColor(LDialogColor)));
  end;
end;

function TfrmMain.IndexOfCustomColor(const AColor: TAlphaColor): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FCustomColors) do
    if FCustomColors[I] = OpaqueColor(AColor) then
      Exit(I);
  Result := -1;
end;

procedure TfrmMain.LoadCustomColors;
var
  LValue: string;
  LColor: TAlphaColor;
begin
  FCustomColors := nil;
  for LValue in FEditorSettings.CustomColors.Split([',']) do
    if TLottieColorScanner.TryParseHexColor(LValue, LColor) and
      (IndexOfCustomColor(LColor) < 0) then
      FCustomColors := FCustomColors + [OpaqueColor(LColor)];
  UpdateCustomColorItems;
end;

procedure TfrmMain.SaveCustomColors;
var
  LValues: TArray<string>;
  I: Integer;
begin
  SetLength(LValues, Length(FCustomColors));
  for I := 0 to High(FCustomColors) do
    LValues[I] := TLottieColorScanner.ColorToHex(FCustomColors[I]);
  FEditorSettings.WriteCustomColors(string.Join(',', LValues));
  UpdateCustomColorItems;
end;

procedure TfrmMain.AddCustomColor(const AColor: TAlphaColor);
begin
  if IndexOfCustomColor(AColor) >= 0 then
    Exit;
  FCustomColors := FCustomColors + [OpaqueColor(AColor)];
  SaveCustomColors;
end;

procedure TfrmMain.UpdateCustomColorItems;
var
  LItems: TColorPaletteItems;
  I: Integer;
begin
  SetLength(LItems, Length(FCustomColors));
  for I := 0 to High(FCustomColors) do
  begin
    LItems[I].Color := FCustomColors[I];
    LItems[I].Count := 0;
    LItems[I].Hint := ColorDescription(FCustomColors[I]) + sLineBreak + PALETTE_HINT_CUSTOM;
  end;
  FPaletteBar.SetItems(psCustom, LItems);
end;

procedure TfrmMain.PaletteAddClick(Sender: TObject);
var
  LColor: TAlphaColor;
begin
  //Start from the selected color or from the one under the caret
  if not GetSelectedPaletteColor(LColor) then
  begin
    if FCaretOccurrence >= 0 then
      LColor := FColorOccurrences[FCaretOccurrence].Color
    else
      LColor := TAlphaColors.Black;
  end;
  if ExecutePaletteColorDialog(LColor) then
    AddCustomColor(LColor);
end;

procedure TfrmMain.PaletteBarContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var
  LColor: TAlphaColor;
  LUsed: Boolean;
begin
  //Bring positions up to date with the text typed since the last scan
  UpdateColorPalette;
  if (MousePos.X = -1) and (MousePos.Y = -1) then
    FPopupHit := FPaletteBar.Selected //from the keyboard
  else
    FPopupHit := FPaletteBar.HitTest(MousePos.X, MousePos.Y);
  if not FPopupHit.IsSwatch then
  begin
    Handled := True;
    Exit;
  end;
  LColor := SwatchColor(FPopupHit.Section, FPopupHit.Index);
  LUsed := TLottieColorScanner.IndexOfColor(FColorPalette, LColor) >= 0;
  ReplaceAllColorMenuItem.Enabled := LUsed and (CurrentEditor <> nil) and
    not CurrentEditor.ReadOnly;
  SelectAllColorMenuItem.Enabled := LUsed and (CurrentEditor <> nil);
  AddCustomColorMenuItem.Visible := FPopupHit.Section = psDocument;
  AddCustomColorMenuItem.Enabled := IndexOfCustomColor(LColor) < 0;
  RemoveCustomColorMenuItem.Visible := FPopupHit.Section = psCustom;
end;

procedure TfrmMain.ReplaceAllColorMenuItemClick(Sender: TObject);
var
  LEntry: Integer;
  LColor: TAlphaColor;
begin
  LColor := SwatchColor(FPopupHit.Section, FPopupHit.Index);
  LEntry := TLottieColorScanner.IndexOfColor(FColorPalette, LColor);
  if (LEntry < 0) or not ExecutePaletteColorDialog(LColor) then
    Exit;
  if ReplaceColorOccurrences(FColorPalette[LEntry].Occurrences, LColor) > 0 then
  begin
    //Follow the new color: select it and highlight its occurrences
    LEntry := TLottieColorScanner.IndexOfColor(FColorPalette, LColor);
    FPaletteBar.Select(psDocument, LEntry);
    HighlightPaletteEntry(LEntry);
  end;
  FocusCurrentEditor;
end;

procedure TfrmMain.SelectAllColorMenuItemClick(Sender: TObject);
var
  LEditor: TSynEdit;
  LEntry, I: Integer;
  LStorage: TSynSelStorage;
  LOccurrence: TLottieColorOccurrence;
  LStart, LEnd: TBufferCoord;
begin
  LEditor := CurrentEditor;
  LEntry := TLottieColorScanner.IndexOfColor(FColorPalette,
    SwatchColor(FPopupHit.Section, FPopupHit.Index));
  if (LEditor = nil) or (LEntry < 0) then
    Exit;
  //One selection (multi-caret) for each occurrence, to edit them together
  SetLength(LStorage.Selections, FColorPalette[LEntry].Count);
  for I := 0 to High(LStorage.Selections) do
  begin
    LOccurrence := FColorOccurrences[FColorPalette[LEntry].Occurrences[I]];
    LStart := OccurrenceStart(LOccurrence);
    LEnd := OccurrenceEnd(LOccurrence);
    LStorage.Selections[I] := TSynSelection.Create(LEnd, LStart, LEnd);
  end;
  LStorage.BaseIndex := 0;
  LStorage.ActiveIndex := 0;
  LEditor.Selections.Restore(LStorage);
  FocusCurrentEditor;
end;

procedure TfrmMain.CopyColorMenuItemClick(Sender: TObject);
begin
  Clipboard.AsText := TLottieColorScanner.ColorToHex(
    OpaqueColor(SwatchColor(FPopupHit.Section, FPopupHit.Index)));
end;

procedure TfrmMain.AddCustomColorMenuItemClick(Sender: TObject);
begin
  AddCustomColor(SwatchColor(FPopupHit.Section, FPopupHit.Index));
end;

procedure TfrmMain.RemoveCustomColorMenuItemClick(Sender: TObject);
begin
  if (FPopupHit.Section <> psCustom) or (FPopupHit.Index > High(FCustomColors)) then
    Exit;
  if (FPaletteBar.Selected.Section = psCustom) and FPaletteBar.Selected.IsSwatch then
  begin
    FPaletteBar.Select(psCustom, -1);
    ClearPaletteHighlight;
  end;
  Delete(FCustomColors, FPopupHit.Index, 1);
  SaveCustomColors;
end;

procedure TfrmMain.acPaletteNavigateExecute(Sender: TObject);
var
  LCount, LPos: Integer;
begin
  //Bring positions up to date with the text typed since the last scan
  UpdateColorPalette;
  if FPaletteMatchEntry < 0 then
    Exit;
  LCount := FColorPalette[FPaletteMatchEntry].Count;
  if LCount = 0 then
    Exit;
  if Sender = acPalettePrev then
  begin
    if FPaletteMatchPos <= 0 then
      LPos := LCount - 1
    else
      LPos := FPaletteMatchPos - 1;
  end
  else
    LPos := (FPaletteMatchPos + 1) mod LCount;
  GotoPaletteOccurrence(LPos);
end;

procedure TfrmMain.acPaletteNavigateUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := PalettePanel.Visible and
    (CurrentEditor <> nil) and (FPaletteMatchEntry >= 0);
end;

procedure TfrmMain.CreatePageControl;
begin
  PageControl := TPageControlEx.Create(Self);
  PageControl.Parent := ClientPanel;
  PageControl.Align := alClient;
  PageControl.Images := VirtualImageList;
  PageControl.TabOrder := 0;
  PageControl.OnChange := PageControlChange;
  PageControl.OnMouseMove := PageControlMouseMove;
  PageControl.OnCloseButtonClick := TabSheetCloseButtonClick;
end;

initialization
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

end.

