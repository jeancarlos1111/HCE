unit uSesion;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uPermisos;

type
  TSesion = class
  private
    FUsuarioId: Int64;
    FLogin: string;
    FNombreCompleto: string;
    FCedula: string;
    FRoles: TStringList;
    FPermisos: TConjuntoPermisos;
    FEquipo: string;
    FIp: string;
    FInicioUtc: TDateTime;
    FDebeCambiarClave: Boolean;
  public
    constructor Create(AUsuarioId: Int64; const ALogin, ANombreCompleto, ACedula, AEquipo, AIp: string;
      ADebeCambiarClave: Boolean);
    destructor Destroy; override;

    procedure AgregarRol(const ARol: string);
    procedure AgregarPermiso(const APermiso: string);
    function TienePermiso(const APermiso: string): Boolean;
    function TieneRol(const ARol: string): Boolean;

    property UsuarioId: Int64 read FUsuarioId;
    property Login: string read FLogin;
    property NombreCompleto: string read FNombreCompleto;
    property Cedula: string read FCedula;
    property Equipo: string read FEquipo;
    property Ip: string read FIp;
    property DebeCambiarClave: Boolean read FDebeCambiarClave write FDebeCambiarClave;
    property Roles: TStringList read FRoles;
    property Permisos: TConjuntoPermisos read FPermisos;
  end;

implementation

constructor TSesion.Create(AUsuarioId: Int64; const ALogin, ANombreCompleto, ACedula, AEquipo, AIp: string;
  ADebeCambiarClave: Boolean);
begin
  inherited Create;
  FUsuarioId := AUsuarioId;
  FLogin := ALogin;
  FNombreCompleto := ANombreCompleto;
  FCedula := ACedula;
  FEquipo := AEquipo;
  FIp := AIp;
  FDebeCambiarClave := ADebeCambiarClave;

  FRoles := TStringList.Create;
  FRoles.Sorted := True;
  FRoles.Duplicates := dupIgnore;

  FPermisos := TConjuntoPermisos.Create;
end;

destructor TSesion.Destroy;
begin
  FPermisos.Free;
  FRoles.Free;
  inherited Destroy;
end;

procedure TSesion.AgregarRol(const ARol: string);
begin
  FRoles.Add(ARol);
end;

procedure TSesion.AgregarPermiso(const APermiso: string);
begin
  FPermisos.Agregar(APermiso);
end;

function TSesion.TienePermiso(const APermiso: string): Boolean;
begin
  Result := FPermisos.Tiene(APermiso);
end;

function TSesion.TieneRol(const ARol: string): Boolean;
begin
  Result := FRoles.IndexOf(ARol) <> -1;
end;

end.

