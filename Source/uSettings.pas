{******************************************************************************}
{                                                                              }
{       SKIA Shell Extensions: Shell extensions for animated files             }
{       (Preview Panel, Thumbnail Icon, Lottie Editor)                         }
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
{                                                                              }
{  The Initial Developer of the Original Code is Rodrigo Ruz V.                }
{  Portions created by Rodrigo Ruz V. are Copyright 2011-2021 Rodrigo Ruz V.   }
{  All Rights Reserved.                                                        }
{******************************************************************************}
unit uSettings;

interface

uses
  System.SysUtils,
  System.Classes,
  VCL.Graphics,
  SynEditHighlighter,
  System.Generics.Collections,
  SynEditOptionsDialog,
  IniFiles;

const
  MaxfontSize = 30;
  MinfontSize = 8;
  default_lightactivelinecolor = 15066597;
  default_darkactivelinecolor = 0;
  default_checkdays = 7;
  default_colorpaletteheight = 90; //at 96 DPI

resourcestring
  Background_Grayscale_Caption = 'Backlight %d%%';

type
  TThemeSelection = (tsAsWindows, tsDarkTheme, tsLightTheme);
  TThemeType = (ttLight, ttDark);

  //Class to register Theme attributes (like dark or light)
  TThemeAttribute = class
    StyleName: String;
    ThemeType: TThemeType;

  //function to get Theme Attributes
  class function GetStyleAttributes(const AStyleName: string;
    out AThemeAttribute: TThemeAttribute): Boolean;
  private
  end;

  TSettings = class
  private
    FSplitterPos: Integer;
    FVersionCheckTime: TDateTime;
    FDaysForNextCheck: Integer;
    FFontSize: Integer;
    FStyleName: string;
    FUseDarkStyle: boolean;
    FFontName: string;
    FShowEditor: Boolean;
    FActivePageIndex: Integer;
    FThemeSelection: TThemeSelection;
    FAutoPlay: Boolean;
    FPlayInLoop: Boolean;
    FButtonDrawRounded: Boolean;
    FToolbarDrawRounded: Boolean;
    FMenuDrawRounded: Boolean;
    function GetUseDarkStyle: Boolean;
    procedure SetPlayInLoop(const Value: Boolean);
    procedure SetAutoPlay(const Value: Boolean);
    function GetThemeSectionName: string;
    function GetButtonTextColor: TColor;
    class function GetSettingsFileName: string; static;
    procedure SetButtonDrawRounded(const Value: Boolean);
    procedure SetToolbarDrawRounded(const Value: Boolean);
    procedure SetMenuDrawRounded(const Value: Boolean);
    procedure SetDaysForNextCheck(const Value: Integer);
  protected
    FIniFile: TIniFile;
  public
    LightBackground: Integer;
    constructor CreateSettings(const ASettingFileName: string;
      const ASynEditHighilighter: TSynCustomHighlighter;
      const ASynEditorOptions: TSynEditorOptionsContainer);
    destructor Destroy; override;

    class var FSettingsFileName: string;
    class var FSettingsPath: string;
    class property SettingsFileName: string read GetSettingsFileName;

    procedure UpdateSettings(const AFontName: string;
      AFontSize: Integer; AEditorVisible: Boolean);
    procedure ReadSettings(const ASynEditHighilighter: TSynCustomHighlighter;
      const ASynEditorOptions: TSynEditorOptionsContainer); virtual;
    procedure WriteSettings(const ASynEditHighilighter: TSynCustomHighlighter;
      const ASynEditorOptions: TSynEditorOptionsContainer); virtual;

    property UseDarkStyle: Boolean read GetUseDarkStyle;
    property ButtonTextColor: TColor read GetButtonTextColor;
    property FontSize: Integer read FFontSize write FFontSize;
    property FontName: string read FFontName write FFontName;
    property StyleName: string read FStyleName write FStyleName;
    property ShowEditor: Boolean read FShowEditor write FShowEditor;
    property SplitterPos: Integer read FSplitterPos write FSplitterPos;
    property AutoPlay: Boolean read FAutoPlay write SetAutoPlay default True;
    property PlayInLoop: Boolean read FPlayInLoop write SetPlayInLoop default True;
    property ActivePageIndex: Integer read FActivePageIndex write FActivePageIndex;
    property ThemeSelection: TThemeSelection read FThemeSelection write FThemeSelection;
    property ButtonDrawRounded: Boolean read FButtonDrawRounded write SetButtonDrawRounded;
    property ToolbarDrawRounded: Boolean read FToolbarDrawRounded write SetToolbarDrawRounded;
    property MenuDrawRounded: Boolean read FMenuDrawRounded write SetMenuDrawRounded;
    property DaysForNextCheck: Integer read FDaysForNextCheck write SetDaysForNextCheck;
  end;

  TEditorSettings = class(TSettings)
  private
    FLightActiveLineColor: TColor;
    FDarkActiveLineColor: TColor;
    FRestoreLastSession: Boolean;
    FShowColorPalette: Boolean;
    FColorPaletteHeight: Integer;
    FCustomColors: string;
    procedure WriteSynEditorOptions(
      const ASynEditorOptions: TSynEditorOptionsContainer);
    procedure ReadSynEditorOptions(
      const ASynEditorOptions: TSynEditorOptionsContainer);
    procedure SetRestoreLastSession(const Value: Boolean);
  public
    HistoryFileList: TStrings;
    OpenedFileList: TStrings;
    CurrentFileName: string;
    function IsTimeToCheckNewVersion: Boolean;
    procedure ReadSettings(const ASynEditHighilighter: TSynCustomHighlighter;
      const ASynEditorOptions: TSynEditorOptionsContainer); override;
    procedure WriteSettings(const ASynEditHighilighter: TSynCustomHighlighter;
      const ASynEditorOptions: TSynEditorOptionsContainer); override;
    constructor CreateSettings(const ASynEditHighilighter: TSynCustomHighlighter;
      const ASynEditorOptions: TSynEditorOptionsContainer;
      const AFileName: TFileName = '');
    destructor Destroy; override;
    procedure UpdateOpenedFiles(AFileList: TStrings; const ACurrentFileName: string);
    property LightActiveLineColor: TColor read FLightActiveLineColor write FLightActiveLineColor;
    property DarkActiveLineColor: TColor read FDarkActiveLineColor write FDarkActiveLineColor;
    property RestoreLastSession: Boolean read FRestoreLastSession write SetRestoreLastSession;
    //Color palette panel under the editor
    property ShowColorPalette: Boolean read FShowColorPalette write FShowColorPalette;
    //Height of the color palette panel, at 96 DPI
    property ColorPaletteHeight: Integer read FColorPaletteHeight write FColorPaletteHeight;
    //Custom colors of the palette, as '#RRGGBB,#RRGGBB,...'
    property CustomColors: string read FCustomColors;
    //Custom colors are saved at once: the settings are read again from the
    //file in many places, which would otherwise drop the unsaved ones
    procedure WriteCustomColors(const AValue: string);
  end;

  TPreviewSettings = class(TEditorSettings)
  public
    constructor CreateSettings(const ASynEditHighilighter: TSynCustomHighlighter;
      const ASynEditorOptions: TSynEditorOptionsContainer);
  end;

