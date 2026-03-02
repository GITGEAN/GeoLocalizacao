{ View.Main - Janela principal da aplicação.
  Renderiza o mapa ArcGIS via TWebBrowser (OLE Automation para
  comunicação bidirecional Delphi <-> JavaScript). }
unit View.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ActiveX,
  System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus,
  Vcl.OleCtrls, SHDocVw, MSHTML,  // TWebBrowser & IHTMLDocument2
  Service.Geo, Service.POI, Service.Auth;

type
  TFrmMain = class(TForm)
    { === Componentes de Layout === }
    pnlTop: TPanel;          // Barra de ferramentas superior
    pnlLeft: TPanel;         // Painel lateral (busca/resultados)
    pnlMap: TPanel;          // Área do mapa
    Splitter1: TSplitter;    // Divisor redimensionável
    StatusBar1: TStatusBar;  // Barra de status inferior

    { === Menu Principal === }
    MainMenu1: TMainMenu;
    mnuArquivo: TMenuItem;
    mnuArqConectar: TMenuItem;
    mnuArqDesconectar: TMenuItem;
    mnuArqSep1: TMenuItem;
    mnuArqConfig: TMenuItem;
    mnuArqSep2: TMenuItem;
    mnuArqSair: TMenuItem;
    mnuPOI: TMenuItem;
    mnuPOIGerenciar: TMenuItem;
    mnuPOINovo: TMenuItem;
    mnuMapa: TMenuItem;
    mnuMapaCentralizar: TMenuItem;
    mnuMapaLimpar: TMenuItem;
    mnuAjuda: TMenuItem;
    mnuAjudaSobre: TMenuItem;

    { === Toolbar Superior === }
    edtBusca: TEdit;           // Campo de busca
    btnBuscar: TButton;        // Botão buscar
    btnGeocoding: TButton;     // Botão geocodificar
    cmbTipoPOI: TComboBox;     // Filtro por tipo de POI
    lblBusca: TLabel;

    { === Painel Lateral === }
    lstResultados: TListBox;   // Lista de resultados
    lblResultados: TLabel;
    mmoDetalhes: TMemo;        // Detalhes do POI selecionado
    btnAdicionarPOI: TButton;
    btnVerNoMapa: TButton;

    { === Mapa === }
    WebBrowser1: TWebBrowser;  // Navegador embutido que exibe o mapa

    { === Eventos === }
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure btnGeocodingClick(Sender: TObject);
    procedure btnAdicionarPOIClick(Sender: TObject);
    procedure btnVerNoMapaClick(Sender: TObject);
    procedure lstResultadosClick(Sender: TObject);
    procedure mnuArqConectarClick(Sender: TObject);
    procedure mnuArqDesconectarClick(Sender: TObject);
    procedure mnuArqConfigClick(Sender: TObject);
    procedure mnuArqSairClick(Sender: TObject);
    procedure mnuPOIGerenciarClick(Sender: TObject);
    procedure mnuMapaCentralizarClick(Sender: TObject);
    procedure mnuAjudaSobreClick(Sender: TObject);

  private
    FGeoService: TGeoService;
    FPOIService: TPOIService;
    FAuthService: TAuthService;

    { Carrega o mapa ArcGIS no WebBrowser }
    procedure CarregarMapa;

    { Gera o HTML+JavaScript do mapa ArcGIS }
    function GerarHTMLMapa: string;

    { Executa JavaScript no WebBrowser }
    procedure ExecutarJavaScript(const AScript: string);

    { Adiciona marcador no mapa via JavaScript }
    procedure AdicionarMarcadorMapa(ALatitude, ALongitude: Double;
      const ATitulo, ADescricao: string);

    { Centraliza o mapa em uma coordenada }
    procedure CentralizarMapa(ALatitude, ALongitude: Double;
      AZoom: Integer = 15);

    { Atualiza a barra de status }
    procedure AtualizarStatus(const AMensagem: string);

    { Carrega POIs na lista lateral }
    procedure CarregarPOIsNaLista;
  public
    { Nada público por enquanto - View não expõe métodos }
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

uses
  View.POIManager, View.Config, View.DataModule,
  Model.POI, Utils.Logger, Utils.Config;

