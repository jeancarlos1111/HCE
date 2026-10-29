unit TestPoliticaClave;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uPoliticaClave;

type
  TTestPoliticaClave = class(TTestCase)
  published
    procedure TestClaveDemasiadoCortaRechazada;
    procedure TestClaveSinSuficientesCategoriasRechazada;
    procedure TestClaveIgualALoginOCedulaRechazada;
    procedure TestClaveCumplePoliticaAceptada;
    procedure TestPinInvalidoRechazado;
    procedure TestPinValidoAceptado;
  end;

implementation

procedure TTestPoliticaClave.TestClaveDemasiadoCortaRechazada;
var
  Motivos: TStringList;
begin
  AssertFalse(TPoliticaClave.ValidarClave('Ab1!', 'jperez', 'V-12345678', Motivos));
  try
    AssertTrue(Motivos.Text.Contains('al menos 10 caracteres'));
  finally
    Motivos.Free;
  end;
end;

procedure TTestPoliticaClave.TestClaveSinSuficientesCategoriasRechazada;
var
  Motivos: TStringList;
begin
  // Solo minúsculas
  AssertFalse(TPoliticaClave.ValidarClave('sololetrasminusculas', 'jperez', 'V-12345678', Motivos));
  try
    AssertTrue(Motivos.Text.Contains('al menos 3'));
  finally
    Motivos.Free;
  end;
end;

procedure TTestPoliticaClave.TestClaveIgualALoginOCedulaRechazada;
var
  Motivos: TStringList;
begin
  AssertFalse(TPoliticaClave.ValidarClave('jperez1234', 'jperez1234', 'V-12345678', Motivos));
  try
    AssertTrue(Motivos.Text.Contains('nombre de usuario'));
  finally
    Motivos.Free;
  end;
end;

procedure TTestPoliticaClave.TestClaveCumplePoliticaAceptada;
var
  Motivos: TStringList;
begin
  AssertTrue(TPoliticaClave.ValidarClave('ClaveRobusta2026!', 'jperez', 'V-12345678', Motivos));
  try
    AssertEquals(0, Motivos.Count);
  finally
    Motivos.Free;
  end;
end;

procedure TTestPoliticaClave.TestPinInvalidoRechazado;
var
  Motivo: string;
begin
  AssertFalse(TPoliticaClave.ValidarPin('1234', Motivo)); // muy corto
  AssertFalse(TPoliticaClave.ValidarPin('12345a', Motivo)); // contiene letras
end;

procedure TTestPoliticaClave.TestPinValidoAceptado;
var
  Motivo: string;
begin
  AssertTrue(TPoliticaClave.ValidarPin('123456', Motivo));
  AssertTrue(TPoliticaClave.ValidarPin('98765432', Motivo));
end;

initialization
  RegisterTest(TTestPoliticaClave);

end.

