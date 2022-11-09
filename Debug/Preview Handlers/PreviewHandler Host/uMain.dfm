object FrmMain: TFrmMain
  Left = 0
  Top = 0
  Caption = 'Preview Handler Host Demo'
  ClientHeight = 559
  ClientWidth = 960
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 121
    Top = 35
    Width = 4
    Height = 524
    AutoSnap = False
    ExplicitLeft = 112
    ExplicitTop = -8
    ExplicitHeight = 559
  end
  object Splitter2: TSplitter
    Left = 542
    Top = 35
    Width = 4
    Height = 524
    AutoSnap = False
    ExplicitLeft = 8
    ExplicitTop = -28
    ExplicitHeight = 559
  end
  object Panel1: TPanel
    Left = 546
    Top = 35
    Width = 414
    Height = 524
    Align = alClient
    TabOrder = 0
    ExplicitWidth = 410
    ExplicitHeight = 523
  end
  object Panel3: TPanel
    Left = 125
    Top = 35
    Width = 417
    Height = 524
    Align = alLeft
    TabOrder = 1
    ExplicitHeight = 523
    object ShellListView: TShellListView
      Left = 1
      Top = 1
      Width = 415
      Height = 522
      ObjectTypes = [otFolders, otNonFolders]
      Root = 'rfDesktop'
      ShellTreeView = ShellTreeView
      Sorted = True
      Align = alClient
      ReadOnly = False
      HideSelection = False
      OnChange = ShellListViewChange
      TabOrder = 0
    end
  end
  object ShellTreeView: TShellTreeView
    Left = 0
    Top = 35
    Width = 121
    Height = 524
    ObjectTypes = [otFolders]
    Root = 'rfDesktop'
    ShellListView = ShellListView
    UseShellImages = True
    Align = alLeft
    AutoRefresh = False
    Indent = 19
    ParentColor = False
    RightClickSelect = True
    ShowRoot = False
    TabOrder = 2
    ExplicitHeight = 523
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 960
    Height = 35
    Align = alTop
    TabOrder = 3
    ExplicitWidth = 956
    object PathEditor: TEdit
      AlignWithMargins = True
      Left = 6
      Top = 6
      Width = 948
      Height = 23
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alClient
      TabOrder = 0
      OnChange = PathEditorChange
      ExplicitWidth = 944
      ExplicitHeight = 21
    end
  end
end