implementation

uses
  Vcl.Controls,
  SVGInterfaces,
  D2DSVGFactory,
  Image32SVGFactory,
  System.Types,
  System.TypInfo,
  System.Rtti,
  System.StrUtils,
  System.IOUtils,
  Winapi.ShlObj,
  Winapi.Windows,
{$IFNDEF DISABLE_STYLES}
  Vcl.Themes,
  Vcl.StandardButtonStyles,
{$ENDIF}
  uLogExcept,
  uRegistry,
  uMisc,
  SynEdit
  ;

const
  LAST_OPENED_SECTION = 'LastOpened';
  FILES_OPENED_SECTION = 'FilesOpened';
  EDITOPTION_GUTTER = 'EditorOptions_Gutter';
  EDITOPTION_RIGHTEDGE = 'EditorOptions_RightEdge';
  EDITOPTION_LINESPACING = 'EditorOptions_LineSpacing';
  EDITOPTION_BOOKMARK = 'EditorOptions_Bookmark';
  EDITOPTION_OPTIONS = 'EditorOptions_Options';
  default_lightbackground = 200;
  default_darkbackground = 55;

var
  ThemeAttributes: TList<TThemeAttribute>;

//Theme type (light or dark) of a VCL style: from the table of StyledComponents,
//which knows the VCL styles shipped with Delphi; for any other style (e.g. a
//custom one linked by who builds the editor), from the luminance of its
//window color
function StyleThemeType(const AStyleName: string; out AThemeType: TThemeType): Boolean;
{$IFNDEF DISABLE_STYLES}
var
  LStyledAttribute: Vcl.StandardButtonStyles.TThemeAttribute;
  LStyle: TCustomStyleServices;
  LColor: Integer;
  LLuminance: Integer;
{$ENDIF}
begin
  Result := False;
  AThemeType := ttLight;
{$IFNDEF DISABLE_STYLES}
  //NB: for a style it does not know, GetStyleAttributes returns the attributes
  //of "Windows": only an entry with the same name is taken
  if Vcl.StandardButtonStyles.GetStyleAttributes(AStyleName, LStyledAttribute) and
    Assigned(LStyledAttribute) and SameText(LStyledAttribute.StyleName, AStyleName) then
  begin
    if LStyledAttribute.ThemeType = Vcl.StandardButtonStyles.ttDark then
      AThemeType := ttDark;
    Exit(True);
  end;
  try
    LStyle := TStyleManager.Style[AStyleName];
  except
    LStyle := nil; //style not registered
  end;
  if not Assigned(LStyle) then
    Exit;
  LColor := ColorToRGB(LStyle.GetSystemColor(clWindow));
  LLuminance := (299 * (LColor and $FF) + 587 * ((LColor shr 8) and $FF) +
    114 * ((LColor shr 16) and $FF)) div 1000;
  if LLuminance < 128 then
    AThemeType := ttDark;
  Result := True;
{$ENDIF}
end;

