unit uConexionSQLite;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, SQLite3Conn, SQLdb, sqlite3dyn;

type
  IConexionBD = interface
    ['{884A48C8-D3A3-41A3-9A9A-A3E59D50DF01}']
    function ObtenerConnection: TSQLite3Connection;
    function ObtenerTransaction: TSQLTransaction;
    procedure Conectar;
    procedure Desconectar;
    function EstaConectado: Boolean;
    procedure EjecutarDirecto(const ASQL: string);
    procedure EjecutarScript(const ASQL: string); // Soporta multiples sentencias en bloque
    function EjecutarConsultaEscalarEntero(const ASQL: string): Int64;
    function EjecutarConsultaEscalarTexto(const ASQL: string): string;
    procedure IniciarTransaccion;
    procedure IniciarEscrituraInmediata;
    procedure Confirmar;
    procedure Cancelar;
  end;

  TConexionSQLite = class(TInterfacedObject, IConexionBD)
  private
    FRutaBD: string;
    FConn: TSQLite3Connection;
    FTran: TSQLTransaction;
    FEnTransaccionPropia: Boolean;
    procedure ConfigurarConexion;
  public
    constructor Create(const ARutaBD: string);
    destructor Destroy; override;

    function ObtenerConnection: TSQLite3Connection;
    function ObtenerTransaction: TSQLTransaction;
    procedure Conectar;
    procedure Desconectar;
    function EstaConectado: Boolean;
    procedure EjecutarDirecto(const ASQL: string);
    procedure EjecutarScript(const ASQL: string);
    function EjecutarConsultaEscalarEntero(const ASQL: string): Int64;
    function EjecutarConsultaEscalarTexto(const ASQL: string): string;
    procedure IniciarTransaccion;
    procedure IniciarEscrituraInmediata;
    procedure Confirmar;
    procedure Cancelar;
  end;

implementation

constructor TConexionSQLite.Create(const ARutaBD: string);
begin
  inherited Create;
  FRutaBD := ARutaBD;
  FConn := TSQLite3Connection.Create(nil);
  FTran := TSQLTransaction.Create(nil);

  FConn.Transaction := FTran;
  FTran.Database := FConn;

  FConn.DatabaseName := FRutaBD;
  FConn.CharSet := 'UTF-8';
  FEnTransaccionPropia := False;

  ConfigurarConexion;
end;

destructor TConexionSQLite.Destroy;
begin
  Desconectar;
  FreeAndNil(FTran);
  FreeAndNil(FConn);
  inherited Destroy;
end;

procedure TConexionSQLite.ConfigurarConexion;
begin
  // ADR-001: foreign_keys activo nativamente en SQLite3Connection
  FConn.Params.Clear;
  FConn.Params.Add('foreign_keys=ON');
end;

procedure TConexionSQLite.Conectar;
begin
  if not FConn.Connected then
  begin
    FConn.Open;

    // SQLite exige que PRAGMA journal_mode = WAL se ejecute fuera de cualquier transaccion
    // FConn.ExecuteDirect inicia una transaccion si no hay una activa en SQLdb,
    // por lo que usamos sqlite3_exec a nivel de handle de SQLite directamente:
    sqlite3_exec(FConn.Handle, 'PRAGMA busy_timeout = 5000;', nil, nil, nil);

    if (FRutaBD <> ':memory:') and (FRutaBD <> '') then
    begin
      sqlite3_exec(FConn.Handle, 'PRAGMA journal_mode = WAL;', nil, nil, nil);
      sqlite3_exec(FConn.Handle, 'PRAGMA synchronous = FULL;', nil, nil, nil);
      sqlite3_exec(FConn.Handle, 'PRAGMA cache_size = -8000;', nil, nil, nil); // ~8MB
    end;
  end;
end;

procedure TConexionSQLite.Desconectar;
begin
  if EstaConectado then
  begin
    if FEnTransaccionPropia then
      Cancelar
    else if (FTran <> nil) and FTran.Active then
      FTran.Rollback;

    FConn.Close;
  end;
end;

function TConexionSQLite.EstaConectado: Boolean;
begin
  Result := (FConn <> nil) and FConn.Connected;
end;

function TConexionSQLite.ObtenerConnection: TSQLite3Connection;
begin
  Result := FConn;
end;

function TConexionSQLite.ObtenerTransaction: TSQLTransaction;
begin
  Result := FTran;
end;

procedure TConexionSQLite.EjecutarDirecto(const ASQL: string);
begin
  Conectar;
  FConn.ExecuteDirect(ASQL);
end;

procedure TConexionSQLite.EjecutarScript(const ASQL: string);
var
  Res: Integer;
  ErrMsg: PChar;
begin
  Conectar;
  ErrMsg := nil;
  Res := sqlite3_exec(FConn.Handle, PChar(ASQL), nil, nil, @ErrMsg);
  if Res <> 0 then
  begin
    try
      raise Exception.CreateFmt('Error ejecutando script SQLite (codigo %d): %s', [Res, StrPas(ErrMsg)]);
    finally
      if ErrMsg <> nil then
        sqlite3_free(ErrMsg);
    end;
  end;
end;

function TConexionSQLite.EjecutarConsultaEscalarEntero(const ASQL: string): Int64;
var
  Q: TSQLQuery;
begin
  Conectar;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConn;
    Q.Transaction := FTran;
    Q.SQL.Text := ASQL;
    Q.Open;
    if not Q.EOF then
      Result := Q.Fields[0].AsLargeInt
    else
      Result := 0;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TConexionSQLite.EjecutarConsultaEscalarTexto(const ASQL: string): string;
var
  Q: TSQLQuery;
begin
  Conectar;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConn;
    Q.Transaction := FTran;
    Q.SQL.Text := ASQL;
    Q.Open;
    if not Q.EOF then
      Result := Q.Fields[0].AsString
    else
      Result := '';
    Q.Close;
  finally
    Q.Free;
  end;
end;

procedure TConexionSQLite.IniciarTransaccion;
begin
  Conectar;
  if (FTran <> nil) and FTran.Active then
    FTran.Commit;

  FTran.StartTransaction;
  FEnTransaccionPropia := True;
end;

procedure TConexionSQLite.IniciarEscrituraInmediata;
begin
  Conectar;
  if (FTran <> nil) and FTran.Active then
    FTran.Commit;

  // BEGIN IMMEDIATE toma lock reservado para evitar deadlocks de concurrencia
  FConn.ExecuteDirect('BEGIN IMMEDIATE;');
  FEnTransaccionPropia := True;
end;

procedure TConexionSQLite.Confirmar;
begin
  if EstaConectado and FEnTransaccionPropia then
  begin
    if (FTran <> nil) and FTran.Active then
      FTran.Commit
    else
      FConn.ExecuteDirect('COMMIT;');
    FEnTransaccionPropia := False;
  end;
end;

procedure TConexionSQLite.Cancelar;
begin
  if EstaConectado and FEnTransaccionPropia then
  begin
    if (FTran <> nil) and FTran.Active then
      FTran.Rollback
    else
      FConn.ExecuteDirect('ROLLBACK;');
    FEnTransaccionPropia := False;
  end;
end;

end.
