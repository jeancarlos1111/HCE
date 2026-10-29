unit uUsuarioRepository;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, SQLite3Conn, SQLdb,
  uConexionSQLite, uUsuario;

type
  IUsuarioRepository = interface
    ['{DA988229-37BE-4D88-9AA2-AC650C53112E}']
    function ObtenerPorId(AId: Int64): TUsuario;
    function ObtenerPorLogin(const ALogin: string): TUsuario;
    function ObtenerPorCedula(const ACedula: string): TUsuario;
    function Crear(AUsuario: TUsuario): Int64;
    procedure Actualizar(AUsuario: TUsuario);
    procedure ActualizarSeguridad(AId: Int64; AIntentosFallidos: Integer;
      AEstado: TEstadoUsuario; const ABloqueadoHastaUtc: string);
    procedure CambiarClaveYPin(AId: Int64; const ANuevaClaveHash, ANuevoPinHash, AFechaUtcIso: string);
    function SonRolesIncompatibles(const RolA, RolB: string): Boolean;
    function ObtenerPermisosDeRoles(ARoles: TStrings): TStringArray;
    function MppsExiste(const AMpps: string; AExcluirUsuarioId: Int64 = 0): Boolean;
    function Listar(const AFiltro: string = ''): TFPList;
  end;

  TUsuarioRepositorySQLite = class(TInterfacedObject, IUsuarioRepository)
  private
    FConexion: IConexionBD;
    procedure CargarRolesYProfesional(AUsuario: TUsuario);
  public
    constructor Create(AConexion: IConexionBD);
    function ObtenerPorId(AId: Int64): TUsuario;
    function ObtenerPorLogin(const ALogin: string): TUsuario;
    function ObtenerPorCedula(const ACedula: string): TUsuario;
    function Crear(AUsuario: TUsuario): Int64;
    procedure Actualizar(AUsuario: TUsuario);
    procedure ActualizarSeguridad(AId: Int64; AIntentosFallidos: Integer;
      AEstado: TEstadoUsuario; const ABloqueadoHastaUtc: string);
    procedure CambiarClaveYPin(AId: Int64; const ANuevaClaveHash, ANuevoPinHash, AFechaUtcIso: string);
    function SonRolesIncompatibles(const RolA, RolB: string): Boolean;
    function ObtenerPermisosDeRoles(ARoles: TStrings): TStringArray;
    function MppsExiste(const AMpps: string; AExcluirUsuarioId: Int64 = 0): Boolean;
    function Listar(const AFiltro: string = ''): TFPList;
  end;

implementation

constructor TUsuarioRepositorySQLite.Create(AConexion: IConexionBD);
begin
  inherited Create;
  FConexion := AConexion;
end;

procedure TUsuarioRepositorySQLite.CargarRolesYProfesional(AUsuario: TUsuario);
var
  Q: TSQLQuery;
  Prof: TProfesional;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConexion.ObtenerConnection;
    Q.Transaction := FConexion.ObtenerTransaction;

    // Roles
    Q.SQL.Text := 'SELECT rol FROM usuario_roles WHERE usuario_id = :uid ORDER BY rol;';
    Q.ParamByName('uid').AsLargeInt := AUsuario.Id;
    Q.Open;
    AUsuario.Roles.Clear;
    while not Q.EOF do
    begin
      AUsuario.Roles.Add(Q.Fields[0].AsString);
      Q.Next;
    end;
    Q.Close;

    // Profesional
    Q.SQL.Text := 'SELECT tipo, mpps, colegio, nro_colegio, especialidades FROM profesionales WHERE usuario_id = :uid;';
    Q.ParamByName('uid').AsLargeInt := AUsuario.Id;
    Q.Open;
    if not Q.EOF then
    begin
      AUsuario.EsProfesional := True;
      Prof.Tipo := Q.FieldByName('tipo').AsString;
      Prof.Mpps := Q.FieldByName('mpps').AsString;
      Prof.Colegio := Q.FieldByName('colegio').AsString;
      Prof.NroColegio := Q.FieldByName('nro_colegio').AsString;
      Prof.Especialidades := Q.FieldByName('especialidades').AsString;
      AUsuario.Profesional := Prof;
    end
    else
      AUsuario.EsProfesional := False;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TUsuarioRepositorySQLite.ObtenerPorLogin(const ALogin: string): TUsuario;
