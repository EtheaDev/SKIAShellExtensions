{******************************************************************************}
{                                                                              }
{       SKIA Shell Extensions: Shell extensions for animated files             }
{       (Preview Panel, Thumbnail Icon, File Editor)                           }
{                                                                              }
{       Copyright (c) 2021-2022 (Ethea S.r.l.)                                 }
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
unit uSKIAThumbnailHandler;


interface

uses
  System.Classes,
  System.Types,
  Vcl.Controls,
  System.Win.ComObj,
  Winapi.ShlObj,
  Winapi.Windows,
  Vcl.Graphics,
  Winapi.PropSys,
  Winapi.ActiveX,
  System.Generics.Collections,
  SVGInterfaces,
  System.Skia,
  Vcl.Skia;

type
  TSKIAThumbnailProvider = class abstract
  public
    class function GetComClass: TComClass; virtual;
    class procedure RegisterThumbnailProvider(const AClassID: TGUID;
      const AName, ADescription: string);
  end;

  TThumbnailHandlerClass = class of TSKIAThumbnailProvider;

{$EXTERNALSYM IThumbnailProvider}
  IThumbnailProvider = interface(IUnknown)
    ['{E357FCCD-A995-4576-B01F-234630154E96}']
    function GetThumbnail(cx : uint; out hBitmap : HBITMAP; out bitmapType : dword): HRESULT; stdcall;
  end;

const
  {$EXTERNALSYM IID_IThumbnailProvider}
  ThumbnailProviderGUID = '{E357FCCD-A995-4576-B01F-234630154E96}';
  IID_IThumbnailProvider: TGUID = ThumbnailProviderGUID;

  MySKIA_ThumbNailProviderGUID: TGUID = '{C76B1689-1067-4B6D-BD21-AB27BBB980C6}';

type
  TComAnimThumbnailProvider = class(TComObject, IInitializeWithStream, IThumbnailProvider)
    function IInitializeWithStream.Initialize = IInitializeWithStream_Initialize;
    function IInitializeWithStream_Initialize(const pstream: IStream; grfMode: Cardinal): HRESULT; stdcall;
    function GetThumbnail(cx : uint; out hBitmap : HBITMAP; out bitmapType : dword): HRESULT; stdcall;
    function Unload: HRESULT; stdcall;
  private
    FThumbnailHandlerClass: TThumbnailHandlerClass;
    FIStream: IStream;
    FMode: Cardinal;
    FSource: TSkAnimatedImage.TSource;
    FCodec: TSkAnimatedImage.TAnimationCodec;
    FLightTheme: Boolean;
    procedure SourceChange;
  protected
    property Mode: Cardinal read FMode write FMode;
    property IStream: IStream read FIStream write FIStream;
  public
    property ThumbnailHandlerClass: TThumbnailHandlerClass read FThumbnailHandlerClass write FThumbnailHandlerClass;
  end;

implementation

uses
  System.Win.ComServ,
  System.SysUtils,
  Vcl.ExtCtrls,
  uMisc,
  uREgistry,
  uLogExcept,
  uStreamAdapter,
  WinAPI.GDIPObj,
  WinAPI.GDIPApi,
  uThumbnailHandlerRegister;

{ TComAnimThumbnailProvider }

function TComAnimThumbnailProvider.GetThumbnail(cx: uint; out hBitmap: HBITMAP;
  out bitmapType: dword): HRESULT;
const
  WTSAT_ARGB = 2;
var
  AStream: TIStreamAdapter;
  LBitmap: TBitmap;
  LAntiAliasColor: TColor;
  LRect: TRectF;

  procedure LoadAnimFromStream(const AStream: TStream);
  var
    LBytes: TBytes;
  begin
    SetLength(LBytes, AStream.Size - AStream.Position);
    if Length(LBytes) > 0 then
      AStream.ReadBuffer(LBytes, 0, Length(LBytes));
    FSource.Data := LBytes;
  end;