procedure InitDefaultThemesAttributes;
{$IFDEF DISABLE_STYLES}
var
  LThemeAttribute: TThemeAttribute;
{$ENDIF}
begin
  //NB: the light/dark type of the styles is no longer a fixed list, which had
  //to be kept aligned by hand with the styles linked into the projects (the
  //styles missing from it were not offered at all in Settings). It is worked
  //out on demand from the colors of each style by GetStyleAttributes.
  ThemeAttributes := TList<TThemeAttribute>.Create;
{$IFDEF DISABLE_STYLES}
  LThemeAttribute := TThemeAttribute.Create;
  LThemeAttribute.StyleName := 'Windows';
  LThemeAttribute.ThemeType := ttLight;
  ThemeAttributes.Add(LThemeAttribute);
{$ENDIF}
end;

{ TSettings }

constructor TSettings.CreateSettings(const ASettingFileName: string;
  const ASynEditHighilighter: TSynCustomHighlighter;
  const ASynEditorOptions: TSynEditorOptionsContainer);
begin
  inherited Create;
  FIniFile := TIniFile.Create(ASettingFileName);
  FSettingsFileName := ASettingFileName;
  FSettingsPath := ExtractFilePath(ASettingFileName);
  System.SysUtils.ForceDirectories(FSettingsPath);
  FPlayInLoop := True;
  FAutoPlay := True;
  ReadSettings(ASynEditHighilighter, ASynEditorOptions);
end;

destructor TSettings.Destroy;
begin
  FIniFile.UpdateFile;
  FIniFile.Free;
  inherited;
end;

function TSettings.GetButtonTextColor: TColor;
{$IFNDEF DISABLE_STYLES}
var
  LStyleServices: TCustomStyleServices;
{$ENDIF}
begin
{$IFNDEF DISABLE_STYLES}
  LStyleServices := TStyleManager.Style[Self.StyleName];
  if Assigned(LStyleServices) then
    Result := LStyleServices.GetStyleFontColor(sfButtonTextNormal)
  else
    Result := clBtnText;
{$ELSE}
  Result := clBtnText;
{$ENDIF}
end;

class function TSettings.GetSettingsFileName: string;
begin
  Result := FSettingsFileName;
end;

function TSettings.GetThemeSectionName: string;
begin
  if FUseDarkStyle then
    Result := 'Dark'
  else
    Result := 'Light';
end;

function TSettings.GetUseDarkStyle: Boolean;
begin
  Result := FUseDarkStyle;
end;

procedure TSettings.ReadSettings(const ASynEditHighilighter: TSynCustomHighlighter;
  const ASynEditorOptions: TSynEditorOptionsContainer);
var
  LThemeSection: string;
  I: Integer;
  LAutoPlay: Integer;
  LAttribute: TSynHighlighterAttributes;
