{ Service.POI - Lógica de negócio dos Pontos de Interesse.
  Orquestra validação, persistência via DAO e geocodificação automática. }
unit Service.POI;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Model.POI, DAO.POI, Service.Geo;

type
  TPOIService = class
  private
    FPOIDAL: TPOIDAO;
    FGeoService: TGeoService;
  public
    constructor Create;
    destructor Destroy; override;

    { CRUD com regras de negócio }
    function CriarPOI(const ANome, ADescricao: string;
      ALatitude, ALongitude: Double; ATipo: ETipoPOI;
      AUsuarioID: Integer): TPOI;
    function AtualizarPOI(APOI: TPOI): Boolean;
    function ExcluirPOI(AID: Integer): Boolean;
    function BuscarPOI(AID: Integer): TPOI;

    { Consultas }
    function ListarTodos: TPOIList;
    function ListarPorTipo(ATipo: ETipoPOI): TPOIList;
    function BuscarPorNome(const ANome: string): TPOIList;
    function BuscarProximos(ALatitude, ALongitude, ARaioKM: Double): TPOIList;

    { Operações com geocodificação }
    function CriarPOIPorEndereco(const ANome, ADescricao, AEndereco: string;
      ATipo: ETipoPOI; AUsuarioID: Integer): TPOI;
    function ObterEnderecoPOI(APOI: TPOI): string;
  end;

implementation

uses
  Utils.Logger;

constructor TPOIService.Create;
begin
  inherited Create;
  FPOIDAL := TPOIDAO.Create;
  FGeoService := TGeoService.Create;
end;

destructor TPOIService.Destroy;
begin
  FreeAndNil(FPOIDAL);
  FreeAndNil(FGeoService);
  inherited Destroy;
end;

function TPOIService.CriarPOI(const ANome, ADescricao: string;
  ALatitude, ALongitude: Double; ATipo: ETipoPOI;
  AUsuarioID: Integer): TPOI;
var
  LErros: TStringList;
begin
  { Cria o POI, valida e persiste no banco }
  Result := TPOI.Create(ANome, ALatitude, ALongitude, ATipo);
  Result.Descricao := ADescricao;
  Result.UsuarioID := AUsuarioID;

  { Validação via Model }
  LErros := Result.ObterErrosValidacao;
  try
    if LErros.Count > 0 then
    begin
      FreeAndNil(Result);
      raise Exception.Create('Erro de validação: ' + LErros.Text);
    end;
  finally
    LErros.Free;
  end;

  { Tenta obter endereço via geocodificação reversa }
  try
    Result.Endereco := FGeoService.CoordenadasParaEndereco(
      ALatitude, ALongitude);
  except
    Result.Endereco := '';
  end;

  { Persiste no banco via DAO }
  Result.ID := FPOIDAL.Inserir(Result);

  TLogger.GetInstance.Info('POIService', 'CriarPOI',
    Format('POI criado: ID=%d, Nome=%s', [Result.ID, ANome]));
end;

function TPOIService.CriarPOIPorEndereco(const ANome, ADescricao,
  AEndereco: string; ATipo: ETipoPOI; AUsuarioID: Integer): TPOI;
var
  LLat, LLon: Double;
begin
  { Fluxo: endereço -> geocodifica -> cria POI com coordenadas }
  if not FGeoService.EnderecoParaCoordenadas(AEndereco, LLat, LLon) then
    raise Exception.CreateFmt(
      'Não foi possível geocodificar o endereço: "%s"', [AEndereco]);

  Result := CriarPOI(ANome, ADescricao, LLat, LLon, ATipo, AUsuarioID);
  Result.Endereco := AEndereco;
  FPOIDAL.Atualizar(Result);
end;

function TPOIService.AtualizarPOI(APOI: TPOI): Boolean;
var
  LErros: TStringList;
begin
  LErros := APOI.ObterErrosValidacao;
  try
    if LErros.Count > 0 then
      raise Exception.Create('Erro de validação: ' + LErros.Text);
  finally
    LErros.Free;
  end;

  Result := FPOIDAL.Atualizar(APOI);
end;

function TPOIService.ExcluirPOI(AID: Integer): Boolean;
begin
  { Usa soft delete (exclusão lógica) }
  Result := FPOIDAL.ExcluirLogico(AID);
end;

function TPOIService.BuscarPOI(AID: Integer): TPOI;
begin
  Result := FPOIDAL.BuscarPorID(AID);
end;

function TPOIService.ListarTodos: TPOIList;
begin
  Result := FPOIDAL.ListarTodos(True);
end;

function TPOIService.ListarPorTipo(ATipo: ETipoPOI): TPOIList;
begin
  Result := FPOIDAL.ListarPorTipo(ATipo);
end;

function TPOIService.BuscarPorNome(const ANome: string): TPOIList;
begin
  Result := FPOIDAL.BuscarPorNome(ANome);
end;

function TPOIService.BuscarProximos(
  ALatitude, ALongitude, ARaioKM: Double): TPOIList;
begin
  Result := FPOIDAL.BuscarProximos(ALatitude, ALongitude, ARaioKM);
end;

function TPOIService.ObterEnderecoPOI(APOI: TPOI): string;
begin
  Result := FGeoService.CoordenadasParaEndereco(
    APOI.Latitude, APOI.Longitude);
end;

end.
