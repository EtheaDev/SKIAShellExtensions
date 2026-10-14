{******************************************************************************}
{                                                                              }
{       SKIA Shell Extensions: Shell extensions for animated files             }
{       (Preview Panel, Thumbnail Icon, File Editor)                           }
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
unit uLottieColorScanner;

//Finds every color value written in the text of a Lottie animation (JSON),
//together with its position in the text, and groups them into a palette.
//In Lottie a color is almost never a string: it is an array of numbers (RGB or
//RGBA, from 0 to 1), and the same array could just as well be a position or a
//scale. What makes it a color is where it is: the key holding it and the type
//("ty") of the objects containing it. So the text is read by a minimal JSON
//tokenizer that keeps the position of every value and the chain of keys that
//leads to it; the rules on the chain are applied at the end of the scan,
//because "ty" can come after the color in the same object.
//Recognized colors:
//- fill and stroke ("ty":"fl"/"st"): "c":{"k":[r,g,b,a]}, animated keyframes
//  "c":{"k":[{"s":[...]}, ...]} (also "e" of the old Bodymovin format);
//- gradient stops ("ty":"gf"/"gs"): "g":{"p":n,"k":{"k":[o,r,g,b, ...]}},
//  static or animated: one occurrence for every stop, r,g,b only;
//- solid layers ("ty":1): "sc":"#rrggbb";
//- text documents: "s":{"fc":[r,g,b],"sc":[r,g,b]};
//- color effect values ("ty":2 inside "ef"): "v":{"k":[r,g,b,a]};
//- slots: "slots":{"id":{"p":{"k":[r,g,b,a]}}}, values from 0 to 1 only.
//Old exports with values from 0 to 255 are recognized (a component > 1).
//The unit has no VCL dependencies so it can be tested on its own.

interface

uses
  System.SysUtils,
  System.UITypes;

type
  TLottieColorFormat = (lcfFloatRGB, lcfFloatRGBA, lcfIntRGB, lcfIntRGBA,
    lcfHex, lcfGradientStop);

  //Position of one of the r, g, b numbers inside RawText (0-based)
  TLottieColorComponent = record
    Start: Integer;
    Len: Integer;
  end;

  TLottieColorOccurrence = record
    Offset: Integer;        //1-based position in the scanned text
    EndOffset: Integer;     //1-based position after the last char
    Line: Integer;          //1-based line of the first char (TBufferCoord.Line)
    CharStart: Integer;     //1-based char in Line (TBufferCoord.Char)
    EndLine: Integer;       //1-based line of the last char: a formatted array
                            //spans more lines
    CharEnd: Integer;       //1-based char in EndLine after the last char
    RawText: string;        //the value as written: '[1,0,0,1]', '#ff0000',
                            //'1,0,0' for a gradient stop
    Color: TAlphaColor;     //$AARRGGBB
    Format: TLottieColorFormat;
    Scale255: Boolean;      //components written from 0 to 255 (old exports)
    Decimals: Integer;      //max decimals of the r,g,b numbers as written
    PropertyName: string;   //'fill', 'stroke', 'gradient fill stop 2', ...
    Components: array[0..2] of TLottieColorComponent; //r,g,b (arrays only)
    function Length: Integer;
  end;
  TLottieColorOccurrences = TArray<TLottieColorOccurrence>;

  //One entry of the palette: the occurrences are grouped by RGB (8 bit),
  //ignoring the alpha. Two floats giving the same byte (0.9372 and 0.93725)
  //are the same entry, as they are the same color in the animation.
  TLottiePaletteEntry = record
    Color: TAlphaColor;              //opaque RGB of the group
    Occurrences: TArray<Integer>;    //indexes in the occurrences array
    PropertyNames: TArray<string>;   //distinct properties using the color
    Alphas: TArray<Byte>;            //distinct alpha values used
    function Count: Integer;
  end;
  TLottiePalette = TArray<TLottiePaletteEntry>;

  TLottieColorScanner = class
  public
    //Scans the whole text of a Lottie animation. The occurrences are returned
    //in text order. A text that is not valid JSON (e.g. while typing) gives
    //the colors found in the part that can be read.
    class function Scan(const AText: string): TLottieColorOccurrences; static;
    //Groups the occurrences by RGB, in order of first appearance.
    class function BuildPalette(
      const AOccurrences: TLottieColorOccurrences): TLottiePalette; static;
    //Index of the palette entry with the given color (alpha ignored), or -1.
    class function IndexOfColor(const APalette: TLottiePalette;
      const AColor: TAlphaColor): Integer; static;
    //Index of the occurrence containing the given text position, or -1.
    class function OccurrenceAt(const AOccurrences: TLottieColorOccurrences;
      const ALine, AChar: Integer): Integer; static;
    //Parses '#RRGGBB', '#RGB' or '#RRGGBBAA'.
    class function TryParseHexColor(const AValue: string;
      out AColor: TAlphaColor): Boolean; static;
    //Writes a color like an existing occurrence, so a replacement keeps the
    //style of the document: an array keeps its separators, its number of
    //components, its alpha and its scale (0..1 or 0..255), every number keeps
    //its precision; a gradient stop changes only r,g,b, not the offset; a hex
    //string keeps its case.
    class function FormatColorLike(const AColor: TAlphaColor;
      const AOriginal: TLottieColorOccurrence): string; static;
    //'#RRGGBB', or '#RRGGBBAA' when the color is not opaque.
    class function ColorToHex(const AColor: TAlphaColor): string; static;
  end;

