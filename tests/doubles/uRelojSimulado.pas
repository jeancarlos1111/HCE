unit uRelojSimulado;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, DateUtils, uReloj;

type
  TRelojSimulado = class(TInterfacedObject, IReloj)
  private
    FAhoraUtc: TDateTime;
    FDesfaseHorasLocal: Integer;
  public
    constructor Create(const AAhoraUtc: TDateTime; ADesfaseHorasLocal: Integer = -4);
    procedure FijarHoraUtc(const AAhoraUtc: TDateTime);
    procedure AvanzarMinutos(AMinutos: Integer);

    function AhoraUtc: TDateTime;
    function AhoraUtcIso: string;
    function AhoraLocal: TDateTime;
    function FechaLocalIso: string;
  end;

implementation

constructor TRelojSimulado.Create(const AAhoraUtc: TDateTime; ADesfaseHorasLocal: Integer);
begin
  inherited Create;
  FAhoraUtc := AAhoraUtc;
  FDesfaseHorasLocal := ADesfaseHorasLocal;
end;

procedure TRelojSimulado.FijarHoraUtc(const AAhoraUtc: TDateTime);
begin
  FAhoraUtc := AAhoraUtc;
end;

procedure TRelojSimulado.AvanzarMinutos(AMinutos: Integer);
begin
  FAhoraUtc := IncMinute(FAhoraUtc, AMinutos);
end;

function TRelojSimulado.AhoraUtc: TDateTime;
begin
  Result := FAhoraUtc;
end;

function TRelojSimulado.AhoraUtcIso: string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz', FAhoraUtc);
end;

function TRelojSimulado.AhoraLocal: TDateTime;
begin
  Result := IncHour(FAhoraUtc, FDesfaseHorasLocal);
end;

function TRelojSimulado.FechaLocalIso: string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd', AhoraLocal);
end;

end.

