{ Service.Auth - Autenticação e autorização de usuários.
  Gerencia a sessão do usuário logado e verifica permissões por perfil. }
unit Service.Auth;

interface

uses
  System.SysUtils,
  Model.User, DAO.User;

type
  TAuthService = class
  private
    FUserDAO: TUserDAO;
    FUsuarioLogado: TUser;
    FLogado: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    { Autenticação }
    function Login(const ALogin, ASenha: string): Boolean;
    procedure Logout;

    { Autorização }
    function TemPermissao(APerfil: EPerfilUsuario): Boolean;
    function EhAdmin: Boolean;

    { Gestão de usuários (requer perfil Admin) }
    function CriarUsuario(const ALogin, ANome, AEmail, ASenha: string;
      APerfil: EPerfilUsuario): TUser;
    function AlterarSenha(const ASenhaAtual, ANovaSenha: string): Boolean;

    property UsuarioLogado: TUser read FUsuarioLogado;
    property Logado: Boolean read FLogado;
  end;

implementation

uses
  Utils.Logger;

constructor TAuthService.Create;
begin
  inherited Create;
  FUserDAO := TUserDAO.Create;
  FUsuarioLogado := nil;
  FLogado := False;
end;

destructor TAuthService.Destroy;
begin
  FreeAndNil(FUsuarioLogado);
  FreeAndNil(FUserDAO);
  inherited Destroy;
end;

function TAuthService.Login(const ALogin, ASenha: string): Boolean;
begin
  Result := False;

  { Limpa sessão anterior }
  FreeAndNil(FUsuarioLogado);
  FLogado := False;

  { Tenta autenticar via DAO }
  FUsuarioLogado := FUserDAO.Autenticar(ALogin, ASenha);
  FLogado := Assigned(FUsuarioLogado);
  Result := FLogado;

  if FLogado then
    TLogger.GetInstance.Info('AuthService', 'Login',
      Format('Usuário autenticado: %s (Perfil: %s)',
        [FUsuarioLogado.Nome, FUsuarioLogado.PerfilToString]))
  else
    TLogger.GetInstance.Warning('AuthService', 'Login',
      Format('Falha de autenticação: %s', [ALogin]));
end;

procedure TAuthService.Logout;
begin
  if FLogado then
    TLogger.GetInstance.Info('AuthService', 'Logout',
      Format('Logout: %s', [FUsuarioLogado.Login]));

  FreeAndNil(FUsuarioLogado);
  FLogado := False;
end;

function TAuthService.TemPermissao(APerfil: EPerfilUsuario): Boolean;
begin
  Result := FLogado and Assigned(FUsuarioLogado) and
            FUsuarioLogado.TemPermissao(APerfil);
end;

function TAuthService.EhAdmin: Boolean;
begin
  Result := TemPermissao(puAdmin);
end;

function TAuthService.CriarUsuario(const ALogin, ANome, AEmail,
  ASenha: string; APerfil: EPerfilUsuario): TUser;
begin
  if not EhAdmin then
    raise Exception.Create('Apenas administradores podem criar usuários');

  Result := TUser.Create;
  Result.Login := ALogin;
  Result.Nome := ANome;
  Result.Email := AEmail;
  Result.DefinirSenha(ASenha);
  Result.Perfil := APerfil;

  Result.ID := FUserDAO.Inserir(Result);
  TLogger.GetInstance.Info('AuthService', 'CriarUsuario',
    Format('Usuário criado: %s por %s',
      [ALogin, FUsuarioLogado.Login]));
end;

function TAuthService.AlterarSenha(
  const ASenhaAtual, ANovaSenha: string): Boolean;
begin
  Result := False;
  if not FLogado then
    raise Exception.Create('Usuário não está autenticado');

  if not FUsuarioLogado.ValidarSenha(ASenhaAtual) then
    raise Exception.Create('Senha atual incorreta');

  if Length(ANovaSenha) < 6 then
    raise Exception.Create('Nova senha deve ter no mínimo 6 caracteres');

  Result := FUserDAO.AlterarSenha(FUsuarioLogado.ID, ANovaSenha);
  if Result then
    FUsuarioLogado.DefinirSenha(ANovaSenha);
end;

end.