var
  Q: TSQLQuery;
begin
  Result := nil;
  FConexion.Conectar;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConexion.ObtenerConnection;
    Q.Transaction := FConexion.ObtenerTransaction;
    Q.SQL.Text :=
      'SELECT id, login, cedula, nombres, apellidos, email, telefono, ' +
      '       clave_hash, clave_temporal, clave_cambiada_utc, pin_hash, ' +
      '       estado, bloqueado_hasta_utc, intentos_fallidos, creado_utc, creado_por, version ' +
      'FROM usuarios WHERE login = :login COLLATE NOCASE;';
    Q.ParamByName('login').AsString := Trim(ALogin);
    Q.Open;

    if not Q.EOF then
    begin
      Result := TUsuario.Create;
      Result.Id := Q.FieldByName('id').AsLargeInt;
      Result.Login := Q.FieldByName('login').AsString;
      Result.Cedula := Q.FieldByName('cedula').AsString;
      Result.Nombres := Q.FieldByName('nombres').AsString;
      Result.Apellidos := Q.FieldByName('apellidos').AsString;
      Result.Email := Q.FieldByName('email').AsString;
      Result.Telefono := Q.FieldByName('telefono').AsString;
      Result.ClaveHash := Q.FieldByName('clave_hash').AsString;
      Result.ClaveTemporal := (Q.FieldByName('clave_temporal').AsInteger = 1);
      Result.ClaveCambiadaUtc := Q.FieldByName('clave_cambiada_utc').AsString;
      Result.PinHash := Q.FieldByName('pin_hash').AsString;
      Result.Estado := StrToEstadoUsuario(Q.FieldByName('estado').AsString);
      Result.BloqueadoHastaUtc := Q.FieldByName('bloqueado_hasta_utc').AsString;
      Result.IntentosFallidos := Q.FieldByName('intentos_fallidos').AsInteger;
      Result.CreadoUtc := Q.FieldByName('creado_utc').AsString;
      Result.CreadoPor := Q.FieldByName('creado_por').AsLargeInt;
      Result.Version := Q.FieldByName('version').AsInteger;
      Q.Close;

      CargarRolesYProfesional(Result);
    end;
  finally
    Q.Free;
  end;
end;

function TUsuarioRepositorySQLite.ObtenerPorId(AId: Int64): TUsuario;
var
  Q: TSQLQuery;
begin
  Result := nil;
  FConexion.Conectar;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConexion.ObtenerConnection;
    Q.Transaction := FConexion.ObtenerTransaction;
    Q.SQL.Text :=
      'SELECT id, login, cedula, nombres, apellidos, email, telefono, ' +
      '       clave_hash, clave_temporal, clave_cambiada_utc, pin_hash, ' +
      '       estado, bloqueado_hasta_utc, intentos_fallidos, creado_utc, creado_por, version ' +
      'FROM usuarios WHERE id = :id;';
    Q.ParamByName('id').AsLargeInt := AId;
    Q.Open;

    if not Q.EOF then
    begin
      Result := TUsuario.Create;
      Result.Id := Q.FieldByName('id').AsLargeInt;
      Result.Login := Q.FieldByName('login').AsString;
      Result.Cedula := Q.FieldByName('cedula').AsString;
      Result.Nombres := Q.FieldByName('nombres').AsString;
      Result.Apellidos := Q.FieldByName('apellidos').AsString;
      Result.Email := Q.FieldByName('email').AsString;
      Result.Telefono := Q.FieldByName('telefono').AsString;
      Result.ClaveHash := Q.FieldByName('clave_hash').AsString;
      Result.ClaveTemporal := (Q.FieldByName('clave_temporal').AsInteger = 1);
      Result.ClaveCambiadaUtc := Q.FieldByName('clave_cambiada_utc').AsString;
      Result.PinHash := Q.FieldByName('pin_hash').AsString;
      Result.Estado := StrToEstadoUsuario(Q.FieldByName('estado').AsString);
      Result.BloqueadoHastaUtc := Q.FieldByName('bloqueado_hasta_utc').AsString;
      Result.IntentosFallidos := Q.FieldByName('intentos_fallidos').AsInteger;
      Result.CreadoUtc := Q.FieldByName('creado_utc').AsString;
      Result.CreadoPor := Q.FieldByName('creado_por').AsLargeInt;
      Result.Version := Q.FieldByName('version').AsInteger;
      Q.Close;

      CargarRolesYProfesional(Result);
    end;
  finally
    Q.Free;
  end;
