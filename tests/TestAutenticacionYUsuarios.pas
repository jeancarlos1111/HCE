unit TestAutenticacionYUsuarios;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, fpcunit, testregistry,
  uConexionSQLite, uMigradorBD, uReloj, uRelojSimulado,
  uPasswordHasher, uUsuario, uUsuarioRepository,
  uAuditoria, uAuditoriaSQLite, uAutenticacionService, uUsuarioService,
  uAutorizacion, uPermisos, uSesion;

type
  TTestAutenticacionYUsuarios = class(TTestCase)
  private
    FConexion: IConexionBD;
    FReloj: TRelojSimulado;
    FHasher: IPasswordHasher;
    FAuditoria: IAuditoria;
    FRepo: IUsuarioRepository;
    FAuthSvc: TAutenticacionService;
    FUserSvc: TUsuarioService;
    procedure CrearUsuarioAdminDirecto;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestLoginExitosoCargaRolesYPermisos;
    procedure TestLoginFallidoCincoVecesBloqueaCuenta;
    procedure TestSeparacionDeFuncionesAdminYAuditorIncompatibles;
    procedure TestMedicoSinMppsEsRechazado;
    procedure TestAdminNoTienePermisoClinico;
    procedure TestCambioClaveYPinExitoso;
  end;

implementation

procedure TTestAutenticacionYUsuarios.CrearUsuarioAdminDirecto;
var
  Admin: TUsuario;
begin
  Admin := TUsuario.Create;
  try
    Admin.Login := 'admin';
    Admin.Cedula := 'V-10000001';
    Admin.Nombres := 'Administrador';
    Admin.Apellidos := 'Inicial';
    Admin.ClaveHash := FHasher.HashClave('AdminSeguro2026!');
    Admin.ClaveTemporal := False;
    Admin.CreadoUtc := FReloj.AhoraUtcIso;
    Admin.Roles.Add(ROL_ADMIN);
    FRepo.Crear(Admin);
  finally
    Admin.Free;
  end;
end;

procedure TTestAutenticacionYUsuarios.SetUp;
var
  Migrador: TMigradorBD;
begin
  FConexion := TConexionSQLite.Create(':memory:');
  FConexion.Conectar;

  Migrador := TMigradorBD.Create(FConexion, 'db/migrations');
  try
    Migrador.Migrar;
  finally
    Migrador.Free;
  end;

  FReloj := TRelojSimulado.Create(EncodeDateTime(2026, 10, 29, 8, 0, 0, 0));
  FHasher := TPBKDF2PasswordHasher.Create(1000); // Rápido para tests
  FAuditoria := TAuditoriaSQLite.Create(FConexion, FReloj);
  FRepo := TUsuarioRepositorySQLite.Create(FConexion);

  FAuthSvc := TAutenticacionService.Create(FRepo, FHasher, FAuditoria, FReloj);
  FUserSvc := TUsuarioService.Create(FRepo, nil, FAuditoria, FReloj, FHasher);

  CrearUsuarioAdminDirecto;
end;

procedure TTestAutenticacionYUsuarios.TearDown;
begin
  FUserSvc.Free;
  FAuthSvc.Free;
  FRepo := nil;
  FAuditoria := nil;
  FHasher := nil;
  FReloj := nil;
  if FConexion <> nil then
    FConexion.Desconectar;
  FConexion := nil;
end;

procedure TTestAutenticacionYUsuarios.TestLoginExitosoCargaRolesYPermisos;
var
  Sesion: TSesion;
begin
  Sesion := FAuthSvc.Login('admin', 'AdminSeguro2026!', 'CONSULTORIO-1', '127.0.0.1');
  try
    AssertNotNull('Sesion debe existir', Sesion);
    AssertEquals('admin', Sesion.Login);
    AssertTrue('Debe tener rol ADMIN', Sesion.TieneRol(ROL_ADMIN));
    AssertTrue('Debe tener permiso USUARIO.GESTIONAR', Sesion.TienePermiso(PERM_USUARIO_GESTIONAR));
    AssertFalse('No debe tener permiso HC.LEER', Sesion.TienePermiso(PERM_HC_LEER));
  finally
    Sesion.Free;
  end;
end;

procedure TTestAutenticacionYUsuarios.TestLoginFallidoCincoVecesBloqueaCuenta;
var
  i: Integer;
  FalloCredenciales: Boolean;
  CuentaBloqueada: Boolean;
