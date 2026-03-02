{ DAO.POI - Acesso a dados da tabela GEO_PONTOS_INTERESSE.
  Soft delete via UPDATE POI_ATIVO = 0. Bounding box no BuscarProximos
  para uso de índice; filtragem por Haversine fica no Service.Geo. }
unit DAO.POI;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  FireDAC.Comp.Client, Data.DB,
  DAO.Base, Model.POI;

type
  TPOIDAO = class(TBaseDAO)
  private
    { Mapeia um registro do banco para um objeto TPOI }
    function MapearPOI(AQuery: TFDQuery): TPOI;
  public
    { CRUD - Create, Read, Update, Delete }
    function Inserir(APOI: TPOI): Integer;
    function Atualizar(APOI: TPOI): Boolean;
    function Excluir(AID: Integer): Boolean;
    function ExcluirLogico(AID: Integer): Boolean; // Soft delete

    { Consultas }
    function BuscarPorID(AID: Integer): TPOI;
    function ListarTodos(AApenaAtivos: Boolean = True): TPOIList;
    function ListarPorTipo(ATipo: ETipoPOI): TPOIList;
    function BuscarPorNome(const ANome: string): TPOIList;
    function BuscarProximos(ALatitude, ALongitude, ARaioKM: Double): TPOIList;
    function ContarTotal(AApenasAtivos: Boolean = True): Integer;
  end;

implementation

uses
  Utils.Logger, DAO.Connection;

