{ View.POIManager - Tela de CRUD de Pontos de Interesse.
  O ID de cada registro é guardado em TListItem.Data para não
  precisar exibir a chave primária na lista. }
unit View.POIManager;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids, Vcl.DBGrids,
  Data.DB, Model.POI, Service.POI;

type
  TFrmPOIManager = class(TForm)
    pnlTop: TPanel;
    pnlBottom: TPanel;
    pnlEdit: TPanel;

    { Grid de dados }
    lstPOIs: TListView;

    { Campos de edição }
    lblNome: TLabel;
    edtNome: TEdit;
    lblDescricao: TLabel;
    mmoDescricao: TMemo;
    lblLatitude: TLabel;
    edtLatitude: TEdit;
    lblLongitude: TLabel;
    edtLongitude: TEdit;
    lblTipo: TLabel;
    cmbTipo: TComboBox;
    lblEndereco: TLabel;
    edtEndereco: TEdit;

    { Botões de ação }
    btnNovo: TButton;
    btnSalvar: TButton;
    btnExcluir: TButton;
    btnCancelar: TButton;
    btnGeocoding: TButton;
    btnFechar: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnGeocodingClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
    procedure lstPOIsSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
  private
    FPOIService: TPOIService;
    FPOIAtual: TPOI;
    FEditando: Boolean;

    procedure CarregarLista;
    procedure PreencherCampos(APOI: TPOI);
    procedure LimparCampos;
    procedure HabilitarEdicao(AHabilitar: Boolean);
    function ValidarCampos: Boolean;
  public
    { Nada público }
  end;

var
  FrmPOIManager: TFrmPOIManager;

implementation

{$R *.dfm}

uses
  Service.Geo, Utils.Logger;

procedure TFrmPOIManager.FormCreate(Sender: TObject);
begin
  FPOIService := TPOIService.Create;
  FPOIAtual := nil;
  FEditando := False;

  { Popula tipos de POI }
  cmbTipo.Items.Clear;
  cmbTipo.Items.Add('GERAL');
  cmbTipo.Items.Add('MONUMENTO');
  cmbTipo.Items.Add('GOVERNO');
  cmbTipo.Items.Add('CULTURA');
  cmbTipo.Items.Add('INFRAESTRUTURA');
  cmbTipo.Items.Add('SAUDE');
  cmbTipo.Items.Add('EDUCACAO');
  cmbTipo.Items.Add('TRANSPORTE');
  cmbTipo.Items.Add('MEIO_AMBIENTE');
  cmbTipo.ItemIndex := 0;

  { Configura colunas do ListView }
  lstPOIs.ViewStyle := vsReport;
  with lstPOIs.Columns.Add do begin Caption := 'ID'; Width := 50; end;
  with lstPOIs.Columns.Add do begin Caption := 'Nome'; Width := 200; end;
  with lstPOIs.Columns.Add do begin Caption := 'Tipo'; Width := 120; end;
  with lstPOIs.Columns.Add do begin Caption := 'Latitude'; Width := 100; end;
  with lstPOIs.Columns.Add do begin Caption := 'Longitude'; Width := 100; end;
  with lstPOIs.Columns.Add do begin Caption := 'Endereço'; Width := 250; end;

  HabilitarEdicao(False);
  CarregarLista;
end;

procedure TFrmPOIManager.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPOIAtual);
  FreeAndNil(FPOIService);
end;

procedure TFrmPOIManager.CarregarLista;
var
  LPOIs: TPOIList;
  LPOI: TPOI;
  LItem: TListItem;
begin
  lstPOIs.Items.Clear;
  try
    LPOIs := FPOIService.ListarTodos;
    try
      for LPOI in LPOIs do
      begin
        LItem := lstPOIs.Items.Add;
        LItem.Caption := IntToStr(LPOI.ID);
        LItem.SubItems.Add(LPOI.Nome);
        LItem.SubItems.Add(LPOI.TipoToString);
        LItem.SubItems.Add(Format('%.6f', [LPOI.Latitude]));
        LItem.SubItems.Add(Format('%.6f', [LPOI.Longitude]));
        LItem.SubItems.Add(LPOI.Endereco);
        LItem.Data := Pointer(LPOI.ID); // Armazena ID no ponteiro
      end;
    finally
      LPOIs.Free;
    end;
  except
    on E: Exception do
      ShowMessage('Erro ao carregar POIs: ' + E.Message);
  end;
end;

procedure TFrmPOIManager.lstPOIsSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
begin
  if Selected and Assigned(Item) then
  begin
    FreeAndNil(FPOIAtual);
    FPOIAtual := FPOIService.BuscarPOI(Integer(Item.Data));
    if Assigned(FPOIAtual) then
      PreencherCampos(FPOIAtual);
  end;
end;

procedure TFrmPOIManager.PreencherCampos(APOI: TPOI);
begin
  edtNome.Text := APOI.Nome;
  mmoDescricao.Text := APOI.Descricao;
  edtLatitude.Text := Format('%.8f', [APOI.Latitude]);
  edtLongitude.Text := Format('%.8f', [APOI.Longitude]);
  cmbTipo.ItemIndex := cmbTipo.Items.IndexOf(APOI.TipoToString);
  edtEndereco.Text := APOI.Endereco;
