{******************************************************************************}
{                                                                              }
{       Skia.Vcl.AnimatedBrush: Brush Control for Animation of Skia4Delphi/VCL }
{       to simplify use of animations commands and control                     }
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
unit Skia.Vcl.AnimatedBrush;

interface

uses
  System.Types
  , System.Classes
  , Winapi.Windows
  , Winapi.Messages
  , Vcl.Graphics
  , Vcl.Controls
  , Vcl.ExtCtrls
  , Skia
  , Skia.Vcl
  ;

type
  TWinControlAccess = class(TWinControl);

  TSkAnimatedImageBrush = class(TPersistent)
  protected type
    TAnimation = class(TSkCustomAnimation)
    strict private
      FInsideDoProcess: Boolean;
    protected
      procedure DoChanged; override;
      procedure DoFinish; override;
      procedure DoProcess; override;
      procedure DoStart; override;
    end;

  //TSkCustomControl strict private
  strict private
    FBackgroundBuffer: TBitmap;
    FDrawBuffer: HBITMAP;
    FDrawBufferData: Pointer;
    FDrawBufferStride: Integer;
    FDrawCached: Boolean;
    FDrawCacheKind: TSkDrawCacheKind;
    FDrawParentInBackground: Boolean;
    FOnDraw: TSkDrawEvent;

    FCodec: TSkAnimatedImage.TAnimationCodec;
    FSource: TSkAnimatedImage.TSource;
    FWrapMode: TSkAnimatedImageWrapMode;
    FAbsoluteVisible: Boolean;
    FAbsoluteVisibleCached: Boolean;
    FOnAnimationDraw: TSkAnimationDrawEvent;
    FOnAnimationFinish: TNotifyEvent;
    FOnAnimationProcess: TNotifyEvent;
    FOnAnimationStart: TNotifyEvent;
    FScaleFactor: Single;
    FProgress: Double;
    FProgressChangedManually: Boolean;
    FLottieText: string;

    //Parent Control and his Canvas for animation
    FTargetControl: TWinControl;
    FTargetCanvas: TCanvas;

    FTargetRect: TRectF;
    FTargetOpacity: Single;
    FLeft, FTop, FWidth, FHeight: Integer;
    procedure CheckAbsoluteVisible;
    procedure CheckDuration;
    {$IF CompilerVersion >= 34}
    procedure CMParentVisibleChanged(var AMessage: TMessage); message CM_PARENTVISIBLECHANGED;
    {$ELSE}
    procedure CMShowingChanged(var AMessage: TMessage); message CM_SHOWINGCHANGED;
    {$ENDIF}
    procedure CMVisibleChanged(var AMessage: TMessage); message CM_VISIBLECHANGED;
    function GetAbsoluteVisible: Boolean;

    function NeedsRedraw: Boolean; virtual;
    function GetLottieText: string;
    procedure SetLottieText(const AValue: string);

    procedure SetDrawCacheKind(const AValue: TSkDrawCacheKind);
    procedure SetDrawParentInBackground(const AValue: Boolean);
    procedure CreateBuffer(const AMemDC: HDC; out ABuffer: HBITMAP; out AData: Pointer; out AStride: Integer);
    procedure DeleteBuffers;
    function GetOpaqueParent: TWinControl;
    procedure DrawParentImage(ADC: HDC; AInvalidateParent: Boolean = False);
    procedure SetProgress(AValue: Double);
    function GetAnimationIsRunning: Boolean;
    procedure SetAnimationIsRunning(const AValue: Boolean);
    function GerParent: TWinControl;
    function GetAnimation: TAnimation;
    procedure SetAnimation(const AValue: TAnimation);
  strict protected
    //TSkCustomAnimatedControl strict protected
    FAnimation: TAnimation;

    //TSkAnimatedImage strict protected
    function CreateAnimation: TAnimation; virtual;
    function CanRunAnimation: Boolean; virtual;
    procedure CheckAnimation;
    procedure DoAnimationChanged; virtual;
    procedure DoAnimationFinish; virtual;
    procedure DoAnimationProcess; virtual;
    procedure DoAnimationStart; virtual;
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); virtual;
    function GetDuration: Double; virtual;
    procedure RenderFrame(const ACanvas: ISkCanvas; const ADest: TRectF; const AProgress: Double; const AOpacity: Single); virtual;
    procedure SourceChange; virtual;
    property AbsoluteVisible: Boolean read GetAbsoluteVisible;
    property Duration: Double read GetDuration;
    property Progress: Double read FProgress write SetProgress;
    procedure UpdateLottieText;
    procedure Resize(R: TRectF);
    procedure Paint(DC: HDC; AOpacity: Single);

    property DrawCacheKind: TSkDrawCacheKind read FDrawCacheKind write SetDrawCacheKind default TSkDrawCacheKind.Raster;
    property DrawParentInBackground: Boolean read FDrawParentInBackground write SetDrawParentInBackground;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromStream(const AStream: TStream);
    procedure PaintTo(ACanvas: TCanvas; ARect: TRect; AProgress: Integer;
      AOpacity: Single); overload;
    procedure PaintTo(DC: HDC; R: TRectF; KeepAspectRatio: Boolean; AOpacity: Single); overload;
    procedure AnimateTo(AControl: TWinControl; ACanvas: TCanvas; R: TRectF; AOpacity: Single;
       ALoop: Boolean = False);

    procedure Repaint;
    procedure ClearImage;
    procedure StartAnimation(const ALoop: Boolean);
    procedure PauseAnimation;
    procedure StopAnimation;
    procedure ResumeAnimation;
    function AnimationLoaded: Boolean;
    function CanPlayAnimation: Boolean;
    function CanPauseAnimation: Boolean;
    function CanStopAnimation: Boolean;
    function CanResumeAnimation: Boolean;

    function IsAnimationFile: Boolean;
    function IsLottieFile: Boolean;
    function GetFormatInfo(out AFormat: TSkAnimatedImage.TFormatInfo): Boolean;

    property AnimationIsRunning: Boolean read GetAnimationIsRunning write SetAnimationIsRunning;
    property LottieText: string read GetLottieText write SetLottieText;
    property Animation: TAnimation read GetAnimation write SetAnimation;
    property Source: TSkAnimatedImage.TSource read FSource;
    property Parent: TWinControl read GerParent;
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

