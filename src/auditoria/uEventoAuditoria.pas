unit uEventoAuditoria;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TResultadoAud = (raOK, raDenegado, raError);

  TEventoAuditoria = record
    UsuarioId: Int64;
    LoginTxt: string;
    Roles: string;
    SesionId: Int64;
    Equipo: string;
    Ip: string;
    Accion: string;
    Entidad: string;
    EntidadId: string;
    PacienteId: Int64;
    Resultado: TResultadoAud;
    Motivo: string;
    DatosJson: string; // JSON {antes:{}, despues:{}}
  end;

const
  // Catálogo Spec 003
  AUD_LOGIN_OK          = 'LOGIN_OK';
  AUD_LOGIN_FALLIDO     = 'LOGIN_FALLIDO';
  AUD_LOGIN_BLOQUEADO   = 'LOGIN_BLOQUEADO';
  AUD_CUENTA_BLOQUEADA  = 'CUENTA_BLOQUEADA';
  AUD_CUENTA_DESBLOQUEADA = 'CUENTA_DESBLOQUEADA';
  AUD_LOGOUT            = 'LOGOUT';
  AUD_CLAVE_CAMBIADA    = 'CLAVE_CAMBIADA';
  AUD_PIN_CAMBIADO      = 'PIN_CAMBIADO';
  AUD_USUARIO_CREAR     = 'USUARIO_CREAR';
  AUD_USUARIO_EDITAR    = 'USUARIO_EDITAR';
  AUD_USUARIO_INACTIVAR = 'USUARIO_INACTIVAR';
  AUD_ACCESO_DENEGADO   = 'ACCESO_DENEGADO';
  AUD_ACCESO_EMERGENCIA = 'ACCESO_EMERGENCIA';

function ResultadoAudToStr(R: TResultadoAud): string;
function StrToResultadoAud(const S: string): TResultadoAud;

implementation

function ResultadoAudToStr(R: TResultadoAud): string;
begin
  case R of
    raOK: Result := 'O';
    raDenegado: Result := 'D';
    raError: Result := 'E';
  end;
end;

function StrToResultadoAud(const S: string): TResultadoAud;
begin
  if S = 'O' then Result := raOK
  else if S = 'D' then Result := raDenegado
  else Result := raError;
end;

end.

