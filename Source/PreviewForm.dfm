inherited FrmPreview: TFrmPreview
  Left = 522
  Top = 286
  ClientHeight = 616
  ClientWidth = 613
  DoubleBuffered = True
  Font.Name = 'Segoe UI'
  OnAfterMonitorDpiChanged = FormAfterMonitorDpiChanged
  OnResize = FormResize
  ExplicitWidth = 629
  ExplicitHeight = 655
  TextHeight = 13
  inherited Label1: TLabel
    Top = 338
    Width = 607
    Height = 216
    ExplicitTop = 338
    ExplicitWidth = 146
  end
  object Splitter: TSplitter
    Left = 0
    Top = 329
    Width = 613
    Height = 6
    Cursor = crVSplit
    Align = alTop
    AutoSnap = False
    MinSize = 100
    OnMoved = SplitterMoved
    ExplicitWidth = 888
  end
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 613
    Height = 35
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object ToolBar: TToolBar
      Left = 0
      Top = 0
      Width = 617
      Height = 35
      Align = alClient
      AutoSize = True
      ButtonHeight = 30
      ButtonWidth = 35
      EdgeInner = esNone
      EdgeOuter = esNone
      Images = SVGIconImageList
      List = True
      TabOrder = 0
      ExplicitWidth = 613
      object ToolButtonPlay: TToolButton
        Left = 0
        Top = 0
        Cursor = crHandPoint
        Hint = 'Play/Restart animation'
        AutoSize = True
        Caption = 'Play'
        ImageIndex = 13
        ImageName = 'play'
        OnClick = ToolButtonPlayClick
        OnMouseEnter = ToolButtonMouseEnter
        OnMouseLeave = ToolButtonMouseLeave
      end
      object ToolButtonPause: TToolButton
        Left = 35
        Top = 0
        Cursor = crHandPoint
        Hint = 'Pause animation'
        AutoSize = True
        Caption = 'Pause'
        Enabled = False
        ImageIndex = 12
        ImageName = 'pause'
        OnClick = ToolButtonPauseClick
        OnMouseEnter = ToolButtonMouseEnter
        OnMouseLeave = ToolButtonMouseLeave
      end
      object ToolButtonStop: TToolButton
        Left = 70
        Top = 0
        Hint = 'Stop animation'
        AutoSize = True
        Caption = 'Stop'
        Enabled = False
        ImageIndex = 14
        ImageName = 'Stop'
        OnClick = ToolButtonStopClick
        OnMouseEnter = ToolButtonMouseEnter
        OnMouseLeave = ToolButtonMouseLeave
      end
      object ToolButtonSettings: TToolButton
        Left = 105
        Top = 0
        Cursor = crHandPoint
        Hint = 'Preview settings...'
        AutoSize = True
        Caption = 'Settings...'
        ImageIndex = 11
        ImageName = 'preferences-desktop'
        Visible = False
        OnClick = ToolButtonSettingsClick
        OnMouseEnter = ToolButtonMouseEnter
        OnMouseLeave = ToolButtonMouseLeave
      end
      object ToolButtonAbout: TToolButton
        Left = 140
        Top = 0
        Cursor = crHandPoint
        Hint = 'Show about...'
        AutoSize = True
        Caption = 'About...'
        ImageIndex = 2
        ImageName = 'about'
        Visible = False
        OnClick = ToolButtonAboutClick
        OnMouseEnter = ToolButtonMouseEnter
        OnMouseLeave = ToolButtonMouseLeave
      end
      object ToolButtonShowText: TToolButton
        Left = 175
        Top = 0
        Cursor = crHandPoint
        AutoSize = True
        Caption = 'Hide text'
        ImageIndex = 1
        ImageName = 'Hide-Text'
        Visible = False
        OnClick = ToolButtonShowTextClick
        OnMouseEnter = ToolButtonMouseEnter
        OnMouseLeave = ToolButtonMouseLeave
      end
      object ToolButtonReformat: TToolButton
        Left = 210
        Top = 0
        Cursor = crHandPoint
        Hint = 'Reformat JSON text'
        AutoSize = True
        Caption = 'Format'
        ImageIndex = 10
        ImageName = 'Reformat'
        OnClick = ToolButtonReformatClick
        OnMouseEnter = ToolButtonMouseEnter
        OnMouseLeave = ToolButtonMouseLeave
      end
      object ToolButtonZoomOut: TToolButton
        Left = 245
        Top = 0
        Cursor = crHandPoint
        Hint = 'Zoom out (decrease font size)'
        AutoSize = True
        Caption = 'Zoom Out'
        ImageIndex = 7
        ImageName = 'minus'
        Visible = False
        OnClick = ToolButtonZoomOutClick
        OnMouseEnter = ToolButtonMouseEnter
        OnMouseLeave = ToolButtonMouseLeave
      end
      object ToolButtonZoomIn: TToolButton
        Left = 280
        Top = 0
        Cursor = crHandPoint
        Hint = 'Zoom in (increase font size)'
        AutoSize = True
        Caption = 'Zoom In'
        ImageIndex = 6
        ImageName = 'plus'
        Visible = False
        OnClick = ToolButtonZoomInClick
        OnMouseEnter = ToolButtonMouseEnter
        OnMouseLeave = ToolButtonMouseLeave
      end
    end
  end
  object PanelEditor: TPanel
    Left = 0
    Top = 35
    Width = 613
    Height = 294
    Align = alTop
    BevelOuter = bvNone
    Caption = 'PanelEditor'
    ParentBackground = False
    TabOrder = 1
    Visible = False
    object SynEdit: TSynEdit
      Left = 0
      Top = 0
      Width = 617
      Height = 294
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Pitch = fpFixed
      Font.Style = []
      TabOrder = 0
      CodeFolding.GutterShapeSize = 11
      CodeFolding.CollapsedLineColor = clGrayText
      CodeFolding.FolderBarLinesColor = clGrayText
      CodeFolding.IndentGuidesColor = clGray
      CodeFolding.IndentGuides = True
      CodeFolding.ShowCollapsedLine = False
      CodeFolding.ShowHintMark = True
      UseCodeFolding = False
      BorderStyle = bsNone
      Gutter.Font.Charset = DEFAULT_CHARSET
      Gutter.Font.Color = clWindowText
      Gutter.Font.Height = -11
      Gutter.Font.Name = 'Consolas'
      Gutter.Font.Style = []
      Gutter.ShowLineNumbers = True
      ReadOnly = True
      FontSmoothing = fsmNone
      ExplicitWidth = 613
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 597
    Width = 613
    Height = 19
    Panels = <>
    ParentFont = True
    SimplePanel = True
    SimpleText = 
      'SKIA Preview - Ver.%s (%dbit)- Copyright '#169' 2021-2022 Ethea S.r.l' +
      '. - Author: Carlo Barazzetta'
    UseSystemFont = False
  end
  object ImagePanel: TPanel
    Left = 0
    Top = 335
    Width = 613
    Height = 222
    Align = alClient
    BevelOuter = bvNone
    DoubleBuffered = True
    ParentBackground = False
    ParentColor = True
    ParentDoubleBuffered = False
    TabOrder = 3
    StyleElements = []
    ExplicitLeft = 1
    ExplicitWidth = 617
    ExplicitHeight = 223
    object panelPreview: TPanel
      Left = 0
      Top = 0
      Width = 617
      Height = 40
      Align = alTop
      ParentBackground = False
      ShowCaption = False
      TabOrder = 0
      ExplicitWidth = 613
      object BackgroundGrayScaleLabel: TLabel
        Left = 10
        Top = 6
        Width = 56
        Height = 29
        AutoSize = False
        Caption = 'Backlight %:'
        WordWrap = True
      end
      object BackgroundTrackBar: TTrackBar
        AlignWithMargins = True
        Left = 81
        Top = 4
        Width = 532
        Height = 32
        Margins.Left = 80
        Align = alClient
        Max = 255
        Frequency = 10
        Position = 117
        TabOrder = 0
        TabStop = False
        OnChange = BackgroundTrackBarChange
        ExplicitWidth = 528
      end
    end
  end
  object PlayerPanel: TPanel
    Left = 0
    Top = 557
    Width = 613
    Height = 40
    Align = alBottom
    BevelInner = bvLowered
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 4
    object RunLabel: TLabel
      AlignWithMargins = True
      Left = 572
      Top = 11
      Width = 38
      Height = 22
      Margins.Left = 10
      Margins.Top = 10
      Margins.Right = 6
      Margins.Bottom = 6
      Align = alRight
      AutoSize = False
      Caption = '0 %'
      WordWrap = True
      ExplicitLeft = 127
      ExplicitTop = 13
    end
    object TrackBar: TTrackBar
      AlignWithMargins = True
      Left = 124
      Top = 4
      Width = 435
      Height = 32
      Align = alClient
      Max = 100
      Frequency = 5
      TabOrder = 0
      OnChange = TrackBarChange
      ExplicitWidth = 431
    end
    object TogglePanel: TPanel
      Left = 1
      Top = 1
      Width = 120
      Height = 38
      Align = alLeft
      TabOrder = 1
      object LoopToggleSwitch: TToggleSwitch
        Left = 6
        Top = 3
        Width = 100
        Height = 20
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        StateCaptions.CaptionOn = 'Loop'
        StateCaptions.CaptionOff = 'No Loop'
        TabOrder = 0
        OnClick = LoopToggleSwitchClick
      end
    end
  end
  object SVGIconImageList: TVirtualImageList
    Images = <
      item
        CollectionIndex = 42
        CollectionName = 'Show-Text'
        Name = 'Show-Text'
      end
      item
        CollectionIndex = 43
        CollectionName = 'Hide-Text'
        Name = 'Hide-Text'
      end
      item
        CollectionIndex = 23
        CollectionName = 'about'
        Name = 'about'
      end
      item
        CollectionIndex = 41
        CollectionName = 'Support'
        Name = 'Support'
      end
      item
        CollectionIndex = 0
        CollectionName = 'Style'
        Name = 'Style'
      end
      item
        CollectionIndex = 45
        CollectionName = 'Services'
        Name = 'Services'
      end
      item
        CollectionIndex = 26
        CollectionName = 'plus'
        Name = 'plus'
      end
      item
        CollectionIndex = 25
        CollectionName = 'Minus'
        Name = 'Minus'
      end
      item
        CollectionIndex = 6
        CollectionName = 'Search'
        Name = 'Search'
      end
      item
        CollectionIndex = 38
        CollectionName = 'export'
        Name = 'export'
      end
      item
        CollectionIndex = 19
        CollectionName = 'Reformat'
        Name = 'Reformat'
      end
      item
        CollectionIndex = 28
        CollectionName = 'preferences-desktop'
        Name = 'preferences-desktop'
      end
      item
        CollectionIndex = 50
        CollectionName = 'pause'
        Name = 'pause'
      end
      item
        CollectionIndex = 51
        CollectionName = 'play'
        Name = 'play'
      end
      item
        CollectionIndex = 52
        CollectionName = 'stop'
        Name = 'stop'
      end>
    ImageCollection = dmResources.SVGIconImageCollection
    Width = 24
    Height = 24
    Left = 384
    Top = 208
  end
end
