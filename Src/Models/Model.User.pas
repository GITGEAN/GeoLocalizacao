{ Model.User - Entidade usuário do sistema.
  Perfis hierarquicos: puVisualizador < puAnalista < puAdmin.
  Hash SHA-256 gerenciado internamente via THashSHA2. }
unit Model.User;

interface

uses
  System.SysUtils, System.Classes, System.Hash;

type
  { Enum de perfis de acesso - governança e segurança da informação }
  EPerfilUsuario = (
    puVisualizador,  // Apenas consulta
    puAnalista,      // Consulta + edição de dados
    puAdmin          // Acesso total ao sistema
  );

  { Classe Usuário do sistema }
  TUser = class
  private
    FID: Integer;
    FLogin: string;
    FNome: string;
    FEmail: string;
    FSenhaHash: string;     // NUNCA armazene senha em texto puro!
    FPerfil: EPerfilUsuario;
    FAtivo: Boolean;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
    procedure SetLogin(const Value: string);
    procedure SetEmail(const Value: string);
  public
    constructor Create;
    destructor Destroy; override;

    { Gera o hash SHA-256 da senha - função unidirecional }
    class function GerarHashSenha(const ASenha: string): string;

    { Valida a senha comparando hashes }
    function ValidarSenha(const ASenha: string): Boolean;

    { Define nova senha (armazena apenas o hash) }
    procedure DefinirSenha(const ASenha: string);

    { Validação do usuário }
    function Validar: Boolean;
    function ObterErrosValidacao: TStringList;

    { Conversões de perfil }
    function PerfilToString: string;
    class function StringToPerfil(const AValue: string): EPerfilUsuario;

    { Verifica permissão baseada no perfil }
    function TemPermissao(APerfilMinimo: EPerfilUsuario): Boolean;

    function ToString: string; override;

    property ID: Integer read FID write FID;
    property Login: string read FLogin write SetLogin;
    property Nome: string read FNome write FNome;
    property Email: string read FEmail write SetEmail;
    property SenhaHash: string read FSenhaHash write FSenhaHash;
    property Perfil: EPerfilUsuario read FPerfil write FPerfil;
    property Ativo: Boolean read FAtivo write FAtivo;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

constructor TUser.Create;
begin
  inherited Create;
  FAtivo := True;
  FPerfil := puVisualizador;
  FDataCriacao := Now;
end;

destructor TUser.Destroy;
begin
  inherited Destroy;
end;

procedure TUser.SetLogin(const Value: string);
begin
  { Login: sem espaços, lowercase }
  FLogin := LowerCase(Trim(Value));
end;

procedure TUser.SetEmail(const Value: string);
begin
  FEmail := LowerCase(Trim(Value));
end;

class function TUser.GerarHashSenha(const ASenha: string): string;
begin
  Result := THashSHA2.GetHashString(ASenha, SHA256);
end;

function TUser.ValidarSenha(const ASenha: string): Boolean;
begin
  { Compara o hash da senha informada com o hash armazenado }
  Result := GerarHashSenha(ASenha) = FSenhaHash;
end;

procedure TUser.DefinirSenha(const ASenha: string);
begin
  if Length(ASenha) < 6 then
    raise EArgumentException.Create('Senha deve ter no mínimo 6 caracteres');
  FSenhaHash := GerarHashSenha(ASenha);
end;

function TUser.Validar: Boolean;
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

function TUser.ObterErrosValidacao: TStringList;
begin
  Result := TStringList.Create;
  if Trim(FLogin) = '' then
    Result.Add('Login é obrigatório');
  if Trim(FNome) = '' then
    Result.Add('Nome é obrigatório');
  if Trim(FEmail) = '' then
    Result.Add('Email é obrigatório');
  if (Pos('@', FEmail) = 0) and (Trim(FEmail) <> '') then
    Result.Add('Email inválido');
  if Trim(FSenhaHash) = '' then
    Result.Add('Senha é obrigatória');
end;

function TUser.PerfilToString: string;
begin
  case FPerfil of
    puVisualizador: Result := 'VISUALIZADOR';
    puAnalista:     Result := 'ANALISTA';
    puAdmin:        Result := 'ADMIN';
  else
    Result := 'VISUALIZADOR';
  end;
end;

class function TUser.StringToPerfil(const AValue: string): EPerfilUsuario;
var
  LValue: string;
begin
  LValue := UpperCase(Trim(AValue));
  if (LValue = 'ADMIN') or (LValue = 'ADMINISTRADOR') then Result := puAdmin
  else if (LValue = 'ANALISTA') or (LValue = 'OPERADOR') then Result := puAnalista
  else Result := puVisualizador;
end;

function TUser.TemPermissao(APerfilMinimo: EPerfilUsuario): Boolean;
begin
  Result := Ord(FPerfil) >= Ord(APerfilMinimo);
end;

function TUser.ToString: string;
begin
  Result := Format('User[ID=%d, Login="%s", Perfil=%s, Ativo=%s]',
    [FID, FLogin, PerfilToString, BoolToStr(FAtivo, True)]);
end;

end.