function TPOIDAO.MapearPOI(AQuery: TFDQuery): TPOI;
begin
  { Cria o objeto e mapeia campos do banco para properties.
    CONCEITO: Este mapeamento manual é o que ORMs como Entity Framework
    (C#) ou Hibernate (Java) fazem automaticamente.
    Em Delphi, existem ORMs como TMS Aurelius, mas o mapeamento
    manual é mais comum em sistemas legados. }
  Result := TPOI.Create;
  Result.ID := AQuery.FieldByName('POI_ID').AsInteger;
  Result.Nome := AQuery.FieldByName('POI_NOME').AsString;
  Result.Descricao := AQuery.FieldByName('POI_DESCRICAO').AsString;
  Result.Latitude := AQuery.FieldByName('POI_LATITUDE').AsFloat;
  Result.Longitude := AQuery.FieldByName('POI_LONGITUDE').AsFloat;
  Result.Tipo := TPOI.StringToTipo(AQuery.FieldByName('POI_TIPO').AsString);
  Result.Endereco := AQuery.FieldByName('POI_ENDERECO').AsString;
  Result.UsuarioID := AQuery.FieldByName('POI_USUARIO_ID').AsInteger;
  { SQLite armazena boolean como INTEGER (0 ou 1) }
  Result.Ativo := AQuery.FieldByName('POI_ATIVO').AsInteger <> 0;
  Result.DataCriacao := AQuery.FieldByName('POI_DATA_CRIACAO').AsDateTime;

  if not AQuery.FieldByName('POI_DATA_ALTERACAO').IsNull then
    Result.DataAlteracao := AQuery.FieldByName('POI_DATA_ALTERACAO').AsDateTime;
end;

function TPOIDAO.Inserir(APOI: TPOI): Integer;
var
  LQuery: TFDQuery;
  LIdentitySQL: string;
begin
  Result := 0;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;
    
    { Define o SQL para recuperar o ID gerado conforme o banco }
    case TConnectionManager.GetInstance.TipoBanco of
      tbSQLite: LIdentitySQL := 'SELECT last_insert_rowid() AS NOVO_ID;';
      tbSQLServer: LIdentitySQL := 'SELECT SCOPE_IDENTITY() AS NOVO_ID;';
      tbOracle: LIdentitySQL := 'SELECT SEQ_POI.CURRVAL AS NOVO_ID FROM DUAL;';
    else
      LIdentitySQL := 'SELECT last_insert_rowid() AS NOVO_ID;';
    end;

    LQuery.SQL.Text :=
      'INSERT INTO GEO_PONTOS_INTERESSE ' +
      '(POI_NOME, POI_DESCRICAO, POI_LATITUDE, POI_LONGITUDE, ' +
      ' POI_TIPO, POI_ENDERECO, POI_USUARIO_ID, POI_ATIVO) ' +
      'VALUES (:pNome, :pDesc, :pLat, :pLon, :pTipo, :pEnd, :pUsu, :pAtivo); ' +
      LIdentitySQL;

    LQuery.Params.ParamByName('pNome').AsString := APOI.Nome;
    LQuery.Params.ParamByName('pDesc').AsString := APOI.Descricao;
    LQuery.Params.ParamByName('pLat').AsFloat := APOI.Latitude;
    LQuery.Params.ParamByName('pLon').AsFloat := APOI.Longitude;
    LQuery.Params.ParamByName('pTipo').AsString := APOI.TipoToString;
    LQuery.Params.ParamByName('pEnd').AsString := APOI.Endereco;
    LQuery.Params.ParamByName('pUsu').AsInteger := APOI.UsuarioID;
    { SQLite: converter boolean para integer (0 ou 1) }
    LQuery.Params.ParamByName('pAtivo').AsInteger := Ord(APOI.Ativo);

    LQuery.Open;
    if not LQuery.Eof then
    begin
      Result := LQuery.FieldByName('NOVO_ID').AsInteger;
      APOI.ID := Result;
    end;

    TLogger.GetInstance.Info('DAO.POI', 'Inserir',
      Format('POI inserido: ID=%d, Nome=%s', [Result, APOI.Nome]));
  finally
    LQuery.Free;
  end;
end;

function TPOIDAO.Atualizar(APOI: TPOI): Boolean;
var
  LRows: Integer;
begin
  LRows := ExecuteSQL(
    'UPDATE GEO_PONTOS_INTERESSE SET ' +
    'POI_NOME = :pNome, POI_DESCRICAO = :pDesc, ' +
    'POI_LATITUDE = :pLat, POI_LONGITUDE = :pLon, ' +
    'POI_TIPO = :pTipo, POI_ENDERECO = :pEnd, ' +
    'POI_ATIVO = :pAtivo, POI_DATA_ALTERACAO = :pData ' +
    'WHERE POI_ID = :pID',
    [APOI.Nome, APOI.Descricao, APOI.Latitude, APOI.Longitude,
     APOI.TipoToString, APOI.Endereco, APOI.Ativo, Now, APOI.ID]);

  Result := LRows > 0;

  TLogger.GetInstance.Info('DAO.POI', 'Atualizar',
    Format('POI atualizado: ID=%d, Linhas=%d', [APOI.ID, LRows]));
end;

function TPOIDAO.Excluir(AID: Integer): Boolean;
begin
  { Exclusão física - remove permanentemente do banco.
    Em ambientes corporativos, prefira ExcluirLogico (soft delete). }
  Result := ExecuteSQL(
    'DELETE FROM GEO_PONTOS_INTERESSE WHERE POI_ID = :pID', [AID]) > 0;
end;

function TPOIDAO.ExcluirLogico(AID: Integer): Boolean;
begin
  { Soft delete: mantém histórico e permite auditoria. }
  Result := ExecuteSQL(
    'UPDATE GEO_PONTOS_INTERESSE SET POI_ATIVO = 0, ' +
    'POI_DATA_ALTERACAO = :pData WHERE POI_ID = :pID', [Now, AID]) > 0;
end;

function TPOIDAO.BuscarPorID(AID: Integer): TPOI;
var
  LQuery: TFDQuery;
begin
  Result := nil;
  LQuery := ExecuteQuery(
    'SELECT * FROM GEO_PONTOS_INTERESSE WHERE POI_ID = :pID', [AID]);
  try
    if not LQuery.IsEmpty then
      Result := MapearPOI(LQuery);
  finally
    LQuery.Free;
  end;
end;

function TPOIDAO.ListarTodos(AApenaAtivos: Boolean): TPOIList;
var
  LQuery: TFDQuery;
  LSQL: string;
begin
  Result := TPOIList.Create(True); // True = dona dos objetos
  LSQL := 'SELECT * FROM GEO_PONTOS_INTERESSE';
  if AApenaAtivos then
    LSQL := LSQL + ' WHERE POI_ATIVO = 1';
  LSQL := LSQL + ' ORDER BY POI_NOME';

  LQuery := ExecuteQuery(LSQL, []);
  try
    while not LQuery.Eof do
    begin
      Result.Add(MapearPOI(LQuery));
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
end;

function TPOIDAO.ListarPorTipo(ATipo: ETipoPOI): TPOIList;
var
  LQuery: TFDQuery;
  LPOI: TPOI;
begin
  Result := TPOIList.Create(True);
  LPOI := TPOI.Create;
  try
    LPOI.Tipo := ATipo;
    LQuery := ExecuteQuery(
      'SELECT * FROM GEO_PONTOS_INTERESSE ' +
      'WHERE POI_TIPO = :pTipo AND POI_ATIVO = 1 ORDER BY POI_NOME',
      [LPOI.TipoToString]);
    try
      while not LQuery.Eof do
      begin
        Result.Add(MapearPOI(LQuery));
        LQuery.Next;
      end;
    finally
      LQuery.Free;
    end;
  finally
    LPOI.Free;
  end;
end;

function TPOIDAO.BuscarPorNome(const ANome: string): TPOIList;
var
  LQuery: TFDQuery;
begin
  Result := TPOIList.Create(True);
  LQuery := ExecuteQuery(
    'SELECT * FROM GEO_PONTOS_INTERESSE ' +
    'WHERE POI_NOME LIKE :pNome AND POI_ATIVO = 1 ORDER BY POI_NOME',
    ['%' + ANome + '%']);
  try
    while not LQuery.Eof do
    begin
      Result.Add(MapearPOI(LQuery));
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
end;

function TPOIDAO.BuscarProximos(ALatitude, ALongitude, ARaioKM: Double): TPOIList;
var
  LQuery: TFDQuery;
  LDeltaLat, LDeltaLon: Double;
begin
  { Bounding box rápido para uso de índice; filtragem exata por Haversine fica
    no Service.Geo. LDeltaLon varia com cos(lat) pois a Terra é esférica. }
  Result := TPOIList.Create(True);
  LDeltaLat := ARaioKM / 111.0;
  LDeltaLon := ARaioKM / (111.0 * Cos(ALatitude * Pi / 180));

  LQuery := ExecuteQuery(
    'SELECT * FROM GEO_PONTOS_INTERESSE ' +
    'WHERE POI_ATIVO = 1 ' +
    'AND POI_LATITUDE BETWEEN :pLatMin AND :pLatMax ' +
    'AND POI_LONGITUDE BETWEEN :pLonMin AND :pLonMax ' +
    'ORDER BY POI_NOME',
    [ALatitude - LDeltaLat, ALatitude + LDeltaLat,
     ALongitude - LDeltaLon, ALongitude + LDeltaLon]);
  try
    while not LQuery.Eof do
    begin
      Result.Add(MapearPOI(LQuery));
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
end;

function TPOIDAO.ContarTotal(AApenasAtivos: Boolean): Integer;
var
  LQuery: TFDQuery;
  LSQL: string;
begin
  LSQL := 'SELECT COUNT(*) AS TOTAL FROM GEO_PONTOS_INTERESSE';
  if AApenasAtivos then
    LSQL := LSQL + ' WHERE POI_ATIVO = 1';

  LQuery := ExecuteQuery(LSQL, []);
  try
    Result := LQuery.FieldByName('TOTAL').AsInteger;
  finally
    LQuery.Free;
  end;
end;

end.