begin
  TLogPreview.Add('ReadSettings '+SettingsFileName);
  FVersionCheckTime := FIniFile.ReadDateTime('Global', 'VersionCheckTime', Now());
  FDaysForNextCheck := FIniFile.ReadInteger('Global', 'DaysForNextCheck', default_checkdays);
  FFontSize := FIniFile.ReadInteger('Global', 'FontSize', 10);
  FFontName := FIniFile.ReadString('Global', 'FontName', 'Consolas');
  FShowEditor := FIniFile.ReadInteger('Global', 'ShowEditor', 0) = 1;
  FSplitterPos := FIniFile.ReadInteger('Global', 'SplitterPos', 33);
  LAutoPlay := FIniFile.ReadInteger('Global', 'AutoPlay', 0);
  AutoPlay := not ((LAutoPlay = 0) or (LAutoPlay = 255));
  PlayInLoop := Boolean(FIniFile.ReadInteger('Global', 'PlayInLoop', 0));
  FActivePageIndex := FIniFile.ReadInteger('Global', 'ActivePageIndex', 0);
  FStyleName := FIniFile.ReadString('Global', 'StyleName', DefaultStyleName);
  FThemeSelection := TThemeSelection(FIniFile.ReadInteger('Global', 'ThemeSelection', 0));
  FToolbarDrawRounded := FIniFile.ReadBool('Global', 'ToolbarDrawRounded', false);
  FButtonDrawRounded := FIniFile.ReadBool('Global', 'ButtonDrawRounded', false);
  FMenuDrawRounded := FIniFile.ReadBool('Global', 'MenuDrawRounded', false);
  //Select Style by default on Actual Windows Theme
  if FThemeSelection = tsAsWindows then
  begin
    FUseDarkStyle := not IsWindowsAppThemeLight;
  end
  else
    FUseDarkStyle := FThemeSelection = tsDarkTheme;

  if FUseDarkStyle then
    LightBackground := FIniFile.ReadInteger('Global', 'LightBackground', default_darkbackground)
  else
    LightBackground := FIniFile.ReadInteger('Global', 'LightBackground', default_lightbackground);

  //Load Highlighter in specific section by Theme
  if Assigned(ASynEditHighilighter) then
  begin
    LThemeSection := GetThemeSectionName;
    for I := 0 to ASynEditHighilighter.AttrCount - 1 do
    begin
      LAttribute := ASynEditHighilighter.Attribute[I];
      LAttribute.Background := FIniFile.ReadInteger(LThemeSection+LAttribute.Name, 'Background',
        LAttribute.Background);
      LAttribute.Foreground := FIniFile.ReadInteger(LThemeSection+LAttribute.Name, 'Foreground',
        LAttribute.Foreground);
      LAttribute.IntegerStyle := FIniFile.ReadInteger(LThemeSection+LAttribute.Name, 'Style',
        LAttribute.IntegerStyle);
    end;
  end;
end;

procedure TSettings.SetAutoPlay(const Value: Boolean);
begin
  if FAutoPlay <> Value then
    FAutoPlay := Value;
end;

procedure TSettings.SetPlayInLoop(const Value: Boolean);
begin
  if FPlayInLoop <> Value then
    FPlayInLoop := Value;
end;

procedure TSettings.UpdateSettings(const AFontName: string;
  AFontSize: Integer; AEditorVisible: Boolean);
begin
  FontSize := AFontSize;
  FontName := AFontName;
  ShowEditor := AEditorVisible;
end;

procedure TSettings.WriteSettings(const ASynEditHighilighter: TSynCustomHighlighter;
  const ASynEditorOptions: TSynEditorOptionsContainer);
var
  I: Integer;
  LAttribute: TSynHighlighterAttributes;
  LThemeSection: string;
begin
  FIniFile.WriteDateTime('Global', 'VersionCheckTime', FVersionCheckTime);
  FIniFile.WriteInteger('Global', 'DaysForNextCheck', FDaysForNextCheck);

  FIniFile.WriteInteger('Global', 'FontSize', FFontSize);
  FIniFile.WriteString('Global', 'FontName', FFontName);
  FIniFile.WriteString('Global', 'StyleName', FStyleName);
  FIniFile.WriteInteger('Global', 'ShowEditor', Ord(FShowEditor));
  FIniFile.WriteInteger('Global', 'SplitterPos', FSplitterPos);
  FIniFile.WriteInteger('Global', 'AutoPlay', Ord(FAutoPlay));
  FIniFile.WriteInteger('Global', 'PlayInLoop', Ord(FPlayInLoop));
  FIniFile.WriteInteger('Global', 'ActivePageIndex', FActivePageIndex);
  FIniFile.WriteInteger('Global', 'ThemeSelection', Ord(FThemeSelection));
  FIniFile.WriteBool('Global', 'ToolbarDrawRounded', ToolbarDrawRounded);
  FIniFile.WriteBool('Global', 'ButtonDrawRounded', ButtonDrawRounded);
  FIniFile.WriteBool('Global', 'MenuDrawRounded', MenuDrawRounded);
  if (FUseDarkStyle and (LightBackground <> default_darkbackground)) or
    (not FUseDarkStyle and (LightBackground <> default_lightbackground)) then
    FIniFile.WriteInteger('Global', 'LightBackground', LightBackground);

  if ASynEditHighilighter <> nil then
  begin
    //Save Highlighter in specific section by Theme
    LThemeSection := GetThemeSectionName;
    for I := 0 to ASynEditHighilighter.AttrCount - 1 do
    begin
      LAttribute := ASynEditHighilighter.Attribute[I];
      FIniFile.WriteInteger(LThemeSection+LAttribute.Name, 'Background', LAttribute.Background);
      FIniFile.WriteInteger(LThemeSection+LAttribute.Name, 'Foreground', LAttribute.Foreground);
      FIniFile.WriteInteger(LThemeSection+LAttribute.Name, 'Style', LAttribute.IntegerStyle);
    end;
  end;
end;

procedure TSettings.SetToolbarDrawRounded(
  const Value: Boolean);
begin
  FToolbarDrawRounded := Value;
end;

procedure TSettings.SetMenuDrawRounded(const Value: Boolean);
begin
  FMenuDrawRounded := Value;
