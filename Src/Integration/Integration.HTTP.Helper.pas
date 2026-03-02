{ Integration.HTTP.Helper - Wrapper TRESTClient com retry automático.
  3 tentativas com backoff linear (1s, 2s, 3s) e timeout configurável. }
unit Integration.HTTP.Helper;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  REST.Client, REST.Types, REST.Json;

type
  { Helper genérico para requisições HTTP REST }
  THTTPHelper = class
  private
    FBaseURL: string;
    FTimeout: Integer;       // Timeout em milissegundos
    FMaxRetries: Integer;    // Tentativas em caso de falha
    FApiKey: string;

    { Cria e configura os componentes REST }
    procedure ConfigurarCliente(out AClient: TRESTClient;
      out ARequest: TRESTRequest; out AResponse: TRESTResponse);
  public
    constructor Create(const ABaseURL: string);
    destructor Destroy; override;

    { Requisição GET - retorna JSON }
    function Get(const AEndpoint: string;
      AParams: TStringList = nil): TJSONValue;

    { Requisição POST - envia e retorna JSON }
    function Post(const AEndpoint: string;
      ABody: TJSONObject): TJSONValue;

    { Requisição GET com retorno de string bruta }
    function GetRaw(const AEndpoint: string;
      AParams: TStringList = nil): string;

    property BaseURL: string read FBaseURL write FBaseURL;
    property Timeout: Integer read FTimeout write FTimeout;
    property MaxRetries: Integer read FMaxRetries write FMaxRetries;
    property ApiKey: string read FApiKey write FApiKey;
  end;

implementation

uses
  Utils.Logger;

constructor THTTPHelper.Create(const ABaseURL: string);
begin
  inherited Create;
  FBaseURL := ABaseURL;
  FTimeout := 30000;   // 30 segundos padrão
  FMaxRetries := 3;
  FApiKey := '';
end;

destructor THTTPHelper.Destroy;
begin
  inherited Destroy;
end;

procedure THTTPHelper.ConfigurarCliente(out AClient: TRESTClient;
  out ARequest: TRESTRequest; out AResponse: TRESTResponse);
begin
  { CONCEITO: TRESTClient/TRESTRequest/TRESTResponse são os componentes
    nativos do Delphi para REST API. Foram introduzidos no Delphi XE5.
    São a forma recomendada de consumir APIs REST no Delphi moderno. }
  AClient := TRESTClient.Create(nil);
  ARequest := TRESTRequest.Create(nil);
  AResponse := TRESTResponse.Create(nil);

  AClient.BaseURL := FBaseURL;
  AClient.ContentType := 'application/json';
  ARequest.Client := AClient;
  ARequest.Response := AResponse;
  ARequest.Timeout := FTimeout;
  ARequest.Accept := 'application/json';

  { Adiciona API Key se configurada }
  if FApiKey <> '' then
    ARequest.Params.AddItem('token', FApiKey,
      TRESTRequestParameterKind.pkGETorPOST);
end;

function THTTPHelper.Get(const AEndpoint: string;
  AParams: TStringList): TJSONValue;
var
  LClient: TRESTClient;
  LRequest: TRESTRequest;
  LResponse: TRESTResponse;
  LTentativa: Integer;
  I: Integer;
begin
  Result := nil;
  ConfigurarCliente(LClient, LRequest, LResponse);
  try
    LRequest.Resource := AEndpoint;
    LRequest.Method := TRESTRequestMethod.rmGET;

    { Adiciona parâmetros da query string }
    if Assigned(AParams) then
    begin
      for I := 0 to AParams.Count - 1 do
        LRequest.Params.AddItem(AParams.Names[I],
          AParams.ValueFromIndex[I],
          TRESTRequestParameterKind.pkGETorPOST);
    end;

    { Retry pattern: tenta N vezes antes de desistir }
    for LTentativa := 1 to FMaxRetries do
    begin
      try
        LRequest.Execute;

        if LResponse.StatusCode = 200 then
        begin
          if Assigned(LResponse.JSONValue) then
            Result := LResponse.JSONValue.Clone as TJSONValue;
          Exit;
        end
        else
        begin
          TLogger.GetInstance.Warning('HTTP.Helper', 'Get',
            Format('HTTP %d na tentativa %d: %s',
              [LResponse.StatusCode, LTentativa, AEndpoint]));
        end;
      except
        on E: Exception do
        begin
          TLogger.GetInstance.Error('HTTP.Helper', 'Get',
            Format('Erro tentativa %d: %s', [LTentativa, E.Message]));
          if LTentativa = FMaxRetries then
            raise;
          Sleep(1000 * LTentativa); // Backoff exponencial simples
        end;
      end;
    end;
  finally
    LResponse.Free;
    LRequest.Free;
    LClient.Free;
  end;
end;

function THTTPHelper.Post(const AEndpoint: string;
  ABody: TJSONObject): TJSONValue;
var
  LClient: TRESTClient;
  LRequest: TRESTRequest;
  LResponse: TRESTResponse;
begin
  Result := nil;
  ConfigurarCliente(LClient, LRequest, LResponse);
  try
    LRequest.Resource := AEndpoint;
    LRequest.Method := TRESTRequestMethod.rmPOST;

    if Assigned(ABody) then
      LRequest.Body.Add(ABody.ToJSON, TRESTContentType.ctAPPLICATION_JSON);

    LRequest.Execute;

    if (LResponse.StatusCode >= 200) and (LResponse.StatusCode < 300) then
    begin
      if Assigned(LResponse.JSONValue) then
        Result := LResponse.JSONValue.Clone as TJSONValue;
    end
    else
    begin
      raise Exception.CreateFmt('HTTP POST falhou: %d - %s',
        [LResponse.StatusCode, LResponse.Content]);
    end;
  finally
    LResponse.Free;
    LRequest.Free;
    LClient.Free;
  end;
end;

function THTTPHelper.GetRaw(const AEndpoint: string;
  AParams: TStringList): string;
var
  LClient: TRESTClient;
  LRequest: TRESTRequest;
  LResponse: TRESTResponse;
  I: Integer;
begin
  Result := '';
  ConfigurarCliente(LClient, LRequest, LResponse);
  try
    LRequest.Resource := AEndpoint;
    LRequest.Method := TRESTRequestMethod.rmGET;

    if Assigned(AParams) then
    begin
      for I := 0 to AParams.Count - 1 do
        LRequest.Params.AddItem(AParams.Names[I],
          AParams.ValueFromIndex[I],
          TRESTRequestParameterKind.pkGETorPOST);
    end;

    LRequest.Execute;
    Result := LResponse.Content;
  finally
    LResponse.Free;
    LRequest.Free;
    LClient.Free;
  end;
end;

end.
