{******************************************************************************}
{                                                                              }
{       SKIA Shell Extensions: Shell extensions for animated files             }
{       (Preview Panel, Thumbnail Icon, File Editor)                           }
{                                                                              }
{       Copyright (c) 2022-2025 (Ethea S.r.l.)                                 }
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
  , Vcl.PlatformVclStylesActnCtrls
  , Vcl.Styles.Fixes
  , Vcl.Styles.FormStyleHooks
  , Vcl.Styles.NC
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
  , uDragDropUtils
  , Vcl.Skia.AnimatedImageEx
  , Vcl.StyledButton
  , Vcl.StyledToolbar
  , Vcl.ButtonStylesAttributes
  , Vcl.StyledButtonGroup
  , Vcl.StyledCategoryButtons
  ;

const
  SET_FILE_NAME = 'HiglightSettings';
  SV_COLLAPSED_WIDTH = 42;
  SV_COLLAPSED_WIDTH_WITH_SCROLLBARS = 60;


resourcestring
  PAGE_HEADER_FIRST_LINE_LEFT = '$TITLE$';
  PAGE_HEADER_FIRST_LINE_RIGHT = 'Page count: $PAGECOUNT$';
  PAGE_FOOTER_FIRST_LINE_LEFT = 'Print Date: $DATE$. Time: $TIME$';
  PAGE_FOOTER_FIRST_LINE_RIGHT = 'Page $PAGENUM$ of $PAGECOUNT$';
  FILE_NOT_FOUND = 'File "%s" not found!';
  SMODIFIED = 'Changed';
  SUNMODIFIED = 'Not changed';
  STATE_READONLY = 'ReadOnly';
  STATE_INSERT = 'Insert';
  STATE_OVERWRITE = 'Overwrite';
  CLOSING_PROBLEMS = 'Problem closing!';
  STR_ERROR = 'ERROR!';
  STR_UNEXPECTED_ERROR = 'UNEXPECTED ERROR!';
  CONFIRM_CHANGES = 'ATTENTION: the content of file "%s" is changed: do you want to save the file?';
  LOTTIE_PARSING_OK = 'Lottie Parsing is correct.';
  FILE_CHANGED_RELOAD = 'File "%s" Date/Time changed! Do you want to reload it?';

