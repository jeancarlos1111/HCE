unit uAuditoriaSQLite;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, SQLite3Conn, SQLdb,
  uConexionSQLite, uReloj, uEventoAuditoria, uAuditoria, uCanonico, uSha256;

type
  TAuditoriaSQLite = class(TInterfacedObject, IAuditoria)
  private
    FConexion: IConexionBD;
    FReloj: IReloj;
  public
    constructor Create(AConexion: IConexionBD; AReloj: IReloj);
    function Registrar(const Evento: TEventoAuditoria): Int64;
    function RegistrarIndependiente(const Evento: TEventoAuditoria): Int64;
  end;

implementation

constructor TAuditoriaSQLite.Create(AConexion: IConexionBD; AReloj: IReloj);
begin
  inherited Create;
  FConexion := AConexion;
  FReloj := AReloj;
end;

function TAuditoriaSQLite.Registrar(const Evento: TEventoAuditoria): Int64;
var
  UltimoSeq, NuevoSeq: Int64;
  UltimoHash, HashDatos, HashActual, FechaUtcIso: string;
  Q: TSQLQuery;
  SQLInsert: string;
begin
  FConexion.Conectar;

  // 1. Obtener último seq y último hash
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConexion.ObtenerConnection;
    Q.Transaction := FConexion.ObtenerTransaction;
    Q.SQL.Text := 'SELECT ultimo_seq, ultimo_hash FROM auditoria_cadena WHERE id = 1;';
    Q.Open;
    if Q.EOF then
      raise Exception.Create('Tabla auditoria_cadena sin inicializar');

    UltimoSeq := Q.Fields[0].AsLargeInt;
    UltimoHash := Q.Fields[1].AsString;
    Q.Close;
  finally
    Q.Free;
  end;

  NuevoSeq := UltimoSeq + 1;
  FechaUtcIso := FReloj.AhoraUtcIso;

  // 2. Hash de datos
  if Evento.DatosJson <> '' then
    HashDatos := Sha256Hex(Evento.DatosJson)
  else
    HashDatos := '';

  // 3. Hash encadenado del evento canónico
  HashActual := CalcularHashEvento(NuevoSeq, FechaUtcIso, Evento, HashDatos, UltimoHash);

  // 4. Inserción en auditoria (triggers validan secuencia y hash_prev, y avanzan auditoria_cadena)
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConexion.ObtenerConnection;
    Q.Transaction := FConexion.ObtenerTransaction;
    SQLInsert :=
      'INSERT INTO auditoria (' +
      '  seq, fecha_utc, usuario_id, login_txt, roles, sesion_id, equipo, ip, ' +
      '  accion, entidad, entidad_id, paciente_id, resultado, motivo, datos, ' +
      '  hash_datos, hash_prev, hash' +
      ') VALUES (' +
      '  :seq, :fecha_utc, :usuario_id, :login_txt, :roles, :sesion_id, :equipo, :ip, ' +
      '  :accion, :entidad, :entidad_id, :paciente_id, :resultado, :motivo, :datos, ' +
      '  :hash_datos, :hash_prev, :hash' +
      ');';

    Q.SQL.Text := SQLInsert;
    Q.ParamByName('seq').AsLargeInt := NuevoSeq;
    Q.ParamByName('fecha_utc').AsString := FechaUtcIso;

    if Evento.UsuarioId > 0 then
      Q.ParamByName('usuario_id').AsLargeInt := Evento.UsuarioId
    else
      Q.ParamByName('usuario_id').Clear;

    Q.ParamByName('login_txt').AsString := Evento.LoginTxt;
    Q.ParamByName('roles').AsString := Evento.Roles;

    if Evento.SesionId > 0 then
      Q.ParamByName('sesion_id').AsLargeInt := Evento.SesionId
    else
      Q.ParamByName('sesion_id').Clear;

    Q.ParamByName('equipo').AsString := Evento.Equipo;
    Q.ParamByName('ip').AsString := Evento.Ip;
    Q.ParamByName('accion').AsString := Evento.Accion;
    Q.ParamByName('entidad').AsString := Evento.Entidad;
    Q.ParamByName('entidad_id').AsString := Evento.EntidadId;

    if Evento.PacienteId > 0 then
      Q.ParamByName('paciente_id').AsLargeInt := Evento.PacienteId
    else
      Q.ParamByName('paciente_id').Clear;

    Q.ParamByName('resultado').AsString := ResultadoAudToStr(Evento.Resultado);
    Q.ParamByName('motivo').AsString := Evento.Motivo;

    if Evento.DatosJson <> '' then
      Q.ParamByName('datos').AsString := Evento.DatosJson
    else
      Q.ParamByName('datos').Clear;

    if HashDatos <> '' then
      Q.ParamByName('hash_datos').AsString := HashDatos
    else
      Q.ParamByName('hash_datos').Clear;

    Q.ParamByName('hash_prev').AsString := UltimoHash;
    Q.ParamByName('hash').AsString := HashActual;

    Q.ExecSQL;
    Result := NuevoSeq;
  finally
    Q.Free;
  end;
end;

function TAuditoriaSQLite.RegistrarIndependiente(const Evento: TEventoAuditoria): Int64;
begin
  FConexion.IniciarTransaccion;
  try
    Result := Registrar(Evento);
    FConexion.Confirmar;
  except
    FConexion.Cancelar;
    raise;
  end;
end;

end.