function IsSameBytes(const ALeft, ARight: TBytes): Boolean;
begin
  Result := (ALeft = ARight) or
    ((Length(ALeft) = Length(ARight)) and
    ((Length(ALeft) = 0) or CompareMem(PByte(@ALeft[0]), PByte(@ARight[0]), Length(ALeft))));
end;

function PlaceIntoTopLeft(const ASourceRect, ADesignatedArea: TRectF): TRectF;
begin
  Result := ASourceRect;
  if (ASourceRect.Width > ADesignatedArea.Width) or (ASourceRect.Height > ADesignatedArea.Height) then
    Result := Result.FitInto(ADesignatedArea);
  Result.SetLocation(ADesignatedArea.TopLeft);
end;

{ TSkAnimatedImageBrush }

function TSkAnimatedImageBrush.CanResumeAnimation: Boolean;
begin
  Result := AnimationLoaded and not Animation.Running and
    (Animation.Progress <> 0) and
    (Animation.Loop or (Animation.Progress <> 1));
end;

function TSkAnimatedImageBrush.CanRunAnimation: Boolean;
begin
  Result := AbsoluteVisible and (FWidth > 0) and (FHeight > 0);
end;

procedure TSkAnimatedImageBrush.CheckAbsoluteVisible;
begin
  FAbsoluteVisibleCached := False;
  if Assigned(FAnimation) and FAnimation.Loop and FAnimation.Running and (not FAbsoluteVisible) and AbsoluteVisible then
    FAnimation.Start;
  CheckAnimation;
end;

procedure TSkAnimatedImageBrush.CheckAnimation;
begin
  if Assigned(FAnimation) then
    FAnimation.AllowAnimation := CanRunAnimation;
end;

procedure TSkAnimatedImageBrush.CheckDuration;
begin
  if Assigned(FAnimation) then
  begin
    if SameValue(FAnimation.Duration, 0, TAnimation.TimeEpsilon) then
      DrawCacheKind := TSkDrawCacheKind.Raster
    else
      DrawCacheKind := TSkDrawCacheKind.Never;
  end;
end;

{$IF CompilerVersion >= 34}

procedure TSkAnimatedImageBrush.CMParentVisibleChanged(
  var AMessage: TMessage);
begin
  CheckAbsoluteVisible;
  inherited;
end;

{$ELSE}

