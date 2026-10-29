program hce_tests;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, consoletestrunner,
  uReloj, uConexionSQLite, uMigradorBD,
  uRelojSimulado, uSha256, uPasswordHasher, uPoliticaClave,
  uPermisos, uSesion, uAutorizacion, uEventoAuditoria, uCanonico,
  uAuditoria, uAuditoriaSQLite, uVerificadorCadena,
  uUsuario, uUsuarioRepository, uAutenticacionService, uUsuarioService,
  TestReloj, TestConexionSQLite, TestMigradorBD,
  TestPoliticaClave, TestAuditoriaCadena, TestAutenticacionYUsuarios;

type
  THCETestRunner = class(TTestRunner)
  protected
  end;

var
  Application: THCETestRunner;

begin
  DefaultFormat := fPlain;
  Application := THCETestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'HCE Tests FPCUnit';
  Application.Run;
  Application.Free;
end.
