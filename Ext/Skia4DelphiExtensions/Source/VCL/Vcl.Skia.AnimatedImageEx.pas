{******************************************************************************}
{                                                                              }
{       VCL Skia4Delphi Extensions: extended Controls of Skia4Delphi/VCL       }
{       to simplify use animations                                             }
{                                                                              }
{       Copyright (c) 2022-2023 (Ethea S.r.l.)                                 }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Skia4DelphiExtensions                      }
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
unit Vcl.Skia.AnimatedImageEx;

interface

uses
  System.Types
  , System.Classes
  , Winapi.Windows
  , Winapi.Messages
  , Vcl.Graphics
  , Vcl.Controls
  , Vcl.ExtCtrls
  , System.Skia
  , Vcl.Skia
  ;

type
  TSkAnimatedImageEx = class(TSkAnimatedImage)
  private
    FFileName: string;
    FLottieText: string;
    function GetProgressPercentage: SmallInt;
    procedure SetProgressPercentage(const AValue: SmallInt);
    function GetProgress: Double;
    procedure SetProgress(const AValue: Double);
    function GetLottieText: string;
    procedure SetLottieText(const AValue: string);
    function GetLoop: Boolean;
    procedure SetLoop(const Value: Boolean);
    procedure SetFileName(const AValue: string);
    function GetAnimationIsRunning: Boolean;
    procedure SetAnimationIsRunning(const AValue: Boolean);
    function GetIsStaticImage: Boolean;
    procedure UpdateLottieText;
  public
    destructor Destroy; override;
    procedure RenderFrame(const ACanvas: ISkCanvas; const ADest: TRectF;
      const AProgress: Double; const AOpacity: Single); override;
    constructor Create(AOwner: TComponent); override;
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromStream(const AStream: TStream);
    procedure LoadFromFileAndStart(const AFileName: string;
      const AAutoStart: Boolean = True);
    procedure LoadFromStreamAndStart(const AStream: TStream;
      const AAutoStart: Boolean = True);
    procedure ClearImage;
    //function Animation: TAnimation;
    function AnimationLoaded: Boolean;
    function AnimationRunning: Boolean;
    function AnimationRunningNormal: Boolean;
    function AnimationRunningInverse: Boolean;
    function CanPlayAnimation: Boolean;
    function CanPauseAnimation: Boolean;
    function CanStopAnimation: Boolean;
    function CanResumeAnimation: Boolean;
    procedure ResumeAnimation;
    procedure StartAnimation(const AFromBegin: Boolean = True;
      AInverse: Boolean = False);
    procedure PauseAnimation;
    procedure StopAnimation;
    function IsAnimationFile: Boolean;
    function IsLottieFile: Boolean;
    function GetFormatInfo(out AFormat: TSkAnimatedImage.TFormatInfo): Boolean;
    property IsStaticImage: Boolean read GetIsStaticImage;
    procedure RenderTo(ACanvas: TCanvas; ARect: TRectF; AProgress: Integer; AOpacity: Single);
  published
    property AnimationIsRunning: Boolean read GetAnimationIsRunning write SetAnimationIsRunning;
    property FileName: string read FFileName write SetFileName;
    property LottieText: string read GetLottieText write SetLottieText;
    property AnimationLoop: Boolean read GetLoop write SetLoop;
    property AnimationProgress: Double read GetProgress write SetProgress;
    property ProgressPercentage: SmallInt read GetProgressPercentage write SetProgressPercentage;
  end;

implementation

uses
  System.SysUtils
  , System.IOUtils
  , System.Math
  , System.Math.Vectors
  , System.UITypes
  , Vcl.Forms
  ;

{ TSkAnimatedImageEx }

function TSkAnimatedImageEx.AnimationRunning: Boolean;
begin
  Result := AnimationLoaded and Animation.Enabled and Animation.Running;
end;

function TSkAnimatedImageEx.AnimationRunningInverse: Boolean;
begin
  Result := AnimationRunning and Animation.Inverse;
end;

function TSkAnimatedImageEx.AnimationRunningNormal: Boolean;
begin
  Result := AnimationRunning and not Animation.Inverse;
end;

function TSkAnimatedImageEx.CanPauseAnimation: Boolean;
begin
  Result := AnimationRunning;
end;

function TSkAnimatedImageEx.CanPlayAnimation: Boolean;
begin
  Result := AnimationLoaded and not Animation.Running;
