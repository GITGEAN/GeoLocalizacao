{ Utils.Logger - Sistema de log centralizado (Singleton + thread-safe).
  Grava entradas em arquivo com nível de severidade configurável. }
unit Utils.Logger;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs,
  Model.LogEntry;

type
  TLogger = class
  private
    class var FInstance: TLogger;
    class var FLock: TCriticalSection;
    var
    FNivelMinimo: ENivelLog;
    FCaminhoArquivo: string;
    FLogEmArquivo: Boolean;
    FLogEmConsole: Boolean;

    constructor CreatePrivate;
    procedure EscreverArquivo(const ATexto: string);
    procedure EscreverConsole(const ATexto: string);
  public
    destructor Destroy; override;

    class function GetInstance: TLogger;
    class procedure ReleaseInstance;

    { Métodos de conveniência para cada nível }
    procedure Debug(const AOrigem, AMetodo, AMensagem: string);
    procedure Info(const AOrigem, AMetodo, AMensagem: string);
    procedure Warning(const AOrigem, AMetodo, AMensagem: string);
    procedure Error(const AOrigem, AMetodo, AMensagem: string);
    procedure Fatal(const AOrigem, AMetodo, AMensagem: string);

    { Método genérico de log }
    procedure Log(ANivel: ENivelLog;
      const AOrigem, AMetodo, AMensagem: string);

    property NivelMinimo: ENivelLog read FNivelMinimo write FNivelMinimo;
    property CaminhoArquivo: string read FCaminhoArquivo write FCaminhoArquivo;
    property LogEmArquivo: Boolean read FLogEmArquivo write FLogEmArquivo;
    property LogEmConsole: Boolean read FLogEmConsole write FLogEmConsole;
  end;

implementation

class function TLogger.GetInstance: TLogger;
begin
  if not Assigned(FInstance) then
  begin
    FLock.Enter;
    try
      if not Assigned(FInstance) then
        FInstance := TLogger.CreatePrivate;
    finally
      FLock.Leave;
    end;
  end;
  Result := FInstance;
end;

class procedure TLogger.ReleaseInstance;
begin
  FLock.Enter;
  try
    FreeAndNil(FInstance);
  finally
    FLock.Leave;
  end;
end;

constructor TLogger.CreatePrivate;
begin
  inherited Create;
  FNivelMinimo := nlInfo;
  FCaminhoArquivo := ExtractFilePath(ParamStr(0)) + 'logs\geomanager.log';
  FLogEmArquivo := True;
  FLogEmConsole := False;
end;

destructor TLogger.Destroy;
begin
  inherited Destroy;
end;

procedure TLogger.Log(ANivel: ENivelLog;
  const AOrigem, AMetodo, AMensagem: string);
var
  LEntry: TLogEntry;
  LTexto: string;
begin
  { Verifica se o nível do log é >= ao nível mínimo configurado }
  if Ord(ANivel) < Ord(FNivelMinimo) then
    Exit;

  LEntry := TLogEntry.Create(ANivel, AOrigem + '.' + AMetodo, AMensagem);
  try
    LTexto := Format('%s [%-7s] [%s.%s] %s',
      [FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', LEntry.DataHora),
       LEntry.NivelToString, AOrigem, AMetodo, AMensagem]);

    { Thread-safe: protege escritas simultâneas }
    FLock.Enter;
    try
      if FLogEmArquivo then
        EscreverArquivo(LTexto);
      if FLogEmConsole then
        EscreverConsole(LTexto);
    finally
      FLock.Leave;
    end;
  finally
    LEntry.Free;
  end;
end;

procedure TLogger.EscreverArquivo(const ATexto: string);
var
  LArquivo: TextFile;
  LDir: string;
begin
  try
    LDir := ExtractFilePath(FCaminhoArquivo);
    if not DirectoryExists(LDir) then
      ForceDirectories(LDir);

    AssignFile(LArquivo, FCaminhoArquivo);
    if FileExists(FCaminhoArquivo) then
      Append(LArquivo)
    else
      Rewrite(LArquivo);
    try
      WriteLn(LArquivo, ATexto);
    finally
      CloseFile(LArquivo);
    end;
  except
    // Falha silenciosa - logger não pode lançar exceções
  end;
end;

procedure TLogger.EscreverConsole(const ATexto: string);
begin
  {$IFDEF CONSOLE}
  WriteLn(ATexto);
  {$ENDIF}
end;

procedure TLogger.Debug(const AOrigem, AMetodo, AMensagem: string);
begin
  Log(nlDebug, AOrigem, AMetodo, AMensagem);
end;

procedure TLogger.Info(const AOrigem, AMetodo, AMensagem: string);
begin
  Log(nlInfo, AOrigem, AMetodo, AMensagem);
end;

procedure TLogger.Warning(const AOrigem, AMetodo, AMensagem: string);
begin
  Log(nlWarning, AOrigem, AMetodo, AMensagem);
end;

procedure TLogger.Error(const AOrigem, AMetodo, AMensagem: string);
begin
  Log(nlError, AOrigem, AMetodo, AMensagem);
end;

procedure TLogger.Fatal(const AOrigem, AMetodo, AMensagem: string);
begin
  Log(nlFatal, AOrigem, AMetodo, AMensagem);
end;

initialization
  TLogger.FLock := TCriticalSection.Create;

finalization
  TLogger.ReleaseInstance;
  FreeAndNil(TLogger.FLock);

end.
