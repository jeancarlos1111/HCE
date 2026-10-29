unit uCanonico;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, uEventoAuditoria, uSha256;

function EscaparPipe(const S: string): string;
function SerializarCanonico(Seq: Int64; const FechaUtcIso: string;
  const Evento: TEventoAuditoria; const HashDatos, HashPrev: string): string;
function CalcularHashEvento(Seq: Int64; const FechaUtcIso: string;
  const Evento: TEventoAuditoria; const HashDatos, HashPrev: string): string;

implementation

function EscaparPipe(const S: string): string;
begin
  Result := StringReplace(S, '|', '\|', [rfReplaceAll]);
end;

function SerializarCanonico(Seq: Int64; const FechaUtcIso: string;
  const Evento: TEventoAuditoria; const HashDatos, HashPrev: string): string;
var
  UIdStr, PacIdStr: string;
begin
  if Evento.UsuarioId > 0 then UIdStr := IntToStr(Evento.UsuarioId) else UIdStr := '';
  if Evento.PacienteId > 0 then PacIdStr := IntToStr(Evento.PacienteId) else PacIdStr := '';

  // canon = Seq | FechaUtc | UsuarioId | LoginTxt | Accion | Entidad | EntidadId | PacienteId | Resultado | Motivo | HashDatos | HashPrev
  Result := Format('%d|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s', [
    Seq,
    FechaUtcIso,
    UIdStr,
    Evento.LoginTxt,
    Evento.Accion,
    Evento.Entidad,
    Evento.EntidadId,
    PacIdStr,
    ResultadoAudToStr(Evento.Resultado),
    EscaparPipe(Evento.Motivo),
    HashDatos,
    HashPrev
  ]);
end;

function CalcularHashEvento(Seq: Int64; const FechaUtcIso: string;
  const Evento: TEventoAuditoria; const HashDatos, HashPrev: string): string;
var
  Canon: string;
begin
  Canon := SerializarCanonico(Seq, FechaUtcIso, Evento, HashDatos, HashPrev);
  Result := Sha256Hex(Canon);
end;

end.