end;

procedure TSettings.SetButtonDrawRounded(const Value: Boolean);
begin
  FButtonDrawRounded := Value;
end;

procedure TSettings.SetDaysForNextCheck(const Value: Integer);
begin
  FDaysForNextCheck := Value;
end;

{ TPreviewSettings }

constructor TPreviewSettings.CreateSettings(
  const ASynEditHighilighter: TSynCustomHighlighter;
  const ASynEditorOptions: TSynEditorOptionsContainer);
var
  LFileName: TFileName;
begin
  LFileName := IncludeTrailingPathDelimiter(GetSpecialFolder(CSIDL_APPDATA)) +
    'SKIAPreviewHandler\Settings.ini';
  inherited CreateSettings(ASynEditHighilighter, ASynEditorOptions,
    LFileName);
  ReadSynEditorOptions(ASynEditorOptions);
end;

{ TEditorSettings }

constructor TEditorSettings.CreateSettings(
  const ASynEditHighilighter: TSynCustomHighlighter;
  const ASynEditorOptions: TSynEditorOptionsContainer;
  const AFileName: TFileName = '');
var
  LFileName: TFileName;
begin
  HistoryFileList := TStringList.Create;
  OpenedFileList := TStringList.Create;
  if AFileName <> '' then
    LFileName := AFileName
  else
    LFileName := IncludeTrailingPathDelimiter(
      GetSpecialFolder(CSIDL_APPDATA)) +'LottieTextEditor\Settings.ini';
  inherited CreateSettings(LFileName,
    ASynEditHighilighter, ASynEditorOptions);
  ReadSynEditorOptions(ASynEditorOptions);
end;

destructor TEditorSettings.Destroy;
begin
  HistoryFileList.Free;
  OpenedFileList.Free;
  inherited;
end;

function TEditorSettings.IsTimeToCheckNewVersion: Boolean;
begin
  //NB: a negative number of days means "never check". Without this guard the
  //comparison was always true and the setting produced the opposite of what it
  //promised: a check at every startup.
  if FDaysForNextCheck < 0 then
    Exit(False);
  Result := Now() > FVersionCheckTime + FDaysForNextCheck;
  if Result then
  begin
    FVersionCheckTime := Now(); //Update Next time for check
    //Saved at once: the settings are read again from the file in many places
    //(e.g. for every opened file), which would restore the old date before it
    //is written at closing, and the check would run at every startup
    FIniFile.WriteDateTime('Global', 'VersionCheckTime', FVersionCheckTime);
  end;
end;

procedure TEditorSettings.SetRestoreLastSession(const Value: Boolean);
begin
  FRestoreLastSession := Value;
end;

procedure TEditorSettings.WriteCustomColors(const AValue: string);
begin
  FCustomColors := AValue;
  FIniFile.WriteString('ColorPalette', 'CustomColors', FCustomColors);
end;

procedure TEditorSettings.ReadSettings(
  const ASynEditHighilighter: TSynCustomHighlighter;
  const ASynEditorOptions: TSynEditorOptionsContainer);
var
  I: Integer;
  LValue: string;
  LFileName: string;
begin
  inherited;
  //ActiveLine Color
  DarkActiveLineColor := FIniFile.ReadInteger('Global', 'DarkActiveLineColor', default_darkactivelinecolor);
  LightActiveLineColor := FIniFile.ReadInteger('Global', 'LightActiveLineColor', default_lightactivelinecolor);

  RestoreLastSession := Boolean(FIniFile.ReadInteger('Global', 'RestoreLastSession', 1));

  FShowColorPalette := FIniFile.ReadBool('ColorPalette', 'Visible', True);
  FColorPaletteHeight := FIniFile.ReadInteger('ColorPalette', 'Height', default_colorpaletteheight);
  FCustomColors := FIniFile.ReadString('ColorPalette', 'CustomColors', '');

  if Assigned(ASynEditorOptions) then
  begin
    if FUseDarkStyle then
      ASynEditorOptions.ActiveLineColor := DarkActiveLineColor
    else
      ASynEditorOptions.ActiveLineColor := LightActiveLineColor;
  end;
  if ASynEditHighilighter = nil then
  begin
    //Leggo la lista dei files aperti di recente
    FIniFile.ReadSectionValues(LAST_OPENED_SECTION, HistoryFileList);
    for I := 0 to HistoryFileList.Count -1 do
    begin
      LValue := HistoryFileList.strings[i];
      //tolgo la chiave
      LFileName := Copy(LValue, pos('=',LValue)+1,MaxInt);
      if FileExists(LFileName) then
        HistoryFileList.strings[i] := LFileName;
    end;
    //Leggo la lista dei files aperti l'ultima volta
    FIniFile.ReadSectionValues(FILES_OPENED_SECTION, OpenedFileList);
    for I := 0 to OpenedFileList.Count -1 do
    begin
      LValue := OpenedFileList.strings[i];
      //tolgo la chiave
      LFileName := Copy(LValue, pos('=',LValue)+1,MaxInt);
      if FileExists(LFileName) then
        OpenedFileList.strings[i] := LFileName;
    end;
  end;
  CurrentFileName := FIniFile.ReadString('Global', 'CurrentFileName', '');
