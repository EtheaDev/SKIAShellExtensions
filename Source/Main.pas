{******************************************************************************}
{                                                                              }
{       SKIA Shell Extensions: Shell extensions for animated files             }
{       (Preview Panel, Thumbnail Icon, File Editor)                           }
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
{  The Original Code is Main.pas.                                              }
{  Delphi Preview Handler  https://github.com/RRUZ/delphi-preview-handler      }
{                                                                              }
{  The Initial Developer of the Original Code is Rodrigo Ruz V.                }
{  Portions created by Rodrigo Ruz V. are Copyright 2011-2021 Rodrigo Ruz V.   }
{  All Rights Reserved.                                                        }
{******************************************************************************}
unit Main;

interface

implementation

uses
  uSKIAThumbnailHandler,
  uSKIAPreviewHandler;

initialization
  {$IFDEF WIN64}
  TSKIAPreviewHandler.RegisterPreview(MySKIA_PreviewHandlerGUID_64,
    'SKIA.PreviewHandler', 'Delphi SKIA Preview Handler 64bit');
  {$ELSE}
  TSKIAPreviewHandler.RegisterPreview(MySKIA_PreviewHandlerGUID_32,
    'SKIA.PreviewHandler', 'Delphi SKIA Preview Handler 32bit');
  {$ENDIF}

  {$IFDEF WIN64}
  TSKIAThumbnailProvider.RegisterThumbnailProvider(MySKIA_ThumbnailProviderGUID,
    'SKIA.ThumbnailProvider', 'Delphi SKIA Thumbnail Provider 64bit');
  {$ELSE}
  TSKIAThumbnailProvider.RegisterThumbnailProvider(MySKIA_ThumbnailProviderGUID,
    'SKIA.ThumbnailProvider', 'Delphi SKIA Thumbnail Provider 32bit');
  {$ENDIF}

end.

