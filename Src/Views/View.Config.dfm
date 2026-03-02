object FrmConfig: TFrmConfig
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'GeoManager - Configura'#231#245'es'
  ClientHeight = 450
  ClientWidth = 550
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 15

  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 550
    Height = 395
    ActivePage = tabBanco
    Align = alClient
    TabOrder = 0

    object tabBanco: TTabSheet
      Caption = 'Banco de Dados'
      object lblTipoBD: TLabel
        Left = 16
        Top = 20
        Width = 27
        Height = 15
        Caption = 'Tipo:'
      end
      object cmbTipoBD: TComboBox
        Left = 120
        Top = 17
        Width = 200
        Height = 23
        Style = csDropDownList
        TabOrder = 0
      end
      object lblServidor: TLabel
        Left = 16
        Top = 55
        Width = 50
        Height = 15
        Caption = 'Servidor:'
      end
      object edtServidor: TEdit
        Left = 120
        Top = 52
        Width = 300
        Height = 23
        TabOrder = 1
        Text = 'localhost'
      end
      object lblPorta: TLabel
        Left = 16
        Top = 90
        Width = 32
        Height = 15
        Caption = 'Porta:'
      end
      object edtPorta: TEdit
        Left = 120
        Top = 87
        Width = 80
        Height = 23
        TabOrder = 2
        Text = '1433'
      end
      object lblBanco: TLabel
        Left = 16
        Top = 125
        Width = 38
        Height = 15
        Caption = 'Banco:'
      end
      object edtBanco: TEdit
        Left = 120
        Top = 122
        Width = 300
        Height = 23
        TabOrder = 3
        Text = 'GeoManagerDB'
      end
      object lblUsuarioDB: TLabel
        Left = 16
        Top = 160
        Width = 46
        Height = 15
        Caption = 'Usu'#225'rio:'
      end
      object edtUsuarioDB: TEdit
        Left = 120
        Top = 157
        Width = 200
        Height = 23
        TabOrder = 4
      end
      object lblSenhaDB: TLabel
        Left = 16
        Top = 195
        Width = 35
        Height = 15
        Caption = 'Senha:'
      end
      object edtSenhaDB: TEdit
        Left = 120
        Top = 192
        Width = 200
        Height = 23
        PasswordChar = '*'
        TabOrder = 5
      end
      object chkAuthWindows: TCheckBox
        Left = 120
        Top = 228
        Width = 250
        Height = 17
        Caption = 'Usar Autentica'#231#227'o Windows (Integrada)'
        TabOrder = 6
      end
    end

    object tabArcGIS: TTabSheet
      Caption = 'ArcGIS'
      object lblArcGISURL: TLabel
        Left = 16
        Top = 20
        Width = 53
        Height = 15
        Caption = 'URL Base:'
      end
      object edtArcGISURL: TEdit
        Left = 120
        Top = 17
        Width = 400
        Height = 23
        TabOrder = 0
      end
      object lblApiKey: TLabel
        Left = 16
        Top = 55
        Width = 47
        Height = 15
        Caption = 'API Key:'
      end
      object edtApiKey: TEdit
        Left = 120
        Top = 52
        Width = 400
        Height = 23
        TabOrder = 1
      end
      object lblArcGISInfo: TLabel
        Left = 16
        Top = 95
        Width = 420
        Height = 60
        Caption = 
          'Para obter uma API Key gratuita, acesse: '#13#10'https://developers.ar' +
          'cgis.com'#13#10#13#10'A API Key '#233' necess'#225'ria para geocodifica'#231#227'o e servi'#231'os premium.'
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        ParentFont = False
      end
    end

    object tabMapa: TTabSheet
      Caption = 'Mapa'
      object lblCentroLat: TLabel
        Left = 16
        Top = 20
        Width = 90
        Height = 15
        Caption = 'Centro Latitude:'
      end
      object edtCentroLat: TEdit
        Left = 140
        Top = 17
        Width = 150
        Height = 23
        TabOrder = 0
        Text = '-15.7939'
      end
      object lblCentroLon: TLabel
        Left = 16
        Top = 55
        Width = 100
        Height = 15
        Caption = 'Centro Longitude:'
      end
      object edtCentroLon: TEdit
        Left = 140
        Top = 52
        Width = 150
        Height = 23
        TabOrder = 1
        Text = '-47.8828'
      end
      object lblZoom: TLabel
        Left = 16
        Top = 90
        Width = 77
        Height = 15
        Caption = 'Zoom Padr'#227'o:'
      end
      object edtZoom: TEdit
        Left = 140
        Top = 87
        Width = 60
        Height = 23
        TabOrder = 2
        Text = '5'
      end
    end

    object tabLog: TTabSheet
      Caption = 'Logging'
      object lblNivelLog: TLabel
        Left = 16
        Top = 20
        Width = 81
        Height = 15
        Caption = 'N'#237'vel M'#237'nimo:'
      end
      object cmbNivelLog: TComboBox
        Left = 120
        Top = 17
        Width = 150
        Height = 23
        Style = csDropDownList
        TabOrder = 0
      end
      object chkLogArquivo: TCheckBox
        Left = 120
        Top = 55
        Width = 200
        Height = 17
        Caption = 'Gravar log em arquivo'
        Checked = True
        State = cbChecked
        TabOrder = 1
      end
    end
  end

  object pnlBotoes: TPanel
    Left = 0
    Top = 395
    Width = 550
    Height = 55
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1

    object btnSalvar: TButton
      Left = 250
      Top = 12
      Width = 90
      Height = 30
      Caption = 'Salvar'
      TabOrder = 0
      OnClick = btnSalvarClick
    end
    object btnTestar: TButton
      Left = 350
      Top = 12
      Width = 90
      Height = 30
      Caption = 'Testar Conex'#227'o'
      TabOrder = 1
      OnClick = btnTestarClick
    end
    object btnCancelar: TButton
      Left = 450
      Top = 12
      Width = 90
      Height = 30
      Caption = 'Cancelar'
      TabOrder = 2
      OnClick = btnCancelarClick
    end
  end
end
