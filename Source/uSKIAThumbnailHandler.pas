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
  Classes,
  Controls,
  ComObj,
  ShlObj,
  Windows,
  Winapi.PropSys,
  System.Generics.Collections,
  SVGInterfaces,
  SVGCommon,
  Skia.Vcl,
  Vcl.Skia.ControlsEx,
  ActiveX;

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
    FAnimatedImageBrush: TSkAnimatedImageBrush;
    FLightTheme: Boolean;
  protected
    property Mode: Cardinal read FMode write FMode;
    property IStream: IStream read FIStream write FIStream;
  public
    property ThumbnailHandlerClass: TThumbnailHandlerClass read FThumbnailHandlerClass write FThumbnailHandlerClass;
  end;

implementation

uses
  ComServ,
  Types,
  SysUtils,
  Graphics,
  ExtCtrls,
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
  LRect: TRect;
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
      FAnimatedImageBrush.LoadFromStream(AStream);
      if FAnimatedImageBrush.IsAnimationFile then
      begin
        LBitmap := TBitmap.Create;
        LBitmap.PixelFormat := pf32bit;
        if FLightTheme then
          LAntiAliasColor := clWhite
        else
          LAntiAliasColor := clWebDarkSlategray;
        LBitmap.Canvas.Brush.Color := ColorToRGB(LAntiAliasColor);
        LBitmap.SetSize(cx, cx);
        TLogPreview.Add('TComAnimThumbnailProvider.PaintTo start');
        LRect := TRect.Create(0,0,cx,cx);
        FAnimatedImageBrush.PaintTo(LBitmap.Canvas.Handle, LRect, True, 1);
        TLogPreview.Add('TComAnimThumbnailProvider.PaintTo end');
        hBitmap := LBitmap.Handle;
      end;
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
    FAnimatedImageBrush := TSkAnimatedImageBrush.Create;
    FLightTheme := IsWindowsAppThemeLight;
  end;
  TLogPreview.Add('TComAnimThumbnailProvider.IInitializeWithStream_Initialize done');
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


