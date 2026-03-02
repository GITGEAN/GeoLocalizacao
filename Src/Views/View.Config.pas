{ View.Config - Tela de configurações do sistema.
  Lê do GeoManager.ini ao abrir e persiste ao salvar. }
unit View.Config;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls;

type
  TFrmConfig = class(TForm)
    PageControl1: TPageControl;
    tabBanco: TTabSheet;
    tabArcGIS: TTabSheet;
    tabMapa: TTabSheet;
    tabLog: TTabSheet;
    pnlBotoes: TPanel;
    btnSalvar: TButton;
    btnCancelar: TButton;
    btnTestar: TButton;

    { Banco de Dados }
    lblTipoBD: TLabel;
    cmbTipoBD: TComboBox;
    lblServidor: TLabel;
    edtServidor: TEdit;
    lblPorta: TLabel;
    edtPorta: TEdit;
    lblBanco: TLabel;
    edtBanco: TEdit;
    lblUsuarioDB: TLabel;
    edtUsuarioDB: TEdit;
    lblSenhaDB: TLabel;
    edtSenhaDB: TEdit;
    chkAuthWindows: TCheckBox;

    { ArcGIS }
    lblArcGISURL: TLabel;
    edtArcGISURL: TEdit;
    lblApiKey: TLabel;
    edtApiKey: TEdit;
    lblArcGISInfo: TLabel;

    { Mapa }
    lblCentroLat: TLabel;
    edtCentroLat: TEdit;
    lblCentroLon: TLabel;
    edtCentroLon: TEdit;
    lblZoom: TLabel;
    edtZoom: TEdit;

    { Log }
    lblNivelLog: TLabel;
    cmbNivelLog: TComboBox;
    chkLogArquivo: TCheckBox;

    procedure FormCreate(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnTestarClick(Sender: TObject);
  private
    procedure CarregarConfiguracoes;
    procedure SalvarConfiguracoes;
  end;

var
  FrmConfig: TFrmConfig;

implementation

{$R *.dfm}

uses
  Utils.Config, Utils.Logger, DAO.Connection;

procedure TFrmConfig.FormCreate(Sender: TObject);
begin
  cmbTipoBD.Items.Clear;
  cmbTipoBD.Items.Add('SQLITE');
  cmbTipoBD.Items.Add('SQLSERVER');
  cmbTipoBD.Items.Add('ORACLE');

  cmbNivelLog.Items.Clear;
  cmbNivelLog.Items.Add('DEBUG');
  cmbNivelLog.Items.Add('INFO');
  cmbNivelLog.Items.Add('WARNING');
  cmbNivelLog.Items.Add('ERROR');

  CarregarConfiguracoes;
end;

procedure TFrmConfig.CarregarConfiguracoes;
var
  LConfig: TConfigManager;
begin
  LConfig := TConfigManager.GetInstance;

  cmbTipoBD.ItemIndex := cmbTipoBD.Items.IndexOf(LConfig.GetTipoDB);
  edtServidor.Text := LConfig.GetServidorDB;
  edtPorta.Text := IntToStr(LConfig.GetPortaDB);
  edtBanco.Text := LConfig.GetNomeDB;
  edtUsuarioDB.Text := LConfig.GetUsuarioDB;
  edtSenhaDB.Text := LConfig.GetSenhaDB;

  edtArcGISURL.Text := LConfig.GetArcGISBaseURL;
  edtApiKey.Text := LConfig.GetArcGISApiKey;

  edtCentroLat.Text := FloatToStr(LConfig.GetMapaCentroLatitude);
  edtCentroLon.Text := FloatToStr(LConfig.GetMapaCentroLongitude);
  edtZoom.Text := IntToStr(LConfig.GetMapaZoomPadrao);

  cmbNivelLog.ItemIndex := cmbNivelLog.Items.IndexOf(
    LConfig.ReadString('LOG', 'Nivel', 'INFO'));
  chkLogArquivo.Checked := LConfig.ReadBool('LOG', 'Arquivo', True);
end;

procedure TFrmConfig.SalvarConfiguracoes;
var
  LConfig: TConfigManager;
begin
  LConfig := TConfigManager.GetInstance;

  LConfig.WriteString('DATABASE', 'Tipo', cmbTipoBD.Text);
  LConfig.WriteString('DATABASE', 'Servidor', edtServidor.Text);
  LConfig.WriteInteger('DATABASE', 'Porta', StrToIntDef(edtPorta.Text, 1433));
  LConfig.WriteString('DATABASE', 'Banco', edtBanco.Text);
  LConfig.WriteString('DATABASE', 'Usuario', edtUsuarioDB.Text);
  LConfig.WriteString('DATABASE', 'Senha', edtSenhaDB.Text);

  LConfig.WriteString('ARCGIS', 'BaseURL', edtArcGISURL.Text);
  LConfig.WriteString('ARCGIS', 'ApiKey', edtApiKey.Text);

  LConfig.WriteString('MAPA', 'CentroLatitude', edtCentroLat.Text);
  LConfig.WriteString('MAPA', 'CentroLongitude', edtCentroLon.Text);
  LConfig.WriteInteger('MAPA', 'ZoomPadrao', StrToIntDef(edtZoom.Text, 5));

  LConfig.WriteString('LOG', 'Nivel', cmbNivelLog.Text);
  LConfig.WriteBool('LOG', 'Arquivo', chkLogArquivo.Checked);
end;

procedure TFrmConfig.btnSalvarClick(Sender: TObject);
begin
  SalvarConfiguracoes;
  ShowMessage('Configurações salvas com sucesso!');
  ModalResult := mrOk;
end;

procedure TFrmConfig.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFrmConfig.btnTestarClick(Sender: TObject);
var
  LConn: TConnectionManager;
begin
  LConn := TConnectionManager.GetInstance;

  { Define o tipo de banco conforme selecionado }
  case cmbTipoBD.ItemIndex of
    0: LConn.TipoBanco := tbSQLite;
    1: LConn.TipoBanco := tbSQLServer;
    2: LConn.TipoBanco := tbOracle;
  else
    LConn.TipoBanco := tbSQLite;
  end;

  LConn.Servidor := edtServidor.Text;
  LConn.Porta := StrToIntDef(edtPorta.Text, 1433);
  LConn.Banco := edtBanco.Text;
  LConn.UsuarioDB := edtUsuarioDB.Text;
  LConn.SenhaDB := edtSenhaDB.Text;

  if LConn.TestarConexao then
    ShowMessage('Conexão bem-sucedida!')
  else
    ShowMessage('Falha ao conectar. Verifique os parâmetros.');
end;

end.
