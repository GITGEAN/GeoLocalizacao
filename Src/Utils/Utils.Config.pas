{ Utils.Config - Gerenciador de configurações via GeoManager.ini (Singleton).
  Leitura tipada com fallback para valores padrão. }
unit Utils.Config;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles;

type
  TConfigManager = class
  private
    class var FInstance: TConfigManager;
    var
    FIniFile: TIniFile;
    FCaminhoINI: string;

    constructor CreatePrivate(const ACaminhoINI: string);
  public
    destructor Destroy; override;

    class function GetInstance: TConfigManager;
    class procedure Initialize(const ACaminhoINI: string);
    class procedure ReleaseInstance;

    { Leitura tipada de configurações }
    function ReadString(const ASecao, AChave, APadrao: string): string;
    function ReadInteger(const ASecao, AChave: string; APadrao: Integer): Integer;
    function ReadFloat(const ASecao, AChave: string; APadrao: Double): Double;
    function ReadBool(const ASecao, AChave: string; APadrao: Boolean): Boolean;

    { Escrita de configurações }
    procedure WriteString(const ASecao, AChave, AValor: string);
    procedure WriteInteger(const ASecao, AChave: string; AValor: Integer);
    procedure WriteBool(const ASecao, AChave: string; AValor: Boolean);

    { Configurações de banco de dados }
    function GetServidorDB: string;
    function GetPortaDB: Integer;
    function GetNomeDB: string;
    function GetUsuarioDB: string;
    function GetSenhaDB: string;
    function GetTipoDB: string;

    { Configurações do ArcGIS }
    function GetArcGISBaseURL: string;
    function GetArcGISApiKey: string;

    { Configurações do mapa }
    function GetMapaCentroLatitude: Double;
    function GetMapaCentroLongitude: Double;
    function GetMapaZoomPadrao: Integer;

    property CaminhoINI: string read FCaminhoINI;
  end;

implementation

class procedure TConfigManager.Initialize(const ACaminhoINI: string);
begin
  if Assigned(FInstance) then
    FreeAndNil(FInstance);
  FInstance := TConfigManager.CreatePrivate(ACaminhoINI);
end;

class function TConfigManager.GetInstance: TConfigManager;
begin
  if not Assigned(FInstance) then
  begin
    { Se não foi inicializado, usa caminho padrão }
    Initialize(ExtractFilePath(ParamStr(0)) + 'GeoManager.ini');
  end;
  Result := FInstance;
end;

class procedure TConfigManager.ReleaseInstance;
begin
  FreeAndNil(FInstance);
end;

constructor TConfigManager.CreatePrivate(const ACaminhoINI: string);
begin
  inherited Create;
  FCaminhoINI := ACaminhoINI;
  FIniFile := TIniFile.Create(ACaminhoINI);
end;

destructor TConfigManager.Destroy;
begin
  FreeAndNil(FIniFile);
  inherited Destroy;
end;

{ Leitura }
function TConfigManager.ReadString(const ASecao, AChave, APadrao: string): string;
begin
  Result := FIniFile.ReadString(ASecao, AChave, APadrao);
end;

function TConfigManager.ReadInteger(const ASecao, AChave: string; APadrao: Integer): Integer;
begin
  Result := FIniFile.ReadInteger(ASecao, AChave, APadrao);
end;

function TConfigManager.ReadFloat(const ASecao, AChave: string; APadrao: Double): Double;
begin
  Result := FIniFile.ReadFloat(ASecao, AChave, APadrao);
end;

function TConfigManager.ReadBool(const ASecao, AChave: string; APadrao: Boolean): Boolean;
begin
  Result := FIniFile.ReadBool(ASecao, AChave, APadrao);
end;

{ Escrita }
procedure TConfigManager.WriteString(const ASecao, AChave, AValor: string);
begin
  FIniFile.WriteString(ASecao, AChave, AValor);
end;

procedure TConfigManager.WriteInteger(const ASecao, AChave: string; AValor: Integer);
begin
  FIniFile.WriteInteger(ASecao, AChave, AValor);
end;

procedure TConfigManager.WriteBool(const ASecao, AChave: string; AValor: Boolean);
begin
  FIniFile.WriteBool(ASecao, AChave, AValor);
end;

{ Configurações de Banco }
function TConfigManager.GetServidorDB: string;
begin
  Result := ReadString('DATABASE', 'Servidor', 'localhost');
end;

function TConfigManager.GetPortaDB: Integer;
begin
  Result := ReadInteger('DATABASE', 'Porta', 1433);
end;

function TConfigManager.GetNomeDB: string;
begin
  Result := ReadString('DATABASE', 'Banco', ExtractFilePath(ParamStr(0)) + 'data\GeoManager.db');
end;

function TConfigManager.GetUsuarioDB: string;
begin
  Result := ReadString('DATABASE', 'Usuario', '');
end;

function TConfigManager.GetSenhaDB: string;
begin
  Result := ReadString('DATABASE', 'Senha', '');
end;

function TConfigManager.GetTipoDB: string;
begin
  Result := ReadString('DATABASE', 'Tipo', 'SQLITE');
end;

{ Configurações ArcGIS }
function TConfigManager.GetArcGISBaseURL: string;
begin
  Result := ReadString('ARCGIS', 'BaseURL',
    'https://geocode.arcgis.com/arcgis/rest/services');
end;

function TConfigManager.GetArcGISApiKey: string;
begin
  Result := ReadString('ARCGIS', 'ApiKey', '');
end;

{ Configurações do Mapa }
function TConfigManager.GetMapaCentroLatitude: Double;
begin
  Result := ReadFloat('MAPA', 'CentroLatitude', -15.7939);
end;

function TConfigManager.GetMapaCentroLongitude: Double;
begin
  Result := ReadFloat('MAPA', 'CentroLongitude', -47.8828);
end;

function TConfigManager.GetMapaZoomPadrao: Integer;
begin
  Result := ReadInteger('MAPA', 'ZoomPadrao', 5);
end;

initialization

finalization
  TConfigManager.ReleaseInstance;

end.
