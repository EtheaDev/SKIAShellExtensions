{******************************************************************************}
{                                                                              }
{       Vcl.Skia.ControlsEx: extended Controls of Skia4Delphi/VCL              }
{       to simplify use animations                                             }
{                                                                              }
{       Copyright (c) 2022 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/SVGIconImageList                           }
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
unit Vcl.Skia.ControlsEx;

interface

uses
  System.Types
  , System.Classes
  , Winapi.Windows
  , Skia
  , Skia.Vcl
  ;

type
  TSkAnimatedImageBrush = class(TPersistent)
  private
    FCodec: TSkAnimatedImage.TAnimationCodec;
    FWrapMode: TSkAnimatedImageWrapMode;
    FSource: TSkAnimatedImage.TSource;
    FFPS: Double;
    FFixedProgress: Boolean;
    FProgress: Double;
    FIsStaticImage: Boolean;
    FDrawCacheEnabled: Boolean;
    FDrawCached: Boolean;
    procedure RenderFrame(const ACanvas: ISkCanvas; const ADest: TRectF;
      const AProgress: Double; const AOpacity: Single);
    function GetDuration: Double;
    procedure SourceChange(ASender: TObject);
    procedure SetFPS(const AValue: Double);
    procedure SetFixedProgress(const AValue: Boolean);
    procedure SetIsStaticImage(const AValue: Boolean);
    procedure SetDrawCacheEnabled(const AValue: Boolean);

    property Duration: Double read GetDuration;
    property DrawCacheEnabled: Boolean read FDrawCacheEnabled write SetDrawCacheEnabled default True;
    property FPS: Double read FFPS write SetFPS;
    property FixedProgress: Boolean read FFixedProgress write SetFixedProgress;
    property IsStaticImage: Boolean read FIsStaticImage write SetIsStaticImage;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromStream(const AStream: TStream);
    procedure PaintTo(DC: HDC; R: TRectF; KeepAspectRatio: Boolean; AOpacity: Single);

    function IsAnimationFile: Boolean;
    function IsLottieFile: Boolean;
    function GetFormatInfo(out AFormat: TSkAnimatedImage.TFormatInfo): Boolean;
  end;

  TSkAnimatedImageEx = class(TSkAnimatedImage)
  private
    FFileName: string;
    FLottieText: string;
    procedure SetFileName(const AValue: string);
    function GetProgressPercentage: SmallInt;
    procedure SetProgressPercentage(const AValue: SmallInt);
    function GetProgress: Double;
    procedure SetProgress(const AValue: Double);
    function GetAnimationIsRunning: Boolean;
    procedure SetAnimationIsRunning(const AValue: Boolean);
    function GetLottieText: string;
    procedure SetLottieText(const AValue: string);
  public
    constructor Create(AOwner: TComponent); override;
    procedure LoadFromFile(const AFileName: string);
    procedure ClearImage;
    procedure StartAnimation;
    procedure PauseAnimation;
    procedure StopAnimation;
    function AnimationLoaded: Boolean;
    function CanPlayAnimation: Boolean;
    function CanPauseAnimation: Boolean;
    function CanStopAnimation: Boolean;
    function IsAnimationFile: Boolean;
    function IsLottieFile: Boolean;
    function GetFormatInfo(out AFormat: TSkAnimatedImage.TFormatInfo): Boolean;

    //public a protected info
    property IsStaticImage;
  published
    property AnimationIsRunning: Boolean read GetAnimationIsRunning write SetAnimationIsRunning;
    property FileName: string read FFileName write SetFileName;
    property LottieText: string read GetLottieText write SetLottieText;
    property Progress: Double read GetProgress write SetProgress;
    property ProgressPercentage: SmallInt read GetProgressPercentage write SetProgressPercentage;
  end;

implementation

uses
  System.SysUtils
  , System.IOUtils
  , System.Math
  , System.Math.Vectors
  , System.UITypes
  ;

{ TSkAnimatedImageEx }

function TSkAnimatedImageEx.CanPauseAnimation: Boolean;
begin
  Result := AnimationLoaded and not IsStaticImage and AnimationIsRunning;
end;

function TSkAnimatedImageEx.CanPlayAnimation: Boolean;
begin
  Result := AnimationLoaded and not IsStaticImage and (FixedProgress or (Progress = 1));
end;

function TSkAnimatedImageEx.CanStopAnimation: Boolean;
begin
  Result := AnimationLoaded and not IsStaticImage and (AnimationIsRunning or (Progress <> 1));
end;

procedure TSkAnimatedImageEx.ClearImage;
begin
  Source.Data := [];
end;

constructor TSkAnimatedImageEx.Create(AOwner: TComponent);
begin
  inherited;
  Loop := False;
end;

function TSkAnimatedImageEx.GetAnimationIsRunning: Boolean;
begin
  Result := AnimationLoaded and not FixedProgress and (Progress <> 1);
end;