end;

function TUsuarioRepositorySQLite.ObtenerPorCedula(const ACedula: string): TUsuario;
var
  Q: TSQLQuery;
begin
  Result := nil;
  FConexion.Conectar;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConexion.ObtenerConnection;
    Q.Transaction := FConexion.ObtenerTransaction;
    Q.SQL.Text :=
      'SELECT id, login, cedula, nombres, apellidos, email, telefono, ' +
      '       clave_hash, clave_temporal, clave_cambiada_utc, pin_hash, ' +
      '       estado, bloqueado_hasta_utc, intentos_fallidos, creado_utc, creado_por, version ' +
      'FROM usuarios WHERE cedula = :cedula;';
    Q.ParamByName('cedula').AsString := Trim(ACedula);
    Q.Open;

    if not Q.EOF then
    begin
      Result := TUsuario.Create;
      Result.Id := Q.FieldByName('id').AsLargeInt;
      Result.Login := Q.FieldByName('login').AsString;
      Result.Cedula := Q.FieldByName('cedula').AsString;
      Result.Nombres := Q.FieldByName('nombres').AsString;
      Result.Apellidos := Q.FieldByName('apellidos').AsString;
      Result.Email := Q.FieldByName('email').AsString;
      Result.Telefono := Q.FieldByName('telefono').AsString;
      Result.ClaveHash := Q.FieldByName('clave_hash').AsString;
      Result.ClaveTemporal := (Q.FieldByName('clave_temporal').AsInteger = 1);
      Result.ClaveCambiadaUtc := Q.FieldByName('clave_cambiada_utc').AsString;
      Result.PinHash := Q.FieldByName('pin_hash').AsString;
      Result.Estado := StrToEstadoUsuario(Q.FieldByName('estado').AsString);
      Result.BloqueadoHastaUtc := Q.FieldByName('bloqueado_hasta_utc').AsString;
      Result.IntentosFallidos := Q.FieldByName('intentos_fallidos').AsInteger;
      Result.CreadoUtc := Q.FieldByName('creado_utc').AsString;
      Result.CreadoPor := Q.FieldByName('creado_por').AsLargeInt;
      Result.Version := Q.FieldByName('version').AsInteger;
      Q.Close;

      CargarRolesYProfesional(Result);
    end;
  finally
    Q.Free;
  end;
end;

function TUsuarioRepositorySQLite.Crear(AUsuario: TUsuario): Int64;
var
  Q: TSQLQuery;
  i: Integer;
