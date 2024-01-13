{******************************************************************************}
{                                                                              }
{       SKIA Shell Extensions: Shell extensions for animated files             }
{       (Preview Panel, Thumbnail Icon, Lottie Editor)                         }
{                                                                              }
{       Copyright (c) 2022-2024 (Ethea S.r.l.)                                 }
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
{  The Original Code is:                                                       }
{  Delphi Preview Handler  https://github.com/RRUZ/delphi-preview-handler      }
{                                                                              }
{  The Initial Developer of the Original Code is Rodrigo Ruz V.                }
{  Portions created by Rodrigo Ruz V. are Copyright 2011-2021 Rodrigo Ruz V.   }
{  All Rights Reserved.                                                        }
{******************************************************************************}

unit PreviewForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, SynEdit,
  System.Generics.Collections,
  SynEditHighlighter,
  ComCtrls, ToolWin, ImgList, SynHighlighterXML,
  Vcl.Menus, SynEditExport,
  SynExportHTML, SynExportRTF, SynEditMiscClasses,
  uSettings, System.ImageList, SynEditCodeFolding,
  Vcl.Skia.AnimatedImageEx,
  Vcl.WinXCtrls,
  SVGIconImageList, SVGIconImageListBase, SVGIconImage, Vcl.VirtualImageList,
  UPreviewContainer;

type
  TFrmPreview = class(TPreviewContainer)
    SynEdit: TSynEdit;
    PanelTop: TPanel;
    PanelEditor: TPanel;
    StatusBar: TStatusBar;
    SVGIconImageList: TVirtualImageList;
    ToolButtonZoomIn: TToolButton;
    ToolButtonZoomOut: TToolButton;
    ToolBar: TToolBar;
    ToolButtonSettings: TToolButton;
    ToolButtonAbout: TToolButton;
    ToolButtonShowText: TToolButton;
    ToolButtonReformat: TToolButton;
    ImagePanel: TPanel;
    Splitter: TSplitter;
    panelPreview: TPanel;
    BackgroundGrayScaleLabel: TLabel;
    BackgroundTrackBar: TTrackBar;
    ToolButtonPlay: TToolButton;
    ToolButtonInversePlay: TToolButton;
    ToolButtonPause: TToolButton;
    PlayerPanel: TPanel;
    RunLabel: TLabel;
    TrackBar: TTrackBar;
    ToolButtonStop: TToolButton;
    TogglePanel: TPanel;
    LoopToggleSwitch: TToggleSwitch;
    procedure FormCreate(Sender: TObject);
    procedure ToolButtonZoomInClick(Sender: TObject);
    procedure ToolButtonZoomOutClick(Sender: TObject);
    procedure ToolButtonSettingsClick(Sender: TObject);
    procedure ToolButtonAboutClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ToolButtonSelectModeClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ToolButtonShowTextClick(Sender: TObject);
    procedure ToolButtonReformatClick(Sender: TObject);
    procedure ToolButtonMouseEnter(Sender: TObject);
    procedure ToolButtonMouseLeave(Sender: TObject);
    procedure SplitterMoved(Sender: TObject);
    procedure BackgroundTrackBarChange(Sender: TObject);
    procedure SkAnimatedImageExMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ToolButtonPauseClick(Sender: TObject);
    procedure ToolButtonPlayClick(Sender: TObject);
    procedure ToolButtonInversePlayClick(Sender: TObject);
    procedure TrackBarChange(Sender: TObject);
    procedure LoopToggleSwitchClick(Sender: TObject);
    procedure ToolButtonStopClick(Sender: TObject);
  private
    SkAnimatedImageEx: TSkAnimatedImageEx;
    FFontSize: Integer;
    FSimpleText: string;
    FPreviewSettings: TPreviewSettings;

    class var FExtensions: TDictionary<TSynCustomHighlighterClass, TStrings>;
    class var FAParent: TWinControl;

    procedure UpdateRunLabel;
    function DialogPosRect: TRect;
    procedure AppException(Sender: TObject; E: Exception);
    procedure UpdateGUI;
    procedure UpdateFromSettings;
    procedure SaveSettings;
    procedure SetEditorFontSize(const Value: Integer);
    procedure UpdateHighlighter;
    procedure SkAnimatedImageAnimationProcess(Sender: TObject);
    procedure StartAnimation(const AFromBegin: Boolean;
      AInverse: Boolean = False);
    procedure PauseAnimation;
    procedure StopAnimation;
    procedure UpdateAnimButtons;
  protected
  public
    procedure ScaleControls(const ANewPPI: Integer);
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class property Extensions: TDictionary<TSynCustomHighlighterClass, TStrings> read FExtensions write FExtensions;
    class property AParent: TWinControl read FAParent write FAParent;
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromStream(const AStream: TStream);
    property EditorFontSize: Integer read FFontSize write SetEditorFontSize;
  end;


implementation

uses
  SynEditTypes
  , System.Math
  , Vcl.Clipbrd
{$IFNDEF DISABLE_STYLES}
  , Vcl.Themes
{$ENDIF}
  , uLogExcept
  , System.Types
  , Registry
  , uMisc
  , IOUtils
  , ShellAPI
  , ComObj
  , IniFiles
  , GraphUtil
  , uAbout
  , Xml.XMLDoc
  , SettingsForm
  , DResources
  ;

{$R *.dfm}

  { TFrmPreview }

procedure TFrmPreview.AppException(Sender: TObject; E: Exception);
begin
  // log unhandled exceptions (TSynEdit, etc)
  TLogPreview.Add(Format('Error: AppException: %s',[E.Message]));
end;

procedure TFrmPreview.BackgroundTrackBarChange(Sender: TObject);
var
  LValue: byte;
begin
  LValue := BackgroundTrackBar.Position;
  BackgroundGrayScaleLabel.Caption := Format(
    Background_Grayscale_Caption,
    [LValue * 100 div 255]);
  ImagePanel.Color := RGB(LValue, LValue, LValue);
  FPreviewSettings.LightBackground := BackgroundTrackBar.Position;
end;

constructor TFrmPreview.Create(AOwner: TComponent);
begin
  inherited;
  FPreviewSettings := TPreviewSettings.CreateSettings(SynEdit.Highlighter);
  dmResources := TdmResources.Create(nil);
end;

destructor TFrmPreview.Destroy;
begin
  FreeAndNil(FPreviewSettings);
  FreeAndNil(dmResources);
  inherited;
end;

function TFrmPreview.DialogPosRect: TRect;
begin
  Result := ClientToScreen(ActualRect);
end;

procedure TFrmPreview.UpdateGUI;
begin
  if PanelEditor.Visible then
  begin
    Splitter.Top := PanelEditor.Top + PanelEditor.Height;
    Splitter.Visible := True;
    ToolButtonShowText.Caption := 'Hide Text';
    ToolButtonShowText.Hint := 'Hide content of file';
    ToolButtonShowText.ImageName := 'hide-text';
  end
  else
  begin
    Splitter.Visible := False;
    ToolButtonShowText.Caption := 'Show Text';
    ToolButtonShowText.Hint := 'Show content of file';
    ToolButtonShowText.ImageName := 'show-text';
  end;
  ToolButtonAbout.Visible := True;
  ToolButtonSettings.Visible := True;
  if ToolButtonShowText.Visible then
  begin
    ToolButtonReformat.Visible := PanelEditor.Visible;
    ToolButtonZoomIn.Visible := PanelEditor.Visible;
    ToolButtonZoomOut.Visible := PanelEditor.Visible;
  end
  else
  begin
    ToolButtonReformat.Visible := False;
    ToolButtonZoomIn.Visible := False;
    ToolButtonZoomOut.Visible := False;
  end;
end;

procedure TFrmPreview.UpdateHighlighter;
var
  LBackgroundColor: TColor;
begin
{$IFNDEF DISABLE_STYLES}
  LBackgroundColor := StyleServices.GetSystemColor(clWindow);
{$ELSE}
  LBackgroundColor := clWindow;
{$ENDIF}
  SynEdit.Highlighter := dmResources.GetSynHighlighter(
    FPreviewSettings.UseDarkStyle, LBackgroundColor);
  //Assegna i colori "custom" all'Highlighter
  FPreviewSettings.ReadSettings(SynEdit.Highlighter, nil);
  SynEdit.Gutter.Font.Name := SynEdit.Font.Name;
{$IFNDEF DISABLE_STYLES}
  SynEdit.Gutter.Font.Color := StyleServices.GetSystemColor(clWindowText);
  SynEdit.Gutter.Color := StyleServices.GetSystemColor(clBtnFace);
{$ELSE}
  SynEdit.Gutter.Font.Color := clWindowText;
  SynEdit.Gutter.Color := clBtnFace;
{$ENDIF}
end;

procedure TFrmPreview.UpdateRunLabel;
begin
  RunLabel.Caption := SkAnimatedImageEx.ProgressPercentage.ToString+' %';
end;

procedure TFrmPreview.FormCreate(Sender: TObject);
var
  FileVersionStr: string;
begin
  inherited;
  TLogPreview.Add('TFrmPreview.FormCreate');
  FileVersionStr := uMisc.GetFileVersion(GetModuleLocation());
  FSimpleText := Format(StatusBar.SimpleText,
    [FileVersionStr, {$IFDEF WIN32}32{$ELSE}64{$ENDIF}]);
  StatusBar.SimpleText := FSimpleText;
  //Build animated preview images
  SkAnimatedImageEx := TSkAnimatedImageEx.Create(Self);
  try
    SkAnimatedImageEx.AlignWithMargins := True;
    SkAnimatedImageEx.Parent := ImagePanel;
    SkAnimatedImageEx.Align := alClient;
    SkAnimatedImageEx.OnMouseMove := SkAnimatedImageExMouseMove;
    SkAnimatedImageEx.OnAnimationProcess := SkAnimatedImageAnimationProcess;
  except
    SkAnimatedImageEx.Free;
    raise;
  end;
  Application.OnException := AppException;
  UpdateFromSettings;
end;

procedure TFrmPreview.FormDestroy(Sender: TObject);
begin
  StopAnimation;
  HideAboutForm;
  SaveSettings;
  TLogPreview.Add('TFrmPreview.FormDestroy');
  inherited;
end;

procedure TFrmPreview.FormResize(Sender: TObject);
begin
  PanelEditor.Height := Round(Self.Height * (FPreviewSettings.SplitterPos / 100));
  Splitter.Top := PanelEditor.Height;
(*
  if Self.Width < (550 * Self.ScaleFactor) then
    ToolBar.ShowCaptions := False
  else
    Toolbar.ShowCaptions := True;
*)
  UpdateGUI;
end;

procedure TFrmPreview.LoadFromFile(const AFileName: string);
begin
  //Not implemented: using stream!
end;

procedure TFrmPreview.LoadFromStream(const AStream: TStream);
begin
  TLogPreview.Add('TFrmPreview.LoadFromStream Init');

  SkAnimatedImageEx.LoadFromStream(AStream);
  if SkAnimatedImageEx.IsAnimationFile then
  begin
    PlayerPanel.Enabled := True;
    //Load also text content
    try
      if SkAnimatedImageEx.IsLottieFile then
      begin
        AStream.Position := 0;
        SynEdit.Lines.LoadFromStream(AStream);
        ToolButtonPlay.Enabled := True;
        ToolButtonInversePlay.Enabled := True;
        ToolButtonShowText.Visible := True;
      end
      else
      begin
        PanelEditor.Visible := False;
        ToolButtonShowText.Visible := False;
      end;
    except
      on Exception do
      begin
        PanelEditor.Visible := False;
        ToolButtonShowText.Visible := False;
        raise;
      end;
    end;
  end
  else
  begin
    PlayerPanel.Enabled := False;
    ToolButtonPlay.Enabled := False;
    ToolButtonInversePlay.Enabled := False;
    ToolButtonShowText.Enabled := False;
  end;
  UpdateGUI;
  if SkAnimatedImageEx.IsAnimationFile and not SkAnimatedImageEx.IsStaticImage then
  begin
    if FPreviewSettings.AutoPlay then
      StartAnimation(True)
    else
      StopAnimation;
  end;
  TLogPreview.Add('TFrmPreview.LoadFromStream Done');
end;

procedure TFrmPreview.LoopToggleSwitchClick(Sender: TObject);
begin
  SkAnimatedImageEx.AnimationLoop := LoopToggleSwitch.State = tssOn;
end;

procedure TFrmPreview.SaveSettings;
begin
  if Assigned(FPreviewSettings) then
  begin
    FPreviewSettings.UpdateSettings(SynEdit.Font.Name,
      EditorFontSize,
      PanelEditor.Visible);
    FPreviewSettings.WriteSettings(SynEdit.Highlighter, nil);
  end;
end;

procedure TFrmPreview.ScaleControls(const ANewPPI: Integer);
var
  LCurrentPPI: Integer;
  LNewSize: Integer;
begin
  LCurrentPPI := FCurrentPPI;
  if ANewPPI <> LCurrentPPI then
  begin
    LNewSize := MulDiv(SVGIconImageList.Width, ANewPPI, LCurrentPPI);
    SVGIconImageList.SetSize(LNewSize, LNewSize);
  end;
end;

procedure TFrmPreview.SetEditorFontSize(const Value: Integer);
var
  LScaleFactor: Single;
begin
  if (Value >= MinfontSize) and (Value <= MaxfontSize) then
  begin
    TLogPreview.Add('TFrmPreview.SetEditorFontSize'+
      ' CurrentPPI: '+Self.CurrentPPI.ToString+
      ' ScaleFactor: '+ScaleFactor.ToString+
      ' Value: '+Value.ToString);
    if FFontSize <> 0 then
      LScaleFactor := SynEdit.Font.Size / FFontSize
    else
      LScaleFactor := 1;
    FFontSize := Value;
    SynEdit.Font.Size := Round(FFontSize * LScaleFactor);
    SynEdit.Gutter.Font.Size := SynEdit.Font.Size;
  end;
end;

procedure TFrmPreview.SplitterMoved(Sender: TObject);
begin
  FPreviewSettings.SplitterPos := splitter.Top * 100 div
    (Self.Height - Toolbar.Height);
  SaveSettings;
end;

procedure TFrmPreview.ToolButtonShowTextClick(Sender: TObject);
begin
  PanelEditor.Height := Self.Height div 3;
  PanelEditor.Visible := not PanelEditor.Visible;
  UpdateGUI;
  SaveSettings;
end;

procedure TFrmPreview.ToolButtonStopClick(Sender: TObject);
begin
  StopAnimation;
end;

procedure TFrmPreview.ToolButtonInversePlayClick(Sender: TObject);
begin
  inherited;
  StartAnimation(False, True);
end;

procedure TFrmPreview.ToolButtonAboutClick(Sender: TObject);
begin
  ShowAboutForm(DialogPosRect, Title_SKIAPreview);
end;

procedure TFrmPreview.ToolButtonMouseEnter(Sender: TObject);
begin
  StatusBar.SimpleText := (Sender as TToolButton).Hint;
end;

procedure TFrmPreview.ToolButtonMouseLeave(Sender: TObject);
begin
  StatusBar.SimpleText := FSimpleText;
end;

procedure TFrmPreview.ToolButtonPauseClick(Sender: TObject);
begin
  PauseAnimation;
end;

procedure TFrmPreview.UpdateAnimButtons;
begin
  ToolButtonPlay.Enabled := SkAnimatedImageEx.CanPlayAnimation or
    SkAnimatedImageEx.AnimationRunningInverse;
  ToolButtonInversePlay.Enabled := SkAnimatedImageEx.CanPlayAnimation or
    SkAnimatedImageEx.AnimationRunningNormal;
  ToolButtonPause.Enabled := SkAnimatedImageEx.CanPauseAnimation;
  ToolButtonStop.Enabled := SkAnimatedImageEx.CanStopAnimation;
end;

procedure TFrmPreview.PauseAnimation;
begin
  SkAnimatedImageEx.PauseAnimation;
  UpdateAnimButtons;
end;

procedure TFrmPreview.StartAnimation(const AFromBegin: Boolean;
  AInverse: Boolean = False);
begin
  SkAnimatedImageEx.StartAnimation(AFromBegin, AInverse);
  UpdateAnimButtons;
end;

procedure TFrmPreview.StopAnimation;
begin
  SkAnimatedImageEx.StopAnimation;
  UpdateAnimButtons;
end;

procedure TFrmPreview.ToolButtonPlayClick(Sender: TObject);
begin
  StartAnimation(False);
end;

procedure TFrmPreview.ToolButtonReformatClick(Sender: TObject);
var
  OldText, NewText : string;
begin
  //format JSON text
  OldText := SynEdit.Lines.Text;
  NewText := ReformatJSON(OldText);
  if OldText <> NewText then
    SynEdit.Lines.Text := NewText;
end;

procedure TFrmPreview.UpdateFromSettings;
begin
  FPreviewSettings.ReadSettings(SynEdit.Highlighter, nil);
  if FPreviewSettings.FontSize >= MinfontSize then
    EditorFontSize := FPreviewSettings.FontSize
  else
    EditorFontSize := MinfontSize;
  SynEdit.Font.Name := FPreviewSettings.FontName;
  PanelEditor.Visible := FPreviewSettings.ShowEditor;
{$IFNDEF DISABLE_STYLES}
  TStyleManager.TrySetStyle(FPreviewSettings.StyleName, False);
{$ENDIF}
  BackgroundTrackBar.Position := FPreviewSettings.LightBackground;
  UpdateHighlighter;
  UpdateGUI;
  LoopToggleSwitch.State := TToggleSwitchState(Ord(FPreviewSettings.PlayInLoop));
  if FPreviewSettings.AutoPlay and SkAnimatedImageEx.CanPlayAnimation then
    StartAnimation(False)
  else if not FPreviewSettings.AutoPlay and SkAnimatedImageEx.CanStopAnimation then
    StopAnimation;
end;

procedure TFrmPreview.ToolButtonSettingsClick(Sender: TObject);
begin
  if ShowSettings(DialogPosRect, Title_SKIAPreview, SynEdit, FPreviewSettings, True) then
  begin
    FPreviewSettings.WriteSettings(SynEdit.Highlighter, nil);
    UpdateFromSettings;
  end;
end;

procedure TFrmPreview.ToolButtonSelectModeClick(Sender: TObject);
begin
  TToolButton(Sender).CheckMenuDropdown;
end;

procedure TFrmPreview.ToolButtonZoomOutClick(Sender: TObject);
begin
  EditorFontSize := EditorFontSize - 1;
  SaveSettings;
end;

procedure TFrmPreview.ToolButtonZoomInClick(Sender: TObject);
begin
  EditorFontSize := EditorFontSize + 1;
  SaveSettings;
end;

procedure TFrmPreview.TrackBarChange(Sender: TObject);
begin
  SkAnimatedImageEx.ProgressPercentage := TrackBar.Position;
  UpdateRunLabel;
end;

procedure TFrmPreview.SkAnimatedImageAnimationProcess(Sender: TObject);
var
  LPos: Integer;
begin
  TrackBar.OnChange := nil;
  Try
    LPos := SkAnimatedImageEx.ProgressPercentage;
    if LPos <> TrackBar.Position then
      TrackBar.Position := LPos;
    UpdateRunLabel;
    UpdateAnimButtons;
  Finally
    TrackBar.OnChange := TrackBarChange;
  End;
end;

procedure TFrmPreview.SkAnimatedImageExMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  LSize: Integer;
  LSkAnimatedImageEx: TSkAnimatedImageEx;
begin
  LSkAnimatedImageEx := Sender as TSkAnimatedImageEx;
  LSize := Min(LSkAnimatedImageEx.Width, LSkAnimatedImageEx.Height);
  LSkAnimatedImageEx.Hint := Format('%dx%d',[LSize, LSize]);
end;

end.