end;

procedure TeditorSettings.ReadSynEditorOptions(
  const ASynEditorOptions: TSynEditorOptionsContainer);

  procedure UpdateEditorOptions(const AName: string; const AValue: TSynEditorOption;
    const ADefault: Boolean = True);
  begin
    if FIniFile.ReadBool(EDITOPTION_OPTIONS, AName, ADefault) then
      ASynEditorOptions.Options := ASynEditorOptions.Options + [AValue];
  end;

  procedure UpdateEditorScrollOptions(const AName: string;
    const AValue: TSynEditorScrollOption;
    const ADefault: Boolean = True);
  begin
    if FIniFile.ReadBool(EDITOPTION_OPTIONS, AName, ADefault) then
      ASynEditorOptions.ScrollOptions := ASynEditorOptions.ScrollOptions + [AValue];
  end;

begin
  if not Assigned(ASynEditorOptions) then
    Exit;

  //Gutter
  ASynEditorOptions.Gutter.Visible := FIniFile.ReadBool(EDITOPTION_GUTTER, 'Visible', True);
  ASynEditorOptions.Gutter.AutoSize := FIniFile.ReadBool(EDITOPTION_GUTTER, 'AutoSize', True);
  ASynEditorOptions.Gutter.ShowLineNumbers := FIniFile.ReadBool(EDITOPTION_GUTTER, 'ShowLineNumbers', True);
  ASynEditorOptions.Gutter.LeadingZeros := FIniFile.ReadBool(EDITOPTION_GUTTER, 'LeadingZeros', False);
  ASynEditorOptions.Gutter.ZeroStart := FIniFile.ReadBool(EDITOPTION_GUTTER, 'ZeroStart', False);
  ASynEditorOptions.Gutter.UseFontStyle := FIniFile.ReadBool(EDITOPTION_GUTTER, 'UseFontStyle', True);
  ASynEditorOptions.Gutter.Font.Name := FIniFile.ReadString(EDITOPTION_GUTTER, 'Font.Name', 'Consolas');
  ASynEditorOptions.Gutter.Font.Size := FIniFile.ReadInteger(EDITOPTION_GUTTER, 'Font.Size', 11);
  //Right Edge
  ASynEditorOptions.RightEdge := FIniFile.ReadInteger(EDITOPTION_RIGHTEDGE,'RightEdge',80);
  //Line Spacing
  ASynEditorOptions.ExtraLineSpacing := FIniFile.ReadInteger(EDITOPTION_LINESPACING,'ExtraLineSpacing', 0);
  ASynEditorOptions.TabWidth := FIniFile.ReadInteger(EDITOPTION_LINESPACING,'TabWidth',4);
  //Bookmarks
  ASynEditorOptions.BookMarkOptions.EnableKeys := FIniFile.ReadBool(EDITOPTION_BOOKMARK,'EnableKeys', True);
  ASynEditorOptions.BookMarkOptions.GlyphsVisible := FIniFile.ReadBool(EDITOPTION_BOOKMARK,'GlyphsVisible', True);
  //Options
  ASynEditorOptions.Options := [];
  UpdateEditorOptions('AutoIndent', eoAutoIndent);
  UpdateEditorOptions('DragDropEditing',  eoDragDropEditing);
  UpdateEditorOptions('SmartTabs',  eoSmartTabs);
  UpdateEditorScrollOptions('HalfPageScroll',  eoHalfPageScroll);
  UpdateEditorScrollOptions('ScrollByOneLess',  eoScrollByOneLess);
  UpdateEditorScrollOptions('ScrollPastEof',  eoScrollPastEof);
  UpdateEditorScrollOptions('ScrollPastEol',  eoScrollPastEol);
  UpdateEditorScrollOptions('ShowScrollHint',  eoShowScrollHint);
  UpdateEditorOptions('TabsToSpaces',  eoTabsToSpaces);
  UpdateEditorOptions('TrimTrailingSpaces',  eoTrimTrailingSpaces);
  UpdateEditorOptions('KeepCaretX',  eoKeepCaretX);
  UpdateEditorOptions('SmartTabDelete',  eoSmartTabDelete);
  UpdateEditorOptions('RightMouseMovesCursor',  eoRightMouseMovesCursor);
  UpdateEditorOptions('EnhanceHomeKey',  eoEnhanceHomeKey);
  UpdateEditorOptions('EnhanceEndKey',  eoEnhanceEndKey);
  UpdateEditorOptions('GroupUndo',  eoGroupUndo);
  UpdateEditorOptions('TabIndent',  eoTabIndent);
  UpdateEditorScrollOptions('DisableScrollArrows',  eoDisableScrollArrows);
  UpdateEditorScrollOptions('HideShowScrollbars',  eoHideShowScrollbars);
  ASynEditorOptions.WantTabs := FIniFile.ReadBool(EDITOPTION_OPTIONS, 'WantTabs', False);
  ASynEditorOptions.WordWrap := FIniFile.ReadBool(EDITOPTION_OPTIONS, 'WordWrap', True);

