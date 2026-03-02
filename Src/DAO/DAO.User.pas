{ DAO.User - Acesso a dados da tabela GEO_USUARIOS.
  Autenticação por comparação de hash SHA-256 no código,
  nunca comparando senha em texto plano no SQL. }
unit DAO.User;

interface

uses
  System.SysUtils, FireDAC.Comp.Client, Data.DB,
  DAO.Base, Model.User;

type
  TUserDAO = class(TBaseDAO)
  private
    function MapearUser(AQuery: TFDQuery): TUser;
  public
    function Inserir(AUser: TUser): Integer;
    function Atualizar(AUser: TUser): Boolean;
    function BuscarPorID(AID: Integer): TUser;
    function BuscarPorLogin(const ALogin: string): TUser;
    function Autenticar(const ALogin, ASenha: string): TUser;
    function AlterarSenha(AID: Integer; const ANovaSenha: string): Boolean;
  end;

implementation

uses
  Utils.Logger, DAO.Connection;

function TUserDAO.MapearUser(AQuery: TFDQuery): TUser;
begin
  Result := TUser.Create;
  Result.ID := AQuery.FieldByName('USU_ID').AsInteger;
  Result.Login := AQuery.FieldByName('USU_LOGIN').AsString;
  Result.Nome := AQuery.FieldByName('USU_NOME').AsString;
  Result.Email := AQuery.FieldByName('USU_EMAIL').AsString;
  Result.SenhaHash := AQuery.FieldByName('USU_SENHA_HASH').AsString;
  Result.Perfil := TUser.StringToPerfil(
    AQuery.FieldByName('USU_PERFIL').AsString);
  { SQLite armazena boolean como INTEGER (0 ou 1) }
  Result.Ativo := AQuery.FieldByName('USU_ATIVO').AsInteger <> 0;
  Result.DataCriacao := AQuery.FieldByName('USU_DATA_CRIACAO').AsDateTime;
  if not AQuery.FieldByName('USU_DATA_ALTERACAO').IsNull then
    Result.DataAlteracao := AQuery.FieldByName('USU_DATA_ALTERACAO').AsDateTime;
end;

function TUserDAO.Inserir(AUser: TUser): Integer;
var
  LQuery: TFDQuery;
  LIdentitySQL: string;
begin
  Result := 0;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := GetConnection;

    case TConnectionManager.GetInstance.TipoBanco of
      tbSQLite: LIdentitySQL := 'SELECT last_insert_rowid() AS NOVO_ID;';
      tbSQLServer: LIdentitySQL := 'SELECT SCOPE_IDENTITY() AS NOVO_ID;';
      tbOracle: LIdentitySQL := 'SELECT SEQ_USER.CURRVAL AS NOVO_ID FROM DUAL;';
    else
      LIdentitySQL := 'SELECT last_insert_rowid() AS NOVO_ID;';
    end;

    LQuery.SQL.Text :=
      'INSERT INTO GEO_USUARIOS ' +
      '(USU_LOGIN, USU_NOME, USU_EMAIL, USU_SENHA_HASH, USU_PERFIL) ' +
      'VALUES (:pLogin, :pNome, :pEmail, :pHash, :pPerfil); ' +
      LIdentitySQL;

    LQuery.Params.ParamByName('pLogin').AsString := AUser.Login;
    LQuery.Params.ParamByName('pNome').AsString := AUser.Nome;
    LQuery.Params.ParamByName('pEmail').AsString := AUser.Email;
    LQuery.Params.ParamByName('pHash').AsString := AUser.SenhaHash;
    LQuery.Params.ParamByName('pPerfil').AsString := AUser.PerfilToString;

    LQuery.Open;
    if not LQuery.Eof then
    begin
      Result := LQuery.FieldByName('NOVO_ID').AsInteger;
      AUser.ID := Result;
    end;
  finally
    LQuery.Free;
  end;
end;

function TUserDAO.Atualizar(AUser: TUser): Boolean;
begin
  Result := ExecuteSQL(
    'UPDATE GEO_USUARIOS SET USU_NOME = :pNome, USU_EMAIL = :pEmail, ' +
    'USU_PERFIL = :pPerfil, USU_ATIVO = :pAtivo, ' +
    'USU_DATA_ALTERACAO = :pData WHERE USU_ID = :pID',
    [AUser.Nome, AUser.Email, AUser.PerfilToString,
     AUser.Ativo, Now, AUser.ID]) > 0;
end;

function TUserDAO.BuscarPorID(AID: Integer): TUser;
var
  LQuery: TFDQuery;
begin
  Result := nil;
  LQuery := ExecuteQuery(
    'SELECT * FROM GEO_USUARIOS WHERE USU_ID = :pID', [AID]);
  try
    if not LQuery.IsEmpty then
      Result := MapearUser(LQuery);
  finally
    LQuery.Free;
  end;
end;

function TUserDAO.BuscarPorLogin(const ALogin: string): TUser;
var
  LQuery: TFDQuery;
begin
  Result := nil;
  LQuery := ExecuteQuery(
    'SELECT * FROM GEO_USUARIOS WHERE USU_LOGIN = :pLogin AND USU_ATIVO = 1',
    [LowerCase(Trim(ALogin))]);
  try
    if not LQuery.IsEmpty then
      Result := MapearUser(LQuery);
  finally
    LQuery.Free;
  end;
end;

function TUserDAO.Autenticar(const ALogin, ASenha: string): TUser;
begin
  { FLUXO COMPLETO DE AUTENTICAÇÃO (2 etapas):

    ETAPA 1 - Busca o usuário no banco:
    BuscarPorLogin faz:
      SELECT * FROM GEO_USUARIOS
      WHERE USU_LOGIN = :pLogin AND USU_ATIVO = 1
    Se não encontrar: Result = nil, logamos WARNING, terminamos.
    Se encontrar: Result = TUser preenchido (com SenhaHash do banco).

    ETAPA 2 - Compara o hash da senha:
    Result.ValidarSenha(ASenha) faz internamente:
      SHA256(ASenha) == Result.SenhaHash ?

    Por que comparar hash, não senha em texto?
    - SHA256 é one-way: dado o hash, não dá pra recuperar a senha original
    - Se o banco vazar, os hashes sozinhos são inúteis para login
    - O banco NUNCA conhece a senha em texto plano do usuário

    FreeAndNil(Result) vs Result := nil:
    - FreeAndNil libera a memória do objeto E coloca o ponteiro como nil
    - Só Result := nil 'perde' o objeto na memória (memory leak!) }
  Result := BuscarPorLogin(ALogin);
  if Assigned(Result) then
  begin
    if not Result.ValidarSenha(ASenha) then
    begin
      TLogger.GetInstance.Warning('DAO.User', 'Autenticar',
        Format('Tentativa de login com senha inválida: %s', [ALogin]));
      FreeAndNil(Result);
    end
    else
    begin
      TLogger.GetInstance.Info('DAO.User', 'Autenticar',
        Format('Login bem-sucedido: %s', [ALogin]));
    end;
  end
  else
  begin
    TLogger.GetInstance.Warning('DAO.User', 'Autenticar',
      Format('Tentativa de login com usuário inexistente: %s', [ALogin]));
  end;
end;

function TUserDAO.AlterarSenha(AID: Integer; const ANovaSenha: string): Boolean;
begin
  Result := ExecuteSQL(
    'UPDATE GEO_USUARIOS SET USU_SENHA_HASH = :pHash, ' +
    'USU_DATA_ALTERACAO = :pData WHERE USU_ID = :pID',
    [TUser.GerarHashSenha(ANovaSenha), Now, AID]) > 0;
end;

end.