function AlphaColorToColor(const AColor: TAlphaColor): TColor;
function ColorToAlphaColor(const AColor: TColor): TAlphaColor;
function OpaqueColor(const AColor: TAlphaColor): TAlphaColor; inline;
function AlphaOf(const AColor: TAlphaColor): Byte; inline;

implementation

uses
  System.Math,
  System.Generics.Collections,
  System.Generics.Defaults;

type
  TNumberToken = record
    Offset: Integer;   //1-based
    Len: Integer;
    Value: Double;
  end;

  //The values of a JSON object that decide whether its arrays are colors.
  //They are known only when the whole object has been read.
  TObjectInfo = record
    TyStr: string;     //"ty" written as a string: 'fl', 'st', 'gf', 'gs'...
    TyNum: Integer;    //"ty" written as a number: 1 = solid layer,
                       //2 = color value of an effect; -1 = none
    P: Integer;        //"p" written as a number: stops of a gradient; -1 = none
  end;

  //A container being read
  TFrame = record
    IsObject: Boolean;
    ObjId: Integer;          //objects: index in the object infos
    Key: string;             //objects: key of the value being read
    ExpectKey: Boolean;      //objects: the next string is a key
    ReachedBy: string;       //key in the parent object, '#' for an array
                             //element, '' for the root
    StartOffset: Integer;    //arrays: offset of '['
    AllNumbers: Boolean;     //arrays: only numbers so far
    NumberBase: Integer;     //arrays: index of its first number
  end;

  //One step of the way from a value up to the root
  TStep = record
    ReachedBy: string;
    ObjId: Integer;          //-1 when the step is not an object
  end;

  TCandidateKind = (ckArray, ckHexString);

  //A value that may be a color: decided once the whole text has been read
  TCandidate = record
    Kind: TCandidateKind;
    StartOffset: Integer;
    EndOffset: Integer;
    Numbers: TArray<TNumberToken>;
    //[0] = the value itself (ObjId -1), [1] = its container, ... up to root
    Chain: TArray<TStep>;
  end;

  TLottieTokenizer = class
  private
    FText: string;
    FStack: TArray<TFrame>;
    FStackCount: Integer;
    FObjects: TArray<TObjectInfo>;
    FObjectCount: Integer;
    FNumbers: TArray<TNumberToken>;
    FNumberCount: Integer;
    FCandidates: TList<TCandidate>;
    FLineStarts: TArray<Integer>;
    FOccurrences: TList<TLottieColorOccurrence>;
    function Top: Integer; inline;
    procedure Push(const AFrame: TFrame);
    function CurrentReachedBy: string;
    procedure OpenContainer(const AIsObject: Boolean; const AOffset: Integer);
    procedure CloseContainer(const AOffset: Integer);
    procedure ValueIsNotNumber;
    procedure HandleString(const AStart, AEnd: Integer);
    procedure HandleNumber(const AStart, ALen: Integer);
    function BuildChain(const AValueReachedBy: string): TArray<TStep>;
    procedure Tokenize;
    procedure BuildLineStarts;
    procedure OffsetToPos(const AOffset: Integer; out ALine, AChar: Integer);
    //Rules
    function StepKey(const ACandidate: TCandidate; const AIndex: Integer): string;
    function StepObj(const ACandidate: TCandidate; const AIndex: Integer): Integer;
    function ColorPropertyName(const ACandidate: TCandidate;
      const ABase: Integer; out AName: string; out AOnlyUnitRange: Boolean): Boolean;
    function GradientInfo(const ACandidate: TCandidate; const ABase: Integer;
      out AName: string; out AStops: Integer): Boolean;
    procedure ResolveCandidate(const ACandidate: TCandidate);
    procedure AddArrayColor(const ACandidate: TCandidate; const AName: string;
      const AFirst, ACount: Integer; const AIsGradientStop, AOnlyUnitRange: Boolean);
    procedure AddHexColor(const ACandidate: TCandidate; const AName: string);
    procedure FillPosition(var AOccurrence: TLottieColorOccurrence);
  public
    constructor Create(const AText: string);
    destructor Destroy; override;
    function Execute: TLottieColorOccurrences;
  end;

const
  NO_OBJECT = -1;

function AlphaColorToColor(const AColor: TAlphaColor): TColor;
begin
  //$AARRGGBB -> $00BBGGRR
  Result := TColor(((AColor and $FF) shl 16) or (AColor and $FF00) or
    ((AColor shr 16) and $FF));
end;

function ColorToAlphaColor(const AColor: TColor): TAlphaColor;
var
  LRGB: Cardinal;
begin
  LRGB := Cardinal(AColor) and $FFFFFF;
  Result := $FF000000 or ((LRGB and $FF) shl 16) or (LRGB and $FF00) or
    ((LRGB shr 16) and $FF);
