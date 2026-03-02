{ Model.POI - Entidade Ponto de Interesse (POI).
  Inclui validação de coordenadas e TPOIList (TObjectList<TPOI>). }
unit Model.POI;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  ETipoPOI = (
    tpGeral, tpMonumento, tpGoverno, tpCultura, tpInfraestrutura,
    tpSaude, tpEducacao, tpTransporte, tpMeioAmbiente
  );

  TPOI = class
  private
    FID: Integer;
    FNome: string;
    FDescricao: string;
    FLatitude: Double;
    FLongitude: Double;
    FTipo: ETipoPOI;
    FEndereco: string;
    FUsuarioID: Integer;
    FUsuarioNome: string;
    FAtivo: Boolean;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
    procedure SetNome(const Value: string);
    procedure SetLatitude(const Value: Double);
    procedure SetLongitude(const Value: Double);
  public
    constructor Create; overload;
    constructor Create(const ANome: string; ALatitude, ALongitude: Double;
      ATipo: ETipoPOI); overload;
    destructor Destroy; override;
    function Validar: Boolean;
    function ObterErrosValidacao: TStringList;
    function TipoToString: string;
    class function StringToTipo(const AValue: string): ETipoPOI;
    function CoordenadasFormatadas: string;
    function Clone: TPOI;
    function ToString: string; override;

    property ID: Integer read FID write FID;
    property Nome: string read FNome write SetNome;
    property Descricao: string read FDescricao write FDescricao;
    property Latitude: Double read FLatitude write SetLatitude;
    property Longitude: Double read FLongitude write SetLongitude;
    property Tipo: ETipoPOI read FTipo write FTipo;
    property Endereco: string read FEndereco write FEndereco;
    property UsuarioID: Integer read FUsuarioID write FUsuarioID;
    property UsuarioNome: string read FUsuarioNome write FUsuarioNome;
    property Ativo: Boolean read FAtivo write FAtivo;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

  TPOIList = class(TObjectList<TPOI>)
  public
    function FiltrarPorTipo(ATipo: ETipoPOI): TPOIList;
    function FiltrarAtivos: TPOIList;
    procedure OrdenarPorNome;
  end;

implementation

uses
  System.Math, System.Generics.Defaults;

{ TPOI }

constructor TPOI.Create;
begin
  inherited Create;
  FAtivo := True;
  FDataCriacao := Now;
  FTipo := tpGeral;
end;

constructor TPOI.Create(const ANome: string; ALatitude, ALongitude: Double;
  ATipo: ETipoPOI);
begin
  Create;
  Nome := ANome;
  Latitude := ALatitude;
  Longitude := ALongitude;
  FTipo := ATipo;
end;

destructor TPOI.Destroy;
begin
  inherited Destroy;
end;

procedure TPOI.SetNome(const Value: string);
begin
  FNome := Trim(Value);
end;

procedure TPOI.SetLatitude(const Value: Double);
begin
  if (Value < -90) or (Value > 90) then
    raise EArgumentOutOfRangeException.CreateFmt(
      'Latitude inválida: %.8f. Deve estar entre -90 e +90.', [Value]);
  FLatitude := Value;
end;

procedure TPOI.SetLongitude(const Value: Double);
begin
  if (Value < -180) or (Value > 180) then
    raise EArgumentOutOfRangeException.CreateFmt(
      'Longitude inválida: %.8f. Deve estar entre -180 e +180.', [Value]);
  FLongitude := Value;
end;

function TPOI.Validar: Boolean;
var
  LErros: TStringList;
begin
  LErros := ObterErrosValidacao;
  try
    Result := LErros.Count = 0;
  finally
    LErros.Free;
  end;
end;

function TPOI.ObterErrosValidacao: TStringList;
begin
  Result := TStringList.Create;
  if Trim(FNome) = '' then
    Result.Add('Nome é obrigatório');
  if Length(FNome) > 200 then
    Result.Add('Nome não pode ter mais de 200 caracteres');
  if (FLatitude = 0) and (FLongitude = 0) then
    Result.Add('Coordenadas não foram definidas');
  if FUsuarioID <= 0 then
    Result.Add('Usuário responsável é obrigatório');
end;

function TPOI.TipoToString: string;
begin
  case FTipo of
    tpGeral:          Result := 'GERAL';
    tpMonumento:      Result := 'MONUMENTO';
    tpGoverno:        Result := 'GOVERNO';
    tpCultura:        Result := 'CULTURA';
    tpInfraestrutura: Result := 'INFRAESTRUTURA';
    tpSaude:          Result := 'SAUDE';
    tpEducacao:       Result := 'EDUCACAO';
    tpTransporte:     Result := 'TRANSPORTE';
    tpMeioAmbiente:   Result := 'MEIO_AMBIENTE';
  else
    Result := 'GERAL';
  end;
end;

class function TPOI.StringToTipo(const AValue: string): ETipoPOI;
var
  LValue: string;
begin
  LValue := UpperCase(Trim(AValue));
  if LValue = 'MONUMENTO' then Result := tpMonumento
  else if LValue = 'GOVERNO' then Result := tpGoverno
  else if LValue = 'CULTURA' then Result := tpCultura
  else if LValue = 'INFRAESTRUTURA' then Result := tpInfraestrutura
  else if LValue = 'SAUDE' then Result := tpSaude
  else if LValue = 'EDUCACAO' then Result := tpEducacao
  else if LValue = 'TRANSPORTE' then Result := tpTransporte
  else if LValue = 'MEIO_AMBIENTE' then Result := tpMeioAmbiente
  else Result := tpGeral;
end;

function TPOI.CoordenadasFormatadas: string;
begin
  Result := Format('%.6f, %.6f', [FLatitude, FLongitude]);
end;

function TPOI.Clone: TPOI;
begin
  Result := TPOI.Create;
  Result.FID := Self.FID;
  Result.FNome := Self.FNome;
  Result.FDescricao := Self.FDescricao;
  Result.FLatitude := Self.FLatitude;
  Result.FLongitude := Self.FLongitude;
  Result.FTipo := Self.FTipo;
  Result.FEndereco := Self.FEndereco;
  Result.FUsuarioID := Self.FUsuarioID;
  Result.FUsuarioNome := Self.FUsuarioNome;
  Result.FAtivo := Self.FAtivo;
  Result.FDataCriacao := Self.FDataCriacao;
  Result.FDataAlteracao := Self.FDataAlteracao;
end;

function TPOI.ToString: string;
begin
  Result := Format('POI[ID=%d, Nome="%s", Coord=(%s), Tipo=%s]',
    [FID, FNome, CoordenadasFormatadas, TipoToString]);
end;

{ TPOIList }

function TPOIList.FiltrarPorTipo(ATipo: ETipoPOI): TPOIList;
var
  LPOI: TPOI;
begin
  Result := TPOIList.Create(False);
  for LPOI in Self do
    if LPOI.Tipo = ATipo then
      Result.Add(LPOI);
end;

function TPOIList.FiltrarAtivos: TPOIList;
var
  LPOI: TPOI;
begin
  Result := TPOIList.Create(False);
  for LPOI in Self do
    if LPOI.Ativo then
      Result.Add(LPOI);
end;

procedure TPOIList.OrdenarPorNome;
begin
  Sort(TComparer<TPOI>.Construct(
    function(const Left, Right: TPOI): Integer
    begin
      Result := CompareText(Left.Nome, Right.Nome);
    end
  ));
end;

end.