type
  TEditingFile = class
  private
    FIcon : TIcon;
    FFileName : string;
    FFileAge: TDateTime;
    FName : string;
    FExtension: string;
    procedure ReadFromFile;
    procedure SaveToFile;
    function GetFileName: string;
    function GetName: string;
    procedure SetFileName(const Value: string);
    procedure LoadFromFile(const AFileName: string);
  public
    EditFileType: TEditFileType;
    SynEditor: TSynEdit;
    TabSheet: TTabSheet;
    Constructor Create(const EditFileName : string);
    Destructor Destroy; override;
    property FileName: string read GetFileName write SetFileName; //with full path
    property Name: string read GetName; //only name of file
    property Extension : string read FExtension;
  end;

  TfrmMain = class(TForm, IDragDrop)
    OpenDialog: TOpenDialog;
    ActionList: TActionList;
    acOpenFile: TAction;
    acSave: TAction;
    SaveDialog: TSaveDialog;
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
    PageControl: TPageControl;
    ImagePanel: TPanel;
    RightSplitter: TSplitter;
    panelPreview: TPanel;
    SV: TSplitView;
    catMenuItems: TStyledCategoryButtons;
    panlTop: TPanel;
    lblTitle: TLabel;
    SettingsToolBar: TStyledToolBar;
    ColorSettingsToolButton: TStyledToolButton;
    EditOptionsToolButton: TStyledToolButton;
    VirtualImageList: TVirtualImageList;
    actMenu: TAction;
    MenuButtonToolbar: TStyledToolBar;
    ToolButton1: TStyledToolButton;
    PageSetupToolButton: TStyledToolButton;
    PrinterSetupToolButton: TStyledToolButton;
    AbouTStyledToolButton: TStyledToolButton;
    QuiTStyledToolButton: TStyledToolButton;
    ToolButton9: TStyledToolButton;
    FlowPanel: TFlowPanel;
    BackgroundTrackBar: TTrackBar;
    BackgroundGrayScaleLabel: TLabel;
    OpenRecentAction: TAction;
    RecentPopupMenu: TPopupMenu;
    SaveMenuItem: TMenuItem;
    CloseMenuItem: TMenuItem;
    Sep1MenuItem: TMenuItem;
    SelectAllMenuItem: TMenuItem;
    Reformattext1: TMenuItem;
    ImagePreviewPanel: TPanel;
    ExportToPNGAction: TAction;
    N1: TMenuItem;
    ExporttoPNGMenuItem: TMenuItem;
    StatusPanel: TPanel;
    StatusImage: TSVGIconImage;
    StatusStaticText: TStaticText;
    StatusSplitter: TSplitter;
    CloseAll1: TMenuItem;
    VirtualImageList20: TVirtualImageList;
    PanelCloseButton: TPanel;
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
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure acEditCopyUpdate(Sender: TObject);
    procedure TrackBarChange(Sender: TObject);
    procedure LoopToggleSwitchClick(Sender: TObject);
    procedure SkAnimatedImageExMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PauseActionExecute(Sender: TObject);
    procedure PageControlMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PlayInverseActionExecute(Sender: TObject);
    procedure PageControlMouseEnter(Sender: TObject);
    procedure PageControlMouseLeave(Sender: TObject);
    procedure SVGIconImageCloseButtonClick(Sender: TObject);
    procedure CheckFileChangedTimerTimer(Sender: TObject);
  private
    FirstAction: Boolean;
    SkAnimatedImageEx: TSkAnimatedImageEx;
    SkAnimatedImageEx16: TSkAnimatedImageEx;
    SkAnimatedImageEx32: TSkAnimatedImageEx;
    SkAnimatedImageEx48: TSkAnimatedImageEx;
    SkAnimatedImageEx96: TSkAnimatedImageEx;
    MinFormWidth, MinFormHeight, MaxFormWidth, MaxFormHeight: Integer;
    FProcessingFiles: Boolean;
    FEditorSettings: TEditorSettings;
    currentDir: string;
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
    function OpenFile(const FileName: string;
      const ARaiseError: Boolean = True): Boolean;
    function AddEditingFile(EditingFile: TEditingFile): Integer;
    procedure RemoveEditingFile(EditingFile: TEditingFile);
    function CurrentEditFile: TEditingFile;
    function CurrentEditor: TSynEdit;
    function ModifiedCount: integer;
    procedure InitSynEditPrint;
    procedure InitEditorOptions;
    procedure SetSynEditPrintProperties(SynEditPrint : TSynEditPrint);
    procedure UpdateEditorsOptions;
    function CurrentEditorState : string;
    procedure UpdateStatusBarPanels;
    procedure AddOpenedFile(const AFileName: string);
    procedure AssignLottieTextToImage;
    procedure SynEditChange(Sender: TObject);
    procedure SynEditEnter(Sender: TObject);
    procedure UpdateHighlighter(ASynEditor: TSynEdit);
    procedure SetEditorFontSize(const Value: Integer);
    procedure LoadOpenedFiles;
    function CanAcceptFileName(const AFileName: string): Boolean;
    function AcceptedExtensions: string;
    function CreateAnimatedImageEx(const AParent: TWinControl; const ALeft,
      ATop, AWidth, AHeight: Integer; const AHint: string): TSkAnimatedImageEx;
    procedure UpdatePlayerControls;
    procedure ConfirmChanges(EditingFile: TEditingFile);
    procedure SkAnimatedImageAnimationProcess(Sender: TObject);
    procedure UpdateRunLabel;
    procedure ShowTabCloseButtonOnHotTab;
    procedure UpdateTabsheetImage(ATabSheet: TTabSheet; AModified: Boolean);
    property EditorFontSize: Integer read FFontSize write SetEditorFontSize;
  protected
    procedure CreateWindowHandle(const Params: TCreateParams); override;
    procedure DestroyWindowHandle; override;
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
  , System.UITypes
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
  , dlgExportPNG
  , SettingsForm
  , Vcl.StyledTaskDialog
  ;

{$R *.dfm}

const
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

procedure UpdateApplicationStyle(const VCLStyleName: string);
begin
  if StyleServices.Enabled then
    TStyleManager.SetStyle(VCLStyleName);
end;

{ TEditingFile }

procedure TEditingFile.ReadFromFile;
begin
  LoadFromFile(FileName);
end;

constructor TEditingFile.Create(const EditFileName: string);
var
  Filter : Word;