begin
  FConexion.Conectar;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConexion.ObtenerConnection;
    Q.Transaction := FConexion.ObtenerTransaction;

    Q.SQL.Text :=
      'INSERT INTO usuarios (' +
      '  login, cedula, nombres, apellidos, email, telefono, clave_hash, ' +
      '  clave_temporal, pin_hash, estado, intentos_fallidos, creado_utc, creado_por, version' +
      ') VALUES (' +
      '  :login, :cedula, :nombres, :apellidos, :email, :telefono, :clave_hash, ' +
      '  :clave_temporal, :pin_hash, :estado, :intentos_fallidos, :creado_utc, :creado_por, :version' +
      ') RETURNING id;';

    Q.ParamByName('login').AsString := Trim(AUsuario.Login);
    Q.ParamByName('cedula').AsString := Trim(AUsuario.Cedula);
    Q.ParamByName('nombres').AsString := Trim(AUsuario.Nombres);
    Q.ParamByName('apellidos').AsString := Trim(AUsuario.Apellidos);
    Q.ParamByName('email').AsString := Trim(AUsuario.Email);
    Q.ParamByName('telefono').AsString := Trim(AUsuario.Telefono);
    Q.ParamByName('clave_hash').AsString := AUsuario.ClaveHash;
    Q.ParamByName('clave_temporal').AsInteger := Ord(AUsuario.ClaveTemporal);
    if AUsuario.PinHash <> '' then
      Q.ParamByName('pin_hash').AsString := AUsuario.PinHash
    else
      Q.ParamByName('pin_hash').Clear;
    Q.ParamByName('estado').AsString := EstadoUsuarioToStr(AUsuario.Estado);
    Q.ParamByName('intentos_fallidos').AsInteger := AUsuario.IntentosFallidos;
    Q.ParamByName('creado_utc').AsString := AUsuario.CreadoUtc;
    if AUsuario.CreadoPor > 0 then
      Q.ParamByName('creado_por').AsLargeInt := AUsuario.CreadoPor
    else
      Q.ParamByName('creado_por').Clear;
    Q.ParamByName('version').AsInteger := 1;

    Q.Open;
    Result := Q.Fields[0].AsLargeInt;
    AUsuario.Id := Result;
    Q.Close;

    // Insertar roles
    for i := 0 to AUsuario.Roles.Count - 1 do
    begin
      Q.SQL.Text := 'INSERT INTO usuario_roles (usuario_id, rol) VALUES (:uid, :rol);';
      Q.ParamByName('uid').AsLargeInt := Result;
      Q.ParamByName('rol').AsString := AUsuario.Roles[i];
      Q.ExecSQL;
    end;

    // Si es profesional
    if AUsuario.EsProfesional then
    begin
      Q.SQL.Text :=
        'INSERT INTO profesionales (usuario_id, tipo, mpps, colegio, nro_colegio, especialidades) ' +
        'VALUES (:uid, :tipo, :mpps, :colegio, :nro_colegio, :especialidades);';
      Q.ParamByName('uid').AsLargeInt := Result;
      Q.ParamByName('tipo').AsString := AUsuario.Profesional.Tipo;
      Q.ParamByName('mpps').AsString := AUsuario.Profesional.Mpps;
      Q.ParamByName('colegio').AsString := AUsuario.Profesional.Colegio;
      Q.ParamByName('nro_colegio').AsString := AUsuario.Profesional.NroColegio;
      Q.ParamByName('especialidades').AsString := AUsuario.Profesional.Especialidades;
      Q.ExecSQL;
    end;

    // Confirmar transaccion de insercion
    if FConexion.ObtenerTransaction.Active then
      FConexion.ObtenerTransaction.Commit;
  finally
    Q.Free;
  end;
end;

procedure TUsuarioRepositorySQLite.Actualizar(AUsuario: TUsuario);
var
  Q: TSQLQuery;
  i: Integer;
begin
  FConexion.Conectar;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConexion.ObtenerConnection;
    Q.Transaction := FConexion.ObtenerTransaction;

    Q.SQL.Text :=
      'UPDATE usuarios SET ' +
      '  nombres = :nombres, apellidos = :apellidos, email = :email, telefono = :telefono, ' +
      '  estado = :estado, version = version + 1 ' +
      'WHERE id = :id AND version = :version;';
    Q.ParamByName('nombres').AsString := Trim(AUsuario.Nombres);
    Q.ParamByName('apellidos').AsString := Trim(AUsuario.Apellidos);
    Q.ParamByName('email').AsString := Trim(AUsuario.Email);
    Q.ParamByName('telefono').AsString := Trim(AUsuario.Telefono);
    Q.ParamByName('estado').AsString := EstadoUsuarioToStr(AUsuario.Estado);
    Q.ParamByName('id').AsLargeInt := AUsuario.Id;
    Q.ParamByName('version').AsInteger := AUsuario.Version;
    Q.ExecSQL;

    // Actualizar roles: limpiar y reinsertar
    Q.SQL.Text := 'DELETE FROM usuario_roles WHERE usuario_id = :uid;';
    Q.ParamByName('uid').AsLargeInt := AUsuario.Id;
    Q.ExecSQL;

    for i := 0 to AUsuario.Roles.Count - 1 do
    begin
      Q.SQL.Text := 'INSERT INTO usuario_roles (usuario_id, rol) VALUES (:uid, :rol);';
      Q.ParamByName('uid').AsLargeInt := AUsuario.Id;
      Q.ParamByName('rol').AsString := AUsuario.Roles[i];
      Q.ExecSQL;
    end;

    // Profesional
    if AUsuario.EsProfesional then
    begin
      Q.SQL.Text :=
        'INSERT INTO profesionales (usuario_id, tipo, mpps, colegio, nro_colegio, especialidades) ' +
        'VALUES (:uid, :tipo, :mpps, :colegio, :nro_colegio, :especialidades) ' +
        'ON CONFLICT(usuario_id) DO UPDATE SET ' +
        '  tipo = excluded.tipo, mpps = excluded.mpps, colegio = excluded.colegio, ' +
        '  nro_colegio = excluded.nro_colegio, especialidades = excluded.especialidades;';
      Q.ParamByName('uid').AsLargeInt := AUsuario.Id;
      Q.ParamByName('tipo').AsString := AUsuario.Profesional.Tipo;
      Q.ParamByName('mpps').AsString := AUsuario.Profesional.Mpps;
      Q.ParamByName('colegio').AsString := AUsuario.Profesional.Colegio;
      Q.ParamByName('nro_colegio').AsString := AUsuario.Profesional.NroColegio;
      Q.ParamByName('especialidades').AsString := AUsuario.Profesional.Especialidades;
      Q.ExecSQL;
    end;

    if FConexion.ObtenerTransaction.Active then
      FConexion.ObtenerTransaction.Commit;
  finally
    Q.Free;
  end;