function TSkAnimatedImageEx.GetLottieText: string;
begin
  Result := FLottieText;
end;

function TSkAnimatedImageEx.GetProgress: Double;
begin
  Result := inherited Progress;
end;

function TSkAnimatedImageEx.GetProgressPercentage: SmallInt;
begin
  Result := Round(inherited Progress * 100);
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
    REsult := False;
end;

function TSkAnimatedImageEx.IsAnimationFile: Boolean;
var
  LFormat: TSkAnimatedImage.TFormatInfo;
begin
  Result := GetFormatInfo(LFormat);
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

function TSkAnimatedImageEx.AnimationLoaded: Boolean;
begin
  Result := Length(Source.Data) > 0;
end;

procedure TSkAnimatedImageEx.LoadFromFile(const AFileName: string);
var
  LOldLoop: Boolean;
begin
  LOldLoop := Loop;
  Loop := False;
  try
    FixedProgress := True;
    inherited Progress := 1;
    if FileExists(AFileName) then
    begin
      inherited LoadFromFile(AFileName);
      FFileName := AFileName;
      Redraw;
    end
    else
      ClearImage;
  finally
    Loop := LOldLoop;
  end;
end;

procedure TSkAnimatedImageEx.SetAnimationIsRunning(const AValue: Boolean);
begin
  if AValue then
    StartAnimation
  else
    StopAnimation;
end;

procedure TSkAnimatedImageEx.SetFileName(const AValue: string);
begin
  if FFileName <> AValue then
    LoadFromFile(AValue);
end;

procedure TSkAnimatedImageEx.SetLottieText(const AValue: string);
var
  LStringStream: TStringStream;
  LOldLoop: Boolean;
begin
  LOldLoop := Loop;
  Loop := False;
  try
    FixedProgress := True;
    inherited Progress := 1;
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
    Loop := LOldLoop;
  end;
end;

procedure TSkAnimatedImageEx.SetProgress(const AValue: Double);
var
  LEvent: TNotifyEvent;
begin
  if Assigned(OnAnimationProgress) then
    LEvent := OnAnimationProgress
  else
    LEvent := nil;
  OnAnimationProgress := nil;
  Try
    FixedProgress := True;
    inherited Progress := AValue;
  Finally
    if Assigned(LEvent) then
      OnAnimationProgress := LEvent;
  End;
end;

procedure TSkAnimatedImageEx.SetProgressPercentage(const AValue: SmallInt);
begin
  Progress := AValue / 100;
end;

procedure TSkAnimatedImageEx.StartAnimation;
begin
  if not AnimationIsRunning then
    FixedProgress := False;
  if Progress = 1 then
    inherited Progress := 0;
end;

procedure TSkAnimatedImageEx.StopAnimation;
begin
  FixedProgress := True;
  inherited Progress := 1;
end;

procedure TSkAnimatedImageEx.PauseAnimation;
begin
  FixedProgress := True;
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
  FCodec.SeekFrameTime(AProgress * Duration);
  FCodec.Render(ACanvas, GetWrappedRect(ADest), AOpacity);
  inherited;
end;

constructor TSkAnimatedImageBrush.Create;
begin
  FWrapMode := TSkAnimatedImageWrapMode.Fit;
  FSource := TSkAnimatedImage.TSource.Create(SourceChange);
end;

procedure TSkAnimatedImageBrush.SetDrawCacheEnabled(const AValue: Boolean);
begin
  if FDrawCacheEnabled <> AValue then
  begin
    FDrawCacheEnabled := AValue;
    (* TODO?
    if not AValue then
      Repaint;
    *)
  end;
end;

procedure TSkAnimatedImageBrush.SetFixedProgress(const AValue: Boolean);
begin
  FFixedProgress := AValue;
end;

procedure TSkAnimatedImageBrush.SetFPS(const AValue: Double);
begin
  if not SameValue(FFPS, AValue, TEpsilon.Vector) then
  begin
    FFPS := AValue;
    (* TODO?
    if Assigned(FAnimation) then
      FAnimation.Interval := Round(1000 / FFPS);
    *)
  end;
end;

procedure TSkAnimatedImageBrush.SetIsStaticImage(const AValue: Boolean);
begin
  if FIsStaticImage <> AValue then
  begin
    FIsStaticImage := AValue;
    DrawCacheEnabled := FIsStaticImage;
    //CheckAnimation;
  end;
end;

procedure TSkAnimatedImageBrush.SourceChange(ASender: TObject);
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
    FPS := Max(FCodec.FPS, TSkCustomAnimatedControl.MinFPS);
  if not FixedProgress then
    FProgress := 0;
  IsStaticImage := (FCodec = nil) or FCodec.IsStatic;
  FDrawCached := False;
  //Repaint;
end;

destructor TSkAnimatedImageBrush.Destroy;
begin
  FCodec.Free;
  FSource.Free;
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
end;