begin
  inherited Create;

  if not IsStyleHookRegistered(TCustomSynEdit, TScrollingStyleHook) then
    TStyleManager.Engine.RegisterStyleHook(TCustomSynEdit, TScrollingStyleHook);

  FileName := EditFileName;
  Fextension := ExtractFileExt(FileName);

  FIcon := TIcon.Create;
  if FileExists(FileName) then
    FIcon.Handle := ExtractAssociatedIcon(hInstance, PChar(DoubleQuote(FileName)),Filter);
end;

function TEditingFile.GetFileName: string;
begin
  Result := FFileName;
end;

function TEditingFile.GetName: string;
begin
  Result := FName;
end;

procedure TEditingFile.SetFileName(const Value: string);
var
  Ext : string;
begin
  FFileName := Value;
  FName := ExtractFileName(FFileName);
  Ext := ExtractFileExt(FFileName);
  EditFileType := dmResources.GetEditFileType(Ext);
  if TabSheet <> nil then
  begin
    TabSheet.Caption := Name;
    TabSheet.Hint := FFileName;
  end;
end;

destructor TEditingFile.Destroy;
begin
  FreeAndNil(FIcon);
  inherited;
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
  SynEditor.Modified := False;
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
  Result := pos(ExtractFileExt(AFileName), AcceptedExtensions) <> 0;
end;

function TfrmMain.AcceptedExtensions: string;
begin
  //Check file extension
  Result := string('').Join(';', GetSupportedExtensions(True));
end;

function TfrmMain.OpenFile(const FileName : string;
  const ARaiseError: Boolean = True): Boolean;
var
  EditingFile: TEditingFile;
  I, J: Integer;
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
          //Add file to list
          I := AddEditingFile(EditingFile);
        end;

        EditingFile.ReadFromFile;

        Result := True;
      Except
        if I >= 0 then
          RemoveEditingFile(EditingFile)
        else
          EditingFile.Free;
        raise;
      End;
      AddOpenedFile(FileName);
    end
    else
    begin
      Result := False;
      if ARaiseError then
        Raise EFilerError.CreateFmt(FILE_NOT_FOUND,[FileName]);
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

procedure TfrmMain.SVGIconImageCloseButtonClick(Sender: TObject);
begin
  PanelCloseButton.Visible := False;
  PageControl.ActivePageIndex := PanelCloseButton.Tag;
  acClose.Execute;
  ShowTabCloseButtonOnHotTab;
end;

procedure TfrmMain.SkAnimatedImageExMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
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
  //ExportToPNG(DialogPosRect, LFileName, SkAnimatedImageEx.LottieText, True);
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
    for I := 0 to EditFileList.Count -1 do
    begin
      LEditingFile := TEditingFile(EditFileList.Items[I]);
      //Confirm save changes
      ConfirmChanges(LEditingFile);
      LFileList.Add(LEditingFile.FileName);
    end;
    if CurrentEditFile <> nil then
      LCurrentFileName := CurrentEditFile.FileName
    else
      LCurrentFileName := '';
    FEditorSettings.UpdateOpenedFiles(LFileList, LCurrentFileName);
    FEditorSettings.WriteSettings(nil, FEditorOptions);
  finally
    LFileList.Free;
  end;
end;

procedure TfrmMain.LoadOpenedFiles;
var
  I: Integer;
  LFileName: string;
  LIndex: Integer;
  LCurrentFileName: string;
begin
  LIndex := -1;
  for I := 0 to FEditorSettings.OpenedFileList.Count-1 do
  begin
    LCurrentFileName := FEditorSettings.CurrentFileName;
    LFileName := FEditorSettings.OpenedFileList.Strings[I];
    if OpenFile(LFileName, False) and SameText(LFileName, LCurrentFileName) then
      LIndex := I;
  end;
  if LIndex <> -1 then
    PageControl.ActivePageIndex := LIndex;
  AssignLottieTextToImage;
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
  OpenDialog.Filter := GetOpenDialogFilter(True);

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
  if not IsStyleHookRegistered(TCustomSynEdit, TScrollingStyleHook) then
    TStyleManager.Engine.RegisterStyleHook(TCustomSynEdit, TScrollingStyleHook);

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
  NewFileType : TEditFileType;
