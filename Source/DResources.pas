{******************************************************************************}
{                                                                              }
{       SKIA Shell Extensions: Shell extensions for animated files             }
{       (Preview Panel, Thumbnail Icon, File Editor)                           }
{                                                                              }
{       Copyright (c) 2022 (Ethea S.r.l.)                                      }
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
unit DResources;

interface

uses
  System.SysUtils
  , System.Types
  , System.UITypes
  , System.Classes
  , SynHighlighterJSON
  , Winapi.Windows
  , Vcl.Graphics
  , Vcl.ImgList
  , Vcl.Controls
  , System.ImageList
  , SynEditOptionsDialog
  , SynEditPrint
  , SynEditCodeFolding
  , SynEditHighlighter
  , SVGIconImageListBase
  , SVGIconImageList, Vcl.BaseImageCollection, SVGIconImageCollection
  ;

type
  TEditFileType = Record
    ComponentName : string;
    LanguageName : string;
    FileExtensions : string;
    SynHighlighter : TSynCustomHighlighter;
  end;

  TdmResources = class(TDataModule)
    SynJSONSyn: TSynJSONSyn;
    SynJSONSynDark: TSynJSONSyn;
    SVGIconImageCollection: TSVGIconImageCollection;
    procedure DataModuleCreate(Sender: TObject);
  private
  public
    function GetEditFileType(const Extension : string) : TEditFileType;
    function GetFilter(const Language : string = '') : string;
    function GetSynHighlighter(const ADarkStyle: boolean;
      const ABackgroundColor: TColor) : TSynCustomHighlighter;
  end;

function ReformatJSON(const AJSONText: string): string;
function GetOpenDialogFilter(const AOnlyTextFormat: boolean): string;
function GetSupportedExtensions(const AOnlyTextFormat: boolean): TArray<string>;

var
  dmResources: TdmResources;

  AFileTypes : Array of TEditFileType;

implementation

{$R *.dfm}

uses
  System.Math.Vectors
  , System.JSON
  , REST.Json
  , System.StrUtils
  , Skia
  , skia.Vcl
  ;


function ReformatJSON(const AJSONText: string): string;
var
  LJSONObject: TJSONObject;
begin
  //format JSON text
  LJSONObject := TJSONObject.ParseJSONValue(AJSONText, True, True) as TJSONObject;
  Result := TJSON.Format(LJSONObject);
end;

procedure TdmResources.DataModuleCreate(Sender: TObject);
var
  i,p : integer;
begin
  p := 0;
  for i := 0 to ComponentCount -1 do
  begin
    if Components[i] is TSynCustomHighlighter then
      inc(p);
  end;
  SetLength(AFileTypes, p);

  p := 0;
  for i := 0 to ComponentCount -1 do
  begin
    if Components[i] is TSynCustomHighlighter then
    begin
      AFileTypes[p].ComponentName := Components[i].Name;
      AFileTypes[p].LanguageName := (Components[i] as TSynCustomHighlighter).LanguageName;
      AFileTypes[p].FileExtensions := (Components[i] as TSynCustomHighlighter).DefaultFilter;
      AFileTypes[p].SynHighlighter := (Components[i] as TSynCustomHighlighter);
      inc(p);
    end;
  end;
end;

function TdmResources.GetEditFileType(
  const Extension: string): TEditFileType;
var
  i : integer;
begin
  Result := AFileTypes[0]; //Svg
  for i := low(AFileTypes) to high(AFileTypes) do
  begin
    if Pos(Extension, AFileTypes[i].FileExtensions) <> 0 then
    begin
      Result := AFileTypes[i];
      break;
    end;
  end;
end;

function TdmResources.GetFilter(const Language: string) : string;
var
  i : integer;
begin
  Result := '';
  for i := low(AFileTypes) to high(AFileTypes) do
  begin
    if (Language = '') or SameText(Language, afileTypes[i].LanguageName) then
    begin
      Result := Result + AFileTypes[i].FileExtensions+'|';
    end;
  end;
end;

