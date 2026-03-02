{ View.DataModule - Módulo não-visual com os componentes FireDAC.
  Centraliza FDConnection, FDQuery e TDataSource compartilhados entre formulários. }
unit View.DataModule;

interface

uses
  System.SysUtils, System.Classes,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.VCLUI.Wait, FireDAC.Comp.Client, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.DataSet, Data.DB,
  FireDAC.Phys.SQLite;

type
  TDmGeoManager = class(TDataModule)
    { Conexão principal com banco de dados }
    FDConnection: TFDConnection;
    { Query para POIs }
    qryPOI: TFDQuery;
    { DataSource conecta query ao DBGrid }
    dsPOI: TDataSource;
    { Query para Usuários }
    qryUsuarios: TFDQuery;
    dsUsuarios: TDataSource;
    { Query genérica para consultas avulsos }
    qryGeneric: TFDQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    procedure ConfigurarConexao;
  public
    function Conectar: Boolean;
    procedure Desconectar;
    function EstaConectado: Boolean;
    procedure CarregarPOIs;
    procedure CarregarUsuarios;
  end;

var
  { Variável global - criada automaticamente pelo Application.CreateForm }
  DmGeoManager: TDmGeoManager;

implementation

{$R *.dfm}

uses
  Utils.Config, Utils.Logger, DAO.Connection;

procedure TDmGeoManager.DataModuleCreate(Sender: TObject);
begin
  { Evento OnCreate: executado quando o DataModule é criado.
    Configura a conexão com base no arquivo INI }
  ConfigurarConexao;
  TLogger.GetInstance.Info('DataModule', 'Create', 'DataModule inicializado');
end;

procedure TDmGeoManager.DataModuleDestroy(Sender: TObject);
begin
  Desconectar;
  TLogger.GetInstance.Info('DataModule', 'Destroy', 'DataModule destruído');
end;

procedure TDmGeoManager.ConfigurarConexao;
var
  LConfig: TConfigManager;
  LTipo: string;
begin
  LConfig := TConfigManager.GetInstance;

  FDConnection.Params.Clear;
  LTipo := UpperCase(LConfig.GetTipoDB);

  if LTipo = 'ORACLE' then
  begin
    FDConnection.Params.Add('DriverID=Ora');
    FDConnection.Params.Add('Database=' + LConfig.GetServidorDB + ':' +
      IntToStr(LConfig.GetPortaDB) + '/' + LConfig.GetNomeDB);
    if LConfig.GetUsuarioDB <> '' then
    begin
      FDConnection.Params.Add('User_Name=' + LConfig.GetUsuarioDB);
      FDConnection.Params.Add('Password=' + LConfig.GetSenhaDB);
    end;
  end
  else if (LTipo = 'MSSQL') or (LTipo = 'SQLSERVER') then
  begin
    { ODBC com driver "SQL Server" (Community Edition não tem FireDAC.Phys.MSSQL) }
    FDConnection.Params.Add('DriverID=ODBC');
    FDConnection.Params.Add('ODBCDriver=SQL Server');
    FDConnection.Params.Add('Server=' + LConfig.GetServidorDB + ',' +
      IntToStr(LConfig.GetPortaDB));
    FDConnection.Params.Add('Database=' + LConfig.GetNomeDB);
    if LConfig.GetUsuarioDB <> '' then
    begin
      FDConnection.Params.Add('User_Name=' + LConfig.GetUsuarioDB);
      FDConnection.Params.Add('Password=' + LConfig.GetSenhaDB);
    end
    else
      FDConnection.Params.Add('Trusted_Connection=Yes');
  end
  else
  begin
    { Default to SQLite }
    ForceDirectories(ExtractFilePath(LConfig.GetNomeDB));
    FDConnection.Params.Add('DriverID=SQLite');
    FDConnection.Params.Add('Database=' + LConfig.GetNomeDB);
    FDConnection.Params.Add('LockingMode=Normal');
  end;

  FDConnection.LoginPrompt := False;
end;

function TDmGeoManager.Conectar: Boolean;
var
  LConn: TConnectionManager;
begin
  Result := False;
  try
    FDConnection.Connected := True;
    Result := True;
    TLogger.GetInstance.Info('DataModule', 'Conectar', 'Conectado ao banco');

    { Sincroniza o ConnectionManager singleton para que os DAOs funcionem }
    LConn := TConnectionManager.GetInstance;
    LConn.CarregarConfiguracao(TConfigManager.GetInstance.CaminhoINI);
    LConn.Conectar;
  except
    on E: Exception do
    begin
      TLogger.GetInstance.Error('DataModule', 'Conectar', 'Erro: ' + E.Message);
      raise; { Re-lança para o View.Main exibir a mensagem real ao usuário }
    end;
  end;
end;

procedure TDmGeoManager.Desconectar;
begin
  qryPOI.Close;
  qryUsuarios.Close;
  qryGeneric.Close;
  FDConnection.Connected := False;
end;

function TDmGeoManager.EstaConectado: Boolean;
begin
  Result := FDConnection.Connected;
end;

procedure TDmGeoManager.CarregarPOIs;
begin
  qryPOI.Close;
  qryPOI.SQL.Text := 'SELECT * FROM GEO_PONTOS_INTERESSE WHERE POI_ATIVO = 1 ORDER BY POI_NOME';
  qryPOI.Open;
end;

procedure TDmGeoManager.CarregarUsuarios;
begin
  qryUsuarios.Close;
  qryUsuarios.SQL.Text := 'SELECT * FROM GEO_USUARIOS ORDER BY USU_NOME';
  qryUsuarios.Open;
end;

end.
