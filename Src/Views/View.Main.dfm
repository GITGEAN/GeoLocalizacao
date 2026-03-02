object FrmMain: TFrmMain
  Left = 0
  Top = 0
  Caption = 'GeoManager - Sistema de Geoprocessamento'
  ClientHeight = 700
  ClientWidth = 1100
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu1
  Position = poScreenCenter
  WindowState = wsMaximized
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 320
    Top = 50
    Width = 5
    Height = 625
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    ExplicitWidth = 1098
    object lblBusca: TLabel
      Left = 12
      Top = 16
      Width = 92
      Height = 15
      Caption = 'Buscar/Endere'#231'o:'
    end
    object edtBusca: TEdit
      Left = 110
      Top = 13
      Width = 400
      Height = 23
      TabOrder = 0
      TextHint = 'Digite um nome de POI ou endere'#231'o para geocodificar...'
    end
    object btnBuscar: TButton
      Left = 520
      Top = 12
      Width = 90
      Height = 25
      Caption = 'Buscar POI'
      TabOrder = 1
      OnClick = btnBuscarClick
    end
    object btnGeocoding: TButton
      Left = 618
      Top = 12
      Width = 110
      Height = 25
      Caption = 'Geocodificar'
      TabOrder = 2
      OnClick = btnGeocodingClick
    end
    object cmbTipoPOI: TComboBox
      Left = 742
      Top = 13
      Width = 150
      Height = 23
      Style = csDropDownList
      TabOrder = 3
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 50
    Width = 320
    Height = 625
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitHeight = 617
    DesignSize = (
      320
      625)
    object lblResultados: TLabel
      Left = 8
      Top = 4
      Width = 60
      Height = 15
      Caption = 'Resultados:'
    end
    object lstResultados: TListBox
      Left = 0
      Top = 24
      Width = 320
      Height = 280
      Anchors = [akLeft, akTop, akRight]
      ItemHeight = 15
      TabOrder = 0
      OnClick = lstResultadosClick
    end
    object mmoDetalhes: TMemo
      Left = 0
      Top = 350
      Width = 320
      Height = 220
      Anchors = [akLeft, akTop, akRight, akBottom]
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 1
      ExplicitHeight = 212
    end
    object btnVerNoMapa: TButton
      Left = 8
      Top = 312
      Width = 145
      Height = 30
      Caption = 'Ver no Mapa'
      TabOrder = 2
      OnClick = btnVerNoMapaClick
    end
    object btnAdicionarPOI: TButton
      Left = 165
      Top = 312
      Width = 145
      Height = 30
      Caption = 'Gerenciar POIs'
      TabOrder = 3
      OnClick = btnAdicionarPOIClick
    end
  end
  object pnlMap: TPanel
    Left = 325
    Top = 50
    Width = 775
    Height = 625
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitWidth = 773
    ExplicitHeight = 617
    object WebBrowser1: TWebBrowser
      Left = 0
      Top = 0
      Width = 775
      Height = 625
      Align = alClient
      TabOrder = 0
      ExplicitWidth = 773
      ExplicitHeight = 617
      ControlData = {
        4C00000014400000AD3300000000000000000000000000000000000000000000
        000000004C000000000000000000000001000000E0D057007335CF11AE690800
        2B2E126208000000000000004C0000000114020000000000C000000000000046
        8000000000000000000000000000000000000000000000000000000000000000
        00000000000000000100000000000000000000000000000000000000}
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 675
    Width = 1100
    Height = 25
    Panels = <>
    SimplePanel = True
    SimpleText = 'Pronto'
    ExplicitTop = 667
    ExplicitWidth = 1098
  end
  object MainMenu1: TMainMenu
    Left = 920
    Top = 8
    object mnuArquivo: TMenuItem
      Caption = '&Arquivo'
      object mnuArqConectar: TMenuItem
        Caption = '&Conectar ao Banco'
        ShortCut = 16451
        OnClick = mnuArqConectarClick
      end
      object mnuArqDesconectar: TMenuItem
        Caption = '&Desconectar'
        OnClick = mnuArqDesconectarClick
      end
      object mnuArqSep1: TMenuItem
        Caption = '-'
      end
      object mnuArqConfig: TMenuItem
        Caption = 'Co&nfigura'#231#245'es...'
        ShortCut = 16455
        OnClick = mnuArqConfigClick
      end
      object mnuArqSep2: TMenuItem
        Caption = '-'
      end
      object mnuArqSair: TMenuItem
        Caption = '&Sair'
        ShortCut = 32883
        OnClick = mnuArqSairClick
      end
    end
    object mnuPOI: TMenuItem
      Caption = '&POIs'
      object mnuPOIGerenciar: TMenuItem
        Caption = '&Gerenciar Pontos de Interesse'
        ShortCut = 16464
        OnClick = mnuPOIGerenciarClick
      end
      object mnuPOINovo: TMenuItem
        Caption = '&Novo POI...'
        ShortCut = 16462
      end
    end
    object mnuMapa: TMenuItem
      Caption = '&Mapa'
      object mnuMapaCentralizar: TMenuItem
        Caption = '&Centralizar no Brasil'
        ShortCut = 16456
        OnClick = mnuMapaCentralizarClick
      end
      object mnuMapaLimpar: TMenuItem
        Caption = '&Limpar Marcadores'
      end
    end
    object mnuAjuda: TMenuItem
      Caption = 'Aj&uda'
      object mnuAjudaSobre: TMenuItem
        Caption = '&Sobre...'
        ShortCut = 112
        OnClick = mnuAjudaSobreClick
      end
    end
  end
end