function TdmResources.GetSynHighlighter(
  const ADarkStyle: boolean;
  const ABackgroundColor: TColor): TSynCustomHighlighter;
begin
  if ADarkStyle then
  begin
    Result := dmResources.SynJSONSynDark;
    SynJSONSynDark.AttributeAttri.Background := ABackgroundColor;
    SynJSONSynDark.SpaceAttri.Background := ABackgroundColor;
    SynJSONSynDark.ReservedAttri.Background := ABackgroundColor;
    SynJSONSynDark.SymbolAttri.Background := ABackgroundColor;
    SynJSONSynDark.SpaceAttri.Background := ABackgroundColor;
    SynJSONSynDark.SymbolAttri.Background := ABackgroundColor;
  end
  else
  begin
    Result := dmResources.SynJSONSyn;
    SynJSONSyn.AttributeAttri.Background := ABackgroundColor;
    SynJSONSyn.SpaceAttri.Background := ABackgroundColor;
    SynJSONSyn.ReservedAttri.Background := ABackgroundColor;
    SynJSONSyn.SymbolAttri.Background := ABackgroundColor;
    SynJSONSyn.SpaceAttri.Background := ABackgroundColor;
    SynJSONSyn.SymbolAttri.Background := ABackgroundColor;
  end;
end;

function GetOpenDialogFilter(const AOnlyTextFormat: boolean): string;
const
  AllFiles = 'All files';
  AllImagesDescription = 'All animated images';
var
  LCodecClass: TSkAnimatedImage.TAnimationCodecClass;
  LFormat: TSkAnimatedImage.TFormatInfo;
  LAllExtensions: string;
  LExtensions: string;
begin
  Result := '';
  LAllExtensions := '';
  for LCodecClass in TSkAnimatedImage.RegisteredCodecs do
  begin
    for LFormat in LCodecClass.SupportedFormats do
    begin
      LExtensions := string('').Join(';', LFormat.Extensions);
      if AOnlyTextFormat and not (SameText(LExtensions,'.json;.lottie')) then
        Continue;
      begin
        Result := Result + Format('|%s (%s)|%s', [LFormat.Description, LExtensions, LExtensions]);
        if not LAllExtensions.IsEmpty then
          LAllExtensions := LAllExtensions + ';';
        LAllExtensions := LAllExtensions + LExtensions;
      end;
    end;
  end;
  if not AOnlyTextFormat then
    Result := Format('%s (%s)|%s', [AllImagesDescription, LAllExtensions, LAllExtensions]) + Result
  else
    Result := Copy(Result,2,maxint);
  Result := Result + Format('|%s (%s)|%s', [AllFiles, '.*', '.*']);
  Result := Result.Replace('.', '*.');
end;

function GetSupportedExtensions(const AOnlyTextFormat: boolean): TArray<string>;
var
  LCodecClass: TSkAnimatedImage.TAnimationCodecClass;
  LFormat: TSkAnimatedImage.TFormatInfo;
  LExtension: string;
  LExtensions: string;
begin
  Result := [];
  //Add animation extensions
  for LCodecClass in TSkAnimatedImage.RegisteredCodecs do
    for LFormat in LCodecClass.SupportedFormats do
    begin
      LExtensions := string('').Join(';', LFormat.Extensions);
      if AOnlyTextFormat and not (SameText(LExtensions,'.json;.lottie')) then
        Continue;
      for LExtension in LFormat.Extensions do
        Result := Result + [LExtension];
    end;
(*
  //Add image extensions
  if not AOnlyTextFormat then
  begin
    //Result := Result + ['.svg'];
    Result := Result + ['.webp'];
    Result := Result + ['.wbmp'];
    Result := Result + ['.arw'];
    Result := Result + ['.cr2'];
    Result := Result + ['.dng'];
    Result := Result + ['.nef'];
    Result := Result + ['.nrw'];
    Result := Result + ['.orf'];
    Result := Result + ['.raf'];
    Result := Result + ['.rw2'];
    Result := Result + ['.pef'];
    Result := Result + ['.srw'];
  end;
*)
end;

end.
