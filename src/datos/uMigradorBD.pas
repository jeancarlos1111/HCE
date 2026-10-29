unit uMigradorBD;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, DateUtils, uConexionSQLite;

type
  EMigradorError = class(Exception);

  TMigradorBD = class
  private
    FConexion: IConexionBD;
    FCarpetaMigraciones: string;
    procedure CrearTablaControl;
    function ObtenerVersionActual: Integer;
    procedure FijarVersion(AVersion: Integer);
    procedure EjecutarArchivoScript(const ARutaArchivo: string);
  public
    constructor Create(AConexion: IConexionBD; const ACarpetaMigraciones: string);
    function ObtenerVersion: Integer;
    function Migrar: Integer; // Retorna cantidad de migraciones aplicadas
  end;

implementation

constructor TMigradorBD.Create(AConexion: IConexionBD; const ACarpetaMigraciones: string);
begin
  inherited Create;
  FConexion := AConexion;
  FCarpetaMigraciones := IncludeTrailingPathDelimiter(ACarpetaMigraciones);
end;

procedure TMigradorBD.CrearTablaControl;
begin
  FConexion.EjecutarDirecto(
    'CREATE TABLE IF NOT EXISTS schema_migraciones (' +
    '  version INTEGER PRIMARY KEY,' +
    '  nombre TEXT NOT NULL,' +
    '  aplicado_utc TEXT NOT NULL' +
    ') STRICT;'
  );
end;

function TMigradorBD.ObtenerVersionActual: Integer;
begin
  CrearTablaControl;
  // user_version de SQLite es nativo y rápido
  Result := FConexion.EjecutarConsultaEscalarEntero('PRAGMA user_version;');
end;

procedure TMigradorBD.FijarVersion(AVersion: Integer);
begin
  FConexion.EjecutarDirecto(Format('PRAGMA user_version = %d;', [AVersion]));
end;

function TMigradorBD.ObtenerVersion: Integer;
begin
  Result := ObtenerVersionActual;
end;

procedure TMigradorBD.EjecutarArchivoScript(const ARutaArchivo: string);
var
  Lineas: TStringList;
  SQLCompleto: string;
begin
  Lineas := TStringList.Create;
  try
    Lineas.LoadFromFile(ARutaArchivo);
    SQLCompleto := Lineas.Text;
    FConexion.EjecutarScript(SQLCompleto);
  finally
    Lineas.Free;
  end;
end;

function TMigradorBD.Migrar: Integer;
var
  Info: TSearchRec;
  Archivos: TStringList;
  i, VersionArchivo, VersionActual: Integer;
  NombreArchivo, NumStr, AhoraUtcIso: string;
begin
  Result := 0;
  FConexion.Conectar;
  CrearTablaControl;
  VersionActual := ObtenerVersionActual;

  Archivos := TStringList.Create;
  try
    Archivos.Sorted := True;
    if FindFirst(FCarpetaMigraciones + '*.sql', faAnyFile, Info) = 0 then
    begin
      repeat
        Archivos.Add(Info.Name);
      until FindNext(Info) <> 0;
      FindClose(Info);
    end;

    for i := 0 to Archivos.Count - 1 do
    begin
      NombreArchivo := Archivos[i];
      // Espera convención: 001_descripcion.sql
      NumStr := Copy(NombreArchivo, 1, 3);
      if TryStrToInt(NumStr, VersionArchivo) then
      begin
        if VersionArchivo > VersionActual then
        begin
          FConexion.IniciarTransaccion;
          try
            EjecutarArchivoScript(FCarpetaMigraciones + NombreArchivo);
            FijarVersion(VersionArchivo);

            AhoraUtcIso := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz',
              LocalTimeToUniversal(Now));

            FConexion.EjecutarDirecto(Format(
              'INSERT INTO schema_migraciones (version, nombre, aplicado_utc) VALUES (%d, ''%s'', ''%s'');',
              [VersionArchivo, NombreArchivo, AhoraUtcIso]
            ));

            FConexion.Confirmar;
            Inc(Result);
            VersionActual := VersionArchivo;
          except
            on E: Exception do
            begin
              FConexion.Cancelar;
              raise EMigradorError.CreateFmt('Error aplicando migracion %s: %s', [NombreArchivo, E.Message]);
            end;
          end;
        end;
      end;
    end;
  finally
    Archivos.Free;
  end;
end;

end.