end;

function TSkAnimatedImageEx.CanResumeAnimation: Boolean;
begin
  Result := AnimationLoaded and not AnimationRunning and
    (Animation.Progress <> 0) and
    (Animation.Loop or (Animation.Progress <> 1));
end;

function TSkAnimatedImageEx.CanStopAnimation: Boolean;
begin
  Result := AnimationRunning;
end;

procedure TSkAnimatedImageEx.ClearImage;
begin
  Source.Data := [];
end;

function TSkAnimatedImageEx.AnimationLoaded: Boolean;
begin
  Result := (Length(Source.Data) > 0) and Assigned(Codec) and
    not Codec.Isstatic;
end;

function TSkAnimatedImageEx.GetProgressPercentage: SmallInt;
begin
  Result := Round(inherited Animation.Progress * 100);
end;

procedure TSkAnimatedImageEx.SetProgress(const AValue: Double);
var
  LEvent: TNotifyEvent;
begin
  if Assigned(OnAnimationProcess) then
    LEvent := OnAnimationProcess
  else
    LEvent := nil;
  OnAnimationProcess := nil;
  Try
    Animation.Stop;
    Animation.Progress := AValue;
  Finally
    if Assigned(LEvent) then
      OnAnimationProcess := LEvent;
  End;
end;

function TSkAnimatedImageEx.GetLoop: Boolean;
begin
  Result := Animation.Loop;
end;

function TSkAnimatedImageEx.GetLottieText: string;
begin
  Result := FLottieText;
end;

function TSkAnimatedImageEx.GetProgress: Double;
begin
  Result := inherited Animation.Progress;
end;

procedure TSkAnimatedImageEx.SetProgressPercentage(const AValue: SmallInt);
begin
  Animation.Progress := AValue / 100;
end;

procedure TSkAnimatedImageEx.SetLoop(const Value: Boolean);
begin
  Animation.Loop := Value;
end;

procedure TSkAnimatedImageEx.SetLottieText(const AValue: string);
var
  LStringStream: TStringStream;
  LOldLoop: Boolean;
begin
  LOldLoop := Loop;
  Animation.Loop := False;
  try
    inherited Animation.Progress := 1;
    if AValue <> '' then
    begin
      LStringStream := TStringStream.Create(AValue, TEncoding.UTF8);
      try
        LStringStream.Position := 0;
        LoadFromStream(LStringStream);
        FLottieText := AValue;
      finally
        LStringStream.Free;
      end;
      Redraw;
    end
    else
    begin
      FLottieText := '';
      ClearImage;
    end;
  finally
    Animation.Loop := LOldLoop;
  end;
end;

procedure TSkAnimatedImageEx.StartAnimation(const AFromBegin: Boolean = True;
  AInverse: Boolean = False);
begin
  Animation.StartFromCurrent := not AFromBegin;

  if not AInverse and (Animation.Progress = 1) then
    inherited Animation.Progress := 0
  else if AInverse and (Animation.Progress = 0) then
    inherited Animation.Progress := 1;
  Animation.Inverse := AInverse;
  if not Animation.Running then
    Animation.Start;
end;

procedure TSkAnimatedImageEx.StopAnimation;
begin
  Animation.Stop;
  inherited Animation.Progress := 1;
end;

procedure TSkAnimatedImageEx.RenderTo(ACanvas: TCanvas; ARect: TRectF;
  AProgress: Integer; AOpacity: Single);
var
  LBitmap: TBitmap;
  LRect: TRectF;
  LTop, LLeft, LWidth, LHeight: Integer;
begin
  ACanvas.Lock;
  try
    Animation.Progress := AProgress;
    LTop := Round(ARect.Top);
    LLeft := Round(ARect.Left);
    LWidth := Round(ARect.Width);
    LHeight := Round(ARect.Height);
    LBitmap := TBitmap.Create;
    try
      LBitmap.PixelFormat := pf32bit;
      LBitmap.AlphaFormat := afPremultiplied;
      LBitmap.SetSize(LWidth, LHeight);
      LRect := TRect.Create(0,0,LWidth, LHeight);
      LBitmap.SkiaDraw(
        procedure (const ACanvas: ISkCanvas)
        begin
          RenderFrame(ACanvas, LRect, GetProgress, AOpacity);
        end
        );
        ACanvas.Draw(LTop, LLeft, LBitmap);
    finally
      LBitmap.Free;
    end;
  finally
    ACanvas.Unlock;
  end;