end;

function OpaqueColor(const AColor: TAlphaColor): TAlphaColor;
begin
  Result := AColor or $FF000000;
end;

function AlphaOf(const AColor: TAlphaColor): Byte;
begin
  Result := AColor shr 24;
end;

function MakeColor(const R, G, B, A: Integer): TAlphaColor;
begin
  Result := (Cardinal(EnsureRange(A, 0, 255)) shl 24) or
    (Cardinal(EnsureRange(R, 0, 255)) shl 16) or
    (Cardinal(EnsureRange(G, 0, 255)) shl 8) or
    Cardinal(EnsureRange(B, 0, 255));
end;

//A component of a Lottie color as a byte
function ComponentToByte(const AValue: Double; const AScale255: Boolean): Integer;
begin
  if AScale255 then
    Result := EnsureRange(Round(AValue), 0, 255)
  else
    Result := EnsureRange(Round(AValue * 255), 0, 255);
end;

//Decimals of a number as written ('0.94' -> 2); 0 with an exponent
function DecimalsOf(const ANumber: string): Integer;
var
  LDot: Integer;
begin
  Result := 0;
  if (Pos('e', ANumber) > 0) or (Pos('E', ANumber) > 0) then
    Exit;
  LDot := Pos('.', ANumber);
  if LDot > 0 then
    Result := Length(ANumber) - LDot;
end;

//The number is written with trailing zeros ('0.500')
function HasTrailingZeros(const ANumber: string): Boolean;
begin
  Result := (DecimalsOf(ANumber) > 0) and (ANumber[Length(ANumber)] = '0');
end;

//A component from 0 to 1 with ADecimals decimals: fixed ('0.500') or with the
//trailing zeros removed ('0.5')
function FormatUnitValue(const AByte, ADecimals: Integer;
  const AFixed: Boolean): string;
var
  LFormat: string;
begin
  if ADecimals = 0 then
    LFormat := '0'
  else if AFixed then
    LFormat := '0.' + StringOfChar('0', ADecimals)
  else
    LFormat := '0.' + StringOfChar('#', ADecimals);
  Result := FormatFloat(LFormat, AByte / 255, TFormatSettings.Invariant);
end;

function ReadsBackAs(const AText: string; const AByte: Integer): Boolean;
var
  LValue: Double;
begin
  Result := TryStrToFloat(AText, LValue, TFormatSettings.Invariant) and
    (ComponentToByte(LValue, False) = AByte);
end;

{ TLottieColorOccurrence }

function TLottieColorOccurrence.Length: Integer;
begin
  Result := EndOffset - Offset;
end;

{ TLottiePaletteEntry }

function TLottiePaletteEntry.Count: Integer;
begin
  Result := System.Length(Occurrences);
end;

{ TLottieTokenizer }

constructor TLottieTokenizer.Create(const AText: string);
begin
  inherited Create;
  FText := AText;
  FCandidates := TList<TCandidate>.Create;
  FOccurrences := TList<TLottieColorOccurrence>.Create;
end;

destructor TLottieTokenizer.Destroy;
begin
  FOccurrences.Free;
  FCandidates.Free;
  inherited;
end;

function TLottieTokenizer.Top: Integer;
begin
  Result := FStackCount - 1;
end;

procedure TLottieTokenizer.Push(const AFrame: TFrame);
begin
  if FStackCount = System.Length(FStack) then
    SetLength(FStack, Max(16, FStackCount * 2));
  FStack[FStackCount] := AFrame;
  Inc(FStackCount);
end;

function TLottieTokenizer.CurrentReachedBy: string;
begin
  //How a value starting now is reached from its container
  if FStackCount = 0 then
    Result := ''
  else if FStack[Top].IsObject then
    Result := FStack[Top].Key
  else
    Result := '#';
end;

procedure TLottieTokenizer.ValueIsNotNumber;
begin
  if (FStackCount > 0) and not FStack[Top].IsObject then
    FStack[Top].AllNumbers := False;
end;

procedure TLottieTokenizer.OpenContainer(const AIsObject: Boolean;
  const AOffset: Integer);
var
  LFrame: TFrame;
begin
  ValueIsNotNumber;
  LFrame := Default(TFrame);
  LFrame.IsObject := AIsObject;
  LFrame.ReachedBy := CurrentReachedBy;
  LFrame.StartOffset := AOffset;
  if AIsObject then
  begin
    if FObjectCount = System.Length(FObjects) then
      SetLength(FObjects, Max(64, FObjectCount * 2));
    FObjects[FObjectCount].TyStr := '';
    FObjects[FObjectCount].TyNum := -1;
    FObjects[FObjectCount].P := -1;
    LFrame.ObjId := FObjectCount;
    Inc(FObjectCount);
    LFrame.ExpectKey := True;
  end
  else
  begin
    LFrame.ObjId := NO_OBJECT;
    LFrame.AllNumbers := True;
    LFrame.NumberBase := FNumberCount;
  end;
  Push(LFrame);
end;

function TLottieTokenizer.BuildChain(const AValueReachedBy: string): TArray<TStep>;
var
  I: Integer;
