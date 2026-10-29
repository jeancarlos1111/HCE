unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  ExtCtrls, StdCtrls,
  uConexionSQLite, uReloj, uPasswordHasher, uUsuarioRepository,
  uAuditoria, uAuditoriaSQLite, uAutenticacionService, uUsuarioService,
  uSesion, uPermisos, ufrmLogin, ufrmUsuarios;

type
  { TForm1 }
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    mnuSistema: TMenuItem;
    mnuUsuarios: TMenuItem;
    mnuSeparador1: TMenuItem;
    mnuCerrarSesion: TMenuItem;
    mnuSalir: TMenuItem;
    mnuPacientes: TMenuItem;
    mnuBuscarPaciente: TMenuItem;
    mnuHistoriaClinica: TMenuItem;
    mnuConsultaSoap: TMenuItem;
    mnuEstadisticas: TMenuItem;
    mnuReportes: TMenuItem;
    mnuAyuda: TMenuItem;
    mnuAcercaDe: TMenuItem;
    StatusBar1: TStatusBar;
    pnlCabecera: TPanel;
    lblLogoIcono: TLabel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    btnCerrarSesionTop: TButton;
    pnlFondo: TPanel;
    pnlCardUsuario: TPanel;
    lblEtiquetaSesion: TLabel;
    lblNombreUsuario: TLabel;
    lblLoginYCedula: TLabel;
    lblRolesUsuario: TLabel;
    lblSeguridadInfo: TLabel;
    pnlCardAcciones: TPanel;
    lblEtiquetaModulos: TLabel;
    btnAccesoPacientes: TButton;
    btnAccesoHistoria: TButton;
    btnAccesoEstadisticas: TButton;
    btnAccesoUsuarios: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure mnuUsuariosClick(Sender: TObject);
    procedure mnuCerrarSesionClick(Sender: TObject);
    procedure mnuSalirClick(Sender: TObject);
    procedure mnuAcercaDeClick(Sender: TObject);
    procedure mnuBuscarPacienteClick(Sender: TObject);
    procedure mnuConsultaSoapClick(Sender: TObject);
    procedure mnuReportesClick(Sender: TObject);
  private
    FConexion: IConexionBD;
    FReloj: IReloj;
    FHasher: IPasswordHasher;
    FAuditoria: IAuditoria;
    FUsuarioRepo: IUsuarioRepository;
    FAuthService: TAutenticacionService;
    FUsuarioService: TUsuarioService;
    FSesionActual: TSesion;

    procedure InicializarServicios;
    procedure ActualizarBarraEstado;
  public
    function EjecutarLogin: Boolean;
    procedure AplicarPermisosUI;
    destructor Destroy; override;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption := 'Sistema de Historia Clinica Electronica (HCE)';
  FSesionActual := nil;
  InicializarServicios;
end;

destructor TForm1.Destroy;
begin
  FreeAndNil(FSesionActual);
  FreeAndNil(FUsuarioService);
  FreeAndNil(FAuthService);
  FUsuarioRepo := nil;
  FAuditoria := nil;
  FHasher := nil;
  FReloj := nil;
  if FConexion <> nil then
    FConexion.Desconectar;
  FConexion := nil;
  inherited Destroy;
end;

procedure TForm1.InicializarServicios;
var
  RutaBD: string;
begin
  RutaBD := ExtractFilePath(Application.ExeName) + 'hce.db';
  if not FileExists(RutaBD) and FileExists('hce.db') then
    RutaBD := 'hce.db';

  FConexion := TConexionSQLite.Create(RutaBD);
  FConexion.Conectar;

  FReloj := TRelojSistema.Create;
  FHasher := TPBKDF2PasswordHasher.Create(100000);
  FAuditoria := TAuditoriaSQLite.Create(FConexion, FReloj);
  FUsuarioRepo := TUsuarioRepositorySQLite.Create(FConexion);

  FAuthService := TAutenticacionService.Create(FUsuarioRepo, FHasher, FAuditoria, FReloj);
  FUsuarioService := TUsuarioService.Create(FUsuarioRepo, nil, FAuditoria, FReloj, FHasher);
end;

function TForm1.EjecutarLogin: Boolean;
var
  Frm: TfrmLogin;
begin
  Result := False;
  Frm := TfrmLogin.Create(nil);
  try
    Frm.AuthService := FAuthService;
    if Frm.ShowModal = mrOk then
    begin
      FreeAndNil(FSesionActual);
      FSesionActual := Frm.SesionIniciada;
      Result := (FSesionActual <> nil);
    end;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.AplicarPermisosUI;
