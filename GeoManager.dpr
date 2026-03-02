{*******************************************************************************
  GeoManager - Sistema de Geoprocessamento Corporativo
  =====================================================

  PROJETO DE ESTUDO - Delphi + ESRI/ArcGIS

  Este projeto demonstra:
  - Arquitetura em camadas (MVC)
  - Integração com ArcGIS REST API (geoprocessamento ESRI)
  - Acesso a banco de dados Oracle/SQL Server via FireDAC
  - APIs REST e SOAP
  - Padrões de projeto (Singleton, DAO, Strategy)
  - Logging e auditoria
  - Boas práticas de desenvolvimento Delphi

  CONCEITOS IMPORTANTES PARA ENTREVISTA:
  ----------------------------------------
  1. O arquivo .DPR é o "Program" do Delphi - é o ponto de entrada da aplicação
  2. "uses" declara as dependências (equivalente a imports em outras linguagens)
  3. Application.Initialize prepara o framework VCL
  4. Application.CreateForm instancia os formulários automaticamente
  5. Application.Run inicia o loop de mensagens do Windows (message loop)

  PADRÃO DE NOMENCLATURA:
  - Prefixo T para Types/Classes (ex: TPOI, TUser)
  - Prefixo F para campos privados (Fields) (ex: FNome, FLatitude)
  - Prefixo I para Interfaces (ex: IDAO, IService)
  - Unit names seguem padrão: Camada.Contexto (ex: Model.POI, DAO.Base)
*******************************************************************************}
program GeoManager;

uses
  { --- Módulos do sistema (VCL Framework) --- }
  Vcl.Forms,
  System.SysUtils,
  Winapi.Windows,

  { --- Views (Interface do Usuário) ---
    CONCEITO: No padrão MVC, as Views são responsáveis apenas pela
    apresentação. A lógica de negócio fica nos Services. }
  View.Main in 'Src\Views\View.Main.pas' {FrmMain},
  View.POIManager in 'Src\Views\View.POIManager.pas' {FrmPOIManager},
  View.Config in 'Src\Views\View.Config.pas' {FrmConfig},
  View.DataModule in 'Src\Views\View.DataModule.pas' {DmGeoManager: TDataModule},

  { --- Models (Entidades de Negócio) ---
    CONCEITO: Models representam os objetos do domínio da aplicação.
    São classes simples com propriedades e validações básicas. }
  Model.POI in 'Src\Models\Model.POI.pas',
  Model.User in 'Src\Models\Model.User.pas',
  Model.LogEntry in 'Src\Models\Model.LogEntry.pas',

  { --- DAO (Data Access Objects) ---
    CONCEITO: Padrão DAO separa a lógica de acesso a dados da lógica
    de negócio. Facilita trocar o banco de dados sem alterar o resto. }
  DAO.Base in 'Src\DAO\DAO.Base.pas',
  DAO.Connection in 'Src\DAO\DAO.Connection.pas',
  DAO.POI in 'Src\DAO\DAO.POI.pas',
  DAO.User in 'Src\DAO\DAO.User.pas',

  { --- Services (Camada de Serviço / Regras de Negócio) ---
    CONCEITO: Services orquestram a lógica de negócio, chamando DAOs
    e integrações externas conforme necessário. }
  Service.Geo in 'Src\Services\Service.Geo.pas',
  Service.POI in 'Src\Services\Service.POI.pas',
  Service.Auth in 'Src\Services\Service.Auth.pas',

  { --- Integration (Integrações Externas) ---
    CONCEITO: Camada dedicada para comunicação com sistemas externos.
    Isola a complexidade de protocolos (REST, SOAP) do resto do app. }
  Integration.ArcGIS.REST in 'Src\Integration\Integration.ArcGIS.REST.pas',
  Integration.SOAP.Client in 'Src\Integration\Integration.SOAP.Client.pas',
  Integration.HTTP.Helper in 'Src\Integration\Integration.HTTP.Helper.pas',

  { --- Utils (Utilitários) ---
    CONCEITO: Funções auxiliares reutilizáveis em todo o projeto.
    Cross-cutting concerns como logging e configuração. }
  Utils.Logger in 'Src\Utils\Utils.Logger.pas',
  Utils.Config in 'Src\Utils\Utils.Config.pas',
  Utils.GeoCalc in 'Src\Utils\Utils.GeoCalc.pas';

{$R *.res}

{*******************************************************************************
  PONTO DE ENTRADA DA APLICAÇÃO
  =============================

  CONCEITO PARA ENTREVISTA:
  - Em Delphi, o Application é um objeto global (TApplication) que gerencia
    o ciclo de vida da aplicação Windows
  - Application.MainFormOnTaskbar controla se o form principal aparece na
    barra de tarefas (Windows 7+)
  - Os formulários criados aqui ficam disponíveis como variáveis globais
  - O DataModule é criado PRIMEIRO porque os outros forms dependem dele
    para conexão com banco de dados
  - try/except no bloco principal captura erros não tratados na inicialização
*******************************************************************************}
begin
  { ReportMemoryLeaksOnShutdown é uma variável global do Delphi que,
    quando True, exibe um relatório de memory leaks ao fechar a aplicação.
    MUITO ÚTIL durante desenvolvimento para detectar vazamentos de memória.
    IMPORTANTE: Deve ser False em produção! }
  ReportMemoryLeaksOnShutdown := True;

  try
    { Inicializa o framework VCL (Visual Component Library) }
    Application.Initialize;

    { Define o título que aparece na barra de tarefas }
    Application.Title := 'GeoManager - Sistema de Geoprocessamento';

    { Formulário principal aparece na barra de tarefas do Windows }
    Application.MainFormOnTaskbar := True;

    { ORDEM DE CRIAÇÃO É IMPORTANTE:
      1. DataModule PRIMEIRO - contém a conexão com banco de dados
      2. FrmMain SEGUNDO - formulário principal
      Os outros forms são criados sob demanda (não aqui) }
    Application.CreateForm(TDmGeoManager, DmGeoManager);
    Application.CreateForm(TFrmMain, FrmMain);

    { Inicia o loop de mensagens do Windows.
      A aplicação fica "rodando" aqui até o usuário fechar o form principal. }
    Application.Run;
  except
    on E: Exception do
    begin
      { Em produção, este erro seria logado em arquivo/banco.
        Aqui usamos MessageBox nativo do Windows como último recurso. }
      Application.MessageBox(
        PChar('Erro fatal na inicialização: ' + E.Message),
        'GeoManager - Erro',
        MB_ICONERROR or MB_OK
      );
    end;
  end;
end.