begin
  NewExt := 'lottie';
  NewFileType := dmResources.GetEditFileType(NewExt);

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
    if EditingFile.SynEditor.CanFocus then
      EditingFile.SynEditor.SetFocus;
  Except
    EditingFile.Free;
    raise;
  End;
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
  //Remove editing file
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
    ATabSheet.ImageName := 'lottie-logo'
  else
    ATabSheet.ImageName := 'lottie-logo-gray';
end;

procedure TfrmMain.SynEditChange(Sender: TObject);
begin
  if Sender = CurrentEditor then
  begin
    UpdateTabsheetImage(pageControl.ActivePage, CurrentEditor.Modified);
    AssignLottieTextToImage;
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

function TfrmMain.AddEditingFile(EditingFile: TEditingFile): Integer;
var
  LTabSheet : TTabSheet;
  LEditor : TSynEdit;
begin
  //Add file to opened-list
  Result := EditFileList.Add(EditingFile);
  //Create the Tabsheet page associated to the file
  LTabSheet := nil;
  LEditor := nil;
  Try
    LTabSheet := TTabSheet.Create(self);
    LTabSheet.PageControl := PageControl;
    //Use TAG of tabsheet to store the object pointer
    LTabSheet.Tag := NativeInt(EditingFile);
    LTabSheet.Caption := EditingFile.Name;
    LTabSheet.Hint := EditingFile.FileName;
    LTabSheet.Imagename := 'lottie-logo-gray';
    LTabSheet.Parent := PageControl;
    LTabSheet.TabVisible := True;
    EditingFile.TabSheet := LTabSheet;

    //Create the SynEdit object editor into the TabSheet that is the owner
    LEditor := TSynEdit.Create(LTabSheet);
    LEditor.OnChange := SynEditChange;
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
    LTabSheet.Free;
    LEditor.Free;
    raise;
  End;

    //Make the Tabsheet the current page
    PageControl.ActivePage := LTabSheet;

    //and call "change" of pagecontrol
    PageControl.OnChange(PageControl);
end;

procedure TfrmMain.AssignLottieTextToImage;
var
  LLottieText: string;
begin
  if FProcessingFiles then
    Exit;
  //Assign SVG image
  try
    if CurrentEditor <> nil then
    begin
      LLottieText := CurrentEditor.Lines.Text;
      SkAnimatedImageEx.LottieText := LLottieText;
      SkAnimatedImageEx16.LottieText := LLottieText;
      SkAnimatedImageEx32.LottieText := LLottieText;
      SkAnimatedImageEx48.LottieText := LLottieText;
      SkAnimatedImageEx96.LottieText := LLottieText;
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
  end;
  AssignLottieTextToImage;
end;

procedure TfrmMain.PageControlMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
{$WRITEABLECONST ON}
const oldPos : integer = -2;
{$WRITEABLECONST OFF}
var
  iot : integer;

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
      Application.ProcessMessages; // force hint to appear
    finally
      Application.HintPause := LHintPause;
    end;
  end;

  iot := TTabControl(Sender).IndexOfTabAt(x,y);
  if (iot > -1) then
  begin
    if iot <> oldPos then
      ShowTabCloseButtonOnHotTab;
  end;
  oldPos := iot;
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
        if LFileAge <> LEditFile.FFileAge then
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
            LEditFile.FFileAge := LFileAge;
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

procedure TfrmMain.CreateWindowHandle(const Params: TCreateParams);
begin
  inherited;
  FDropTarget := TDropTarget.Create(WindowHandle, Self);
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
  if EditingFile.SynEditor.Modified then
  begin
    LConfirm := StyledMessageDlg(Format(CONFIRM_CHANGES,[EditingFile.FileName]),
      mtWarning, [mbYes, mbNo], 0);
    if LConfirm = mrYes then
      EditingFile.SaveToFile
    else if LConfirm = mrCancel then
      Abort;
    //if LConfirm = mrNo continue without saving
  end;
end;

procedure TfrmMain.RemoveEditingFile(EditingFile: TEditingFile);
var
  i : integer;
  pos : integer;
