program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, SysUtils, Unit1, ufrmLogin, ufrmUsuarios,
  uConexionSQLite, uMigradorBD, uPasswordHasher, uUsuario, uUsuarioRepository,
  uReloj;

{$R *.res}

procedure InicializarBaseDeDatos;
var
  RutaBD, RutaMigraciones: string;
  Conexion: IConexionBD;
  Migrador: TMigradorBD;
  Repo: IUsuarioRepository;
  Hasher: IPasswordHasher;
  Reloj: IReloj;
  Admin: TUsuario;
begin
  RutaBD := ExtractFilePath(Application.ExeName) + 'hce.db';
  RutaMigraciones := ExtractFilePath(Application.ExeName) + 'db/migrations';
  if not DirectoryExists(RutaMigraciones) then
    RutaMigraciones := ExtractFilePath(Application.ExeName) + '../db/migrations';

  Conexion := TConexionSQLite.Create(RutaBD);
  try
    Conexion.Conectar;
    if DirectoryExists(RutaMigraciones) then
    begin
      Migrador := TMigradorBD.Create(Conexion, RutaMigraciones);
      try
        Migrador.Migrar;
      finally
        Migrador.Free;
      end;
    end;

    // Crear admin inicial si no existe ninguno
    Repo := TUsuarioRepositorySQLite.Create(Conexion);
    if Repo.ObtenerPorLogin('admin') = nil then
    begin
      Hasher := TPBKDF2PasswordHasher.Create(100000);
      Reloj := TRelojSistema.Create;
      Admin := TUsuario.Create;
      try
        Admin.Login := 'admin';
        Admin.Cedula := 'V-00000001';
        Admin.Nombres := 'Administrador';
        Admin.Apellidos := 'del Sistema';
        Admin.Email := 'admin@hce.local';
        Admin.ClaveHash := Hasher.HashClave('Admin2026!');
        Admin.ClaveTemporal := True;
        Admin.CreadoUtc := Reloj.AhoraUtcIso;
        Admin.Roles.Add('ADMIN');
        Repo.Crear(Admin);
      finally
        Admin.Free;
      end;
    end;
  finally
    Conexion.Desconectar;
    Conexion := nil;
  end;
end;

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize;

  // 1. Asegurar migraciones y usuario admin inicial
  InicializarBaseDeDatos;

  // 2. Crear Form principal oculto inicialmente
  Application.ShowMainForm := False;
  Application.CreateForm(TForm1, Form1);

  // 3. Solicitar login antes de mostrar Form principal
  if not Form1.EjecutarLogin then
  begin
    Application.Terminate;
    Exit;
  end;

  // 4. Si credenciales validas, aplicar permisos y mostrar Form principal
  Form1.AplicarPermisosUI;
  Form1.Show;
  Application.Run;
end.