procedure TSkAnimatedImageBrush.CMShowingChanged(var AMessage: TMessage);
begin
  CheckAbsoluteVisible;
  inherited;
end;
{$ENDIF}

procedure TSkAnimatedImageBrush.CMVisibleChanged(var AMessage: TMessage);
begin
  CheckAbsoluteVisible;
  inherited;
end;

procedure TSkAnimatedImageBrush.DoAnimationChanged;
begin
  CheckDuration;
end;

procedure TSkAnimatedImageBrush.DoAnimationFinish;
begin
  if Assigned(FOnAnimationFinish) then
    FOnAnimationFinish(Self);
  FProgressChangedManually := False;
end;

procedure TSkAnimatedImageBrush.DoAnimationProcess;
begin
  if Assigned(FOnAnimationProcess) then
    FOnAnimationProcess(Self);
end;

procedure TSkAnimatedImageBrush.DoAnimationStart;
begin
  if Assigned(FOnAnimationStart) then
    FOnAnimationStart(Self);
end;

procedure TSkAnimatedImageBrush.Draw(const ACanvas: ISkCanvas;
  const ADest: TRectF; const AOpacity: Single);
begin
  inherited;
  if not FAnimation.AllowAnimation then
    CheckAnimation;
  FAnimation.BeforePaint;
  RenderFrame(ACanvas, ADest, FAnimation.Progress, AOpacity);
end;

procedure TSkAnimatedImageBrush.DrawParentImage(ADC: HDC;
  AInvalidateParent: Boolean);

  function LocalToParent(const AParent: TWinControl): TPoint;
  var
    LControl: TWinControl;
  begin
    Result := Point(0, 0);
    if Parent = AParent then
    begin
      Result := Result + Parent.BoundsRect.TopLeft;
    end
    else
    begin
      LControl := Parent;
      repeat
        Result := Result + LControl.BoundsRect.TopLeft;
        LControl := LControl.Parent;
      until (LControl = AParent);
    end;
  end;

var
  LSaveIndex: Integer;
  LPoint: TPoint;
  LParentOffset: TPoint;
  LOpaqueParent: TWinControl;
begin
  LOpaqueParent := GetOpaqueParent;
  if LOpaqueParent = nil then
    Exit;
  LSaveIndex := SaveDC(ADC);
  GetViewportOrgEx(ADC, LPoint);
  LParentOffset := LocalToParent(LOpaqueParent);
  SetViewportOrgEx(ADC, LPoint.X - LParentOffset.X, LPoint.Y - LParentOffset.Y, nil);
  IntersectClipRect(ADC, 0, 0, LOpaqueParent.ClientWidth, LOpaqueParent.ClientHeight);
  LOpaqueParent.Perform(WM_ERASEBKGND, ADC, 0);
  LOpaqueParent.Perform(WM_PRINTCLIENT, ADC, prf_Client);
  RestoreDC(ADC, LSaveIndex);
  if AInvalidateParent and not (LOpaqueParent is TCustomControl) and
    not (LOpaqueParent is TCustomForm) and not (csDesigning in Parent.ComponentState) then
  begin
    LOpaqueParent.Invalidate;
  end;
end;

function TSkAnimatedImageBrush.GerParent: TWinControl;
begin
  Result := FTargetControl;
end;

function TSkAnimatedImageBrush.GetAbsoluteVisible: Boolean;
(*
  function GetParentedVisible: Boolean;
  var
    LControl: TWinControl;
  begin
    if not Visible then
      Exit(False);
    LControl := Parent;
    while LControl <> nil do
    begin
      if not LControl.Visible then
        Exit(False);
      LControl := LControl.Parent;
    end;
    Result := True;
  end;
*)
begin
  if not FAbsoluteVisibleCached then
  begin
    //FAbsoluteVisible := GetParentedVisible;
    FAbsoluteVisible := True; //TODO
    FAbsoluteVisibleCached := True;
  end;
  Result := FAbsoluteVisible;
end;

function TSkAnimatedImageBrush.NeedsRedraw: Boolean;
begin
  Result := (not FDrawCached) or (FDrawCacheKind = TSkDrawCacheKind.Never) or (FDrawBuffer = 0);
end;

