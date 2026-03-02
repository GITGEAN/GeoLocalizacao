{ Integration.ArcGIS.REST - Cliente REST para a plataforma ESRI/ArcGIS.
  Endpoints: GeocodeServer (geocodificação), MapServer, FeatureServer.
  Autenticado via API Key no parâmetro da requisição. }
unit Integration.ArcGIS.REST;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  System.Generics.Collections,
  Integration.HTTP.Helper, Model.POI, Utils.GeoCalc;

type
  { Resultado de geocodificação }
  TGeocodingResult = record
    Endereco: string;
    Latitude: Double;
    Longitude: Double;
    Score: Double;      // Confiança do resultado (0-100)
    MatchAddr: string;  // Endereço encontrado
  end;

  { Resultado de geocodificação reversa }
  TReverseGeocodingResult = record
    Endereco: string;
    Bairro: string;
    Cidade: string;
    Estado: string;
    Pais: string;
    CEP: string;
  end;

  { Feature de um Feature Service }
  TGeoFeature = record
    ObjectID: Integer;
    Geometry: TCoordinate;
    Attributes: TStringList;  // Pares chave=valor
  end;

  { Cliente REST para ArcGIS: geocodificação, Feature Service, Map Service. }
  TArcGISClient = class
  private
    FHTTPHelper: THTTPHelper;
    FGeocodeURL: string;
    FApiKey: string;

    { Parseia o resultado JSON de geocodificação }
    function ParseGeocodingResult(AJSON: TJSONValue): TGeocodingResult;
    function ParseReverseResult(AJSON: TJSONValue): TReverseGeocodingResult;
  public
    constructor Create(const AApiKey: string = '');
    destructor Destroy; override;

    { === GEOCODING === }

    { Geocodificação: endereço -> coordenadas }
    function Geocodificar(const AEndereco: string): TGeocodingResult;

    { Geocodificação reversa: coordenadas -> endereço }
    function GeocodificacaoReversa(ALatitude, ALongitude: Double
      ): TReverseGeocodingResult;

    { Sugestões de endereço (autocomplete) }
    function SugerirEnderecos(const ATexto: string;
      AMaxResultados: Integer = 5): TStringList;

    { === FEATURE SERVICE === }

    { Consulta features de um Feature Service }
    function ConsultarFeatures(const AFeatureServiceURL: string;
      const AWhere: string = '1=1';
      AMaxRegistros: Integer = 100): TJSONValue;

    { Consulta features dentro de uma extensão geográfica }
    function ConsultarFeaturesNaArea(const AFeatureServiceURL: string;
      ABBox: TBoundingBox): TJSONValue;

    { === MAP SERVICE === }

    { Obtém informações de um Map Service }
    function ObterInfoServico(const AServiceURL: string): TJSONValue;

    { Lista camadas de um Map Service }
    function ListarCamadas(const AServiceURL: string): TStringList;

    { Identifica feature no ponto clicado }
    function Identificar(const AServiceURL: string;
      ALatitude, ALongitude: Double;
      AToleranciaPixels: Integer = 5): TJSONValue;

    property ApiKey: string read FApiKey write FApiKey;
    property GeocodeURL: string read FGeocodeURL write FGeocodeURL;
  end;

implementation

uses
  Utils.Logger;

const
  { URLs padrão dos serviços ArcGIS Online (públicos) }
  ARCGIS_GEOCODE_URL = 'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer';
  ARCGIS_GEOMETRY_URL = 'https://utility.arcgisonline.com/ArcGIS/rest/services/Geometry/GeometryServer';

constructor TArcGISClient.Create(const AApiKey: string);
begin
  inherited Create;
  FApiKey := AApiKey;
  FGeocodeURL := ARCGIS_GEOCODE_URL;
  FHTTPHelper := THTTPHelper.Create(FGeocodeURL);
  FHTTPHelper.ApiKey := FApiKey;
  FHTTPHelper.Timeout := 15000;
end;

destructor TArcGISClient.Destroy;
begin
  FreeAndNil(FHTTPHelper);
  inherited Destroy;
end;

{ === GEOCODING === }

function TArcGISClient.Geocodificar(const AEndereco: string): TGeocodingResult;
var
  LParams: TStringList;
  LJSON: TJSONValue;
