object DmGeoManager: TDmGeoManager
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 375
  Width = 625
  PixelsPerInch = 120
  object FDConnection: TFDConnection
    LoginPrompt = False
    Left = 70
    Top = 30
  end
  object qryPOI: TFDQuery
    Connection = FDConnection
    Left = 70
    Top = 120
  end
  object dsPOI: TDataSource
    DataSet = qryPOI
    Left = 70
    Top = 210
  end
  object qryUsuarios: TFDQuery
    Connection = FDConnection
    Left = 220
    Top = 120
  end
  object dsUsuarios: TDataSource
    DataSet = qryUsuarios
    Left = 220
    Top = 210
  end
  object qryGeneric: TFDQuery
    Connection = FDConnection
    Left = 370
    Top = 120
  end
end