(*
  //Caret
  cInsertCaret.ItemIndex := ord(ASynEditorOptions.InsertCaret);
  cOverwriteCaret.ItemIndex := ord(ASynEditorOptions.OverwriteCaret);

  KeyList.Items.BeginUpdate;
  try
    KeyList.Items.Clear;
    for I := 0 to ASynEditorOptions.Keystrokes.Count-1 do
    begin
      Item := KeyList.Items.Add;
      FillInKeystrokeInfo(ASynEditorOptions.Keystrokes.Items[I], Item);
      Item.Data := ASynEditorOptions.Keystrokes.Items[I];
    end;
    if (KeyList.Items.Count > 0) then KeyList.Items[0].Selected := True;
  finally
    KeyList.Items.EndUpdate;
  end;
*)
end;

procedure TEditorSettings.UpdateOpenedFiles(AFileList: TStrings;
  const ACurrentFileName: string);
begin
  OpenedFileList.Assign(AFileList);
  CurrentFileName := ACurrentFileName;
end;

procedure TEditorSettings.WriteSettings(
  const ASynEditHighilighter: TSynCustomHighlighter;
  const ASynEditorOptions: TSynEditorOptionsContainer);
var
  I: Integer;
begin
  inherited;
  if (DarkActiveLineColor <> default_darkactivelinecolor) then
    FIniFile.WriteInteger('Global', 'DarkActiveLineColor', DarkActiveLineColor)
  else
    FIniFile.DeleteKey('Global', 'DarkActiveLineColor');

  if (LightActiveLineColor <> default_lightactivelinecolor) then
    FIniFile.WriteInteger('Global', 'LightActiveLineColor', LightActiveLineColor)
  else
    FIniFile.DeleteKey('Global', 'LightActiveLineColor');

  FIniFile.WriteInteger('Global', 'RestoreLastSession', Ord(FRestoreLastSession));
  FIniFile.WriteBool('ColorPalette', 'Visible', FShowColorPalette);
  FIniFile.WriteInteger('ColorPalette', 'Height', FColorPaletteHeight);

  FIniFile.EraseSection(LAST_OPENED_SECTION);
  for I := 0 to HistoryFileList.Count -1 do
  begin
    FIniFile.WriteString(LAST_OPENED_SECTION, InttoStr(I),
      HistoryFileList.strings[i]);
  end;
  FIniFile.EraseSection(FILES_OPENED_SECTION);
  for I := 0 to OpenedFileList.Count -1 do
  begin
    FIniFile.WriteString(FILES_OPENED_SECTION, InttoStr(I),
      OpenedFileList.strings[i]);
  end;
  FIniFile.WriteString('Global', 'CurrentFileName', CurrentFileName);
  WriteSynEditorOptions(ASynEditorOptions);
end;

procedure TEditorSettings.WriteSynEditorOptions(
  const ASynEditorOptions: TSynEditorOptionsContainer);

  procedure WriteEditorOptions(const AName: string; const AValue: TSynEditorOption);
  begin
    FIniFile.WriteBool(EDITOPTION_OPTIONS, AName, AValue in ASynEditorOptions.Options);
  end;

  procedure WriteEditorScrollOptions(const AName: string;
    const AValue: TSynEditorScrollOption);
  begin
    FIniFile.WriteBool(EDITOPTION_OPTIONS, AName, AValue in ASynEditorOptions.ScrollOptions);
  end;

