{******************************************************************************}
{                                                                              }
{       SKIA Shell Extensions: Shell extensions for animated files             }
{       (Preview Panel, Thumbnail Icon, File Editor)                           }
{                                                                              }
{       Copyright (c) 2021-2026 (Ethea S.r.l.)                                 }
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
{ The Original Code is:                                                        }
{ Writing a Windows Shell Extension (by Marco Cantu)                           }
{ https://blog.marcocantu.com/blog/2016-03-writing-windows-shell-extension.html}
{                                                                              }
{******************************************************************************}
unit uSKIAContextMenuHandler;

interface

uses
  Winapi.Windows
  , ActiveX
  , ComObj
  , ShlObj
  , ShellApi
  , uSettings;

const
  MENU_ITEM_OPEN_WITH_EDITOR = 0;
  MENU_ITEM_SHOW_ANIMATION = 1;
  MENU_ITEM_COUNT = 2;

type
  TSKIAContextMenu = class(TComObject, IUnknown,
    IContextMenu,
    //IContextMenu2, IContextMenu3,
    IShellExtInit)
  private
    FFileName: string;
    FOwnerDrawId: UINT;
    FSettings: TPreviewSettings;
  protected
    {Declare IContextMenu methods here}
    function QueryContextMenu(Menu: HMENU; indexMenu, idCmdFirst, idCmdLast,
      uFlags: UINT): HResult; stdcall;
    function InvokeCommand(var lpici: TCMInvokeCommandInfo): HResult; stdcall;
    function GetCommandString(idCmd: UINT_PTR; uFlags: UINT; pwReserved: PUINT;
      pszName: LPSTR; cchMax: UINT): HResult; stdcall;
    {Declare IShellExtInit methods here}
    function IShellExtInit.Initialize = InitShellExt;
    function InitShellExt(pidlFolder: PItemIDList; lpdobj: IDataObject;
      hKeyProgID: HKEY): HResult; stdcall;
    //IContextMenu2
(*
    function HandleMenuMsg(uMsg: UINT; WParam: WPARAM; LParam: LPARAM): HResult; stdcall;
    //IContextMenu3
    function HandleMenuMsg2(uMsg: UINT; wParam: WPARAM; lParam: LPARAM; var lpResult: LRESULT): HResult; stdcall;
    function MenuMessageHandler(uMsg: UINT; wParam: WPARAM; lParam: LPARAM; var lpResult: LRESULT): HResult; stdcall;
*)
  public
    destructor Destroy; override;
  end;

  TSKIAContextMenuFactory = class (TComObjectFactory)
  public
    procedure UpdateRegistry(Register: Boolean); override;
  end;

const
  MyClass_SKIAContextMenu_64: TGUID = '{048B4077-8CAF-4941-A7E9-63F0817B9DC6}';
  MyClass_SKIAContextMenu_32: TGUID = '{CBBE5B6E-4013-431F-A80F-78231F9E1293}';

implementation

uses
  Vcl.Graphics
  , System.Types
  , ComServ
  , Messages
  , SysUtils
  , Registry
  , uLogExcept
  , System.Classes
{$IFNDEF DISABLE_STYLES}
  , Vcl.Themes
{$ENDIF}
  , dlgExportPNG
  , DResources
  , PreviewForm;

// IShellExtInit method
function TSKIAContextMenu.InitShellExt(pidlFolder: PItemIDList;
  lpdobj: IDataObject; hKeyProgID: HKEY): HResult; stdcall;
var
  medium: TStgMedium;
  fe: TFormatEtc;
  LFileExt: string;
  LCountFile: Integer;
begin
  TLogPreview.Add('TSKIAContextMenu.InitShellExt');

  Result := E_FAIL;
  // check if the lpdobj pointer is nil
  if Assigned(lpdobj) then
  begin
    TLogPreview.Add('Assigned(lpdobj)');
    with fe do
    begin
      cfFormat := CF_HDROP;
      ptd := nil;
      dwAspect := DVASPECT_CONTENT;
      lindex := -1;
      tymed := TYMED_HGLOBAL;
    end;
    // transform the lpdobj data to a storage medium structure
    Result := lpdobj.GetData(fe, medium);
    if not Failed(Result) then
    begin
      LCountFile := DragQueryFile(medium.hGlobal, $FFFFFFFF, nil, 0);
      TLogPreview.Add('LCountFile: '+IntToStr(LCountFile));
      // check if only one file is selected
      if LCountFile = 1 then
      begin
        SetLength(FFileName, 1000);
        DragQueryFile(medium.hGlobal, 0, PChar (FFileName), 1000);
        // realign string
        FFileName := PChar(FFileName);
        FSettings := TPreviewSettings.CreateSettings(nil, nil);
        TLogPreview.Add('FFileName: '+FFileName);
        LFileExt := ExtractFileExt(FFileName);
        // only for lottie files
        if SameText(LFileExt,'.lottie') or SameText(LFileExt,'.json') then
          Result := NOERROR
        else
          Result := E_FAIL;
      end
      else
        Result := E_FAIL;
    end;
    ReleaseStgMedium(medium);
  end;
end;

// context menu methods

function TSKIAContextMenu.QueryContextMenu(Menu: HMENU;
  indexMenu, idCmdFirst, idCmdLast, uFlags: UINT): HResult;
var
  LMenuIndex: Integer;
begin
  FOwnerDrawId := idCmdFirst;
  // add a new item to context menu
  LMenuIndex := indexMenu;
  InsertMenu(Menu, LMenuIndex, MF_STRING or MF_BYPOSITION, idCmdFirst+MENU_ITEM_OPEN_WITH_EDITOR,
    'Open with "Lottie Text Editor"...');
  Inc(LMenuIndex);
  InsertMenu(Menu, LMenuIndex, MF_STRING or MF_BYPOSITION, idCmdFirst+MENU_ITEM_SHOW_ANIMATION,
    'Open with "Animation Viewer"...');
  // Return number of menu items added
  Result := MENU_ITEM_COUNT;
end;

function TSKIAContextMenu.InvokeCommand(var lpici: TCMInvokeCommandInfo): HResult;
var
//  LStringStream: TStringStream;
  LFileName: string;
//  LLottieText: string;
  Reg: TRegistry;
  LCommand: string;

  procedure EditorNotInstalled;
  begin
    MessageBox(0, '"Lottie Text Editor" not installed',
      'Error opening file', MB_OK);
  end;

  procedure EditorNotFound;
  begin
    MessageBox(0, '"Lottie Text Editor" not found!',
      'Error opening file', MB_OK);
  end;

  procedure ViewerNotInstalled;
  begin
    MessageBox(0, '"Animation Viewer" not installed',
      'Error opening file', MB_OK);
  end;

  procedure ViewerNotFound;
  begin
    MessageBox(0, '"Animation Viewer" not found!',
      'Error opening file', MB_OK);
  end;

begin
  Result := NOERROR;
  // Make sure we are not being called by an application
  if HiWord(NativeInt(lpici.lpVerb)) <> 0 then
  begin
    Result := E_FAIL;
    Exit;
  end;
  // Make sure we aren't being passed an invalid argument number
  if LoWord(lpici.lpVerb) >= MENU_ITEM_COUNT then
  begin
    Result := E_INVALIDARG;
    Exit;
  end;
  // execute the command specified by lpici.lpVerb.
  if LoWord(lpici.lpVerb) = MENU_ITEM_OPEN_WITH_EDITOR then
  begin
    TLogPreview.Add('TSKIAContextMenu: Menu clicked');

    Reg := TRegistry.Create(KEY_READ);
    try
      Reg.RootKey := HKEY_CLASSES_ROOT;
      TLogPreview.Add('TSKIAContextMenuHandler: Open Registry');
      if Reg.OpenKey('OpenLottieEditor\Shell\Open\Command', False) then
      begin
        LCommand := Reg.ReadString('');
        LCommand := StringReplace(LCommand,' "%1"','', []);
        LFileName := format('"%s"',[FFileName]);
        TLogPreview.Add(Format('TMDContextMenuHandler: Command: %s FileName %s',
          [LCommand, LFileName]));
        if (FFileName <> '') and FileExists(FFileName) then
        begin
          TLogPreview.Add(Format('TSKIAContextMenuHandler: ShellExecute: %s for file %s',
            [LCommand, LFileName]));
          ShellExecute(0, 'Open', PChar(LCommand), PChar(LFileName), nil, SW_SHOWNORMAL);
        end
        else
          EditorNotInstalled;
      end
      else
        EditorNotFound;
    finally
      Reg.Free;
    end;
  end
  else if LoWord(lpici.lpVerb) = MENU_ITEM_SHOW_ANIMATION then
  begin
    TLogPreview.Add('TSKIAContextMenu: Menu clicked');

    Reg := TRegistry.Create(KEY_READ);
    try
      Reg.RootKey := HKEY_CLASSES_ROOT;
      TLogPreview.Add('TSKIAContextMenuHandler: Open Registry');
      if Reg.OpenKey('OpenAnimationViewer\Shell\Open\Command', False) then
      begin
        LCommand := Reg.ReadString('');
        LCommand := StringReplace(LCommand,' "%1"','', []);
        LFileName := format('"%s"',[FFileName]);
        TLogPreview.Add(Format('TMDContextMenuHandler: Command: %s FileName %s',
          [LCommand, LFileName]));
        if (FFileName <> '') and FileExists(FFileName) then
        begin
          TLogPreview.Add(Format('TSKIAContextMenuHandler: ShellExecute: %s for file %s',
            [LCommand, LFileName]));
          ShellExecute(0, 'Open', PChar(LCommand), PChar(LFileName), nil, SW_SHOWNORMAL);
        end
        else
          ViewerNotInstalled;
      end
      else
        ViewerNotFound;
    finally
      Reg.Free;
    end;
  end;
end;

destructor TSKIAContextMenu.Destroy;
begin
  FreeAndNil(FSettings);
  inherited;
end;

function TSKIAContextMenu.GetCommandString(idCmd: UINT_PTR; uFlags: UINT; pwReserved: PUINT;
  pszName: LPSTR; cchMax: UINT): HResult; stdcall;
begin
  Result := E_INVALIDARG;
end;

{ TSKIAContextMenuFactory methods }

procedure TSKIAContextMenuFactory.UpdateRegistry(Register: Boolean);
var
  Reg: TRegistry;
begin
  inherited UpdateRegistry (Register);

  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CLASSES_ROOT;
  if not Reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved', True) then
    Exit;
  try
    if Register then
    begin
      //New registration only for .lottie files
      {$IFDEF WIN64}
      if Reg.OpenKey('\*\ShellEx\ContextMenuHandlers\SKIAContextMenu', True) then
        Reg.WriteString('', GUIDToString(MyClass_SKIAContextMenu_64))
      {$ELSE}
      if Reg.OpenKey('\*\ShellEx\ContextMenuHandlers\SKIAContextMenu32', True) then
        Reg.WriteString('', GUIDToString(MyClass_SKIAContextMenu_32))
      {$ENDIF}
    end
    else
    begin
      //Old registration
      if Reg.OpenKey('\*\ShellEx\ContextMenuHandlers\SKIAContextMenu', False) then
        Reg.DeleteKey('\*\ShellEx\ContextMenuHandlers\SKIAContextMenu');
      //New registration only for .lottie files
      {$IFDEF WIN64}
      if Reg.OpenKey('\*\ShellEx\ContextMenuHandlers\SKIAContextMenu', True) then
        Reg.DeleteKey('\*\ShellEx\ContextMenuHandlers\SKIAContextMenu');
      {$ELSE}
      if Reg.OpenKey('\*\ShellEx\ContextMenuHandlers\SKIAContextMenu32', False) then
        Reg.DeleteKey('\*\ShellEx\ContextMenuHandlers\SKIAContextMenu32');
      {$ENDIF}
    end;
  finally
    Reg.CloseKey;
    Reg.Free;
  end;
end;

initialization
  {$IFDEF WIN64}
  TSKIAContextMenuFactory.Create(
    ComServer, TSKIAContextMenu, MyClass_SKIAContextMenu_64,
    'SKIAContextMenu', 'SKIAContextMenu Shell Extension',
    ciMultiInstance, tmApartment);
  {$ELSE}
  TSKIAContextMenuFactory.Create(
    ComServer, TSKIAContextMenu, MyClass_SKIAContextMenu_32,
    'SKIAContextMenu32', 'SKIAContextMenu Shell Extension',
    ciMultiInstance, tmApartment);
  {$ENDIF}

end.