end;

procedure TUsuarioRepositorySQLite.ActualizarSeguridad(AId: Int64; AIntentosFallidos: Integer;
  AEstado: TEstadoUsuario; const ABloqueadoHastaUtc: string);
var
  Q: TSQLQuery;
begin
  FConexion.Conectar;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConexion.ObtenerConnection;
    Q.Transaction := FConexion.ObtenerTransaction;

    Q.SQL.Text :=
      'UPDATE usuarios SET ' +
      '  intentos_fallidos = :intentos, estado = :estado, bloqueado_hasta_utc = :bloqueo ' +
      'WHERE id = :id;';
    Q.ParamByName('intentos').AsInteger := AIntentosFallidos;
    Q.ParamByName('estado').AsString := EstadoUsuarioToStr(AEstado);
    if ABloqueadoHastaUtc <> '' then
      Q.ParamByName('bloqueo').AsString := ABloqueadoHastaUtc
    else
      Q.ParamByName('bloqueo').Clear;
    Q.ParamByName('id').AsLargeInt := AId;
    Q.ExecSQL;

    if FConexion.ObtenerTransaction.Active then
      FConexion.ObtenerTransaction.Commit;
  finally
    Q.Free;
  end;
end;

procedure TUsuarioRepositorySQLite.CambiarClaveYPin(AId: Int64; const ANuevaClaveHash, ANuevoPinHash, AFechaUtcIso: string);
var
  Q: TSQLQuery;
begin
  FConexion.Conectar;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConexion.ObtenerConnection;
    Q.Transaction := FConexion.ObtenerTransaction;

    // Guardar en histórico de claves
    Q.SQL.Text := 'INSERT INTO claves_hist (usuario_id, clave_hash, creado_utc) VALUES (:uid, :chash, :fecha);';
    Q.ParamByName('uid').AsLargeInt := AId;
    Q.ParamByName('chash').AsString := ANuevaClaveHash;
    Q.ParamByName('fecha').AsString := AFechaUtcIso;
    Q.ExecSQL;

    // Actualizar usuario
    Q.SQL.Text :=
      'UPDATE usuarios SET ' +
      '  clave_hash = :chash, pin_hash = :phash, clave_temporal = 0, ' +
      '  clave_cambiada_utc = :fecha, version = version + 1 ' +
      'WHERE id = :id;';
    Q.ParamByName('chash').AsString := ANuevaClaveHash;
    if ANuevoPinHash <> '' then
      Q.ParamByName('phash').AsString := ANuevoPinHash
    else
      Q.ParamByName('phash').Clear;
    Q.ParamByName('fecha').AsString := AFechaUtcIso;
    Q.ParamByName('id').AsLargeInt := AId;
    Q.ExecSQL;

    if FConexion.ObtenerTransaction.Active then
      FConexion.ObtenerTransaction.Commit;
  finally
    Q.Free;
  end;
end;

function TUsuarioRepositorySQLite.SonRolesIncompatibles(const RolA, RolB: string): Boolean;
var
  Total: Int64;
begin
  Total := FConexion.EjecutarConsultaEscalarEntero(Format(
    'SELECT COUNT(*) FROM roles_incompatibles WHERE (rol_a = ''%s'' AND rol_b = ''%s'') OR (rol_a = ''%s'' AND rol_b = ''%s'');',
    [RolA, RolB, RolB, RolA]
  ));
  Result := (Total > 0);
end;

