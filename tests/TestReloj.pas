unit TestReloj;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, fpcunit, testregistry, uReloj, uRelojSimulado;

type
  TTestReloj = class(TTestCase)
  published
    procedure TestRelojSimuladoAvanzaMinutos;
    procedure TestRelojSistemaRetornaIsoValido;
  end;

implementation

procedure TTestReloj.TestRelojSimuladoAvanzaMinutos;
var
  Reloj: TRelojSimulado;
  TInicial: TDateTime;
begin
  TInicial := EncodeDateTime(2026, 10, 29, 12, 0, 0, 0);
  Reloj := TRelojSimulado.Create(TInicial, -4);
  try
    AssertEquals('2026-10-29T12:00:00.000', Reloj.AhoraUtcIso);
    AssertEquals('2026-10-29', Reloj.FechaLocalIso); // 12h - 4 = 8h local

    Reloj.AvanzarMinutos(30);
    AssertEquals('2026-10-29T12:30:00.000', Reloj.AhoraUtcIso);
  finally
    Reloj.Free;
  end;
end;

procedure TTestReloj.TestRelojSistemaRetornaIsoValido;
var
  Reloj: IReloj;
  S: string;
begin
  Reloj := TRelojSistema.Create;
  S := Reloj.AhoraUtcIso;
  AssertTrue('Debe contener T como separador ISO', Pos('T', S) > 0);
  AssertTrue('Longitud debe ser al menos 23 caracteres', Length(S) >= 23);
end;

initialization
  RegisterTest(TTestReloj);

end.
