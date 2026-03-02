{ Utils.GeoCalc - Cálculos geográficos (Haversine, bounding box, DMS).
  Métodos estáticos (class function) sobre WGS84/EPSG:4326. }
unit Utils.GeoCalc;

interface

uses
  System.SysUtils, System.Math;

type
  { Registro (record) para coordenadas - mais leve que uma classe }
  TCoordinate = record
    Latitude: Double;
    Longitude: Double;
    class function Create(ALat, ALon: Double): TCoordinate; static;
    function ToString: string;
  end;

  { Registro para Bounding Box (extensão geográfica) }
  TBoundingBox = record
    MinLat, MinLon: Double;  // Canto inferior esquerdo
    MaxLat, MaxLon: Double;  // Canto superior direito
    function Contains(ACoord: TCoordinate): Boolean;
    function ToString: string;
  end;

  { Classe estática com funções de cálculo geográfico }
  TGeoCalc = class
  public
    const
      { Raio médio da Terra em quilômetros (WGS84) }
      RAIO_TERRA_KM = 6371.0088;
      { Raio em milhas }
      RAIO_TERRA_MI = 3958.7613;
      { Conversão de graus para radianos }
      DEG_TO_RAD = Pi / 180.0;
      RAD_TO_DEG = 180.0 / Pi;

    { Calcula distância entre dois pontos usando fórmula de Haversine }
    class function DistanciaHaversine(
      ALat1, ALon1, ALat2, ALon2: Double): Double;

    { Variação com record TCoordinate }
    class function Distancia(
      AOrigem, ADestino: TCoordinate): Double;

    { Calcula Bearing (azimute/direção) entre dois pontos }
    class function CalcularBearing(
      ALat1, ALon1, ALat2, ALon2: Double): Double;

    { Calcula o ponto de destino dado origem, distância e bearing }
    class function CalcularPontoDestino(
      ALat, ALon, ADistanciaKM, ABearingGraus: Double): TCoordinate;

    { Calcula Bounding Box ao redor de um ponto com raio dado }
    class function CalcularBoundingBox(
      ALat, ALon, ARaioKM: Double): TBoundingBox;

    { Conversão: Graus Decimais -> Graus/Minutos/Segundos }
    class function GrausDecimaisParaGMS(AGraus: Double;
      AEhLatitude: Boolean): string;

    { Conversão: Graus/Minutos/Segundos -> Graus Decimais }
    class function GMSParaGrausDecimais(
      AGraus, AMinutos, ASegundos: Double;
      const ACardeal: Char): Double;

    { Valida se coordenadas estão no Brasil }
    class function CoordenadaNoBrasil(ALat, ALon: Double): Boolean;

    { Calcula a área aproximada de um retângulo (bounding box) em km² }
    class function AreaBoundingBoxKM2(ABBox: TBoundingBox): Double;
  end;

implementation

{ TCoordinate }

class function TCoordinate.Create(ALat, ALon: Double): TCoordinate;
begin
  Result.Latitude := ALat;
  Result.Longitude := ALon;
end;

function TCoordinate.ToString: string;
begin
  Result := Format('(%.6f, %.6f)', [Latitude, Longitude]);
end;

{ TBoundingBox }

function TBoundingBox.Contains(ACoord: TCoordinate): Boolean;
begin
  Result := (ACoord.Latitude >= MinLat) and (ACoord.Latitude <= MaxLat) and
            (ACoord.Longitude >= MinLon) and (ACoord.Longitude <= MaxLon);
end;

function TBoundingBox.ToString: string;
begin
  Result := Format('BBox[(%.6f,%.6f)-(%.6f,%.6f)]',
    [MinLat, MinLon, MaxLat, MaxLon]);
end;

{ TGeoCalc }

class function TGeoCalc.DistanciaHaversine(
  ALat1, ALon1, ALat2, ALon2: Double): Double;
var
  LdLat, LdLon, LA, LC: Double;
  LLat1Rad, LLat2Rad: Double;
begin
  { FÓRMULA DE HAVERSINE:
    a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)
    c = 2 * atan2(√a, √(1-a))
    d = R * c }
  LLat1Rad := ALat1 * DEG_TO_RAD;
  LLat2Rad := ALat2 * DEG_TO_RAD;
  LdLat := (ALat2 - ALat1) * DEG_TO_RAD;
  LdLon := (ALon2 - ALon1) * DEG_TO_RAD;

  LA := Sin(LdLat / 2) * Sin(LdLat / 2) +
        Cos(LLat1Rad) * Cos(LLat2Rad) *
        Sin(LdLon / 2) * Sin(LdLon / 2);

  LC := 2 * ArcTan2(Sqrt(LA), Sqrt(1 - LA));

  Result := RAIO_TERRA_KM * LC;
end;

class function TGeoCalc.Distancia(
  AOrigem, ADestino: TCoordinate): Double;
begin
  Result := DistanciaHaversine(
    AOrigem.Latitude, AOrigem.Longitude,
    ADestino.Latitude, ADestino.Longitude);
end;