begin
  pos := -1;
  for i := 0 to EditFileList.Count -1 do
  begin
    if EditFileList.Items[i] = EditingFile then
    begin
      pos := i;
      break;
    end;
  end;
  if pos = -1 then
    raise EComponentError.Create(CLOSING_PROBLEMS);

  //Confirm save changes
  ConfirmChanges(EditingFile);

  PanelCloseButton.Visible := False;

  //Delete the file from the Opened-List
  EditFileList.Delete(pos);

  //Delete the TabSheet
  PageControl.Pages[pos].Free;

  //Activate the previous page and call "change" of pagecontrol
  if pos > 0 then
    PageControl.ActivePageIndex := pos-1;

  //Force "change" of Page
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
    PanelCloseButton.Visible := False;
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
begin
  Result := 0;
  for i := 0 to EditFileList.Count -1 do
  begin
    if TEditingFile(EditFileList.items[i]).SynEditor.Modified then
    begin
      Inc(Result);
    end;
  end;
end;

procedure TfrmMain.acSaveAllExecute(Sender: TObject);
var
  i : integer;
begin
  for i := 0 to EditFileList.Count -1 do
  with TEditingFile(EditFileList.items[i]) do
  begin
    if SynEditor.Modified then
    begin
      SaveToFile;
    end;
  end;
end;

procedure TfrmMain.acAboutExecute(Sender: TObject);
begin
  ShowAboutForm(DialogPosRect, Title_LottieTextEditor);
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
var
  LScaleFactor: Single;
begin
  if (CurrentEditor <> nil) and (Value >= MinfontSize) and (Value <= MaxfontSize) then
  begin
    if FFontSize <> 0 then
      LScaleFactor := CurrentEditor.Font.Height / FFontSize
    else
      LScaleFactor := 1;
    CurrentEditor.Font.PixelsPerInch := Self.PixelsPerInch;
    CurrentEditor.Font.Height := Round(Value * LScaleFactor * Self.ScaleFactor);
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
  UpdateApplicationStyle(FEditorSettings.StyleName);
  UpdateHighlighter(AEditor);
  BackgroundTrackBar.Position := FEditorSettings.LightBackground;
  LoopToggleSwitch.State := TToggleSwitchState(Ord(FEditorSettings.PlayInLoop));
  if FEditorSettings.AutoPlay and SkAnimatedImageEx.CanPlayAnimation then
    StartAnimations(False)
  else if not FEditorSettings.AutoPlay and SkAnimatedImageEx.CanStopAnimation then
    StopAnimations;
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
  InitialDir : string;
  LFileName: string;
begin
  UpdateStatusBarPanels;
  UpdatePlayerControls;
  if not FirstAction then
  begin
    FirstAction := True;
    //Load previous opened-files
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

    OpenDialog.InitialDir := InitialDir;
    SaveDialog.InitialDir := InitialDir;
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
  (Sender as TAction).Enabled := CurrentEditFile <> nil;
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

procedure TfrmMain.AdjustCompactWidth;
begin
  //Change size of compact because Scrollbars appears
  if (Height / ScaleFactor) > 900 then
    SV.CompactWidth := Round(SV_COLLAPSED_WIDTH * ScaleFactor)
  else
    SV.CompactWidth := Round(SV_COLLAPSED_WIDTH_WITH_SCROLLBARS * ScaleFactor);
  if PageControl.Width < 100 then
    ImagePanel.Width := Width div 3;
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

procedure TfrmMain.ShowTabCloseButtonOnHotTab;
var
  iot : integer;
  cp : TPoint;
  rectOver: TRect;
begin
  cp := PageControl.ScreenToClient(Mouse.CursorPos);
  iot := PageControl.IndexOfTabAt(cp.X, cp.Y);

  if iot > -1 then
  begin
    rectOver := PageControl.TabRect(iot);

    PanelCloseButton.Left := rectOver.Right - PanelCloseButton.Width;
    PanelCloseButton.Top := rectOver.Top + ((rectOver.Height div 2) - (PanelCloseButton.Height div 2)) + 1;

    PanelCloseButton.Tag := iot;
    PanelCloseButton.Color := Self.Color;
    PanelCloseButton.Show;
  end
  else
  begin
    PanelCloseButton.Tag := -1;
    PanelCloseButton.Hide;
  end;
end;

procedure TfrmMain.PageControlMouseEnter(Sender: TObject);
begin
  ShowTabCloseButtonOnHotTab;
end;

procedure TfrmMain.PageControlMouseLeave(Sender: TObject);
begin
  if PanelCloseButton <> FindVCLWindow(Mouse.CursorPos) then
  begin
    PanelCloseButton.Hide;
    PanelCloseButton.Tag := -1;
  end;
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
      [TMsgDlgBtn.mbOK, TMsgDlgBtn.mbHelp], 0);
  end;
end;

initialization
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

end.