begin
  //The value itself, then the containers on the stack up to the root
  SetLength(Result, FStackCount + 1);
  Result[0].ReachedBy := AValueReachedBy;
  Result[0].ObjId := NO_OBJECT;
  for I := 0 to FStackCount - 1 do
  begin
    Result[I + 1].ReachedBy := FStack[Top - I].ReachedBy;
    Result[I + 1].ObjId := FStack[Top - I].ObjId;
  end;
end;

procedure TLottieTokenizer.CloseContainer(const AOffset: Integer);
var
  LFrame: TFrame;
  LCandidate: TCandidate;
  LCount: Integer;
begin
  if FStackCount = 0 then
    Exit; //unbalanced text: ignored
  LFrame := FStack[Top];
  Dec(FStackCount);
  if LFrame.IsObject then
    Exit;
  LCount := FNumberCount - LFrame.NumberBase;
  //Only arrays of numbers under a key that can hold a color are kept
  if LFrame.AllNumbers and (LCount >= 3) and
    (SameStr(LFrame.ReachedBy, 'k') or SameStr(LFrame.ReachedBy, 's') or
     SameStr(LFrame.ReachedBy, 'e') or SameStr(LFrame.ReachedBy, 'fc') or
     SameStr(LFrame.ReachedBy, 'sc')) then
  begin
    LCandidate := Default(TCandidate);
    LCandidate.Kind := ckArray;
    LCandidate.StartOffset := LFrame.StartOffset;
    LCandidate.EndOffset := AOffset + 1;
    LCandidate.Numbers := Copy(FNumbers, LFrame.NumberBase, LCount);
    LCandidate.Chain := BuildChain(LFrame.ReachedBy);
    FCandidates.Add(LCandidate);
  end;
  //The numbers of the array are no longer needed
  FNumberCount := LFrame.NumberBase;
end;

procedure TLottieTokenizer.HandleString(const AStart, AEnd: Integer);
var
  LValue: string;
  LCandidate: TCandidate;
begin
  //AStart = opening quote, AEnd = closing quote
  LValue := Copy(FText, AStart + 1, AEnd - AStart - 1);
  if FStackCount = 0 then
    Exit;
  if FStack[Top].IsObject then
  begin
    if FStack[Top].ExpectKey then
    begin
      FStack[Top].Key := LValue;
      FStack[Top].ExpectKey := False;
      Exit;
    end;
    if SameStr(FStack[Top].Key, 'ty') then
      FObjects[FStack[Top].ObjId].TyStr := LValue
    else if SameStr(FStack[Top].Key, 'sc') and (LValue <> '') and (LValue[1] = '#') then
    begin
      LCandidate := Default(TCandidate);
      LCandidate.Kind := ckHexString;
      //The value without the quotes
      LCandidate.StartOffset := AStart + 1;
      LCandidate.EndOffset := AEnd;
      LCandidate.Chain := BuildChain('sc');
      FCandidates.Add(LCandidate);
    end;
  end
  else
    FStack[Top].AllNumbers := False;
end;

procedure TLottieTokenizer.HandleNumber(const AStart, ALen: Integer);
var
  LValue: Double;
begin
  if not TryStrToFloat(Copy(FText, AStart, ALen), LValue, TFormatSettings.Invariant) then
  begin
    ValueIsNotNumber;
    Exit;
  end;
  if FStackCount = 0 then
    Exit;
  if FStack[Top].IsObject then
  begin
    if SameStr(FStack[Top].Key, 'ty') then
      FObjects[FStack[Top].ObjId].TyNum := Trunc(LValue)
    else if SameStr(FStack[Top].Key, 'p') then
      FObjects[FStack[Top].ObjId].P := Trunc(LValue);
  end
  else
  begin
    if FNumberCount = System.Length(FNumbers) then
      SetLength(FNumbers, Max(64, FNumberCount * 2));
    FNumbers[FNumberCount].Offset := AStart;
    FNumbers[FNumberCount].Len := ALen;
    FNumbers[FNumberCount].Value := LValue;
    Inc(FNumberCount);
  end;
end;

procedure TLottieTokenizer.Tokenize;
var
  I, L, LStart: Integer;
  C: Char;
begin
  I := 1;
  L := System.Length(FText);
  while I <= L do
  begin
    C := FText[I];
    case C of
      '{', '[':
      begin
        OpenContainer(C = '{', I);
        Inc(I);
      end;
      '}', ']':
      begin
        CloseContainer(I);
        Inc(I);
      end;
      ',':
      begin
        if (FStackCount > 0) and FStack[Top].IsObject then
        begin
          FStack[Top].ExpectKey := True;
          FStack[Top].Key := '';
        end;
        Inc(I);
      end;
      '"':
      begin
        LStart := I;
        Inc(I);
        while (I <= L) and (FText[I] <> '"') do
        begin
          if FText[I] = '\' then
            Inc(I); //escaped char
          Inc(I);
        end;
        if I > L then
          Break; //unterminated string
        HandleString(LStart, I);
        Inc(I);
      end;
      '-', '0'..'9':
      begin
        LStart := I;
        Inc(I);
        while (I <= L) and CharInSet(FText[I], ['0'..'9', '.', 'e', 'E', '+', '-']) do
          Inc(I);
        HandleNumber(LStart, I - LStart);
      end;
      'a'..'z', 'A'..'Z':
      begin
        //true, false, null (or garbage): not a number
        ValueIsNotNumber;
        while (I <= L) and CharInSet(FText[I], ['a'..'z', 'A'..'Z']) do
          Inc(I);
      end;
    else
      Inc(I); //blanks, ':' and anything unexpected
    end;
  end;
