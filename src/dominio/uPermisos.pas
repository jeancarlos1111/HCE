unit uPermisos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  // Catálogo granular Spec 001
  PERM_USUARIO_GESTIONAR = 'USUARIO.GESTIONAR';
  PERM_ROL_GESTIONAR     = 'ROL.GESTIONAR';
  PERM_PACIENTE_LEER     = 'PACIENTE.LEER';
  PERM_PACIENTE_CREAR    = 'PACIENTE.CREAR';
  PERM_PACIENTE_EDITAR   = 'PACIENTE.EDITAR';
  PERM_PACIENTE_CAMBIAR_ESTADO = 'PACIENTE.CAMBIAR_ESTADO';
  PERM_PACIENTE_FUSIONAR = 'PACIENTE.FUSIONAR';
  PERM_HC_LEER           = 'HC.LEER';
  PERM_HC_ESCRIBIR       = 'HC.ESCRIBIR';
  PERM_HC_FIRMAR         = 'HC.FIRMAR';
  PERM_HC_ENMENDAR       = 'HC.ENMENDAR';
  PERM_HC_IMPRIMIR       = 'HC.IMPRIMIR';
  PERM_HC_EXPORTAR       = 'HC.EXPORTAR';
  PERM_HC_ACCESO_EMERGENCIA = 'HC.ACCESO_EMERGENCIA';
  PERM_ESTADISTICA_VER   = 'ESTADISTICA.VER';
  PERM_ESTADISTICA_VER_PROPIA = 'ESTADISTICA.VER_PROPIA';
  PERM_ESTADISTICA_EXPORTAR = 'ESTADISTICA.EXPORTAR';
  PERM_AUDITORIA_LEER    = 'AUDITORIA.LEER';
  PERM_AUDITORIA_EXPORTAR = 'AUDITORIA.EXPORTAR';
  PERM_CATALOGO_GESTIONAR = 'CATALOGO.GESTIONAR';
  PERM_RESPALDO_EJECUTAR = 'RESPALDO.EJECUTAR';

  // Roles predefinidos
  ROL_ADMIN            = 'ADMIN';
  ROL_MEDICO           = 'MEDICO';
  ROL_ENFERMERIA       = 'ENFERMERIA';
  ROL_RECEPCION        = 'RECEPCION';
  ROL_ESTADISTICA      = 'ESTADISTICA';
  ROL_AUDITOR          = 'AUDITOR';
  ROL_DIRECCION_MEDICA = 'DIR_MED';

type
  TConjuntoPermisos = class
  private
    FLista: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Agregar(const APermiso: string);
    function Tiene(const APermiso: string): Boolean;
    procedure Limpiar;
    function ToStringArray: TStringArray;
  end;

implementation

constructor TConjuntoPermisos.Create;
begin
  inherited Create;
  FLista := TStringList.Create;
  FLista.Sorted := True;
  FLista.Duplicates := dupIgnore;
end;

destructor TConjuntoPermisos.Destroy;
begin
  FLista.Free;
  inherited Destroy;
end;

procedure TConjuntoPermisos.Agregar(const APermiso: string);
begin
  FLista.Add(APermiso);
end;

function TConjuntoPermisos.Tiene(const APermiso: string): Boolean;
begin
  Result := FLista.IndexOf(APermiso) <> -1;
end;

procedure TConjuntoPermisos.Limpiar;
begin
  FLista.Clear;
end;

function TConjuntoPermisos.ToStringArray: TStringArray;
var
  i: Integer;
begin
  SetLength(Result, FLista.Count);
  for i := 0 to FLista.Count - 1 do
    Result[i] := FLista[i];
end;

end.