begin
  if not Assigned(ASynEditorOptions) then
    Exit;
  //Gutter
  FIniFile.WriteBool(EDITOPTION_GUTTER, 'Visible', ASynEditorOptions.Gutter.Visible);
  FIniFile.WriteBool(EDITOPTION_GUTTER, 'AutoSize', ASynEditorOptions.Gutter.AutoSize);
  FIniFile.WriteBool(EDITOPTION_GUTTER, 'ShowLineNumbers', ASynEditorOptions.Gutter.ShowLineNumbers);
  FIniFile.WriteBool(EDITOPTION_GUTTER, 'LeadingZeros', ASynEditorOptions.Gutter.LeadingZeros);
  FIniFile.WriteBool(EDITOPTION_GUTTER, 'ZeroStart', ASynEditorOptions.Gutter.ZeroStart);
  FIniFile.WriteBool(EDITOPTION_GUTTER, 'UseFontStyle', ASynEditorOptions.Gutter.UseFontStyle);
  FIniFile.WriteString(EDITOPTION_GUTTER, 'Font.Name', ASynEditorOptions.Gutter.Font.Name);
  FIniFile.WriteInteger(EDITOPTION_GUTTER, 'Font.Size', ASynEditorOptions.Gutter.Font.Size);
  //Right Edge
  FIniFile.WriteInteger(EDITOPTION_RIGHTEDGE,'RightEdge', ASynEditorOptions.RightEdge);
  //Line Spacing
  FIniFile.WriteInteger(EDITOPTION_LINESPACING,'ExtraLineSpacing', ASynEditorOptions.ExtraLineSpacing);
  FIniFile.WriteInteger(EDITOPTION_LINESPACING,'TabWidth', ASynEditorOptions.TabWidth);
  //Bookmarks
  FIniFile.WriteBool(EDITOPTION_BOOKMARK,'EnableKeys', ASynEditorOptions.BookMarkOptions.EnableKeys);
  FIniFile.WriteBool(EDITOPTION_BOOKMARK,'GlyphsVisible', ASynEditorOptions.BookMarkOptions.GlyphsVisible);
  WriteEditorOptions('AutoIndent', eoAutoIndent);
  WriteEditorOptions('DragDropEditing',  eoDragDropEditing);
  WriteEditorOptions('SmartTabs',  eoSmartTabs);
  WriteEditorScrollOptions('HalfPageScroll',  eoHalfPageScroll);
  WriteEditorScrollOptions('ScrollByOneLess',  eoScrollByOneLess);
  WriteEditorScrollOptions('ScrollPastEof',  eoScrollPastEof);
  WriteEditorScrollOptions('ScrollPastEol',  eoScrollPastEol);
  WriteEditorScrollOptions('ShowScrollHint',  eoShowScrollHint);
  WriteEditorOptions('TabsToSpaces',  eoTabsToSpaces);
  WriteEditorOptions('TrimTrailingSpaces',  eoTrimTrailingSpaces);
  WriteEditorOptions('KeepCaretX',  eoKeepCaretX);
  WriteEditorOptions('SmartTabDelete',  eoSmartTabDelete);
  WriteEditorOptions('RightMouseMovesCursor',  eoRightMouseMovesCursor);
  WriteEditorOptions('EnhanceHomeKey',  eoEnhanceHomeKey);
  WriteEditorOptions('EnhanceEndKey',  eoEnhanceEndKey);
  WriteEditorOptions('GroupUndo',  eoGroupUndo);
  WriteEditorOptions('TabIndent',  eoTabIndent);
  WriteEditorScrollOptions('DisableScrollArrows',  eoDisableScrollArrows);
  WriteEditorScrollOptions('HideShowScrollbars',  eoHideShowScrollbars);
  FIniFile.WriteBool(EDITOPTION_OPTIONS, 'WantTabs', ASynEditorOptions.WantTabs);
  FIniFile.WriteBool(EDITOPTION_OPTIONS, 'WordWrap', ASynEditorOptions.WordWrap);
end;

{ TThemeAttribute }

class function TThemeAttribute.GetStyleAttributes(const AStyleName: string;
  out AThemeAttribute: TThemeAttribute): Boolean;
var
  LThemeAttribute: TThemeAttribute;
  LThemeType: TThemeType;
begin
  for LThemeAttribute in ThemeAttributes do
  begin
    if SameText(AStyleName, LThemeAttribute.StyleName) then
    begin
      AThemeAttribute := LThemeAttribute;
      Exit(True);
    end;
  end;
  Result := False;
  AThemeAttribute := nil;
{$IFNDEF DISABLE_STYLES}
  //Not classified yet: any VCL style available, except the system style
  //"Windows" (not a VCL style, as in SVGShellExtensions)
  if SameText(AStyleName, TStyleManager.SystemStyleName) or
    not StyleThemeType(AStyleName, LThemeType) then
    Exit;
  LThemeAttribute := TThemeAttribute.Create;
  LThemeAttribute.StyleName := AStyleName;
  LThemeAttribute.ThemeType := LThemeType;
  ThemeAttributes.Add(LThemeAttribute);
  AThemeAttribute := LThemeAttribute;
  Result := True;
{$ENDIF}
end;

procedure FreeThemesAttributes;
var
  LThemeAttribute: TThemeAttribute;
begin
  if Assigned(ThemeAttributes) then
  begin
    for LThemeAttribute in ThemeAttributes do
      LThemeAttribute.Free;
    FreeAndNil(ThemeAttributes);
  end;
end;

initialization
  InitDefaultThemesAttributes;

finalization
  FreeThemesAttributes;

end.
