{ Model.LogEntry - Registro de auditoria do sistema.
  Captura automaticamente timestamp e hostname (GetComputerName). }
unit Model.LogEntry;

interface

uses
  System.SysUtils, System.Classes;

type
  { Níveis de severidade do log }
  ENivelLog = (
    nlDebug,    // Detalhes técnicos (apenas em desenvolvimento)
    nlInfo,     // Ações normais do usuário
    nlWarning,  // Situações inesperadas mas não críticas
    nlError,    // Erros que afetam funcionalidade
    nlFatal     // Erros que impedem o sistema de funcionar
  );

  { Registro de auditoria - rastreabilidade de ações no sistema }
  TLogEntry = class
  private
    FID: Integer;
    FDataHora: TDateTime;
    FUsuarioID: Integer;
    FUsuarioNome: string;
    FAcao: string;
    FTabela: string;
    FRegistroID: string;
    FDescricao: string;
    FNivel: ENivelLog;
    FIPMaquina: string;
    FNomeMaquina: string;
  public
    constructor Create; overload;
    constructor Create(ANivel: ENivelLog; const AAcao, ADescricao: string); overload;
    destructor Destroy; override;

    function NivelToString: string;
    class function StringToNivel(const AValue: string): ENivelLog;
    function ToString: string; override;

    property ID: Integer read FID write FID;
    property DataHora: TDateTime read FDataHora write FDataHora;
    property UsuarioID: Integer read FUsuarioID write FUsuarioID;
    property UsuarioNome: string read FUsuarioNome write FUsuarioNome;
    property Acao: string read FAcao write FAcao;
    property Tabela: string read FTabela write FTabela;
    property RegistroID: string read FRegistroID write FRegistroID;
    property Descricao: string read FDescricao write FDescricao;
    property Nivel: ENivelLog read FNivel write FNivel;
    property IPMaquina: string read FIPMaquina write FIPMaquina;
    property NomeMaquina: string read FNomeMaquina write FNomeMaquina;
  end;

implementation

uses
  { Winapi.Windows para obter nome da máquina }
  Winapi.Windows;

constructor TLogEntry.Create;
var
  LBuffer: array[0..MAX_COMPUTERNAME_LENGTH] of Char;
  LSize: DWORD;
begin
  inherited Create;
  FDataHora := Now;
  FNivel := nlInfo;

  { Obtém o nome da máquina automaticamente via API do Windows }
  LSize := MAX_COMPUTERNAME_LENGTH + 1;
  if GetComputerName(LBuffer, LSize) then
    FNomeMaquina := LBuffer
  else
    FNomeMaquina := 'DESCONHECIDO';
end;

constructor TLogEntry.Create(ANivel: ENivelLog; const AAcao, ADescricao: string);
begin
  Create;
  FNivel := ANivel;
  FAcao := AAcao;
  FDescricao := ADescricao;
end;

destructor TLogEntry.Destroy;
begin
  inherited Destroy;
end;

function TLogEntry.NivelToString: string;
begin
  case FNivel of
    nlDebug:   Result := 'DEBUG';
    nlInfo:    Result := 'INFO';
    nlWarning: Result := 'WARNING';
    nlError:   Result := 'ERROR';
    nlFatal:   Result := 'FATAL';
  else
    Result := 'INFO';
  end;
end;

class function TLogEntry.StringToNivel(const AValue: string): ENivelLog;
var
  LValue: string;
begin
  LValue := UpperCase(Trim(AValue));
  if LValue = 'DEBUG' then Result := nlDebug
  else if LValue = 'WARNING' then Result := nlWarning
  else if LValue = 'ERROR' then Result := nlError
  else if LValue = 'FATAL' then Result := nlFatal
  else Result := nlInfo;
end;

function TLogEntry.ToString: string;
begin
  Result := Format('[%s] %s - %s: %s',
    [FormatDateTime('yyyy-mm-dd hh:nn:ss', FDataHora),
     NivelToString, FAcao, FDescricao]);
end;

end.