{ ============================================================================ }
{ Eventos do Formulário }
{ ============================================================================ }

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  { Inicializa os serviços }
  FGeoService := TGeoService.Create(
    TConfigManager.GetInstance.GetArcGISApiKey);
  FPOIService := TPOIService.Create;
  FAuthService := TAuthService.Create;

  { Popula o ComboBox de tipos de POI }
  cmbTipoPOI.Items.Clear;
  cmbTipoPOI.Items.Add('Todos');
  cmbTipoPOI.Items.Add('GERAL');
  cmbTipoPOI.Items.Add('MONUMENTO');
  cmbTipoPOI.Items.Add('GOVERNO');
  cmbTipoPOI.Items.Add('CULTURA');
  cmbTipoPOI.Items.Add('INFRAESTRUTURA');
  cmbTipoPOI.Items.Add('SAUDE');
  cmbTipoPOI.Items.Add('EDUCACAO');
  cmbTipoPOI.Items.Add('TRANSPORTE');
  cmbTipoPOI.Items.Add('MEIO_AMBIENTE');
  cmbTipoPOI.ItemIndex := 0;

  TLogger.GetInstance.Info('View.Main', 'FormCreate',
    'Formulário principal inicializado');
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FGeoService);
  FreeAndNil(FPOIService);
  FreeAndNil(FAuthService);
end;

procedure TFrmMain.FormShow(Sender: TObject);
begin
  { Tenta conectar ao banco de dados automaticamente }
  try
    AtualizarStatus('Conectando ao banco de dados...');
    if DmGeoManager.Conectar then
    begin
      AtualizarStatus('Banco conectado com sucesso');
    end
    else
    begin
      AtualizarStatus('Falha ao conectar ao banco - use Arquivo > Conectar');
    end;
  except
    on E: Exception do
      AtualizarStatus('Erro ao conectar: ' + E.Message);
  end;

  { Carrega o mapa ao exibir o formulário }
  try
    AtualizarStatus('Carregando mapa...');
    CarregarMapa;
    AtualizarStatus('Mapa carregado - Carregando POIs...');
    { Aguarda o mapa carregar antes de adicionar marcadores }
    Sleep(500);
    CarregarPOIsNaLista;
    AtualizarStatus('Pronto');
  except
    on E: Exception do
    begin
      AtualizarStatus('ERRO: ' + E.Message);
      ShowMessage('Erro ao carregar o mapa:' + sLineBreak + E.Message);
    end;
  end;
end;


{ ============================================================================ }
{ Ações de Busca e Geocoding }
{ ============================================================================ }

procedure TFrmMain.btnBuscarClick(Sender: TObject);
var
  LResultados: TPOIList;
  LPOI: TPOI;
begin
  if Trim(edtBusca.Text) = '' then
  begin
    ShowMessage('Digite um termo para buscar');
    edtBusca.SetFocus;
    Exit;
  end;

  AtualizarStatus('Buscando POIs...');
  lstResultados.Items.Clear;

  try
    LResultados := FPOIService.BuscarPorNome(edtBusca.Text);
    try
      for LPOI in LResultados do
      begin
        lstResultados.Items.AddObject(
          Format('%s (%s)', [LPOI.Nome, LPOI.TipoToString]),
          LPOI.Clone  // Clone porque a lista original será destruída
        );
      end;
      AtualizarStatus(Format('%d resultado(s) encontrado(s)',
        [LResultados.Count]));
    finally
      LResultados.Free;
    end;
  except
    on E: Exception do
    begin
      AtualizarStatus('Erro na busca');
      ShowMessage('Erro ao buscar: ' + E.Message);
    end;
  end;
end;

procedure TFrmMain.btnGeocodingClick(Sender: TObject);
var
  LLatitude, LLongitude: Double;
begin
  if Trim(edtBusca.Text) = '' then
  begin
    ShowMessage('Digite um endereço para geocodificar');
    Exit;
  end;

  AtualizarStatus('Geocodificando endereço via ArcGIS...');
  try
    if FGeoService.EnderecoParaCoordenadas(edtBusca.Text,
      LLatitude, LLongitude) then
    begin
      CentralizarMapa(LLatitude, LLongitude, 15);
      AdicionarMarcadorMapa(LLatitude, LLongitude,
        'Resultado', edtBusca.Text);

      mmoDetalhes.Lines.Clear;
      mmoDetalhes.Lines.Add('=== Resultado da Geocodificação ===');
      mmoDetalhes.Lines.Add('Endereço: ' + edtBusca.Text);
      mmoDetalhes.Lines.Add(Format('Latitude: %.8f', [LLatitude]));
      mmoDetalhes.Lines.Add(Format('Longitude: %.8f', [LLongitude]));
      mmoDetalhes.Lines.Add('DMS: ' + FGeoService.FormatarCoordenadasDMS(
        LLatitude, LLongitude));
      mmoDetalhes.Lines.Add('No Brasil: ' +
        BoolToStr(FGeoService.ValidarCoordenadas(LLatitude, LLongitude), True));

      AtualizarStatus(Format('Geocodificado: (%.6f, %.6f)',
        [LLatitude, LLongitude]));
    end
    else
    begin
      AtualizarStatus('Endereço não encontrado');
      ShowMessage('Não foi possível geocodificar o endereço.');
    end;
  except
    on E: Exception do
    begin
      AtualizarStatus('Erro na geocodificação');
      ShowMessage('Erro: ' + E.Message);
    end;
  end;
