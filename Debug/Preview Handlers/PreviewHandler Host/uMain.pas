unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.OleCtnrs, uHostPreview,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Shell.ShellCtrls;

type
  TFrmMain = class(TForm)
    Panel1: TPanel;
    Panel3: TPanel;
    ShellListView: TShellListView;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    ShellTreeView: TShellTreeView;
    Panel2: TPanel;
    PathEditor: TEdit;
    procedure ShellListViewChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PathEditorChange(Sender: TObject);
  private
    FFileName: string;
    { Private declarations }
    FPreview: THostPreviewHandler;
    procedure LoadPreview(const FileName: string);
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;

implementation


{$R *.dfm}

type
  THostPreviewHandlerClass=class(THostPreviewHandler);


procedure TFrmMain.FormCreate(Sender: TObject);
begin
  FPreview := nil;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  if FPreview<>nil then
   FPreview.Free;
end;

procedure TFrmMain.LoadPreview(const FileName: string);
begin
  if FPreview = nil then
    FPreview := THostPreviewHandler.Create(Self);

//  if FPreview<>nil then
//   FPreview.Free;

  FPreview.Top := 0;
  FPreview.Left := 0;
  FPreview.Width := Panel1.ClientWidth;
  FPreview.Height := Panel1.ClientHeight;
  FPreview.Parent := Panel1;
  FPreview.Align := alClient;
  //FPreview.FileName:='C:\Users\Dexter\Desktop\RAD Studio Projects\XE2\delphi-preview-handler\main.pas';
  //FPreview.FileName:='C:\Users\Dexter\Desktop\RAD Studio Projects\2010\SMBIOS Delphi\Docs\DSP0119.pdf';
  //FPreview.FileName:='C:\Users\Dexter\Desktop\seleccion\RePLE.msg';
  FPreview.FileName:=FileName;
  THostPreviewHandlerClass(FPreview).Paint;
end;

procedure TFrmMain.PathEditorChange(Sender: TObject);
begin
  if DirectoryExists(PathEditor.Text) then
    ShellTreeView.Root := PathEditor.Text
  else if PathEditor.Text = '' then
    ShellTreeView.Root := 'rfDesktop';
end;

procedure TFrmMain.ShellListViewChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
var
  LFileName: string;
begin
 if (ShellListView.SelectedFolder<>nil) then
 begin
   LFileName := ShellListView.SelectedFolder.PathName;
   if (LFileName <> FFileName) and FileExists(LFileName) then
   begin
     LoadPreview(LFileName);
     FFileName := LFileName;
   end;
 end;
end;

end.