begin
  try
    TLogPreview.Add('TComAnimThumbnailProvider.GetThumbnail start');
    hBitmap := 0;
    if (cx = 0) then
    begin
      Result := S_FALSE;
      Exit;
    end;
    bitmapType := WTSAT_ARGB;
    AStream := TIStreamAdapter.Create(FIStream);
    try
      TLogPreview.Add('TComAnimThumbnailProvider.GetThumbnail LoadFromStream');
      LoadAnimFromStream(AStream);
      LBitmap := TBitmap.Create;
      LBitmap.PixelFormat := pf32bit;
      if FLightTheme then
        LAntiAliasColor := clWhite
      else
        LAntiAliasColor := clWebDarkSlategray;
      LBitmap.Canvas.Brush.Color := ColorToRGB(LAntiAliasColor);
      LBitmap.SetSize(cx, cx);
      TLogPreview.Add('TSkAnimatedImage.RenderFrame start');
      LRect := TRectF.Create(0,0,cx,cx);
      LBitmap.SkiaDraw(
        procedure (const ASkCanvas: ISkCanvas)
        var
          LImageRect: TRectF;
        begin
          FCodec.SeekFrameTime(FCodec.Duration);
          ASkCanvas.Save;
          try
            ASkCanvas.ClipRect(LRect);
            //calculate TSkAnimatedImageWrapMode.Fit
            LImageRect := TRectF.Create(PointF(0, 0), FCodec.Size);
            LRect := LImageRect.FitInto(LRect);
            FCodec.Render(ASkCanvas, LRect, 1);
          finally
            ASkCanvas.Restore;
          end;
        end
        );
      TLogPreview.Add('TSkAnimatedImage.RenderFrame end');
      hBitmap := LBitmap.Handle;
    finally
      AStream.Free;
    end;
    Result := S_OK;
  except
    on E: Exception do
    begin
      Result := E_FAIL;
      TLogPreview.Add(Format('Error in TComAnimThumbnailProvider.GetThumbnail - Message: %s: Trace %s',
        [E.Message, E.StackTrace]));
    end;
  end;
end;

function TComAnimThumbnailProvider.IInitializeWithStream_Initialize(
  const pstream: IStream; grfMode: Cardinal): HRESULT;
begin
  TLogPreview.Add('TComAnimThumbnailProvider.IInitializeWithStream_Initialize Init');
  Initialize_GDI;
  FIStream := pstream;
  Result := S_OK;
  if Result = S_OK then
  begin
    FSource := TSkAnimatedImage.TSource.Create(SourceChange);
    FLightTheme := IsWindowsAppThemeLight;
  end;
  TLogPreview.Add('TComAnimThumbnailProvider.IInitializeWithStream_Initialize done');
end;

procedure TComAnimThumbnailProvider.SourceChange;
begin
  FreeAndNil(FCodec);
  var LStream := TBytesStream.Create(FSource.Data);
  try
    for var LCodecClass in TSkAnimatedImage.RegisteredCodecs do
    begin
      LStream.Position := 0;
      if LCodecClass.TryMakeFromStream(LStream, FCodec) then
        Break;
    end;
  finally
    LStream.Free;
  end;
end;

function TComAnimThumbnailProvider.Unload: HRESULT;
begin
  TLogPreview.Add('TComAnimThumbnailProvider.Unload Init');
  Finalize_GDI;
  result := S_OK;
  TLogPreview.Add('TComAnimThumbnailProvider.Unload Done');
end;

{ TSKIAThumbnailProvider }

class function TSKIAThumbnailProvider.GetComClass: TComClass;
begin
  Result := TComAnimThumbnailProvider;
end;

class procedure TSKIAThumbnailProvider.RegisterThumbnailProvider(
  const AClassID: TGUID; const AName, ADescription: string);
begin
  TLogPreview.Add('TSKIAThumbnailProvider.RegisterThumbnailProvider Init ' + AName);
  TThumbnailHandlerRegister.Create(Self, AClassID, AName, ADescription);
  TLogPreview.Add('TSKIAThumbnailProvider.RegisterThumbnailProvider Done ' + AName);
end;

end.


