unit TestMigradorBD;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uConexionSQLite, uMigradorBD;

type
  TTestMigradorBD = class(TTestCase)
  private
    FConexion: IConexionBD;
    FCarpetaTemporal: string;
    procedure CrearScriptMigracion(const ANombreArchivo, AContenido: string);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAplicaMigracionesEnOrdenYActualizaUserVersion;
    procedure TestIdempotenciaNoReaplicaMigracionesYaEjecutadas;
  end;

implementation

procedure TTestMigradorBD.CrearScriptMigracion(const ANombreArchivo, AContenido: string);
var
  Lista: TStringList;
begin
  Lista := TStringList.Create;
  try
    Lista.Text := AContenido;
    Lista.SaveToFile(FCarpetaTemporal + DirectorySeparator + ANombreArchivo);
  finally
    Lista.Free;
  end;
end;

procedure TTestMigradorBD.SetUp;
begin
  FConexion := TConexionSQLite.Create(':memory:');
  FConexion.Conectar;

  FCarpetaTemporal := GetTempDir + 'hce_migr_test_' + IntToStr(DateTimeToTimeStamp(Now).Time);
  CreateDir(FCarpetaTemporal);
end;

procedure TTestMigradorBD.TearDown;
var
  Info: TSearchRec;
begin
  if DirectoryExists(FCarpetaTemporal) then
  begin
    if FindFirst(FCarpetaTemporal + DirectorySeparator + '*', faAnyFile, Info) = 0 then
    begin
      repeat
        if (Info.Name <> '.') and (Info.Name <> '..') then
          DeleteFile(FCarpetaTemporal + DirectorySeparator + Info.Name);
      until FindNext(Info) <> 0;
      FindClose(Info);
    end;
    RemoveDir(FCarpetaTemporal);
  end;

  if FConexion <> nil then
    FConexion.Desconectar;
  FConexion := nil;
end;

procedure TTestMigradorBD.TestAplicaMigracionesEnOrdenYActualizaUserVersion;
var
  Migrador: TMigradorBD;
  Aplicadas: Integer;
  Version: Integer;
  ValorSeq: Int64;
begin
  CrearScriptMigracion('001_crear_tabla.sql',
    'CREATE TABLE t_migracion (id INTEGER PRIMARY KEY, etiqueta TEXT) STRICT;' + sLineBreak +
    'INSERT INTO t_migracion (id, etiqueta) VALUES (1, ''ok'');');

  CrearScriptMigracion('002_agregar_columna.sql',
    'ALTER TABLE t_migracion ADD COLUMN observacion TEXT;');

  Migrador := TMigradorBD.Create(FConexion, FCarpetaTemporal);
  try
    AssertEquals('Version inicial debe ser 0', 0, Migrador.ObtenerVersion);

    Aplicadas := Migrador.Migrar;
    AssertEquals('Debe haber aplicado 2 migraciones', 2, Aplicadas);
    AssertEquals('user_version debe ser 2', 2, Migrador.ObtenerVersion);

    ValorSeq := FConexion.EjecutarConsultaEscalarEntero('SELECT COUNT(*) FROM t_migracion;');
    AssertEquals('Debe existir 1 fila insertada por la migracion 001', 1, ValorSeq);
  finally
    Migrador.Free;
  end;
end;

procedure TTestMigradorBD.TestIdempotenciaNoReaplicaMigracionesYaEjecutadas;
var
  Migrador: TMigradorBD;
  Aplicadas: Integer;
begin
  CrearScriptMigracion('001_base.sql', 'CREATE TABLE t_base (id INT PRIMARY KEY);');

  Migrador := TMigradorBD.Create(FConexion, FCarpetaTemporal);
  try
    Aplicadas := Migrador.Migrar;
    AssertEquals('Primera pasada aplica 1 migracion', 1, Aplicadas);

    Aplicadas := Migrador.Migrar;
    AssertEquals('Segunda pasada no aplica migraciones pendientes', 0, Aplicadas);
    AssertEquals('Version permanece en 1', 1, Migrador.ObtenerVersion);
  finally
    Migrador.Free;
  end;
end;

initialization
  RegisterTest(TTestMigradorBD);

end.

