{ Service.Geo - Serviço de geoprocessamento.
  Façade sobre ArcGIS REST + Utils.GeoCalc para geocodificação,
  cálculo de distâncias e busca por proximidade. }
unit Service.Geo;

interface

uses
  System.SysUtils, System.Classes,
  Integration.ArcGIS.REST, Utils.GeoCalc, Model.POI;

type
  { Serviço que orquestra as operações de geoprocessamento }
  TGeoService = class
  private
    FArcGISClient: TArcGISClient;
  public
    constructor Create(const AApiKey: string = '');
    destructor Destroy; override;

    { Geocodificação: converte endereço em coordenadas }
    function EnderecoParaCoordenadas(const AEndereco: string;
      out ALatitude, ALongitude: Double): Boolean;

    { Geocodificação reversa: converte coordenadas em endereço }
    function CoordenadasParaEndereco(ALatitude, ALongitude: Double): string;

    { Calcula distância entre dois POIs em km }
    function DistanciaEntrePOIs(APOI1, APOI2: TPOI): Double;

    { Calcula distância entre coordenadas }
    function DistanciaEntrePontos(ALat1, ALon1, ALat2, ALon2: Double): Double;

    { Busca POIs dentro de um raio a partir de um ponto }
    function BuscarPOIsProximos(ALatitude, ALongitude: Double;
      ARaioKM: Double; APOIs: TPOIList): TPOIList;

    { Obtém sugestões de endereço para autocomplete }
    function SugerirEnderecos(const ATexto: string): TStringList;

    { Valida se coordenadas estão no Brasil }
    function ValidarCoordenadas(ALatitude, ALongitude: Double): Boolean;

    { Formata coordenadas em DMS (Graus/Minutos/Segundos) }
    function FormatarCoordenadasDMS(ALatitude, ALongitude: Double): string;

    property ArcGISClient: TArcGISClient read FArcGISClient;
  end;

implementation

uses
  Utils.Logger;

constructor TGeoService.Create(const AApiKey: string);
begin
  inherited Create;
  FArcGISClient := TArcGISClient.Create(AApiKey);
end;

destructor TGeoService.Destroy;
begin
  FreeAndNil(FArcGISClient);
  inherited Destroy;
end;

function TGeoService.EnderecoParaCoordenadas(const AEndereco: string;
  out ALatitude, ALongitude: Double): Boolean;
var
  LResult: TGeocodingResult;
begin
  Result := False;
  ALatitude := 0;
  ALongitude := 0;

  try
    LResult := FArcGISClient.Geocodificar(AEndereco);

    { Score > 80 indica boa confiança no resultado }
    if LResult.Score > 80 then
    begin
      ALatitude := LResult.Latitude;
      ALongitude := LResult.Longitude;
      Result := True;

      TLogger.GetInstance.Info('GeoService', 'EnderecoParaCoordenadas',
        Format('OK: "%s" -> (%.6f, %.6f) Score=%.0f',
          [AEndereco, ALatitude, ALongitude, LResult.Score]));
    end
    else
    begin
      TLogger.GetInstance.Warning('GeoService', 'EnderecoParaCoordenadas',
        Format('Score baixo: "%s" -> Score=%.0f', [AEndereco, LResult.Score]));
    end;
  except
    on E: Exception do
    begin
      TLogger.GetInstance.Error('GeoService', 'EnderecoParaCoordenadas',
        Format('Erro: %s', [E.Message]));
    end;
  end;
end;

function TGeoService.CoordenadasParaEndereco(
  ALatitude, ALongitude: Double): string;
var
  LResult: TReverseGeocodingResult;
begin
  Result := '';
  try
    LResult := FArcGISClient.GeocodificacaoReversa(ALatitude, ALongitude);
    Result := LResult.Endereco;
  except
    on E: Exception do
    begin
      TLogger.GetInstance.Error('GeoService', 'CoordenadasParaEndereco',
        E.Message);
      Result := Format('Coordenadas: %.6f, %.6f', [ALatitude, ALongitude]);
    end;
  end;
end;

function TGeoService.DistanciaEntrePOIs(APOI1, APOI2: TPOI): Double;
begin
  Result := TGeoCalc.DistanciaHaversine(
    APOI1.Latitude, APOI1.Longitude,
    APOI2.Latitude, APOI2.Longitude);
end;

function TGeoService.DistanciaEntrePontos(
  ALat1, ALon1, ALat2, ALon2: Double): Double;
begin
  Result := TGeoCalc.DistanciaHaversine(ALat1, ALon1, ALat2, ALon2);
end;

function TGeoService.BuscarPOIsProximos(ALatitude, ALongitude: Double;
  ARaioKM: Double; APOIs: TPOIList): TPOIList;
var
  LPOI: TPOI;
  LDistancia: Double;
begin
  { Filtra POIs que estão dentro do raio especificado.
    Usa bounding box como pré-filtro e depois Haversine para precisão }
  Result := TPOIList.Create(False);
  for LPOI in APOIs do
  begin
    LDistancia := TGeoCalc.DistanciaHaversine(
      ALatitude, ALongitude, LPOI.Latitude, LPOI.Longitude);
    if LDistancia <= ARaioKM then
      Result.Add(LPOI);
  end;
end;

function TGeoService.SugerirEnderecos(const ATexto: string): TStringList;
begin
  Result := FArcGISClient.SugerirEnderecos(ATexto);
end;

function TGeoService.ValidarCoordenadas(
  ALatitude, ALongitude: Double): Boolean;
begin
  Result := TGeoCalc.CoordenadaNoBrasil(ALatitude, ALongitude);
end;

function TGeoService.FormatarCoordenadasDMS(
  ALatitude, ALongitude: Double): string;
begin
  Result := TGeoCalc.GrausDecimaisParaGMS(ALatitude, True) + ' ' +
            TGeoCalc.GrausDecimaisParaGMS(ALongitude, False);
end;

end.