function TUsuarioRepositorySQLite.ObtenerPermisosDeRoles(ARoles: TStrings): TStringArray;
var
  Q: TSQLQuery;
  i: Integer;
  Lista: TStringList;
  InClause: string;
begin
  if (ARoles = nil) or (ARoles.Count = 0) then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  InClause := '';
  for i := 0 to ARoles.Count - 1 do
  begin
    if i > 0 then InClause := InClause + ',';
    InClause := InClause + QuotedStr(ARoles[i]);
  end;

  Lista := TStringList.Create;
  try
    Lista.Sorted := True;
    Lista.Duplicates := dupIgnore;

    Q := TSQLQuery.Create(nil);
    try
      Q.DataBase := FConexion.ObtenerConnection;
      Q.Transaction := FConexion.ObtenerTransaction;
      Q.SQL.Text := Format('SELECT DISTINCT permiso FROM rol_permisos WHERE rol IN (%s);', [InClause]);
      Q.Open;
      while not Q.EOF do
      begin
        Lista.Add(Q.Fields[0].AsString);
        Q.Next;
      end;
      Q.Close;
    finally
      Q.Free;
    end;

    SetLength(Result, Lista.Count);
    for i := 0 to Lista.Count - 1 do
      Result[i] := Lista[i];
  finally
    Lista.Free;
  end;
end;

function TUsuarioRepositorySQLite.MppsExiste(const AMpps: string; AExcluirUsuarioId: Int64): Boolean;
var
  Total: Int64;
begin
  Total := FConexion.EjecutarConsultaEscalarEntero(Format(
    'SELECT COUNT(*) FROM profesionales WHERE mpps = ''%s'' AND usuario_id <> %d;',
    [Trim(AMpps), AExcluirUsuarioId]
  ));
  Result := (Total > 0);
end;

function TUsuarioRepositorySQLite.Listar(const AFiltro: string): TFPList;
var
  Q: TSQLQuery;
  U: TUsuario;
  Sql: string;
begin
  Result := TFPList.Create;
  FConexion.Conectar;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConexion.ObtenerConnection;
    Q.Transaction := FConexion.ObtenerTransaction;
    Sql :=
      'SELECT id, login, cedula, nombres, apellidos, email, telefono, ' +
      '       clave_hash, clave_temporal, clave_cambiada_utc, pin_hash, ' +
      '       estado, bloqueado_hasta_utc, intentos_fallidos, creado_utc, creado_por, version ' +
      'FROM usuarios ';
    if Trim(AFiltro) <> '' then
      Sql := Sql + 'WHERE login LIKE :filtro OR cedula LIKE :filtro OR nombres LIKE :filtro OR apellidos LIKE :filtro ';
    Sql := Sql + 'ORDER BY login ASC;';

    Q.SQL.Text := Sql;
    if Trim(AFiltro) <> '' then
      Q.ParamByName('filtro').AsString := '%' + Trim(AFiltro) + '%';
    Q.Open;

    while not Q.EOF do
    begin
      U := TUsuario.Create;
      U.Id := Q.FieldByName('id').AsLargeInt;
      U.Login := Q.FieldByName('login').AsString;
      U.Cedula := Q.FieldByName('cedula').AsString;
      U.Nombres := Q.FieldByName('nombres').AsString;
      U.Apellidos := Q.FieldByName('apellidos').AsString;
      U.Email := Q.FieldByName('email').AsString;
      U.Telefono := Q.FieldByName('telefono').AsString;
      U.ClaveHash := Q.FieldByName('clave_hash').AsString;
      U.ClaveTemporal := (Q.FieldByName('clave_temporal').AsInteger = 1);
      U.ClaveCambiadaUtc := Q.FieldByName('clave_cambiada_utc').AsString;
      U.PinHash := Q.FieldByName('pin_hash').AsString;
      U.Estado := StrToEstadoUsuario(Q.FieldByName('estado').AsString);
      U.BloqueadoHastaUtc := Q.FieldByName('bloqueado_hasta_utc').AsString;
      U.IntentosFallidos := Q.FieldByName('intentos_fallidos').AsInteger;
      U.CreadoUtc := Q.FieldByName('creado_utc').AsString;
      U.CreadoPor := Q.FieldByName('creado_por').AsLargeInt;
      U.Version := Q.FieldByName('version').AsInteger;
      CargarRolesYProfesional(U);
      Result.Add(U);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

end.