procedure TSkAnimatedImageBrush.RenderFrame(const ACanvas: ISkCanvas;
  const ADest: TRectF; const AProgress: Double; const AOpacity: Single);

  function GetWrappedRect(const ADest: TRectF): TRectF;
  var
    LImageRect: TRectF;
    LRatio: Single;
  begin
    LImageRect := TRectF.Create(PointF(0, 0), FCodec.Size);
    case FWrapMode of
      TSkAnimatedImageWrapMode.Fit: Result := LImageRect.FitInto(ADest);
      TSkAnimatedImageWrapMode.FitCrop:
        begin
          if (LImageRect.Width / ADest.Width) < (LImageRect.Height / ADest.Height) then
            LRatio := LImageRect.Width / ADest.Width
          else
            LRatio := LImageRect.Height / ADest.Height;
          if SameValue(LRatio, 0, TEpsilon.Vector) then
            Result := ADest
          else
          begin
            Result := RectF(0, 0, Round(LImageRect.Width / LRatio), Round(LImageRect.Height / LRatio));
            RectCenter(Result, ADest);
          end;
        end;
      TSkAnimatedImageWrapMode.Original:
        begin
          Result := LImageRect;
          Result.Offset(ADest.TopLeft);
        end;
      TSkAnimatedImageWrapMode.OriginalCenter:
        begin
          Result := LImageRect;
          RectCenter(Result, ADest);
        end;
      TSkAnimatedImageWrapMode.Place: Result := PlaceIntoTopLeft(LImageRect, ADest);
      TSkAnimatedImageWrapMode.Stretch: Result := ADest;
    end;
  end;

begin
  if Assigned(FCodec) then
  begin
    (* TODO
    if (csDesigning in ComponentState) and (not Animation.Running) and (AProgress = 0) then
      FCodec.SeekFrameTime(Animation.Duration / 8)
    else
    *)
      FCodec.SeekFrameTime(Animation.CurrentTime);
    ACanvas.Save;
    try
      ACanvas.ClipRect(ADest);
      FCodec.Render(ACanvas, GetWrappedRect(ADest), AOpacity);
    finally
      ACanvas.Restore;
    end;
  end;

  //inherited; of TSkCustomAnimatedControl.RenderFrame
  if Assigned(FOnAnimationDraw) then
    FOnAnimationDraw(Self, ACanvas, ADest, AProgress, AOpacity);
end;


constructor TSkAnimatedImageBrush.Create;
begin
  //TSkAnimatedImageBrush.Create
  FAnimation := CreateAnimation;
  FAbsoluteVisible := True;
  FAbsoluteVisibleCached := True;
  CheckDuration;
  DrawParentInBackground := True;

  //TSkAnimatedImage.Create
  FSource := TSkAnimatedImage.TSource.Create(SourceChange);

  FWrapMode := TSkAnimatedImageWrapMode.Fit;
  FScaleFactor := 1;
  FProgress := 1;
  FAbsoluteVisible := False;
  FDrawCacheKind := TSkDrawCacheKind.Raster;

  FTargetCanvas := nil;
end;

function TSkAnimatedImageBrush.CreateAnimation: TAnimation;
begin
  //TSkAnimatedImage.CreateAnimation
  Result := TAnimation.Create(nil);
end;

procedure TSkAnimatedImageBrush.CreateBuffer(const AMemDC: HDC;
  out ABuffer: HBITMAP; out AData: Pointer; out AStride: Integer);
const
  ColorMasks: array[0..2] of DWORD = ($00FF0000, $0000FF00, $000000FF);
var
  LBitmapInfo: PBitmapInfo;
begin
  AStride := BytesPerScanline(FWidth, 32, 32);
  GetMem(LBitmapInfo, SizeOf(TBitmapInfoHeader) + SizeOf(ColorMasks));
  try
    LBitmapInfo.bmiHeader := Default(TBitmapInfoHeader);
    LBitmapInfo.bmiHeader.biSize        := SizeOf(TBitmapInfoHeader);
    LBitmapInfo.bmiHeader.biWidth       := FWidth;
    LBitmapInfo.bmiHeader.biHeight      := -FHeight;
    LBitmapInfo.bmiHeader.biPlanes      := 1;
    LBitmapInfo.bmiHeader.biBitCount    := 32;
    LBitmapInfo.bmiHeader.biCompression := BI_BITFIELDS;
    LBitmapInfo.bmiHeader.biSizeImage   := AStride * FHeight;
    Move(ColorMasks[0], LBitmapInfo.bmiColors[0], SizeOf(ColorMasks));
    ABuffer := CreateDIBSection(AMemDC, LBitmapInfo^, DIB_RGB_COLORS, AData, 0, 0);
    if ABuffer <> 0 then
      GdiFlush;
  finally
    FreeMem(LBitmapInfo);
  end;
