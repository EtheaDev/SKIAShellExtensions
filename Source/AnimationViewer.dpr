{******************************************************************************}
{                                                                              }
{       LottieTextEditor: Advanced Editor for Lottie files                     }
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
{******************************************************************************}
program AnimationViewer;

uses
  System.SysUtils,
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  uPreviewContainer in 'uPreviewContainer.pas' {PreviewContainer},
  PreviewForm in 'PreviewForm.pas' {FrmPreview},
  SettingsForm in 'SettingsForm.pas' {UserSettingsForm},
  uSettings in 'uSettings.pas',
  DResources in 'DResources.pas' {dmResources: TDataModule},
  dlgSearchText in 'dlgSearchText.pas' {TextSearchDialog},
  uAbout in 'uAbout.pas' {FrmAbout};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskBar := True;
  Application.ActionUpdateDelay := 50;
  Application.Title := Title_AnimationViewer+'- © 2022-2026 Ethea S.r.l.';
  //Uses System Style for border / shadow of Forms
  TStyleManager.FormBorderStyle := TStyleManager.TFormBorderStyle.fbsSystemStyle;
  Application.HelpFile := '';
  Application.CreateForm(TdmResources, dmResources);
  Application.CreateForm(TFrmPreview, frmPreview);
  frmPreview.InitViewer;
  Application.OnException := frmPreview.ManageExceptions;
  Application.Run;
end.