end;

procedure TLottieTokenizer.BuildLineStarts;
var
  I, LCount: Integer;
begin
  //Lines end with #10 (SynEdit Lines.Text uses #13#10): the #13 is the last
  //char of its line and never part of a value
  SetLength(FLineStarts, 64);
  FLineStarts[0] := 1;
  LCount := 1;
  for I := 1 to System.Length(FText) do
    if FText[I] = #10 then
    begin
      if LCount = System.Length(FLineStarts) then
        SetLength(FLineStarts, LCount * 2);
      FLineStarts[LCount] := I + 1;
      Inc(LCount);
    end;
  SetLength(FLineStarts, LCount);
end;

procedure TLottieTokenizer.OffsetToPos(const AOffset: Integer;
  out ALine, AChar: Integer);
var
  LLow, LHigh, LMid: Integer;
begin
  //Last line starting at or before AOffset
  LLow := 0;
  LHigh := High(FLineStarts);
  while LLow < LHigh do
  begin
    LMid := (LLow + LHigh + 1) div 2;
    if FLineStarts[LMid] <= AOffset then
      LLow := LMid
    else
      LHigh := LMid - 1;
  end;
  ALine := LLow + 1;
  AChar := AOffset - FLineStarts[LLow] + 1;
end;

function TLottieTokenizer.StepKey(const ACandidate: TCandidate;
  const AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex <= High(ACandidate.Chain)) then
    Result := ACandidate.Chain[AIndex].ReachedBy
  else
    Result := #0; //matches no key
end;

function TLottieTokenizer.StepObj(const ACandidate: TCandidate;
  const AIndex: Integer): Integer;
begin
  if (AIndex >= 0) and (AIndex <= High(ACandidate.Chain)) then
    Result := ACandidate.Chain[AIndex].ObjId
  else
    Result := NO_OBJECT;
end;

function TLottieTokenizer.ColorPropertyName(const ACandidate: TCandidate;
  const ABase: Integer; out AName: string; out AOnlyUnitRange: Boolean): Boolean;
var
  LOwner: Integer;
  LKey: string;
begin
  //Chain[ABase] is an animatable property ({"a":..,"k":..}): it is a color
  //when it is reached through a color key from the right kind of object
  Result := False;
  AOnlyUnitRange := False;
  if StepObj(ACandidate, ABase) = NO_OBJECT then
    Exit;
  LOwner := StepObj(ACandidate, ABase + 1);
  if LOwner = NO_OBJECT then
    Exit;
  LKey := StepKey(ACandidate, ABase);
  if SameStr(LKey, 'c') then
  begin
    //Fill or stroke shape
    if SameStr(FObjects[LOwner].TyStr, 'fl') then
      AName := 'fill'
    else if SameStr(FObjects[LOwner].TyStr, 'st') then
      AName := 'stroke'
    else
      Exit;
  end
  else if SameStr(LKey, 'v') then
  begin
    //Color value of an effect: {"ty":2,"v":{...}} inside "ef"
    if (FObjects[LOwner].TyNum <> 2) or
      not SameStr(StepKey(ACandidate, ABase + 1), '#') or
      not SameStr(StepKey(ACandidate, ABase + 2), 'ef') then
      Exit;
    AName := 'effect';
  end
  else if SameStr(LKey, 'p') then
  begin
    //Slot: "slots":{"id":{"p":{...}}}. A slot can hold any kind of value: a
    //color only when its numbers are from 0 to 1
    if SameStr(StepKey(ACandidate, ABase + 1), '#') or
      not SameStr(StepKey(ACandidate, ABase + 2), 'slots') then
      Exit;
    AName := 'slot ' + StepKey(ACandidate, ABase + 1);
    AOnlyUnitRange := True;
  end
  else
    Exit;
  Result := True;
end;

function TLottieTokenizer.GradientInfo(const ACandidate: TCandidate;
  const ABase: Integer; out AName: string; out AStops: Integer): Boolean;
var
  LGradient, LOwner: Integer;
begin
  //Chain[ABase] is the property {"a":..,"k":..} reached through "k" from the
  //gradient colors {"p":n,"k":..}, reached through "g" from the shape
  Result := False;
  if (StepObj(ACandidate, ABase) = NO_OBJECT) or
    not SameStr(StepKey(ACandidate, ABase), 'k') then
    Exit;
  LGradient := StepObj(ACandidate, ABase + 1);
  if (LGradient = NO_OBJECT) or not SameStr(StepKey(ACandidate, ABase + 1), 'g') then
    Exit;
  LOwner := StepObj(ACandidate, ABase + 2);
  if LOwner = NO_OBJECT then
    Exit;
  if SameStr(FObjects[LOwner].TyStr, 'gf') then
    AName := 'gradient fill'
  else if SameStr(FObjects[LOwner].TyStr, 'gs') then
    AName := 'gradient stroke'
  else
    Exit;
  AStops := FObjects[LGradient].P;
  Result := True;