end;

procedure TSkAnimatedImageBrush.Repaint;
begin
  if Assigned(FTargetCanvas) and Assigned(FTargetControl) then
    Paint(FTargetCanvas.Handle, FTargetOpacity);
end;

procedure TSkAnimatedImageBrush.Resize(R: TRectF);
var
  LLeft, LTop, LWidth, LHeight: Integer;
begin
  LWidth := Round(R.Width);
  LHeight := Round(R.Height);
  LLeft := Round(R.Left);
  LTop := Round(R.Top);
  if (LWidth <> FWidth) or (LHeight <> FHeight) then
  begin
    DeleteBuffers;
    FWidth := LWidth;
    FHeight := LHeight;
  end;
  FLeft := LLeft;
  FTop := LTop;
end;

procedure TSkAnimatedImageBrush.ResumeAnimation;
begin
  Animation.StartFromCurrent := True;
  Animation.start;
end;

procedure TSkAnimatedImageBrush.SetAnimation(const AValue: TAnimation);
begin
  FAnimation.Assign(AValue);
end;

procedure TSkAnimatedImageBrush.SetDrawCacheKind(const AValue: TSkDrawCacheKind);
begin
  if FDrawCacheKind <> AValue then
  begin
    FDrawCacheKind := AValue;
    if FDrawCacheKind <> TSkDrawCacheKind.Always then
      Repaint;
  end;
end;

procedure TSkAnimatedImageBrush.SetDrawParentInBackground(const AValue: Boolean);
begin
  if FDrawParentInBackground <> AValue then
  begin
    FDrawParentInBackground := AValue;
    Repaint;
  end;
end;

procedure TSkAnimatedImageBrush.SetLottieText(const AValue: string);
var
  LStringStream: TStringStream;
begin
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
  end
  else
  begin
    FLottieText := '';
  end;
end;

procedure TSkAnimatedImageBrush.SetProgress(AValue: Double);
begin

end;

procedure TSkAnimatedImageBrush.SourceChange;
var
  LCodecClass: TSkAnimatedImage.TAnimationCodecClass;
  LStream: TStream;
begin
  FreeAndNil(FCodec);
  LStream := TBytesStream.Create(FSource.Data);
  try
    for LCodecClass in TSkAnimatedImage.RegisteredCodecs do
    begin
      LStream.Position := 0;
      if LCodecClass.TryMakeFromStream(LStream, FCodec) then
        Break;
    end;
  finally
    LStream.Free;
  end;
  if Assigned(FCodec) then
  begin
    Animation.SetDuration(FCodec.Duration);
    if Animation.Running then
      Animation.Start;
  end
  else
    Animation.SetDuration(0);
  //Redraw;
end;

procedure TSkAnimatedImageBrush.DeleteBuffers;
begin
  if FDrawBuffer <> 0 then
  begin
    FDrawCached := False;
    DeleteObject(FDrawBuffer);
    FDrawBuffer := 0;
  end;
  FreeAndNil(FBackgroundBuffer);
end;

destructor TSkAnimatedImageBrush.Destroy;
begin
  FAnimation.Free;
  inherited;
end;

function TSkAnimatedImageBrush.GetDuration: Double;
begin
  if Assigned(FCodec) then
    Result := FCodec.Duration
  else
    Result := 0;
end;

function TSkAnimatedImageBrush.GetFormatInfo(
  out AFormat: TSkAnimatedImage.TFormatInfo): Boolean;
begin
  if Assigned(FCodec) then
  begin
    FCodec.TryDetectFormat(FSource.Data, AFormat);
    Result := True;
  end
  else
    REsult := False;
end;

procedure TSkAnimatedImageBrush.UpdateLottieText;
var
  LStringStream: TStringStream;
  LStream: TBytesStream;
begin
  if IsLottieFile then
  begin
    LStream := TBytesStream.Create(FSource.Data);
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

function TSkAnimatedImageBrush.GetLottieText: string;
begin
  Result := FLottieText;
end;