end;

procedure TFrmPOIManager.LimparCampos;
begin
  edtNome.Clear;
  mmoDescricao.Clear;
  edtLatitude.Clear;
  edtLongitude.Clear;
  cmbTipo.ItemIndex := 0;
  edtEndereco.Clear;
end;

procedure TFrmPOIManager.HabilitarEdicao(AHabilitar: Boolean);
begin
  FEditando := AHabilitar;
  edtNome.Enabled := AHabilitar;
  mmoDescricao.Enabled := AHabilitar;
  edtLatitude.Enabled := AHabilitar;
  edtLongitude.Enabled := AHabilitar;
  cmbTipo.Enabled := AHabilitar;
  edtEndereco.Enabled := AHabilitar;
  btnSalvar.Enabled := AHabilitar;
  btnCancelar.Enabled := AHabilitar;
  btnGeocoding.Enabled := AHabilitar;
  btnExcluir.Enabled := Assigned(FPOIAtual) and not AHabilitar;
end;

function TFrmPOIManager.ValidarCampos: Boolean;
begin
  Result := True;
  if Trim(edtNome.Text) = '' then
  begin
    ShowMessage('Nome é obrigatório');
    edtNome.SetFocus;
    Result := False;
    Exit;
  end;
  if Trim(edtLatitude.Text) = '' then
  begin
    ShowMessage('Latitude é obrigatória');
    edtLatitude.SetFocus;
    Result := False;
    Exit;
  end;
  if Trim(edtLongitude.Text) = '' then
  begin
    ShowMessage('Longitude é obrigatória');
    edtLongitude.SetFocus;
    Result := False;
    Exit;
  end;
end;

procedure TFrmPOIManager.btnNovoClick(Sender: TObject);
begin
  FreeAndNil(FPOIAtual);
  LimparCampos;
  HabilitarEdicao(True);
  edtNome.SetFocus;
end;

procedure TFrmPOIManager.btnSalvarClick(Sender: TObject);
var
  LLat, LLon: Double;
begin
  if not ValidarCampos then Exit;

  try
    LLat := StrToFloat(edtLatitude.Text);
    LLon := StrToFloat(edtLongitude.Text);
  except
    ShowMessage('Coordenadas inválidas. Use formato decimal (ex: -23.561204)');
    Exit;
  end;

  try
    if Assigned(FPOIAtual) then
    begin
      { Atualização }
      FPOIAtual.Nome := edtNome.Text;
      FPOIAtual.Descricao := mmoDescricao.Text;
      FPOIAtual.Latitude := LLat;
      FPOIAtual.Longitude := LLon;
      FPOIAtual.Tipo := TPOI.StringToTipo(cmbTipo.Text);
      FPOIAtual.Endereco := edtEndereco.Text;
      FPOIService.AtualizarPOI(FPOIAtual);
      ShowMessage('POI atualizado com sucesso!');
    end
    else
    begin
      { Inserção }
      FPOIAtual := FPOIService.CriarPOI(edtNome.Text, mmoDescricao.Text,
        LLat, LLon, TPOI.StringToTipo(cmbTipo.Text), 1);
      ShowMessage('POI criado com sucesso! ID: ' + IntToStr(FPOIAtual.ID));
    end;

    HabilitarEdicao(False);
    CarregarLista;
  except
    on E: Exception do
      ShowMessage('Erro ao salvar: ' + E.Message);
  end;
end;

procedure TFrmPOIManager.btnExcluirClick(Sender: TObject);
begin
  if not Assigned(FPOIAtual) then Exit;

  if MessageDlg(Format('Deseja excluir o POI "%s"?', [FPOIAtual.Nome]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      FPOIService.ExcluirPOI(FPOIAtual.ID);
      FreeAndNil(FPOIAtual);
      LimparCampos;
      CarregarLista;
      ShowMessage('POI excluído (desativado) com sucesso!');
    except
      on E: Exception do
        ShowMessage('Erro ao excluir: ' + E.Message);
    end;
  end;
end;

procedure TFrmPOIManager.btnCancelarClick(Sender: TObject);
begin
  if Assigned(FPOIAtual) then
    PreencherCampos(FPOIAtual)
  else
    LimparCampos;
  HabilitarEdicao(False);
end;

procedure TFrmPOIManager.btnGeocodingClick(Sender: TObject);
var
  LGeoService: TGeoService;
  LLat, LLon: Double;
begin
  { Geocodifica o endereço informado e preenche as coordenadas }
  if Trim(edtEndereco.Text) = '' then
  begin
    ShowMessage('Informe um endereço para geocodificar');
    Exit;
  end;

  LGeoService := TGeoService.Create;
  try
    if LGeoService.EnderecoParaCoordenadas(edtEndereco.Text, LLat, LLon) then
    begin
      edtLatitude.Text := Format('%.8f', [LLat]);
      edtLongitude.Text := Format('%.8f', [LLon]);
      ShowMessage(Format('Geocodificado: Lat=%.6f, Lon=%.6f', [LLat, LLon]));
    end
    else
      ShowMessage('Não foi possível geocodificar o endereço.');
  finally
    LGeoService.Free;
  end;
end;

procedure TFrmPOIManager.btnFecharClick(Sender: TObject);
begin
  Close;
end;

end.
