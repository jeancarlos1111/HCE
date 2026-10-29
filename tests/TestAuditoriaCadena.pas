unit TestAuditoriaCadena;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, fpcunit, testregistry,
  uConexionSQLite, uMigradorBD, uReloj, uRelojSimulado,
  uEventoAuditoria, uAuditoria, uAuditoriaSQLite, uVerificadorCadena;

type
  TTestAuditoriaCadena = class(TTestCase)
  private
    FConexion: IConexionBD;
    FReloj: TRelojSimulado;
    FAuditoria: IAuditoria;
    FVerificador: TVerificadorCadena;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCadenaIntegraConEventosConsecutivos;
    procedure TestDeteccionDeAlteracionEnRegistro;
    procedure TestDeteccionDeHuecoEnSecuencia;
    procedure TestTriggersBloqueanUpdateYDelete;
  end;

implementation

procedure TTestAuditoriaCadena.SetUp;
var
  Migrador: TMigradorBD;
begin
  FConexion := TConexionSQLite.Create(':memory:');
  FConexion.Conectar;

  // Aplicar migraciones 001 y 003
  Migrador := TMigradorBD.Create(FConexion, 'db/migrations');
  try
    Migrador.Migrar;
  finally
    Migrador.Free;
  end;

  FReloj := TRelojSimulado.Create(EncodeDateTime(2026, 10, 29, 10, 0, 0, 0));
  FAuditoria := TAuditoriaSQLite.Create(FConexion, FReloj);
  FVerificador := TVerificadorCadena.Create(FConexion);
end;

procedure TTestAuditoriaCadena.TearDown;
begin
  FVerificador.Free;
  FAuditoria := nil;
  FReloj := nil;
  if FConexion <> nil then
    FConexion.Desconectar;
  FConexion := nil;
end;

procedure TTestAuditoriaCadena.TestCadenaIntegraConEventosConsecutivos;
var
  Ev: TEventoAuditoria;
  Res: TResultadoVerificacion;
  i: Integer;
begin
  for i := 1 to 5 do
  begin
    FillChar(Ev, SizeOf(Ev), 0);
    Ev.UsuarioId := 1;
    Ev.LoginTxt := 'admin';
    Ev.Accion := 'TEST_ACCION_' + IntToStr(i);
    Ev.Resultado := raOK;
    Ev.Motivo := 'Prueba consecutiva';
    FAuditoria.RegistrarIndependiente(Ev);
    FReloj.AvanzarMinutos(1);
  end;

  Res := FVerificador.VerificarIntegridad;
  AssertEquals('Cadena debe ser integra', Ord(ecIntegra), Ord(Res.Estado));
  AssertEquals('Total eventos debe ser 5', 5, Res.TotalEventos);
  AssertEquals('Primer seq debe ser 1', 1, Res.PrimerSeq);
  AssertEquals('Ultimo seq debe ser 5', 5, Res.UltimoSeq);
end;

procedure TTestAuditoriaCadena.TestDeteccionDeAlteracionEnRegistro;
var
  Ev: TEventoAuditoria;
  Res: TResultadoVerificacion;
begin
  FillChar(Ev, SizeOf(Ev), 0);
  Ev.UsuarioId := 1;
  Ev.Accion := 'ACCION_ORIGINAL';
  Ev.Resultado := raOK;
  FAuditoria.RegistrarIndependiente(Ev);

  // Alteración forzada (simulando desactivación de trigger a bajo nivel)
  FConexion.EjecutarDirecto('DROP TRIGGER tr_aud_no_update;');
  FConexion.EjecutarDirecto('UPDATE auditoria SET accion = ''ALTERADA_POR_ATACANTE'' WHERE seq = 1;');

  Res := FVerificador.VerificarIntegridad;
  AssertEquals('Debe detectar alteracion', Ord(ecAlterada), Ord(Res.Estado));
  AssertEquals('Seq problema debe ser 1', 1, Res.SeqProblema);
end;

procedure TTestAuditoriaCadena.TestDeteccionDeHuecoEnSecuencia;
var
  Ev: TEventoAuditoria;
  Res: TResultadoVerificacion;
begin
  FillChar(Ev, SizeOf(Ev), 0);
  Ev.Accion := 'EV1'; Ev.Resultado := raOK;
  FAuditoria.RegistrarIndependiente(Ev);

  Ev.Accion := 'EV2';
  FAuditoria.RegistrarIndependiente(Ev);

  // Borrado de fila 1 con triggers desactivados
  FConexion.EjecutarDirecto('DROP TRIGGER tr_aud_no_delete;');
  FConexion.EjecutarDirecto('DELETE FROM auditoria WHERE seq = 1;');

  Res := FVerificador.VerificarIntegridad;
  AssertEquals('Debe detectar hueco', Ord(ecHuecoSecuencia), Ord(Res.Estado));
  AssertEquals('Seq faltante debe ser 1', 1, Res.SeqProblema);
end;

procedure TTestAuditoriaCadena.TestTriggersBloqueanUpdateYDelete;
var
  Ev: TEventoAuditoria;
  FalloUpdate, FalloDelete: Boolean;
begin
  FillChar(Ev, SizeOf(Ev), 0);
  Ev.Accion := 'INMUTABLE'; Ev.Resultado := raOK;
  FAuditoria.RegistrarIndependiente(Ev);

  FalloUpdate := False;
  try
    FConexion.EjecutarDirecto('UPDATE auditoria SET motivo = ''cambio'' WHERE seq = 1;');
  except
    FalloUpdate := True;
  end;
  AssertTrue('Trigger debe rechazar UPDATE en auditoria', FalloUpdate);

  FalloDelete := False;
  try
    FConexion.EjecutarDirecto('DELETE FROM auditoria WHERE seq = 1;');
  except
    FalloDelete := True;
  end;
  AssertTrue('Trigger debe rechazar DELETE en auditoria', FalloDelete);
end;

initialization
  RegisterTest(TTestAuditoriaCadena);

end.