begin
  { ArcGIS Geocoding API:
    GET /findAddressCandidates?singleLine=<endereco>&f=json
    
    Parâmetros importantes:
    - singleLine: endereço em texto livre
    - outFields: campos retornados (* = todos)
    - maxLocations: máximo de resultados
    - f: formato da resposta (json)
    - outSR: sistema de referência da resposta (4326 = WGS84) }
    
  Result := Default(TGeocodingResult);
  LParams := TStringList.Create;
  try
    LParams.Add('singleLine=' + AEndereco);
    LParams.Add('outFields=*');
    LParams.Add('maxLocations=1');
    LParams.Add('f=json');
    LParams.Add('outSR=4326');

    { Configura helper para a URL de geocoding }
    FHTTPHelper.BaseURL := FGeocodeURL;
    LJSON := FHTTPHelper.Get('/findAddressCandidates', LParams);
    try
      if Assigned(LJSON) then
        Result := ParseGeocodingResult(LJSON);
    finally
      LJSON.Free;
    end;
  finally
    LParams.Free;
  end;

  TLogger.GetInstance.Info('ArcGIS', 'Geocodificar',
    Format('Endereço: "%s" -> Score: %.0f, Coord: (%.6f, %.6f)',
      [AEndereco, Result.Score, Result.Latitude, Result.Longitude]));
end;

function TArcGISClient.GeocodificacaoReversa(
  ALatitude, ALongitude: Double): TReverseGeocodingResult;
var
  LParams: TStringList;
  LJSON: TJSONValue;
begin
  { ArcGIS Reverse Geocoding:
    GET /reverseGeocode?location=<lon>,<lat>&f=json
    ATENÇÃO: a ordem é longitude,latitude (x,y)! }

  Result := Default(TReverseGeocodingResult);
  LParams := TStringList.Create;
  try
    { CUIDADO: ArcGIS usa X,Y (longitude, latitude) - ordem inversa! }
    LParams.Add('location=' + Format('%.8f,%.8f',
      [ALongitude, ALatitude]));
    LParams.Add('outSR=4326');
    LParams.Add('f=json');

    FHTTPHelper.BaseURL := FGeocodeURL;
    LJSON := FHTTPHelper.Get('/reverseGeocode', LParams);
    try
      if Assigned(LJSON) then
        Result := ParseReverseResult(LJSON);
    finally
      LJSON.Free;
    end;
  finally
    LParams.Free;
  end;
end;

function TArcGISClient.SugerirEnderecos(const ATexto: string;
  AMaxResultados: Integer): TStringList;
var
  LParams: TStringList;
  LJSON: TJSONValue;
  LSuggestions: TJSONArray;
  I: Integer;
begin
  { ArcGIS Suggest API:
    GET /suggest?text=<texto>&maxSuggestions=5&f=json
    Usado para autocomplete em campos de busca }

  Result := TStringList.Create;
  LParams := TStringList.Create;
  try
    LParams.Add('text=' + ATexto);
    LParams.Add('maxSuggestions=' + IntToStr(AMaxResultados));
    LParams.Add('f=json');
    LParams.Add('countryCode=BRA');

    FHTTPHelper.BaseURL := FGeocodeURL;
    LJSON := FHTTPHelper.Get('/suggest', LParams);
    try
      if Assigned(LJSON) then
      begin
        LSuggestions := LJSON.FindValue('suggestions') as TJSONArray;
        if Assigned(LSuggestions) then
        begin
          for I := 0 to LSuggestions.Count - 1 do
            Result.Add(LSuggestions.Items[I]
              .FindValue('text').Value);
        end;
      end;
    finally
      LJSON.Free;
    end;
  finally
    LParams.Free;
  end;
end;

{ === FEATURE SERVICE === }

function TArcGISClient.ConsultarFeatures(
  const AFeatureServiceURL: string;
  const AWhere: string;
  AMaxRegistros: Integer): TJSONValue;
var
  LParams: TStringList;
begin
  { Feature Service Query: GET <url>/query?where=...&outFields=*&f=json }
  LParams := TStringList.Create;
  try
    LParams.Add('where=' + AWhere);
    LParams.Add('outFields=*');
    LParams.Add('returnGeometry=true');
    LParams.Add('outSR=4326');
    LParams.Add('resultRecordCount=' + IntToStr(AMaxRegistros));
    LParams.Add('f=json');

    FHTTPHelper.BaseURL := AFeatureServiceURL;
    Result := FHTTPHelper.Get('/query', LParams);
  finally
    LParams.Free;
  end;
end;

function TArcGISClient.ConsultarFeaturesNaArea(
  const AFeatureServiceURL: string;
  ABBox: TBoundingBox): TJSONValue;
var
  LParams: TStringList;
  LGeometry: string;
