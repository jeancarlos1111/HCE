unit TestConexionSQLite;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uConexionSQLite;

type
  TTestConexionSQLite = class(TTestCase)
  private
    FConexion: IConexionBD;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestConexionMemoriaYPragmas;
    procedure TestTransaccionRollbackYCommit;
    procedure TestForeignKeysActivo;
  end;

implementation

procedure TTestConexionSQLite.SetUp;
begin
  FConexion := TConexionSQLite.Create(':memory:');
  FConexion.Conectar;
end;

procedure TTestConexionSQLite.TearDown;
begin
  if FConexion <> nil then
    FConexion.Desconectar;
  FConexion := nil;
end;

procedure TTestConexionSQLite.TestConexionMemoriaYPragmas;
var
  ValFk: Int64;
begin
  ValFk := FConexion.EjecutarConsultaEscalarEntero('PRAGMA foreign_keys;');
  AssertEquals('foreign_keys debe estar activado', 1, ValFk);
end;

procedure TTestConexionSQLite.TestTransaccionRollbackYCommit;
var
  Total: Int64;
begin
  FConexion.EjecutarDirecto('CREATE TABLE t_prueba (id INTEGER PRIMARY KEY, valor TEXT) STRICT;');

  // Prueba rollback
  FConexion.IniciarTransaccion;
  FConexion.EjecutarDirecto('INSERT INTO t_prueba (id, valor) VALUES (1, ''temporal'');');
  FConexion.Cancelar;

  Total := FConexion.EjecutarConsultaEscalarEntero('SELECT COUNT(*) FROM t_prueba;');
  AssertEquals('Debe haber 0 registros tras ROLLBACK', 0, Total);

  // Prueba commit
  FConexion.IniciarTransaccion;
  FConexion.EjecutarDirecto('INSERT INTO t_prueba (id, valor) VALUES (1, ''persistido'');');
  FConexion.Confirmar;

  Total := FConexion.EjecutarConsultaEscalarEntero('SELECT COUNT(*) FROM t_prueba;');
  AssertEquals('Debe haber 1 registro tras COMMIT', 1, Total);
end;

procedure TTestConexionSQLite.TestForeignKeysActivo;
var
  LanzoExcepcion: Boolean;
begin
  FConexion.EjecutarDirecto('CREATE TABLE padre (id INTEGER PRIMARY KEY) STRICT;');
  FConexion.EjecutarDirecto('CREATE TABLE hijo (id INTEGER PRIMARY KEY, padre_id INTEGER REFERENCES padre(id)) STRICT;');

  LanzoExcepcion := False;
  try
    FConexion.EjecutarDirecto('INSERT INTO hijo (id, padre_id) VALUES (1, 999);');
  except
    LanzoExcepcion := True;
  end;

  AssertTrue('Debe fallar violación de FK', LanzoExcepcion);
end;

initialization
  RegisterTest(TTestConexionSQLite);

end.
