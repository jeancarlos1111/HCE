unit ufrmLogin;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uAutenticacionService, uSesion;

type
  { TfrmLogin }
  TfrmLogin = class(TForm)
    pnlCabecera: TPanel;
    lblLogoIcono: TLabel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    pnlCuerpo: TPanel;
    lblUsuario: TLabel;
    edtUsuario: TEdit;
    lblClave: TLabel;
    edtClave: TEdit;
    pnlError: TPanel;
    lblError: TLabel;
    btnIngresar: TButton;
    btnCancelar: TButton;
    lblPie: TLabel;
    procedure btnIngresarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure edtUsuarioKeyPress(Sender: TObject; var Key: char);
    procedure edtClaveKeyPress(Sender: TObject; var Key: char);
    procedure edtCambioTexto(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FAuthService: TAutenticacionService;
    FSesionIniciada: TSesion;
    procedure MostrarError(const AMensaje: string);
    procedure OcultarError;
  public
    property AuthService: TAutenticacionService read FAuthService write FAuthService;
    property SesionIniciada: TSesion read FSesionIniciada;
  end;

var
  frmLogin: TfrmLogin;

implementation

{$R *.lfm}

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  FSesionIniciada := nil;
  OcultarError;
end;

procedure TfrmLogin.FormShow(Sender: TObject);
begin
  OcultarError;
  if edtUsuario.CanFocus then
    edtUsuario.SetFocus;
end;

procedure TfrmLogin.MostrarError(const AMensaje: string);
begin
  lblError.Caption := AMensaje;
  pnlError.Visible := True;
end;

procedure TfrmLogin.OcultarError;
begin
  lblError.Caption := '';
  pnlError.Visible := False;
end;

procedure TfrmLogin.edtCambioTexto(Sender: TObject);
begin
  if pnlError.Visible then
    OcultarError;
end;

procedure TfrmLogin.edtUsuarioKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    Key := #0;
    edtClave.SetFocus;
  end;
end;

procedure TfrmLogin.edtClaveKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    Key := #0;
    btnIngresarClick(Sender);
  end;
end;

procedure TfrmLogin.btnIngresarClick(Sender: TObject);
var
  NomEquipo, Ip: string;
begin
  OcultarError;

  if Trim(edtUsuario.Text) = '' then
  begin
    MostrarError('Por favor ingrese el nombre de usuario o cedula.');
    edtUsuario.SetFocus;
    Exit;
  end;

  if edtClave.Text = '' then
  begin
    MostrarError('Por favor ingrese su contrasena.');
    edtClave.SetFocus;
    Exit;
  end;

  if FAuthService = nil then
  begin
    MostrarError('Error de configuracion: servicio de autenticacion no disponible.');
    Exit;
  end;

  NomEquipo := GetEnvironmentVariable('HOSTNAME');
  if NomEquipo = '' then NomEquipo := 'LOCAL-PC';
  Ip := '127.0.0.1';

  try
    FSesionIniciada := FAuthService.Login(Trim(edtUsuario.Text), edtClave.Text, NomEquipo, Ip);
    ModalResult := mrOk;
  except
    on E: ECredencialesInvalidas do
    begin
      MostrarError(E.Message);
      edtClave.Clear;
      edtClave.SetFocus;
    end;
    on E: ECuentaBloqueada do
    begin
      MostrarError(E.Message);
      edtClave.Clear;
    end;
    on E: Exception do
    begin
      MostrarError('Error de acceso: ' + E.Message);
      edtClave.Clear;
    end;
  end;
end;

procedure TfrmLogin.btnCancelarClick(Sender: TObject);
begin
  FSesionIniciada := nil;
  ModalResult := mrCancel;
end;

end.