class function TGeoCalc.CalcularBearing(
  ALat1, ALon1, ALat2, ALon2: Double): Double;
var
  LdLon, LX, LY: Double;
begin
  { Bearing (azimute): direção em graus de 0 a 360.
    0° = Norte, 90° = Leste, 180° = Sul, 270° = Oeste }
  ALat1 := ALat1 * DEG_TO_RAD;
  ALat2 := ALat2 * DEG_TO_RAD;
  LdLon := (ALon2 - ALon1) * DEG_TO_RAD;

  LX := Cos(ALat2) * Sin(LdLon);
  LY := Cos(ALat1) * Sin(ALat2) -
        Sin(ALat1) * Cos(ALat2) * Cos(LdLon);

  Result := ArcTan2(LX, LY) * RAD_TO_DEG;
  { Normaliza para 0-360 }
  Result := System.Math.FMod(Result + 360, 360);
end;

class function TGeoCalc.CalcularPontoDestino(
  ALat, ALon, ADistanciaKM, ABearingGraus: Double): TCoordinate;
var
  LLatRad, LLonRad, LBearingRad, LdR: Double;
  LLatDestinoRad, LLonDestinoRad: Double;
begin
  LLatRad := ALat * DEG_TO_RAD;
  LLonRad := ALon * DEG_TO_RAD;
  LBearingRad := ABearingGraus * DEG_TO_RAD;
  LdR := ADistanciaKM / RAIO_TERRA_KM;

  LLatDestinoRad := ArcSin(
    Sin(LLatRad) * Cos(LdR) +
    Cos(LLatRad) * Sin(LdR) * Cos(LBearingRad));

  LLonDestinoRad := LLonRad + ArcTan2(
    Sin(LBearingRad) * Sin(LdR) * Cos(LLatRad),
    Cos(LdR) - Sin(LLatRad) * Sin(LLatDestinoRad));

  Result.Latitude := LLatDestinoRad * RAD_TO_DEG;
  Result.Longitude := LLonDestinoRad * RAD_TO_DEG;
end;

class function TGeoCalc.CalcularBoundingBox(
  ALat, ALon, ARaioKM: Double): TBoundingBox;
var
  LDeltaLat, LDeltaLon: Double;
begin
  { Bounding box: retângulo que contém um círculo de raio ARaioKM.
    1° de latitude ≈ 111 km (constante)
    1° de longitude ≈ 111 * cos(latitude) km (varia com a latitude) }
  LDeltaLat := ARaioKM / 111.0;
  LDeltaLon := ARaioKM / (111.0 * Cos(ALat * DEG_TO_RAD));

  Result.MinLat := ALat - LDeltaLat;
  Result.MaxLat := ALat + LDeltaLat;
  Result.MinLon := ALon - LDeltaLon;
  Result.MaxLon := ALon + LDeltaLon;
end;

class function TGeoCalc.GrausDecimaisParaGMS(AGraus: Double;
  AEhLatitude: Boolean): string;
var
  LHemisferio: Char;
  LGrausAbs: Double;
  LDeg, LMin: Integer;
  LSeg: Double;
begin
  { Converte -23.561204 para 23°33'40.3"S }
  if AEhLatitude then
  begin
    if AGraus >= 0 then LHemisferio := 'N'
    else LHemisferio := 'S';
  end
  else
  begin
    if AGraus >= 0 then LHemisferio := 'E'
    else LHemisferio := 'W';
  end;

  LGrausAbs := Abs(AGraus);
  LDeg := Trunc(LGrausAbs);
  LMin := Trunc((LGrausAbs - LDeg) * 60);
  LSeg := ((LGrausAbs - LDeg) * 60 - LMin) * 60;

  Result := Format('%d°%d''%.1f"%s', [LDeg, LMin, LSeg, LHemisferio]);
end;

class function TGeoCalc.GMSParaGrausDecimais(
  AGraus, AMinutos, ASegundos: Double;
  const ACardeal: Char): Double;
begin
  Result := AGraus + (AMinutos / 60) + (ASegundos / 3600);
  if CharInSet(ACardeal, ['S', 's', 'W', 'w']) then
    Result := -Result;
end;

class function TGeoCalc.CoordenadaNoBrasil(ALat, ALon: Double): Boolean;
begin
  { Limites aproximados do Brasil }
  Result := (ALat >= -33.75) and (ALat <= 5.27) and
            (ALon >= -73.99) and (ALon <= -34.79);
end;

class function TGeoCalc.AreaBoundingBoxKM2(ABBox: TBoundingBox): Double;
var
  LLarguraKM, LAlturaKM: Double;
  LLatMedia: Double;
begin
  LLatMedia := (ABBox.MinLat + ABBox.MaxLat) / 2;
  LAlturaKM := (ABBox.MaxLat - ABBox.MinLat) * 111.0;
  LLarguraKM := (ABBox.MaxLon - ABBox.MinLon) * 111.0 *
                Cos(LLatMedia * DEG_TO_RAD);
  Result := Abs(LLarguraKM * LAlturaKM);
end;

end.
