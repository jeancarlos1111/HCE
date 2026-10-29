unit uAutorizacion;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, uSesion;

type
  EAccesoDenegado = class(Exception);

  IAutorizacion = interface
    ['{F54BE978-B549-41C6-8E38-66519E8EFD78}']
    function Tiene(const APermiso: string): Boolean;
    procedure Exigir(const APermiso: string);
    function ObtenerSesion: TSesion;
  end;

  TAutorizacion = class(TInterfacedObject, IAutorizacion)
  private
    FSesion: TSesion;
  public
    constructor Create(ASesion: TSesion);
    function Tiene(const APermiso: string): Boolean;
    procedure Exigir(const APermiso: string);
    function ObtenerSesion: TSesion;
  end;

implementation

constructor TAutorizacion.Create(ASesion: TSesion);
begin
  inherited Create;
  FSesion := ASesion;
end;

function TAutorizacion.Tiene(const APermiso: string): Boolean;
begin
  if FSesion = nil then
    Exit(False);
  Result := FSesion.TienePermiso(APermiso);
end;

procedure TAutorizacion.Exigir(const APermiso: string);
begin
  if not Tiene(APermiso) then
    raise EAccesoDenegado.CreateFmt('Acceso denegado: requiere permiso %s', [APermiso]);
end;

function TAutorizacion.ObtenerSesion: TSesion;
begin
  Result := FSesion;
end;

end.

