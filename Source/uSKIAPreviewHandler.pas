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
{  The Original Code is:                                                       }
{  Delphi Preview Handler  https://github.com/RRUZ/delphi-preview-handler      }
{                                                                              }
{  The Initial Developer of the Original Code is Rodrigo Ruz V.                }
{  Portions created by Rodrigo Ruz V. are Copyright 2011-2021 Rodrigo Ruz V.   }
{  All Rights Reserved.                                                        }
{******************************************************************************}
unit uSKIAPreviewHandler;

interface

uses
  Classes,
  Controls,
  StdCtrls,
  SysUtils,
  uCommonPreviewHandler,
  uStreamPreviewHandler,
  uPreviewHandler;

  type
    TSKIAPreviewHandler = class(TBasePreviewHandler)
  public
    constructor Create(AParent: TWinControl); override;
  end;

const
  MySKIA_PreviewHandlerGUID_64: TGUID = '{973B66A3-AEC2-40E0-A90E-8BDF123A1D68}';
  MySKIA_PreviewHandlerGUID_32: TGUID = '{881896DA-3AA6-43BA-B23E-BC339D1DD7AC}';

implementation

Uses
  uLogExcept,
  SynEdit,
  Windows,
  Forms,
  uMisc;
type
  TWinControlClass = class(TWinControl);

constructor TSKIAPreviewHandler.Create(AParent: TWinControl);
begin
  TLogPreview.Add('TSKIAPreviewHandler.Create');
  inherited Create(AParent);
  TLogPreview.Add('TSKIAPreviewHandler Done');
end;

end.
