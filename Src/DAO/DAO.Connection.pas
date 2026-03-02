{ DAO.Connection - Singleton de conexão com o banco de dados.
  Suporta SQLite, SQL Server (via ODBC) e Oracle via ETipoBanco.
  Thread-safe com double-checked locking. }
unit DAO.Connection;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, System.SyncObjs,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async,
  FireDAC.Stan.Pool, FireDAC.Phys, FireDAC.DApt,
  { Drivers FireDAC disponíveis na Community Edition:
    FireDAC.Phys.SQLite - embutido, não requer instalação
    FireDAC.Phys.ODBCBase - ODBC genérico (SQL Server, Oracle, etc via ODBC)
    NOTA: FireDAC.Phys.MSSQL não existe na Community Edition }
  FireDAC.Phys.SQLite,
  FireDAC.Phys.ODBCBase;

type
  ETipoBanco = (tbSQLite, tbSQLServer, tbOracle);


  TConnectionManager = class
  private
    class var FInstance: TConnectionManager;
    class var FLock: TCriticalSection;
    var
    FConnection: TFDConnection;
    FTipoBanco: ETipoBanco;
    FServidor: string;
    FPorta: Integer;
    FBanco: string;
    FUsuarioDB: string;
    FSenhaDB: string;
    FConectado: Boolean;


    constructor CreatePrivate;
  public
    destructor Destroy; override;

    { Ponto de acesso global ao Singleton }
    class function GetInstance: TConnectionManager;
    class procedure ReleaseInstance;

    { Carrega configuração do arquivo INI }
    procedure CarregarConfiguracao(const ACaminhoINI: string);

    { Conecta ao banco de dados }
    function Conectar: Boolean;

    { Desconecta do banco }
    procedure Desconectar;

    { Testa a conexão }
    function TestarConexao: Boolean;

    { Retorna a conexão FireDAC para uso nos DAOs }
    property Connection: TFDConnection read FConnection;
    property TipoBanco: ETipoBanco read FTipoBanco write FTipoBanco;
    property Conectado: Boolean read FConectado;
    property Servidor: string read FServidor write FServidor;
    property Porta: Integer read FPorta write FPorta;
    property Banco: string read FBanco write FBanco;
    property UsuarioDB: string read FUsuarioDB write FUsuarioDB;
    property SenhaDB: string read FSenhaDB write FSenhaDB;
  end;

implementation

uses
  System.StrUtils;

class function TConnectionManager.GetInstance: TConnectionManager;
begin
  if not Assigned(FInstance) then
  begin
    FLock.Enter;
    try
      if not Assigned(FInstance) then
        FInstance := TConnectionManager.CreatePrivate;
    finally
      FLock.Leave;
    end;
  end;
  Result := FInstance;
end;

class procedure TConnectionManager.ReleaseInstance;
begin
  FLock.Enter;
  try
    FreeAndNil(FInstance);
  finally
    FLock.Leave;
  end;
end;

constructor TConnectionManager.CreatePrivate;
begin
  inherited Create;

  FConnection := TFDConnection.Create(nil);
  FConnection.LoginPrompt := False;

  FTipoBanco := tbSQLite;
  FServidor := '';
  FPorta := 0;
  FBanco := ExtractFilePath(ParamStr(0)) + 'data\GeoManager.db';
  FUsuarioDB := '';
  FSenhaDB := '';
  FConectado := False;
end;

destructor TConnectionManager.Destroy;
begin
  Desconectar;
  FreeAndNil(FConnection);
  inherited Destroy;
end;

procedure TConnectionManager.CarregarConfiguracao(const ACaminhoINI: string);
var
  LINI: TIniFile;
begin
  LINI := TIniFile.Create(ACaminhoINI);
  try
    FServidor := LINI.ReadString('DATABASE', 'Servidor', '');
    FPorta := LINI.ReadInteger('DATABASE', 'Porta', 0);
    FBanco := LINI.ReadString('DATABASE', 'Banco',
      ExtractFilePath(ParamStr(0)) + 'data\GeoManager.db');
    FUsuarioDB := LINI.ReadString('DATABASE', 'Usuario', '');
    FSenhaDB := LINI.ReadString('DATABASE', 'Senha', '');

    { Lê o tipo de banco e converte }
    case IndexStr(UpperCase(LINI.ReadString('DATABASE', 'Tipo', 'SQLITE')),
      ['SQLITE', 'SQLSERVER', 'ORACLE']) of
      0: FTipoBanco := tbSQLite;
      1: FTipoBanco := tbSQLServer;
      2: FTipoBanco := tbOracle;
    else
      FTipoBanco := tbSQLite;
    end;
  finally
    LINI.Free;
  end;
end;