end;

procedure TFrmMain.lstResultadosClick(Sender: TObject);
var
  LPOI: TPOI;
begin
  { Exibe detalhes do POI selecionado }
  if lstResultados.ItemIndex >= 0 then
  begin
    LPOI := TPOI(lstResultados.Items.Objects[lstResultados.ItemIndex]);
    if Assigned(LPOI) then
    begin
      mmoDetalhes.Lines.Clear;
      mmoDetalhes.Lines.Add('=== ' + LPOI.Nome + ' ===');
      mmoDetalhes.Lines.Add('Tipo: ' + LPOI.TipoToString);
      mmoDetalhes.Lines.Add('Descrição: ' + LPOI.Descricao);
      mmoDetalhes.Lines.Add('Endereço: ' + LPOI.Endereco);
      mmoDetalhes.Lines.Add('Coordenadas: ' + LPOI.CoordenadasFormatadas);
      mmoDetalhes.Lines.Add('DMS: ' + FGeoService.FormatarCoordenadasDMS(
        LPOI.Latitude, LPOI.Longitude));
      mmoDetalhes.Lines.Add('Ativo: ' + BoolToStr(LPOI.Ativo, True));
      mmoDetalhes.Lines.Add('Criado em: ' +
        FormatDateTime('dd/mm/yyyy hh:nn', LPOI.DataCriacao));
    end;
  end;
end;

procedure TFrmMain.btnVerNoMapaClick(Sender: TObject);
var
  LPOI: TPOI;
begin
  if lstResultados.ItemIndex >= 0 then
  begin
    LPOI := TPOI(lstResultados.Items.Objects[lstResultados.ItemIndex]);
    if Assigned(LPOI) then
    begin
      CentralizarMapa(LPOI.Latitude, LPOI.Longitude, 15);
      AdicionarMarcadorMapa(LPOI.Latitude, LPOI.Longitude,
        LPOI.Nome, LPOI.Descricao);
    end;
  end;
end;

procedure TFrmMain.btnAdicionarPOIClick(Sender: TObject);
begin
  mnuPOIGerenciarClick(Sender);
end;

{ ============================================================================ }
{ Menu Handlers }
{ ============================================================================ }

procedure TFrmMain.mnuArqConectarClick(Sender: TObject);
begin
  AtualizarStatus('Conectando ao banco...');
  try
    if DmGeoManager.Conectar then
    begin
      AtualizarStatus('Conectado ao banco de dados');
      CarregarPOIsNaLista;
    end;
  except
    on E: Exception do
    begin
      AtualizarStatus('Erro ao conectar');
      ShowMessage('Falha ao conectar ao banco de dados:'
        + sLineBreak + sLineBreak + E.Message
        + sLineBreak + sLineBreak
        + 'Verifique em Arquivo > Configurações se os dados estão corretos.'
        + sLineBreak + 'Docker rodando? Servidor: localhost:1433');
    end;
  end;
end;

procedure TFrmMain.mnuArqDesconectarClick(Sender: TObject);
begin
  DmGeoManager.Desconectar;
  AtualizarStatus('Desconectado');
end;

procedure TFrmMain.mnuArqConfigClick(Sender: TObject);
begin
  { Abre o formulário de configurações como modal }
  FrmConfig := TFrmConfig.Create(Self);
  try
    FrmConfig.ShowModal;
  finally
    FrmConfig.Free;
  end;
end;

procedure TFrmMain.mnuArqSairClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmMain.mnuPOIGerenciarClick(Sender: TObject);
begin
  { Abre o gerenciador de POIs }
  FrmPOIManager := TFrmPOIManager.Create(Self);
  try
    FrmPOIManager.ShowModal;
    CarregarPOIsNaLista;  // Recarrega após possíveis alterações
  finally
    FrmPOIManager.Free;
  end;
end;

procedure TFrmMain.mnuMapaCentralizarClick(Sender: TObject);
var
  LConfig: TConfigManager;
begin
  LConfig := TConfigManager.GetInstance;
  CentralizarMapa(LConfig.GetMapaCentroLatitude,
    LConfig.GetMapaCentroLongitude, LConfig.GetMapaZoomPadrao);
