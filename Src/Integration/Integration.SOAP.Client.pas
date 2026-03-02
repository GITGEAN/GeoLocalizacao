{ Integration.SOAP.Client - Cliente SOAP para integrações legadas.
  Demonstra montagem manual de envelope SOAP 1.1 e parsing de resposta XML.
  Usado em: NF-e, Correios (consulta CEP), sistemas gov. }  
unit Integration.SOAP.Client;

interface

uses
  System.SysUtils, System.Classes,
  Soap.SOAPHTTPClient, Soap.InvokeRegistry,
  Xml.XMLDoc, Xml.XMLIntf;

type
  { Cliente SOAP genérico para demonstração }
  TSOAPClientHelper = class
  private
    FWSDLURL: string;
    FTimeout: Integer;
  public
    constructor Create(const AWSDLURL: string);
    destructor Destroy; override;

    { Monta e envia envelope SOAP manualmente }
    function EnviarRequisicaoSOAP(const AServiceURL: string;
      const ASoapAction: string;
      const AXMLBody: string): string;

    { Monta envelope SOAP padrão }
    class function MontarEnvelopeSOAP(
      const ANamespace, AMetodo: string;
      AParametros: TStringList): string;

    { Parser de resposta SOAP }
    class function ExtrairValorXML(const AXML: string;
      const ATag: string): string;

    { Exemplo: consulta CEP via ViaCEP (SOAP) }
    function ConsultarCEP(const ACEP: string): string;

    property WSDLURL: string read FWSDLURL write FWSDLURL;
    property Timeout: Integer read FTimeout write FTimeout;
  end;

implementation

uses
  System.Net.HttpClient, System.Net.HttpClientComponent,
  Utils.Logger;

constructor TSOAPClientHelper.Create(const AWSDLURL: string);
begin
  inherited Create;
  FWSDLURL := AWSDLURL;
  FTimeout := 30000;
end;

destructor TSOAPClientHelper.Destroy;
begin
  inherited Destroy;
end;

function TSOAPClientHelper.EnviarRequisicaoSOAP(
  const AServiceURL, ASoapAction, AXMLBody: string): string;
var
  LHTTPClient: TNetHTTPClient;
  LRequest: TNetHTTPRequest;
  LStream: TStringStream;
  LResponse: IHTTPResponse;
begin
  { Envia requisição SOAP manualmente via HTTP POST.
    O envelope SOAP é um XML enviado no body da requisição.
    Headers obrigatórios:
    - Content-Type: text/xml; charset=utf-8
    - SOAPAction: identifica a operação a ser executada }

  Result := '';
  LHTTPClient := TNetHTTPClient.Create(nil);
  LRequest := TNetHTTPRequest.Create(nil);
  LStream := TStringStream.Create(AXMLBody, TEncoding.UTF8);
  try
    LRequest.Client := LHTTPClient;
    LHTTPClient.ContentType := 'text/xml; charset=utf-8';
    LRequest.CustomHeaders['SOAPAction'] := ASoapAction;
    LRequest.ConnectionTimeout := FTimeout;

    LResponse := LRequest.Post(AServiceURL, LStream);

    if LResponse.StatusCode = 200 then
      Result := LResponse.ContentAsString(TEncoding.UTF8)
    else
      TLogger.GetInstance.Error('SOAP.Client', 'EnviarRequisicaoSOAP',
        Format('HTTP %d: %s', [LResponse.StatusCode,
          LResponse.ContentAsString]));
  finally
    LStream.Free;
    LRequest.Free;
    LHTTPClient.Free;
  end;
end;

class function TSOAPClientHelper.MontarEnvelopeSOAP(
  const ANamespace, AMetodo: string;
  AParametros: TStringList): string;
var
  LBody: TStringBuilder;
  I: Integer;
begin
  { Monta o envelope SOAP 1.1 padrão:
    <?xml version="1.0"?>
    <soap:Envelope xmlns:soap="...">
      <soap:Body>
        <Metodo xmlns="namespace">
          <param1>valor1</param1>
        </Metodo>
      </soap:Body>
    </soap:Envelope> }

  LBody := TStringBuilder.Create;
  try
    LBody.AppendLine('<?xml version="1.0" encoding="utf-8"?>');
    LBody.AppendLine('<soap:Envelope ' +
      'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" ' +
      'xmlns:ns="' + ANamespace + '">');
    LBody.AppendLine('  <soap:Body>');
    LBody.AppendLine('    <ns:' + AMetodo + '>');

    if Assigned(AParametros) then
    begin
      for I := 0 to AParametros.Count - 1 do
        LBody.AppendLine(Format('      <ns:%s>%s</ns:%s>',
          [AParametros.Names[I],
           AParametros.ValueFromIndex[I],
           AParametros.Names[I]]));
    end;

    LBody.AppendLine('    </ns:' + AMetodo + '>');
    LBody.AppendLine('  </soap:Body>');
    LBody.AppendLine('</soap:Envelope>');
    Result := LBody.ToString;
  finally
    LBody.Free;
  end;
end;

class function TSOAPClientHelper.ExtrairValorXML(
  const AXML, ATag: string): string;
var
  LPosInicio, LPosFim: Integer;
  LTagInicio, LTagFim: string;
begin
  { Parser XML simples - extrai valor entre tags.
    Em produção, use TXMLDocument para parsing robusto. }
  Result := '';
  LTagInicio := '<' + ATag + '>';
  LTagFim := '</' + ATag + '>';

  LPosInicio := Pos(LTagInicio, AXML);
  if LPosInicio > 0 then
  begin
    LPosInicio := LPosInicio + Length(LTagInicio);
    LPosFim := Pos(LTagFim, AXML);
    if LPosFim > LPosInicio then
      Result := Copy(AXML, LPosInicio, LPosFim - LPosInicio);
  end;
end;

function TSOAPClientHelper.ConsultarCEP(const ACEP: string): string;
var
  LParams: TStringList;
  LEnvelope, LResposta: string;
begin
  { Exemplo de consulta SOAP usando serviço público }
  Result := '';
  LParams := TStringList.Create;
  try
    LParams.Add('cep=' + ACEP);
    LEnvelope := MontarEnvelopeSOAP(
      'https://apps.correios.com.br/SigepMasterJPA/AtendeClienteService',
      'consultaCEP', LParams);

    LResposta := EnviarRequisicaoSOAP(
      'https://apps.correios.com.br/SigepMasterJPA/AtendeClienteService/AtendeCliente',
      'consultaCEP', LEnvelope);

    if LResposta <> '' then
      Result := ExtrairValorXML(LResposta, 'end');
  finally
    LParams.Free;
  end;
end;

end.