begin
  { Consulta espacial usando Envelope (bounding box):
    geometry=<xmin>,<ymin>,<xmax>,<ymax>
    geometryType=esriGeometryEnvelope
    spatialRel=esriSpatialRelIntersects }

  LGeometry := Format('%.8f,%.8f,%.8f,%.8f',
    [ABBox.MinLon, ABBox.MinLat, ABBox.MaxLon, ABBox.MaxLat]);

  LParams := TStringList.Create;
  try
    LParams.Add('geometry=' + LGeometry);
    LParams.Add('geometryType=esriGeometryEnvelope');
    LParams.Add('spatialRel=esriSpatialRelIntersects');
    LParams.Add('inSR=4326');
    LParams.Add('outSR=4326');
    LParams.Add('outFields=*');
    LParams.Add('returnGeometry=true');
    LParams.Add('f=json');

    FHTTPHelper.BaseURL := AFeatureServiceURL;
    Result := FHTTPHelper.Get('/query', LParams);
  finally
    LParams.Free;
  end;
end;

{ === MAP SERVICE === }

function TArcGISClient.ObterInfoServico(
  const AServiceURL: string): TJSONValue;
var
  LParams: TStringList;
begin
  LParams := TStringList.Create;
  try
    LParams.Add('f=json');
    FHTTPHelper.BaseURL := AServiceURL;
    Result := FHTTPHelper.Get('', LParams);
  finally
    LParams.Free;
  end;
end;

function TArcGISClient.ListarCamadas(
  const AServiceURL: string): TStringList;
var
  LJSON: TJSONValue;
  LLayers: TJSONArray;
  LLayer: TJSONValue;
  I: Integer;
begin
  Result := TStringList.Create;
  LJSON := ObterInfoServico(AServiceURL);
  try
    if Assigned(LJSON) then
    begin
      LLayers := LJSON.FindValue('layers') as TJSONArray;
      if Assigned(LLayers) then
      begin
        for I := 0 to LLayers.Count - 1 do
        begin
          LLayer := LLayers.Items[I];
          Result.Add(Format('%s=%s',
            [LLayer.FindValue('id').Value,
             LLayer.FindValue('name').Value]));
        end;
      end;
    end;
  finally
    LJSON.Free;
  end;
end;

function TArcGISClient.Identificar(const AServiceURL: string;
  ALatitude, ALongitude: Double;
  AToleranciaPixels: Integer): TJSONValue;
var
  LParams: TStringList;
begin
  { Identify: dado um ponto no mapa, retorna os features próximos.
    Usado quando o usuário clica no mapa para "identificar" um objeto. }
  LParams := TStringList.Create;
  try
    LParams.Add('geometry=' + Format('%.8f,%.8f',
      [ALongitude, ALatitude]));
    LParams.Add('geometryType=esriGeometryPoint');
    LParams.Add('sr=4326');
    LParams.Add('layers=all');
    LParams.Add('tolerance=' + IntToStr(AToleranciaPixels));
    LParams.Add('mapExtent=-180,-90,180,90');
    LParams.Add('imageDisplay=800,600,96');
    LParams.Add('returnGeometry=true');
    LParams.Add('f=json');

    FHTTPHelper.BaseURL := AServiceURL;
    Result := FHTTPHelper.Get('/identify', LParams);
  finally
    LParams.Free;
  end;
end;

{ === PARSING === }

function TArcGISClient.ParseGeocodingResult(
  AJSON: TJSONValue): TGeocodingResult;
var
  LCandidates: TJSONArray;
  LFirst, LLocation: TJSONValue;
begin
  Result := Default(TGeocodingResult);
  LCandidates := AJSON.FindValue('candidates') as TJSONArray;
  if Assigned(LCandidates) and (LCandidates.Count > 0) then
  begin
    LFirst := LCandidates.Items[0];
    Result.Endereco := LFirst.FindValue('address').Value;
    Result.Score := LFirst.FindValue('score').GetValue<Double>;

    LLocation := LFirst.FindValue('location');
    if Assigned(LLocation) then
    begin
      { ArcGIS retorna x=longitude, y=latitude }
      Result.Longitude := LLocation.FindValue('x').GetValue<Double>;
      Result.Latitude := LLocation.FindValue('y').GetValue<Double>;
    end;

    Result.MatchAddr := Result.Endereco;
  end;
end;

function TArcGISClient.ParseReverseResult(
  AJSON: TJSONValue): TReverseGeocodingResult;
var
  LAddress: TJSONValue;
begin
  Result := Default(TReverseGeocodingResult);
  LAddress := AJSON.FindValue('address');
  if Assigned(LAddress) then
  begin
    Result.Endereco := LAddress.FindValue('LongLabel').Value;
    Result.Bairro := LAddress.FindValue('Nbrhd').Value;
    Result.Cidade := LAddress.FindValue('City').Value;
    Result.Estado := LAddress.FindValue('Region').Value;
    Result.Pais := LAddress.FindValue('CountryCode').Value;
    Result.CEP := LAddress.FindValue('Postal').Value;
  end;
end;

end.