end;

procedure TFrmMain.mnuAjudaSobreClick(Sender: TObject);
begin
  ShowMessage(
    'GeoManager - Sistema de Geoprocessamento' + sLineBreak +
    'Versão 1.0.0' + sLineBreak + sLineBreak +
    'Projeto de estudo Delphi + ESRI/ArcGIS' + sLineBreak +
    'Demonstra: MVC, DAO, REST, SOAP, FireDAC, GIS' + sLineBreak + sLineBreak +
    'Tecnologias:' + sLineBreak +
    '- Delphi (Object Pascal)' + sLineBreak +
    '- ArcGIS JavaScript API 4.x' + sLineBreak +
    '- ArcGIS REST Services' + sLineBreak +
    '- FireDAC (Oracle / SQL Server)' + sLineBreak +
    '- Padrões: Singleton, DAO, MVC, Strategy'
  );
end;

{ ============================================================================ }
{ Mapa ArcGIS }
{ ============================================================================ }

procedure TFrmMain.CarregarMapa;
var
  LHTML: string;
  LArquivoHTML: string;
  LStream: TStringStream;
begin
  if not Assigned(WebBrowser1) then
  begin
    TLogger.GetInstance.Error('View.Main', 'CarregarMapa', 'WebBrowser1 não está inicializado');
    raise Exception.Create('Componente WebBrowser não inicializado');
  end;

  LHTML := GerarHTMLMapa;
  TLogger.GetInstance.Info('View.Main', 'CarregarMapa', 'HTML mapa gerado com ' + IntToStr(Length(LHTML)) + ' caracteres');

  try
    { Salva o HTML em arquivo temporário }
    LArquivoHTML := ExtractFilePath(ParamStr(0)) + 'mapa_temp.html';
    LStream := TStringStream.Create(LHTML, TEncoding.UTF8);
    try
      LStream.SaveToFile(LArquivoHTML);
    finally
      LStream.Free;
    end;

    { Navega para o arquivo HTML via file:// protocol }
    WebBrowser1.Navigate('file:///' + StringReplace(LArquivoHTML, '\', '/', [rfReplaceAll]));
    
    { Aguarda o navegador carregar }
    while WebBrowser1.ReadyState <> READYSTATE_COMPLETE do
    begin
      Application.ProcessMessages;
      Sleep(10);
    end;

    TLogger.GetInstance.Info('View.Main', 'CarregarMapa', 'Mapa carregado de ' + LArquivoHTML);
  except
    on E: Exception do
    begin
      TLogger.GetInstance.Error('View.Main', 'CarregarMapa', 'Erro ao carregar mapa: ' + E.Message);
      raise;
    end;
  end;
end;

function TFrmMain.GerarHTMLMapa: string;
var
  LConfig: TConfigManager;
  LCentroLat, LCentroLon: Double;
  LZoom: Integer;
  LMapaURL: string;
begin
  LConfig := TConfigManager.GetInstance;
  LCentroLat := LConfig.GetMapaCentroLatitude;
  LCentroLon := LConfig.GetMapaCentroLongitude;
  LZoom := LConfig.GetMapaZoomPadrao;

  { Usa OpenStreetMap Static API - sem JavaScript complexo }
  { lat=-15.7939, lon=-47.8828 (Brasília) }
  LMapaURL := Format('https://maps.geoapify.com/v1/staticmap?style=osm-bright&width=1200&height=800&center=lonlat:%.4f,%.4f&zoom=%d&apiKey=', [LCentroLon, LCentroLat, LZoom]);

  Result :=
    '<!DOCTYPE html>' +
    '<html>' +
    '<head>' +
    '<meta charset="utf-8">' +
    '<meta http-equiv="X-UA-Compatible" content="IE=edge">' +
    '<meta name="viewport" content="width=device-width, initial-scale=1">' +
    '<title>GeoManager - Mapa</title>' +
    '<style>' +
    'html, body { margin: 0; padding: 0; width: 100%; height: 100%; font-family: Arial, sans-serif; }' +
    '#mapContainer { width: 100%; height: 100%; display: flex; flex-direction: column; }' +
    '#map { flex: 1; background: url(' + LMapaURL + ') center/cover no-repeat; position: relative; }' +
    '#panel { position: fixed; top: 10px; left: 10px; background: white; padding: 15px; border-radius: 5px; box-shadow: 0 2px 10px rgba(0,0,0,0.3); z-index: 1000; max-width: 300px; }' +
    '.panel-title { font-weight: bold; font-size: 14px; margin-bottom: 10px; }' +
    '.panel-item { font-size: 11px; margin: 4px 0; color: #666; }' +
    '.marker-btn { cursor: pointer; margin-top: 10px; padding: 8px 12px; background: #0077be; color: white; border: none; border-radius: 3px; font-size: 12px; }' +
    '.marker-btn:hover { background: #0055aa; }' +
    '#markersList { position: fixed; bottom: 10px; left: 10px; background: rgba(255,255,255,0.95); padding: 10px; border-radius: 5px; max-height: 300px; overflow-y: auto; max-width: 250px; box-shadow: 0 2px 10px rgba(0,0,0,0.3); z-index: 999; font-size: 11px; }' +
    '.marker-item { padding: 5px; border-bottom: 1px solid #eee; cursor: pointer; }' +
    '.marker-item:hover { background: #f0f0f0; }' +
    '</style>' +
    '</head>' +
    '<body>' +
    '<div id="mapContainer">' +
    '  <div id="map"></div>' +
    '</div>' +
    '<div id="panel">' +
    '  <div class="panel-title">GeoManager - Mapa</div>' +
    '  <div class="panel-item"><b>Local:</b> Brasília, DF</div>' +
    '  <div class="panel-item"><b>Centro:</b> ' + Format('%.4f, %.4f', [LCentroLat, LCentroLon]) + '</div>' +
    '  <div class="panel-item"><b>Zoom:</b> ' + IntToStr(LZoom) + '</div>' +
    '  <div id="poi-count" class="panel-item"><b>POIs:</b> Carregando...</div>' +
    '  <button class="marker-btn" onclick="location.reload()">Recarregar</button>' +
    '</div>' +
    '<div id="markersList">' +
    '  <strong>Pontos de Interesse:</strong>' +
    '  <div id="poiList"></div>' +
    '</div>' +
    '<script>' +
    'var poiCount = 0;' +
    'function addMarker(lat, lon, title, desc) {' +
    '  poiCount++;' +
    '  var item = document.createElement("div");' +
    '  item.className = "marker-item";' +
    '  item.innerHTML = poiCount + ". " + title;' +
    '  document.getElementById("poiList").appendChild(item);' +
    '  document.getElementById("poi-count").innerHTML = "<b>POIs:</b> " + poiCount;' +
    '}' +
    'function centerMap(lat, lon, zoom) {}' +
    'function clearMarkers() { document.getElementById("poiList").innerHTML = ""; poiCount = 0; }' +
    '</script>' +
    '</body>' +
    '</html>';
end;

procedure TFrmMain.ExecutarJavaScript(const AScript: string);
begin
  { Executa JavaScript no WebBrowser via OLE Automation }
  try
    WebBrowser1.OleObject.Document.parentWindow.execScript(AScript, 'JavaScript');
  except
    // Ignora erros de JS
  end;
end;

procedure TFrmMain.AdicionarMarcadorMapa(ALatitude, ALongitude: Double;
  const ATitulo, ADescricao: string);
begin
  ExecutarJavaScript(Format('addMarker(%f, %f, "%s", "%s")',
    [ALatitude, ALongitude, ATitulo, ADescricao]));
end;

procedure TFrmMain.CentralizarMapa(ALatitude, ALongitude: Double;
  AZoom: Integer);
begin
  ExecutarJavaScript(Format('centerMap(%f, %f, %d)',
    [ALatitude, ALongitude, AZoom]));
end;

procedure TFrmMain.AtualizarStatus(const AMensagem: string);
begin
  StatusBar1.SimpleText := Format('[%s] %s',
    [FormatDateTime('hh:nn:ss', Now), AMensagem]);
end;

procedure TFrmMain.CarregarPOIsNaLista;
var
  LPOIs: TPOIList;
  LPOI: TPOI;
begin
  lstResultados.Items.Clear;
  try
    LPOIs := FPOIService.ListarTodos;
    try
      for LPOI in LPOIs do
      begin
        lstResultados.Items.AddObject(
          Format('%s (%s)', [LPOI.Nome, LPOI.TipoToString]),
          LPOI.Clone);
        { Adiciona marcador no mapa }
        AdicionarMarcadorMapa(LPOI.Latitude, LPOI.Longitude,
          LPOI.Nome, LPOI.Descricao);
      end;
      AtualizarStatus(Format('%d POIs carregados', [LPOIs.Count]));
    finally
      LPOIs.Free;
    end;
  except
    on E: Exception do
      AtualizarStatus('Erro ao carregar POIs: ' + E.Message);
  end;
end;

end.
