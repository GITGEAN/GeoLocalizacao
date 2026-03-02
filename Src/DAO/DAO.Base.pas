{ DAO.Base - Classe base para todos os DAOs do projeto.
  Centraliza ExecuteSQL, ExecuteQuery e controle de transações. }
unit DAO.Base;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  FireDAC.Comp.Client, FireDAC.Stan.Param, Data.DB,
  DAO.Connection;

type
  { Classe base para todos os DAOs do projeto.

    Uso correto:
      type TPOIDAO = class(TBaseDAO)   <- herda tudo de TBaseDAO
      begin
        function Inserir(LPOI: TPOI): Integer;
        // Pode chamar ExecuteSQL, ExecuteQuery sem redeclarar
      end;
  }
  TBaseDAO = class
  protected
    { Referência ao Singleton de conexão. NÃO destruir aqui. }
    FConnectionManager: TConnectionManager;

    function GetConnection: TFDConnection;

    { Executa INSERT/UPDATE/DELETE; retorna rowsAffected. }
    function ExecuteSQL(const ASQL: string;
      AParams: array of Variant): Integer;

    { Executa SELECT; retorna TFDQuery aberto. Callee deve liberar. }
    function ExecuteQuery(const ASQL: string;
      AParams: array of Variant): TFDQuery;

    procedure IniciarTransacao;
    procedure ConfirmarTransacao;
    procedure DesfazerTransacao;
    function EmTransacao: Boolean;

  public
    constructor Create; virtual;
    destructor Destroy; override;
  end;

implementation

uses
  Utils.Logger;

constructor TBaseDAO.Create;
begin
  inherited Create;
  { Obtém a instância Singleton do gerenciador de conexão }
  FConnectionManager := TConnectionManager.GetInstance;
end;

destructor TBaseDAO.Destroy;
begin
  inherited Destroy;
end;

function TBaseDAO.GetConnection: TFDConnection;
begin
  Result := FConnectionManager.Connection;
  if not Result.Connected then
    raise Exception.Create('Conexão com banco de dados não está ativa');
end;

function TBaseDAO.ExecuteSQL(const ASQL: string;
  AParams: array of Variant): Integer;
var
  LQuery: TFDQuery;
  I: Integer;
begin
  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := GetConnection;
      LQuery.SQL.Text := ASQL;

      { Atribui os valores aos parâmetros por posição }
      for I := 0 to High(AParams) do
      begin
        if I < LQuery.Params.Count then
          LQuery.Params[I].Value := AParams[I];
      end;

      LQuery.ExecSQL;
      Result := LQuery.RowsAffected;
    except
      on E: Exception do
      begin
        TLogger.GetInstance.Error('DAO.Base', 'ExecuteSQL',
          Format('Erro SQL: %s | Query: %s', [E.Message, ASQL]));
        raise;  // Re-lança a exceção para o chamador tratar
      end;
    end;
  finally
    LQuery.Free;
  end;
end;

function TBaseDAO.ExecuteQuery(const ASQL: string;
  AParams: array of Variant): TFDQuery;
var
  I: Integer;
begin
  Result := TFDQuery.Create(nil);
  try
    Result.Connection := GetConnection;
    Result.SQL.Text := ASQL;

    for I := 0 to High(AParams) do
    begin
      if I < Result.Params.Count then
        Result.Params[I].Value := AParams[I];
    end;

    Result.Open;
  except
    on E: Exception do
    begin
      TLogger.GetInstance.Error('DAO.Base', 'ExecuteQuery',
        Format('Erro SQL: %s | Query: %s', [E.Message, ASQL]));
      FreeAndNil(Result);
      raise;
    end;
  end;
end;

procedure TBaseDAO.IniciarTransacao;
begin
  if not GetConnection.InTransaction then
    GetConnection.StartTransaction;
end;

procedure TBaseDAO.ConfirmarTransacao;
begin
  if GetConnection.InTransaction then
    GetConnection.Commit;
end;

procedure TBaseDAO.DesfazerTransacao;
begin
  if GetConnection.InTransaction then
    GetConnection.Rollback;
end;

function TBaseDAO.EmTransacao: Boolean;
begin
  Result := GetConnection.InTransaction;
end;

end.