end;

procedure TLottieTokenizer.FillPosition(var AOccurrence: TLottieColorOccurrence);
begin
  OffsetToPos(AOccurrence.Offset, AOccurrence.Line, AOccurrence.CharStart);
  OffsetToPos(AOccurrence.EndOffset, AOccurrence.EndLine, AOccurrence.CharEnd);
  AOccurrence.RawText := Copy(FText, AOccurrence.Offset,
    AOccurrence.EndOffset - AOccurrence.Offset);
end;

procedure TLottieTokenizer.AddArrayColor(const ACandidate: TCandidate;
  const AName: string; const AFirst, ACount: Integer;
  const AIsGradientStop, AOnlyUnitRange: Boolean);
var
  LOccurrence: TLottieColorOccurrence;
  LNumbers: TArray<TNumberToken>;
  LScale255: Boolean;
  LAlpha, I: Integer;
begin
  //ACount numbers starting at AFirst: r,g,b(,a)
  LNumbers := ACandidate.Numbers;
  LScale255 := False;
  for I := AFirst to AFirst + ACount - 1 do
  begin
    if (LNumbers[I].Value < 0) or (LNumbers[I].Value > 255) then
      Exit; //not a color
    if (I < AFirst + 3) and (LNumbers[I].Value > 1) then
      LScale255 := True;
  end;
  if LScale255 and AOnlyUnitRange then
    Exit;
  LOccurrence := Default(TLottieColorOccurrence);
  if ACount = 4 then
  begin
    //The alpha of old exports is 1 even with the components from 0 to 255
    if LNumbers[AFirst + 3].Value <= 1 then
      LAlpha := ComponentToByte(LNumbers[AFirst + 3].Value, False)
    else
      LAlpha := ComponentToByte(LNumbers[AFirst + 3].Value, True);
  end
  else
    LAlpha := 255;
  LOccurrence.Color := MakeColor(
    ComponentToByte(LNumbers[AFirst].Value, LScale255),
    ComponentToByte(LNumbers[AFirst + 1].Value, LScale255),
    ComponentToByte(LNumbers[AFirst + 2].Value, LScale255),
    LAlpha);
  LOccurrence.Scale255 := LScale255;
  if AIsGradientStop then
  begin
    //Only the r,g,b numbers: the offset of the stop stays as it is
    LOccurrence.Format := lcfGradientStop;
    LOccurrence.Offset := LNumbers[AFirst].Offset;
    LOccurrence.EndOffset := LNumbers[AFirst + 2].Offset + LNumbers[AFirst + 2].Len;
  end
  else
  begin
    if LScale255 then
    begin
      if ACount = 4 then
        LOccurrence.Format := lcfIntRGBA
      else
        LOccurrence.Format := lcfIntRGB;
    end
    else if ACount = 4 then
      LOccurrence.Format := lcfFloatRGBA
    else
      LOccurrence.Format := lcfFloatRGB;
    //The whole array, brackets included
    LOccurrence.Offset := ACandidate.StartOffset;
    LOccurrence.EndOffset := ACandidate.EndOffset;
  end;
  LOccurrence.Decimals := 0;
  for I := 0 to 2 do
  begin
    LOccurrence.Components[I].Start := LNumbers[AFirst + I].Offset - LOccurrence.Offset;
    LOccurrence.Components[I].Len := LNumbers[AFirst + I].Len;
    LOccurrence.Decimals := Max(LOccurrence.Decimals,
      DecimalsOf(Copy(FText, LNumbers[AFirst + I].Offset, LNumbers[AFirst + I].Len)));
  end;
  LOccurrence.PropertyName := AName;
  FillPosition(LOccurrence);
  FOccurrences.Add(LOccurrence);
end;

procedure TLottieTokenizer.AddHexColor(const ACandidate: TCandidate;
  const AName: string);
var
  LOccurrence: TLottieColorOccurrence;
  LColor: TAlphaColor;
begin
  if not TLottieColorScanner.TryParseHexColor(
    Copy(FText, ACandidate.StartOffset, ACandidate.EndOffset - ACandidate.StartOffset),
    LColor) then
    Exit;
  LOccurrence := Default(TLottieColorOccurrence);
  LOccurrence.Color := LColor;
  LOccurrence.Format := lcfHex;
  LOccurrence.Offset := ACandidate.StartOffset;
  LOccurrence.EndOffset := ACandidate.EndOffset;
  LOccurrence.PropertyName := AName;
  FillPosition(LOccurrence);
  FOccurrences.Add(LOccurrence);
end;

procedure TLottieTokenizer.ResolveCandidate(const ACandidate: TCandidate);
var
  LKey, LName: string;
  LCount, LStops, I: Integer;
  LOnlyUnitRange, LAnimated: Boolean;
  LBase: Integer;