begin
  if FSesionActual = nil then
  begin
    mnuUsuarios.Enabled := False;
    mnuPacientes.Enabled := False;
    mnuHistoriaClinica.Enabled := False;
    mnuEstadisticas.Enabled := False;
    btnAccesoUsuarios.Enabled := False;
    btnAccesoPacientes.Enabled := False;
    btnAccesoHistoria.Enabled := False;
    btnAccesoEstadisticas.Enabled := False;
    lblNombreUsuario.Caption := 'Sesion cerrada';
    lblLoginYCedula.Caption := '';
    lblRolesUsuario.Caption := '';
    Exit;
  end;

  // Permisos según el rol de la sesión
  mnuUsuarios.Enabled := FSesionActual.TienePermiso(PERM_USUARIO_GESTIONAR);
  mnuPacientes.Enabled := FSesionActual.TienePermiso(PERM_PACIENTE_LEER);
  mnuHistoriaClinica.Enabled := FSesionActual.TienePermiso(PERM_HC_LEER);
  mnuEstadisticas.Enabled := FSesionActual.TienePermiso(PERM_ESTADISTICA_VER);

  btnAccesoUsuarios.Enabled := mnuUsuarios.Enabled;
  btnAccesoPacientes.Enabled := mnuPacientes.Enabled;
  btnAccesoHistoria.Enabled := mnuHistoriaClinica.Enabled;
  btnAccesoEstadisticas.Enabled := mnuEstadisticas.Enabled;

  lblNombreUsuario.Caption := FSesionActual.NombreCompleto;
  lblLoginYCedula.Caption := Format('Usuario: %s  |  C.I.: %s',
    [FSesionActual.Login, FSesionActual.Cedula]);
  lblRolesUsuario.Caption := 'Roles asignados: ' + FSesionActual.Roles.CommaText;

  ActualizarBarraEstado;
end;

procedure TForm1.ActualizarBarraEstado;
begin
  if FSesionActual <> nil then
  begin
    StatusBar1.Panels[0].Text := 'Usuario: ' + FSesionActual.Login;
    StatusBar1.Panels[1].Text := 'Equipo: ' + FSesionActual.Equipo;
    StatusBar1.Panels[2].Text := 'BD: SQLite (WAL)';
  end
  else
  begin
    StatusBar1.Panels[0].Text := 'No autenticado';
    StatusBar1.Panels[1].Text := '';
    StatusBar1.Panels[2].Text := '';
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  if FSesionActual = nil then
  begin
    if not EjecutarLogin then
    begin
      Application.Terminate;
      Exit;
    end;
    AplicarPermisosUI;
  end;
end;

procedure TForm1.mnuUsuariosClick(Sender: TObject);
var
  Frm: TfrmUsuarios;
begin
  if (FSesionActual = nil) or not FSesionActual.TienePermiso(PERM_USUARIO_GESTIONAR) then
  begin
    ShowMessage('No tiene permiso para acceder a este modulo');
    Exit;
  end;

  Frm := TfrmUsuarios.Create(nil);
  try
    Frm.UsuarioService := FUsuarioService;
    Frm.UsuarioRepo := FUsuarioRepo;
    Frm.SesionActual := FSesionActual;
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.mnuBuscarPacienteClick(Sender: TObject);
begin
  ShowMessage('Modulo de Pacientes (MPI): Proximo paso en Sprint 2.');
end;

procedure TForm1.mnuConsultaSoapClick(Sender: TObject);
begin
  ShowMessage('Modulo de Historia Clinica (SOAP): Proximo paso en Sprint 3.');
end;

procedure TForm1.mnuReportesClick(Sender: TObject);
begin
  ShowMessage('Modulo de Estadisticas y Morbilidad (CIE-10): Proximo paso en Sprint 4.');
end;

procedure TForm1.mnuCerrarSesionClick(Sender: TObject);
begin
  Hide; // Oculta ventana principal; solo queda visible el login
  FreeAndNil(FSesionActual);
  AplicarPermisosUI;
  if not EjecutarLogin then
  begin
    Application.Terminate;
    Exit;
  end;
  AplicarPermisosUI;
  Show; // Vuelve a mostrar ventana principal con nueva sesion
end;

procedure TForm1.mnuSalirClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.mnuAcercaDeClick(Sender: TObject);
begin
  ShowMessage('Sistema de Historias Clinicas Electronicas (HCE)' + sLineBreak +
              'Desarrollado en Lazarus / Free Pascal' + sLineBreak +
              'Base de Datos: SQLite (Nativo con SQLdb)' + sLineBreak +
              'Cumplimiento: Ley del Ejercicio de la Medicina, Deontologia y LOPNNA');
end;

end.
