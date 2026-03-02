object FrmPOIManager: TFrmPOIManager
  Left = 0
  Top = 0
  BorderStyle = bsSizeable
  Caption = 'GeoManager - Gerenciador de Pontos de Interesse'
  ClientHeight = 650
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15

  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 300
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0

    object lstPOIs: TListView
      Left = 0
      Top = 0
      Width = 900
      Height = 300
      Align = alClient
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
      OnSelectItem = lstPOIsSelectItem
    end
  end

  object pnlEdit: TPanel
    Left = 0
    Top = 300
    Width = 900
    Height = 300
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1

    object lblNome: TLabel
      Left = 16
      Top = 16
      Width = 35
      Height = 15
      Caption = 'Nome:'
    end
    object edtNome: TEdit
      Left = 100
      Top = 13
      Width = 400
      Height = 23
      Enabled = False
      TabOrder = 0
    end
    object lblDescricao: TLabel
      Left = 16
      Top = 48
      Width = 60
      Height = 15
      Caption = 'Descri'#231#227'o:'
    end
    object mmoDescricao: TMemo
      Left = 100
      Top = 45
      Width = 400
      Height = 55
      Enabled = False
      TabOrder = 1
    end
    object lblLatitude: TLabel
      Left = 16
      Top = 115
      Width = 47
      Height = 15
      Caption = 'Latitude:'
    end
    object edtLatitude: TEdit
      Left = 100
      Top = 112
      Width = 180
      Height = 23
      Enabled = False
      TabOrder = 2
    end
    object lblLongitude: TLabel
      Left = 300
      Top = 115
      Width = 58
      Height = 15
      Caption = 'Longitude:'
    end
    object edtLongitude: TEdit
      Left = 370
      Top = 112
      Width = 180
      Height = 23
      Enabled = False
      TabOrder = 3
    end
    object lblTipo: TLabel
      Left = 16
      Top = 147
      Width = 27
      Height = 15
      Caption = 'Tipo:'
    end
    object cmbTipo: TComboBox
      Left = 100
      Top = 144
      Width = 200
      Height = 23
      Style = csDropDownList
      Enabled = False
      TabOrder = 4
    end
    object lblEndereco: TLabel
      Left = 16
      Top = 179
      Width = 54
      Height = 15
      Caption = 'Endere'#231'o:'
    end
    object edtEndereco: TEdit
      Left = 100
      Top = 176
      Width = 400
      Height = 23
      Enabled = False
      TabOrder = 5
    end
    object btnGeocoding: TButton
      Left = 510
      Top = 175
      Width = 100
      Height = 25
      Caption = 'Geocodificar'
      Enabled = False
      TabOrder = 6
      OnClick = btnGeocodingClick
    end
  end

  object pnlBottom: TPanel
    Left = 0
    Top = 600
    Width = 900
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2

    object btnNovo: TButton
      Left = 16
      Top = 10
      Width = 100
      Height = 30
      Caption = 'Novo'
      TabOrder = 0
      OnClick = btnNovoClick
    end
    object btnSalvar: TButton
      Left = 128
      Top = 10
      Width = 100
      Height = 30
      Caption = 'Salvar'
      Enabled = False
      TabOrder = 1
      OnClick = btnSalvarClick
    end
    object btnExcluir: TButton
      Left = 240
      Top = 10
      Width = 100
      Height = 30
      Caption = 'Excluir'
      Enabled = False
      TabOrder = 2
      OnClick = btnExcluirClick
    end
    object btnCancelar: TButton
      Left = 352
      Top = 10
      Width = 100
      Height = 30
      Caption = 'Cancelar'
      Enabled = False
      TabOrder = 3
      OnClick = btnCancelarClick
    end
    object btnFechar: TButton
      Left = 784
      Top = 10
      Width = 100
      Height = 30
      Caption = 'Fechar'
      TabOrder = 4
      OnClick = btnFecharClick
    end
  end
end