begin
  LKey := StepKey(ACandidate, 0);
  if ACandidate.Kind = ckHexString then
  begin
    //"sc":"#rrggbb" of a solid layer
    if (StepObj(ACandidate, 1) <> NO_OBJECT) and
      (FObjects[StepObj(ACandidate, 1)].TyNum = 1) then
      AddHexColor(ACandidate, 'solid layer');
    Exit;
  end;
  LCount := System.Length(ACandidate.Numbers);

  //Text document: "s":{"fc":[r,g,b],"sc":[r,g,b]}
  if SameStr(LKey, 'fc') or SameStr(LKey, 'sc') then
  begin
    if (LCount in [3, 4]) and (StepObj(ACandidate, 1) <> NO_OBJECT) and
      SameStr(StepKey(ACandidate, 1), 's') then
    begin
      if SameStr(LKey, 'fc') then
        AddArrayColor(ACandidate, 'text fill', 0, LCount, False, False)
      else
        AddArrayColor(ACandidate, 'text stroke', 0, LCount, False, False);
    end;
    Exit;
  end;

  //Static value: the array is "k" of the property. Animated value: the array
  //is "s" (or "e") of a keyframe, element of the "k" array of the property.
  if SameStr(LKey, 'k') then
  begin
    LBase := 1;
    LAnimated := False;
  end
  else if (SameStr(LKey, 's') or SameStr(LKey, 'e')) and
    (StepObj(ACandidate, 1) <> NO_OBJECT) and SameStr(StepKey(ACandidate, 1), '#') and
    (StepObj(ACandidate, 2) = NO_OBJECT) and SameStr(StepKey(ACandidate, 2), 'k') then
  begin
    LBase := 3;
    LAnimated := True;
  end
  else
    Exit;

  if (LCount in [3, 4]) and ColorPropertyName(ACandidate, LBase, LName, LOnlyUnitRange) then
  begin
    if LAnimated then
      LName := LName + ' (keyframe)';
    AddArrayColor(ACandidate, LName, 0, LCount, False, LOnlyUnitRange);
  end
  else if GradientInfo(ACandidate, LBase, LName, LStops) then
  begin
    //p stops of 4 numbers (offset,r,g,b), then optional (offset,alpha) pairs
    if (LStops <= 0) or (LStops * 4 > LCount) then
      LStops := LCount div 4;
    if LAnimated then
      LName := LName + ' (keyframe)';
    for I := 0 to LStops - 1 do
      AddArrayColor(ACandidate, Format('%s stop %d', [LName, I + 1]),
        I * 4 + 1, 3, True, False);
  end;
end;

function TLottieTokenizer.Execute: TLottieColorOccurrences;
var
  LCandidate: TCandidate;
begin
  Tokenize;
  if FCandidates.Count = 0 then
    Exit(nil);
  BuildLineStarts;
  for LCandidate in FCandidates do
    ResolveCandidate(LCandidate);
  Result := FOccurrences.ToArray;
end;

{ TLottieColorScanner }

class function TLottieColorScanner.Scan(const AText: string): TLottieColorOccurrences;
var
  LTokenizer: TLottieTokenizer;
begin
  LTokenizer := TLottieTokenizer.Create(AText);
  try
    Result := LTokenizer.Execute;
  finally
    LTokenizer.Free;
  end;
end;

class function TLottieColorScanner.BuildPalette(
  const AOccurrences: TLottieColorOccurrences): TLottiePalette;
var
  LIndexes: TDictionary<TAlphaColor, Integer>;
  LEntry: Integer;
  I: Integer;
  LKey: TAlphaColor;
  LAlpha: Byte;
begin
  Result := nil;
  LIndexes := TDictionary<TAlphaColor, Integer>.Create;
  try
    for I := 0 to High(AOccurrences) do
    begin
      LKey := OpaqueColor(AOccurrences[I].Color);
      if not LIndexes.TryGetValue(LKey, LEntry) then
      begin
        LEntry := System.Length(Result);
        SetLength(Result, LEntry + 1);
        Result[LEntry].Color := LKey;
        LIndexes.Add(LKey, LEntry);
      end;
      Result[LEntry].Occurrences := Result[LEntry].Occurrences + [I];
      if TArray.IndexOf<string>(Result[LEntry].PropertyNames,
        AOccurrences[I].PropertyName) < 0 then
        Result[LEntry].PropertyNames := Result[LEntry].PropertyNames +
          [AOccurrences[I].PropertyName];
      LAlpha := AlphaOf(AOccurrences[I].Color);
      if TArray.IndexOf<Byte>(Result[LEntry].Alphas, LAlpha) < 0 then
        Result[LEntry].Alphas := Result[LEntry].Alphas + [LAlpha];
    end;
  finally
    LIndexes.Free;
  end;
end;

class function TLottieColorScanner.IndexOfColor(const APalette: TLottiePalette;
  const AColor: TAlphaColor): Integer;
var
  I: Integer;
begin
  for I := 0 to High(APalette) do
    if APalette[I].Color = OpaqueColor(AColor) then
      Exit(I);
  Result := -1;
end;

class function TLottieColorScanner.OccurrenceAt(
  const AOccurrences: TLottieColorOccurrences;
  const ALine, AChar: Integer): Integer;
