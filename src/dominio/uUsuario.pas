unit uUsuario;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TEstadoUsuario = (euActivo, euBloqueado, euInactivo);

  TProfesional = record
    Tipo: string;           // MEDICO, ENFERMERIA, etc.
    Mpps: string;           // Matrícula obligatoria
    Colegio: string;        // ej. Colegio de Médicos Edo. Miranda
    NroColegio: string;
    Especialidades: string;
  end;

  TUsuario = class
  private
    FId: Int64;
    FLogin: string;
    FCedula: string;
    FNombres: string;
    FApellidos: string;
    FEmail: string;
    FTelefono: string;
    FClaveHash: string;
    FClaveTemporal: Boolean;
    FClaveCambiadaUtc: string;
    FPinHash: string;
    FEstado: TEstadoUsuario;
    FBloqueadoHastaUtc: string;
    FIntentosFallidos: Integer;
    FCreadoUtc: string;
    FCreadoPor: Int64;
    FVersion: Integer;
    FRoles: TStringList;
    FEsProfesional: Boolean;
    FProfesional: TProfesional;
  public
    constructor Create;
    destructor Destroy; override;

    property Id: Int64 read FId write FId;
    property Login: string read FLogin write FLogin;
    property Cedula: string read FCedula write FCedula;
    property Nombres: string read FNombres write FNombres;
    property Apellidos: string read FApellidos write FApellidos;
    property Email: string read FEmail write FEmail;
    property Telefono: string read FTelefono write FTelefono;
    property ClaveHash: string read FClaveHash write FClaveHash;
    property ClaveTemporal: Boolean read FClaveTemporal write FClaveTemporal;
    property ClaveCambiadaUtc: string read FClaveCambiadaUtc write FClaveCambiadaUtc;
    property PinHash: string read FPinHash write FPinHash;
    property Estado: TEstadoUsuario read FEstado write FEstado;
    property BloqueadoHastaUtc: string read FBloqueadoHastaUtc write FBloqueadoHastaUtc;
    property IntentosFallidos: Integer read FIntentosFallidos write FIntentosFallidos;
    property CreadoUtc: string read FCreadoUtc write FCreadoUtc;
    property CreadoPor: Int64 read FCreadoPor write FCreadoPor;
    property Version: Integer read FVersion write FVersion;
    property Roles: TStringList read FRoles;
    property EsProfesional: Boolean read FEsProfesional write FEsProfesional;
    property Profesional: TProfesional read FProfesional write FProfesional;
  end;

function EstadoUsuarioToStr(E: TEstadoUsuario): string;
function StrToEstadoUsuario(const S: string): TEstadoUsuario;

implementation

function EstadoUsuarioToStr(E: TEstadoUsuario): string;
begin
  case E of
    euActivo: Result := 'A';
    euBloqueado: Result := 'B';
    euInactivo: Result := 'I';
  end;
end;

function StrToEstadoUsuario(const S: string): TEstadoUsuario;
begin
  if S = 'B' then Result := euBloqueado
  else if S = 'I' then Result := euInactivo
  else Result := euActivo;
end;

constructor TUsuario.Create;
begin
  inherited Create;
  FRoles := TStringList.Create;
  FRoles.Sorted := True;
  FRoles.Duplicates := dupIgnore;
  FEstado := euActivo;
  FClaveTemporal := True;
  FIntentosFallidos := 0;
  FVersion := 1;
  FEsProfesional := False;
end;

destructor TUsuario.Destroy;
begin
  FRoles.Free;
  inherited Destroy;
end;

end.