function TSkAnimatedImageBrush.GetOpaqueParent: TWinControl;
begin
  if Parent = nil then
    Exit(nil);
  Result := Parent;
  while Result <> nil do
  begin
    if not TWinControlAccess(Result).ParentBackground then
      Break;
    Result := Result.Parent;
  end;
end;

function TSkAnimatedImageBrush.IsAnimationFile: Boolean;
var
  LFormat: TSkAnimatedImage.TFormatInfo;
begin
  Result := GetFormatInfo(LFormat);
end;

function TSkAnimatedImageBrush.IsLottieFile: Boolean;
var
  LFormat: TSkAnimatedImage.TFormatInfo;
begin
  if GetFormatInfo(LFormat) then
    Result := SameText(LFormat.Name, 'Lottie')
  else
    Result := False;
end;

procedure TSkAnimatedImageBrush.LoadFromFile(const AFileName: string);
begin
  FSource.Data := TFile.ReadAllBytes(AFileName);
  UpdateLottieText;
end;

procedure TSkAnimatedImageBrush.LoadFromStream(const AStream: TStream);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, AStream.Size - AStream.Position);
  if Length(LBytes) > 0 then
    AStream.ReadBuffer(LBytes, 0, Length(LBytes));
  FSource.Data := LBytes;
  UpdateLottieText;
end;

procedure TSkAnimatedImageBrush.PaintTo(DC: HDC; R: TRectF; KeepAspectRatio: Boolean; AOpacity: Single);
const
  BlendFunction: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0; SourceConstantAlpha: 255; AlphaFormat: AC_SRC_ALPHA);
var
  LOldObj: HGDIOBJ;
  LDrawBufferDC: HDC;
  LBlendFunction: TBlendFunction;

  procedure InternalDraw;
  var
    LSurface: ISkSurface;
    LDestRect: TRectF;
  begin
    LSurface := TSkSurface.MakeRasterDirect(TSkImageInfo.Create(FWidth, FHeight), FDrawBufferData, FDrawBufferStride);
    LSurface.Canvas.Clear(TAlphaColors.Null);
    LSurface.Canvas.Concat(TMatrix.CreateScaling(FScaleFactor, FScaleFactor));
    LDestRect := RectF(0, 0, FWidth / FScaleFactor, FHeight / FScaleFactor);
    Draw(LSurface.Canvas, LDestRect, AOpacity);
    if Assigned(FOnDraw) then
      FOnDraw(Self, LSurface.Canvas, LDestRect, AOpacity);
    FDrawCached := True;
  end;

begin
  Resize(R);
  if (FWidth <= 0) or (FHeight <= 0) then
    Exit;

  LDrawBufferDC := CreateCompatibleDC(0);
  if LDrawBufferDC <> 0 then
    try
      if FDrawParentInBackground then
      begin
        if FBackgroundBuffer = nil then
        begin
          FBackgroundBuffer := TBitmap.Create;
          FBackgroundBuffer.SetSize(FWidth, FHeight);
        end;
        if (Parent <> nil) and Parent.DoubleBuffered then
          PerformEraseBackground(Parent, FBackgroundBuffer.Canvas.Handle);
        DrawParentImage(FBackgroundBuffer.Canvas.Handle);
      end;

      if FDrawBuffer = 0 then
        CreateBuffer(LDrawBufferDC, FDrawBuffer, FDrawBufferData, FDrawBufferStride);
      if FDrawBuffer <> 0 then
      begin
        LOldObj := SelectObject(LDrawBufferDC, FDrawBuffer);
        try
          if NeedsRedraw then
            InternalDraw;
          LBlendFunction := BlendFunction;
          LBlendFunction.SourceConstantAlpha := Round(AOpacity * 255);
          if FDrawParentInBackground then
            AlphaBlend(FBackgroundBuffer.Canvas.Handle, 0, 0, FWidth, FHeight, LDrawBufferDC, 0, 0, FWidth, FHeight, LBlendFunction)
          else
          begin
            if Assigned(FTargetCanvas) then
              AlphaBlend(FTargetCanvas.Handle, 0, 0, FWidth, FHeight, LDrawBufferDC, 0, 0, FWidth, FHeight, LBlendFunction)
            else
              AlphaBlend(DC, FLeft, FTop, FWidth, FHeight, LDrawBufferDC, 0, 0, FWidth, FHeight, LBlendFunction);
          end;
        finally
          if LOldObj <> 0 then
            SelectObject(LDrawBufferDC, LOldObj);
        end;
      end;

      if FDrawParentInBackground and Assigned(FTargetCanvas) then
        FTargetCanvas.Draw(FLeft, FTop, FBackgroundBuffer);
    finally
      DeleteDC(LDrawBufferDC);
    end;