procedure TSkAnimatedImageBrush.LoadFromStream(const AStream: TStream);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, AStream.Size - AStream.Position);
  if Length(LBytes) > 0 then
    AStream.ReadBuffer(LBytes, 0, Length(LBytes));
  FSource.Data := LBytes;
end;

procedure TSkAnimatedImageBrush.PaintTo(DC: HDC; R: TRectF; KeepAspectRatio: Boolean; AOpacity: Single);
const
  BlendFunction: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0; SourceConstantAlpha: 255; AlphaFormat: AC_SRC_ALPHA);
var
  LOldObj: HGDIOBJ;
  LDrawBufferDC: HDC;
  LBlendFunction: TBlendFunction;
  LScaleFactor: Single;
  LDrawBufferData: Pointer;
  LDrawBufferStride: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LDrawBuffer: HBITMAP;

  procedure DeleteBuffers;
  begin
    if LDrawBuffer <> 0 then
    begin
      FDrawCached := False;
      DeleteObject(LDrawBuffer);
      LDrawBuffer := 0;
    end;
  end;

  procedure InternalDraw;
  var
    LSurface: ISkSurface;
    LDestRect: TRectF;
  begin
    LSurface := TSkSurface.MakeRasterDirect(TSkImageInfo.Create(LWidth, LHeight), LDrawBufferData, LDrawBufferStride);
    LSurface.Canvas.Clear(TAlphaColors.Null);
    LScaleFactor := 1;
    LSurface.Canvas.Concat(TMatrix.CreateScaling(LScaleFactor, LScaleFactor));
    LDestRect := RectF(0, 0, LWidth / LScaleFactor, LHeight / LScaleFactor);

    //Render Image
    RenderFrame(LSurface.Canvas, LDestRect, 1, AOpacity);
    FDrawCached := True;
  end;

  procedure CreateBuffer(
    const AWidth, AHeight: Integer;
    const AMemDC: HDC; out ABuffer: HBITMAP;
    out AData: Pointer; out AStride: Integer);
  const
    ColorMasks: array[0..2] of DWORD = ($00FF0000, $0000FF00, $000000FF);
  var
    LBitmapInfo: PBitmapInfo;
    function BytesPerScanline(PixelsPerScanline, BitsPerPixel, Alignment: Longint): Longint;
    begin
      Dec(Alignment);
      Result := ((PixelsPerScanline * BitsPerPixel) + Alignment) and not Alignment;
      Result := Result div 8;
    end;

  begin
    AStride := BytesPerScanline(AWidth, 32, 32);
    GetMem(LBitmapInfo, SizeOf(TBitmapInfoHeader) + SizeOf(ColorMasks));
    try
      LBitmapInfo.bmiHeader := Default(TBitmapInfoHeader);
      LBitmapInfo.bmiHeader.biSize        := SizeOf(TBitmapInfoHeader);
      LBitmapInfo.bmiHeader.biWidth       := AWidth;
      LBitmapInfo.bmiHeader.biHeight      := -AHeight;
      LBitmapInfo.bmiHeader.biPlanes      := 1;
      LBitmapInfo.bmiHeader.biBitCount    := 32;
      LBitmapInfo.bmiHeader.biCompression := BI_BITFIELDS;
      LBitmapInfo.bmiHeader.biSizeImage   := AStride * AHeight;
      Move(ColorMasks[0], LBitmapInfo.bmiColors[0], SizeOf(ColorMasks));
      ABuffer := CreateDIBSection(AMemDC, LBitmapInfo^, DIB_RGB_COLORS, AData, 0, 0);
      if ABuffer <> 0 then
        GdiFlush;
    finally
      FreeMem(LBitmapInfo);
    end;
  end;

begin
  LWidth := Round(R.Width);
  LHeight := Round(R.Height);

  DeleteBuffers;
  if (LWidth <= 0) or (LHeight <= 0) then
    Exit;

  LDrawBufferDC := CreateCompatibleDC(0);
  if LDrawBufferDC <> 0 then
    try
      if LDrawBuffer = 0 then
        CreateBuffer(LWidth, LHeight, LDrawBufferDC, LDrawBuffer, LDrawBufferData, LDrawBufferStride);
      if LDrawBuffer <> 0 then
      begin
        LOldObj := SelectObject(LDrawBufferDC, LDrawBuffer);
        try
          if (not FDrawCacheEnabled) or (not FDrawCached) then
            InternalDraw;
          LBlendFunction := BlendFunction;
          LBlendFunction.SourceConstantAlpha := Round(AOpacity * 255);
          AlphaBlend(DC, Round(R.Left), Round(R.Top), LWidth, LHeight, LDrawBufferDC, 0, 0, LWidth, LHeight, LBlendFunction);
        finally
          if LOldObj <> 0 then
            SelectObject(LDrawBufferDC, LOldObj);
        end;
      end;
    finally
      DeleteDC(LDrawBufferDC);
    end;
end;

end.