end;

procedure TSkAnimatedImageEx.PauseAnimation;
begin
  Animation.StopAtCurrent;
end;

procedure TSkAnimatedImageEx.RenderFrame(const ACanvas: ISkCanvas;
  const ADest: TRectF; const AProgress: Double; const AOpacity: Single);
begin
  inherited RenderFrame(ACanvas, ADest, AProgress, AOpacity);
end;

procedure TSkAnimatedImageEx.ResumeAnimation;
begin
  Animation.StartFromCurrent := True;
  Animation.start;
end;

constructor TSkAnimatedImageEx.Create(AOwner: TComponent);
begin
  inherited;
  Animation.Loop := False;
end;

destructor TSkAnimatedImageEx.Destroy;
begin
  ;
  inherited;
end;

procedure TSkAnimatedImageEx.SetFileName(const AValue: string);
begin
  if FFileName <> AValue then
    LoadFromFile(AValue);
end;

function TSkAnimatedImageEx.IsLottieFile: Boolean;
var
  LFormat: TSkAnimatedImage.TFormatInfo;
begin
  if GetFormatInfo(LFormat) then
    Result := SameText(LFormat.Name, 'Lottie')
  else
    Result := False;
end;

procedure TSkAnimatedImageEx.LoadFromFile(const AFileName: string);
begin
  inherited LoadFromFile(AFileName);
  FFileName := AFileName;
  UpdateLottieText;
end;

procedure TSkAnimatedImageEx.UpdateLottieText;
var
  LStringStream: TStringStream;
  LStream: TBytesStream;
begin
  if IsLottieFile then
  begin
    LStream := TBytesStream.Create(Source.Data);
    Try
      LStream.Position := 0;
      LStringStream := TStringStream.Create('', TEncoding.UTF8);
      try
        LStringStream.LoadFromStream(LStream);
        FLottieText := LStringStream.DataString;
      finally
        LStringStream.Free;
      end;
    finally
      LStream.Free;
    end;
  end
  else
    FLottieText := '';
end;

procedure TSkAnimatedImageEx.LoadFromFileAndStart(const AFileName: string;
  const AAutoStart: Boolean = True);
var
  LOldLoop: Boolean;
begin
  LOldLoop := Loop;
  Animation.Loop := False;
  try
    Animation.Stop;
    Visible := True;
    if FileExists(AFileName) then
    begin
      LoadFromFile(AFileName);
      if AAutoStart then
        Animation.Start;
    end
    else
      ClearImage;
  finally
    AnimationLoop := LOldLoop;
  end;
end;

procedure TSkAnimatedImageEx.LoadFromStreamAndStart(const AStream: TStream;
  const AAutoStart: Boolean);
var
  LOldLoop: Boolean;
begin
  LOldLoop := Loop;
  Animation.Loop := False;
  try
    Animation.Stop;
    Visible := True;
    LoadFromStream(AStream);
    if AAutoStart then
      Animation.Start;
  finally
    AnimationLoop := LOldLoop;
  end;
end;

procedure TSkAnimatedImageEx.LoadFromStream(const AStream: TStream);
begin
  inherited LoadFromStream(AStream);
  FFileName := '';
  UpdateLottieText;
end;

function TSkAnimatedImageEx.GetAnimationIsRunning: Boolean;
begin
  Result := AnimationLoaded and Animation.Running;
end;

function TSkAnimatedImageEx.GetFormatInfo(out AFormat: TSkAnimatedImage.TFormatInfo): Boolean;
var
  LCodec: TAnimationCodec;
begin
  LCodec := inherited Codec;
  if Assigned(LCodec) then
  begin
    LCodec.TryDetectFormat(Source.Data, AFormat);
    Result := True;
  end
  else
    Result := False;
end;

function TSkAnimatedImageEx.GetIsStaticImage: Boolean;
begin
  Result := Assigned(Codec) and Codec.IsStatic;
end;

function TSkAnimatedImageEx.IsAnimationFile: Boolean;
var
  LFormat: TSkAnimatedImage.TFormatInfo;
begin
  Result := GetFormatInfo(LFormat) and AnimationLoaded;
end;

procedure TSkAnimatedImageEx.SetAnimationIsRunning(const AValue: Boolean);
begin
  if AValue And AnimationLoaded then
    StartAnimation
  else
    StopAnimation;
end;

end.