function TConnectionManager.Conectar: Boolean;
begin
  Result := False;
  try
    if FConnection.Connected then
      FConnection.Connected := False;

    { Configura o driver FireDAC conforme o tipo de banco }
    FConnection.Params.Clear;
    case FTipoBanco of
      tbSQLite:
      begin
        ForceDirectories(ExtractFilePath(FBanco));
        FConnection.Params.Add('DriverID=SQLite');
        FConnection.Params.Add('Database=' + FBanco);
        FConnection.Params.Add('LockingMode=Normal');
      end;

      tbSQLServer:
      begin
        { Community Edition não inclui FireDAC.Phys.MSSQL; usa ODBC. }
        FConnection.Params.Add('DriverID=ODBC');
        FConnection.Params.Add('ODBCDriver=SQL Server');
        FConnection.Params.Add('Server=' + FServidor + ',' + IntToStr(FPorta));
        FConnection.Params.Add('Database=' + FBanco);
        if FUsuarioDB <> '' then
        begin
          FConnection.Params.Add('User_Name=' + FUsuarioDB);
          FConnection.Params.Add('Password=' + FSenhaDB);
        end
        else
          FConnection.Params.Add('Trusted_Connection=Yes');
      end;

      tbOracle:
      begin
        FConnection.Params.Add('DriverID=Ora');
        FConnection.Params.Add('Database=' + FServidor + ':' +
          IntToStr(FPorta) + '/' + FBanco);
        FConnection.Params.Add('User_Name=' + FUsuarioDB);
        FConnection.Params.Add('Password=' + FSenhaDB);
      end;
    end;

    FConnection.Connected := True;
    FConectado := FConnection.Connected;
    Result := FConectado;

    { Inicializa as tabelas do SQLite se não existirem }
    if (FTipoBanco = tbSQLite) and Result then
    begin
      FConnection.ExecSQL(
        'CREATE TABLE IF NOT EXISTS GEO_USUARIOS (' +
        '  USU_ID INTEGER PRIMARY KEY AUTOINCREMENT,' +
        '  USU_LOGIN VARCHAR(50) NOT NULL UNIQUE,' +
        '  USU_NOME VARCHAR(100) NOT NULL,' +
        '  USU_EMAIL VARCHAR(100) NOT NULL,' +
        '  USU_SENHA_HASH VARCHAR(255) NOT NULL,' +
        '  USU_PERFIL VARCHAR(20) NOT NULL,' +
        '  USU_ATIVO INTEGER DEFAULT 1,' +
        '  USU_DATA_CRIACAO DATETIME,' +
        '  USU_DATA_ALTERACAO DATETIME' +
        ');');

      FConnection.ExecSQL(
        'CREATE TABLE IF NOT EXISTS GEO_PONTOS_INTERESSE (' +
        '  POI_ID INTEGER PRIMARY KEY AUTOINCREMENT,' +
        '  POI_NOME VARCHAR(200) NOT NULL,' +
        '  POI_DESCRICAO TEXT,' +
        '  POI_LATITUDE REAL NOT NULL,' +
        '  POI_LONGITUDE REAL NOT NULL,' +
        '  POI_TIPO VARCHAR(50) NOT NULL,' +
        '  POI_ENDERECO VARCHAR(255),' +
        '  POI_USUARIO_ID INTEGER NOT NULL,' +
        '  POI_ATIVO INTEGER DEFAULT 1,' +
        '  POI_DATA_CRIACAO DATETIME,' +
        '  POI_DATA_ALTERACAO DATETIME,' +
        '  FOREIGN KEY(POI_USUARIO_ID) REFERENCES GEO_USUARIOS(USU_ID)' +
        ');');

      { Inserir admin mock se a tabela estiver vazia }
      if FConnection.ExecSQLScalar('SELECT COUNT(*) FROM GEO_USUARIOS') = 0 then
      begin
        FConnection.ExecSQL(
          'INSERT INTO GEO_USUARIOS (USU_LOGIN, USU_NOME, USU_EMAIL, USU_SENHA_HASH, USU_PERFIL) ' +
          'VALUES (''admin'', ''Administrador'', ''admin@geomanager.com'', ''admin_hash_mock'', ''ADMINISTRADOR'');');
      end;
    end;
  except
    on E: Exception do
    begin
      FConectado := False;
      raise Exception.CreateFmt(
        'Erro ao conectar ao banco de dados: %s', [E.Message]);
    end;
  end;
end;

procedure TConnectionManager.Desconectar;
begin
  if Assigned(FConnection) and FConnection.Connected then
  begin
    FConnection.Connected := False;
    FConectado := False;
  end;
end;

function TConnectionManager.TestarConexao: Boolean;
begin
  try
    Result := Conectar;
    if Result then
      Desconectar;
  except
    Result := False;
  end;
end;

{ Inicialização e finalização da unit }
initialization
  TConnectionManager.FLock := TCriticalSection.Create;

finalization
  TConnectionManager.ReleaseInstance;
  FreeAndNil(TConnectionManager.FLock);

end.
