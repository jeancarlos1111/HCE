unit uVerificadorCadena;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, SQLite3Conn, SQLdb,
  uConexionSQLite, uEventoAuditoria, uCanonico, uSha256;

type
  TEstadoCadena = (ecIntegra, ecAlterada, ecHuecoSecuencia, ecCadenaVacia);

  TResultadoVerificacion = record
    Estado: TEstadoCadena;
    PrimerSeq: Int64;
    UltimoSeq: Int64;
    TotalEventos: Int64;
    SeqProblema: Int64;
    Detalle: string;
  end;

  TVerificadorCadena = class
  private
    FConexion: IConexionBD;
  public
    constructor Create(AConexion: IConexionBD);
    function VerificarIntegridad: TResultadoVerificacion;
  end;

implementation

constructor TVerificadorCadena.Create(AConexion: IConexionBD);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TVerificadorCadena.VerificarIntegridad: TResultadoVerificacion;
var
  Q: TSQLQuery;
  Evento: TEventoAuditoria;
  Seq, SeqEsperado: Int64;
  FechaUtcIso, HashPrev, HashAlmacenado, HashCalculado, HashDatos, DatosJson: string;
begin
  Result.Estado := ecIntegra;
  Result.PrimerSeq := 0;
  Result.UltimoSeq := 0;
  Result.TotalEventos := 0;
  Result.SeqProblema := 0;
  Result.Detalle := 'Cadena integra';

  FConexion.Conectar;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConexion.ObtenerConnection;
    Q.Transaction := FConexion.ObtenerTransaction;
    Q.SQL.Text :=
      'SELECT seq, fecha_utc, usuario_id, login_txt, roles, sesion_id, equipo, ip, ' +
      '       accion, entidad, entidad_id, paciente_id, resultado, motivo, datos, ' +
      '       hash_datos, hash_prev, hash ' +
      'FROM auditoria ORDER BY seq ASC;';
    Q.Open;

    if Q.EOF then
    begin
      Result.Estado := ecCadenaVacia;
      Result.Detalle := 'No hay eventos de auditoria registrados';
      Exit;
    end;

    SeqEsperado := 1;
    while not Q.EOF do
    begin
      Seq := Q.FieldByName('seq').AsLargeInt;

      // 1. Detección de hueco
      if Seq <> SeqEsperado then
      begin
        Result.Estado := ecHuecoSecuencia;
        Result.SeqProblema := SeqEsperado;
        Result.Detalle := Format('Hueco de secuencia: se esperaba seq %d pero se encontro %d', [SeqEsperado, Seq]);
        Exit;
      end;

      if Result.PrimerSeq = 0 then
        Result.PrimerSeq := Seq;

      FechaUtcIso := Q.FieldByName('fecha_utc').AsString;

      Evento.UsuarioId := Q.FieldByName('usuario_id').AsLargeInt;
      Evento.LoginTxt := Q.FieldByName('login_txt').AsString;
      Evento.Roles := Q.FieldByName('roles').AsString;
      Evento.SesionId := Q.FieldByName('sesion_id').AsLargeInt;
      Evento.Equipo := Q.FieldByName('equipo').AsString;
      Evento.Ip := Q.FieldByName('ip').AsString;
      Evento.Accion := Q.FieldByName('accion').AsString;
      Evento.Entidad := Q.FieldByName('entidad').AsString;
      Evento.EntidadId := Q.FieldByName('entidad_id').AsString;
      Evento.PacienteId := Q.FieldByName('paciente_id').AsLargeInt;
      Evento.Resultado := StrToResultadoAud(Q.FieldByName('resultado').AsString);
      Evento.Motivo := Q.FieldByName('motivo').AsString;
      DatosJson := Q.FieldByName('datos').AsString;

      HashPrev := Q.FieldByName('hash_prev').AsString;
      HashAlmacenado := Q.FieldByName('hash').AsString;

      if DatosJson <> '' then
        HashDatos := Sha256Hex(DatosJson)
      else
        HashDatos := '';

      // 2. Recalcular hash y comparar
      HashCalculado := CalcularHashEvento(Seq, FechaUtcIso, Evento, HashDatos, HashPrev);
      if HashCalculado <> HashAlmacenado then
      begin
        Result.Estado := ecAlterada;
        Result.SeqProblema := Seq;
        Result.Detalle := Format('Hash alterado en seq %d: calculado %s <> almacenado %s', [Seq, HashCalculado, HashAlmacenado]);
        Exit;
      end;

      Result.UltimoSeq := Seq;
      Inc(Result.TotalEventos);
      Inc(SeqEsperado);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

end.