var
  I: Integer;
begin
  //The caret is "on" a value also when it is right after its last char
  for I := 0 to High(AOccurrences) do
  begin
    if AOccurrences[I].Line > ALine then
      Break;
    if (ALine = AOccurrences[I].Line) and (AChar < AOccurrences[I].CharStart) then
      Continue;
    if (ALine > AOccurrences[I].EndLine) or
      ((ALine = AOccurrences[I].EndLine) and (AChar > AOccurrences[I].CharEnd)) then
      Continue;
    Exit(I);
  end;
  Result := -1;
end;

class function TLottieColorScanner.TryParseHexColor(const AValue: string;
  out AColor: TAlphaColor): Boolean;
var
  LValue: string;
  LNumber: Cardinal;
  I: Integer;
begin
  Result := False;
  AColor := 0;
  LValue := Trim(AValue);
  if (LValue = '') or (LValue[1] <> '#') then
    Exit;
  Delete(LValue, 1, 1);
  for I := 1 to System.Length(LValue) do
    if not CharInSet(LValue[I], ['0'..'9', 'a'..'f', 'A'..'F']) then
      Exit;
  case System.Length(LValue) of
    3: LValue := LValue[1] + LValue[1] + LValue[2] + LValue[2] + LValue[3] + LValue[3] + 'FF';
    6: LValue := LValue + 'FF';
    8: ;
  else
    Exit;
  end;
  LNumber := StrToUInt('$' + LValue);
  //RRGGBBAA -> AARRGGBB
  AColor := (LNumber shr 8) or ((LNumber and $FF) shl 24);
  Result := True;
end;

class function TLottieColorScanner.ColorToHex(const AColor: TAlphaColor): string;
begin
  Result := '#' + IntToHex(AColor and $FFFFFF, 6);
  if AlphaOf(AColor) <> 255 then
    Result := Result + IntToHex(AlphaOf(AColor), 2);
end;

class function TLottieColorScanner.FormatColorLike(const AColor: TAlphaColor;
  const AOriginal: TLottieColorOccurrence): string;
var
  LBytes: array[0..2] of Integer;
  LOldNumbers, LNewNumbers: array[0..2] of string;
  LUpperCase, LFixed, LReadsBack: Boolean;
  I, D, LStart, LLen: Integer;
begin
  if AOriginal.Format = lcfHex then
  begin
    //Same case of the original; lower case (the usual one) for digits only
    LUpperCase := False;
    for I := 1 to System.Length(AOriginal.RawText) do
      if CharInSet(AOriginal.RawText[I], ['A'..'F']) then
        LUpperCase := True;
    Result := '#' + IntToHex(AColor and $FFFFFF, 6);
    //#rrggbbaa: the alpha digits stay as they are
    if System.Length(AOriginal.RawText) = 9 then
      Result := Result + Copy(AOriginal.RawText, 8, 2);
    if not LUpperCase then
      Result := LowerCase(Result);
    Exit;
  end;
  LBytes[0] := (AColor shr 16) and $FF;
  LBytes[1] := (AColor shr 8) and $FF;
  LBytes[2] := AColor and $FF;
  for I := 0 to 2 do
    LOldNumbers[I] := Copy(AOriginal.RawText, AOriginal.Components[I].Start + 1,
      AOriginal.Components[I].Len);
  if AOriginal.Scale255 then
  begin
    for I := 0 to 2 do
      LNewNumbers[I] := IntToStr(LBytes[I]);
  end
  else
  begin
    //The same precision for the three numbers: the one of the original
    //(the largest number of decimals), raised only as much as needed to read
    //back the same bytes. Trailing zeros are kept only when the original is
    //written with a fixed number of decimals ('0.500,0.250,0.000').
    LFixed := (AOriginal.Decimals > 0) and
      (DecimalsOf(LOldNumbers[0]) = AOriginal.Decimals) and
      (DecimalsOf(LOldNumbers[1]) = AOriginal.Decimals) and
      (DecimalsOf(LOldNumbers[2]) = AOriginal.Decimals) and
      (HasTrailingZeros(LOldNumbers[0]) or HasTrailingZeros(LOldNumbers[1]) or
       HasTrailingZeros(LOldNumbers[2]));
    for D := AOriginal.Decimals to Max(AOriginal.Decimals, 6) do
    begin
      LReadsBack := True;
      for I := 0 to 2 do
      begin
        LNewNumbers[I] := FormatUnitValue(LBytes[I], D, LFixed);
        LReadsBack := LReadsBack and ReadsBackAs(LNewNumbers[I], LBytes[I]);
      end;
      if LReadsBack then
        Break;
    end;
  end;
  //Only the r,g,b numbers are rewritten, from the last so the positions of
  //the others do not move: brackets, separators, line breaks, alpha and the
  //offset of a gradient stop stay as they are
  Result := AOriginal.RawText;
  for I := 2 downto 0 do
  begin
    LStart := AOriginal.Components[I].Start;
    LLen := AOriginal.Components[I].Len;
    Result := Copy(Result, 1, LStart) + LNewNumbers[I] +
      Copy(Result, LStart + LLen + 1, MaxInt);
  end;
end;

end.