begin
  for i := 1 to 4 do
  begin
    FalloCredenciales := False;
    try
      FAuthSvc.Login('admin', 'ClaveErronea!', 'PC1', '127.0.0.1');
    except
      on E: ECredencialesInvalidas do
        FalloCredenciales := True;
    end;
    AssertTrue('Debe fallar intento ' + IntToStr(i), FalloCredenciales);
  end;

  // Intento 5: Bloquea
  try
    FAuthSvc.Login('admin', 'ClaveErronea!', 'PC1', '127.0.0.1');
  except
    on E: ECredencialesInvalidas do ;
  end;

  // Intento 6 con clave correcta: debe rechazar por cuenta bloqueada
  CuentaBloqueada := False;
  try
    FAuthSvc.Login('admin', 'AdminSeguro2026!', 'PC1', '127.0.0.1');
  except
    on E: ECuentaBloqueada do
      CuentaBloqueada := True;
  end;
  AssertTrue('Debe rechazar con ECuentaBloqueada', CuentaBloqueada);
end;

procedure TTestAutenticacionYUsuarios.TestSeparacionDeFuncionesAdminYAuditorIncompatibles;
var
  Usuario: TUsuario;
  LanzoConflicto: Boolean;
begin
  Usuario := TUsuario.Create;
  try
    Usuario.Login := 'superusuario';
    Usuario.Cedula := 'V-11111111';
    Usuario.Nombres := 'Super';
    Usuario.Apellidos := 'Incompatible';
    Usuario.Roles.Add(ROL_ADMIN);
    Usuario.Roles.Add(ROL_AUDITOR);

    LanzoConflicto := False;
    try
      FUserSvc.CrearUsuario(Usuario, 'ClaveFuerte123!');
    except
      on E: EUsuarioInvalido do
        LanzoConflicto := True;
    end;
    AssertTrue('Debe rechazar la combinacion ADMIN + AUDITOR', LanzoConflicto);
  finally
    Usuario.Free;
  end;
end;

procedure TTestAutenticacionYUsuarios.TestMedicoSinMppsEsRechazado;
var
  Doc: TUsuario;
  Rechazado: Boolean;
begin
  Doc := TUsuario.Create;
  try
    Doc.Login := 'drmartinez';
    Doc.Cedula := 'V-12345678';
    Doc.Nombres := 'Carlos';
    Doc.Apellidos := 'Martinez';
    Doc.Roles.Add(ROL_MEDICO);
    Doc.EsProfesional := False; // Sin MPPS

    Rechazado := False;
    try
      FUserSvc.CrearUsuario(Doc, 'ClaveDoctor123!');
    except
      on E: EUsuarioInvalido do
        Rechazado := True;
    end;
    AssertTrue('Medico sin MPPS debe ser rechazado', Rechazado);
  finally
    Doc.Free;
  end;
end;

procedure TTestAutenticacionYUsuarios.TestAdminNoTienePermisoClinico;
var
  Sesion: TSesion;
  Autorizacion: IAutorizacion;
  Denegado: Boolean;
begin
  Sesion := FAuthSvc.Login('admin', 'AdminSeguro2026!', 'PC1', '127.0.0.1');
  try
    Autorizacion := TAutorizacion.Create(Sesion);
    Denegado := False;
    try
      Autorizacion.Exigir(PERM_HC_LEER);
    except
      on E: EAccesoDenegado do
        Denegado := True;
    end;
    AssertTrue('ADMIN no puede tener acceso a HC.LEER (Constitucion Art. 2)', Denegado);
  finally
    Sesion.Free;
  end;
end;

procedure TTestAutenticacionYUsuarios.TestCambioClaveYPinExitoso;
var
  Sesion: TSesion;
begin
  // admin cambia clave y define PIN de 6 digitos
  FAuthSvc.CambiarClaveYPin(1, 'AdminSeguro2026!', 'NuevaClaveValida99!', '123456');

  // Ahora loguea con la nueva
  Sesion := FAuthSvc.Login('admin', 'NuevaClaveValida99!', 'PC1', '127.0.0.1');
  try
    AssertNotNull('Login con nueva clave exitoso', Sesion);
    AssertFalse('Ya no debe marcar clave temporal', Sesion.DebeCambiarClave);
  finally
    Sesion.Free;
  end;
end;

initialization
  RegisterTest(TTestAutenticacionYUsuarios);

end.