end;

procedure TSkAnimatedImageBrush.Paint(DC: HDC; AOpacity: Single);
var
  LRect: TRectF;
begin
  LRect := TRectF.Create(FLeft,FTop,FLeft+FWidth,FTop+FHeight);
  PaintTo(DC, LRect, True, AOpacity);
end;

procedure TSkAnimatedImageBrush.PaintTo(ACanvas: TCanvas; ARect: TRect;
  AProgress: Integer; AOpacity: Single);
begin
  ACanvas.Lock;
  try
    Animation.Progress := AProgress;
    DrawParentInBackground := False;
    Resize(ARect);
    PaintTo(ACanvas.Handle, ARect, True, AOpacity);
  finally
    ACanvas.Unlock;
  end;
end;

procedure TSkAnimatedImageBrush.ClearImage;
begin
  Source.Data := [];
end;

procedure TSkAnimatedImageBrush.StartAnimation(const ALoop: Boolean);
begin
  if FProgress >= 1 then
    FProgress := 0;
  Animation.Loop := ALoop;
  CheckAnimation;
end;

procedure TSkAnimatedImageBrush.PauseAnimation;
begin
  Animation.stopAtCurrent;
end;

procedure TSkAnimatedImageBrush.StopAnimation;
begin
  FProgress := 1;
  CheckAnimation;
end;

procedure TSkAnimatedImageBrush.AnimateTo(AControl: TWinControl; ACanvas: TCanvas; R: TRectF; AOpacity: Single;
  ALoop: Boolean = False);
begin
  Resize(R);
  if (FWidth <= 0) or (FHeight <= 0) then
    Exit;
  FTargetCanvas := ACanvas;
  FTargetControl := AControl;
  FDrawParentInBackground := True;
  PaintTo(ACanvas.Handle, R, True, AOpacity);
  FTargetRect := R;
  FTargetOpacity := AOpacity;
  StartAnimation(ALoop);
end;

function TSkAnimatedImageBrush.AnimationLoaded: Boolean;
begin
  Result := Length(Source.Data) > 0;
end;

function TSkAnimatedImageBrush.CanPlayAnimation: Boolean;
begin
  Result := AnimationLoaded and not Animation.Running;
end;

function TSkAnimatedImageBrush.CanPauseAnimation: Boolean;
begin
  Result := AnimationLoaded and Animation.Enabled and Animation.Running;
end;

function TSkAnimatedImageBrush.CanStopAnimation: Boolean;
begin
  Result := AnimationLoaded and Animation.Running;
end;

function TSkAnimatedImageBrush.GetAnimation: TAnimation;
begin
  Result := TSkAnimatedImageBrush.TAnimation(FAnimation);
end;

function TSkAnimatedImageBrush.GetAnimationIsRunning: Boolean;
begin
  Result := AnimationLoaded and Animation.Running;
end;

procedure TSkAnimatedImageBrush.SetAnimationIsRunning(const AValue: Boolean);
begin
  if AValue then
    StartAnimation(Animation.Loop)
  else
    StopAnimation;
end;

{ TSkAnimatedImageBrush.TAnimation }

procedure TSkAnimatedImageBrush.TAnimation.DoChanged;
begin
  if Created and Assigned(Owner) then
    TSkAnimatedImageBrush(Owner).DoAnimationChanged;
end;

procedure TSkAnimatedImageBrush.TAnimation.DoFinish;
begin
  if Created and Assigned(Owner) then
    TSkAnimatedImageBrush(Owner).DoAnimationFinish;
end;

procedure TSkAnimatedImageBrush.TAnimation.DoProcess;
begin
  if FInsideDoProcess then
    Exit;
  FInsideDoProcess := True;
  try
    TSkAnimatedImageBrush(Owner).DoAnimationProcess;
  finally
    FInsideDoProcess := False;
  end;
end;

procedure TSkAnimatedImageBrush.TAnimation.DoStart;
begin
  if Created and Assigned(Owner) then
    TSkAnimatedImageBrush(Owner).DoAnimationStart;
end;

end.
