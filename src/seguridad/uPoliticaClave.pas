unit uPoliticaClave;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes;

type
  TPoliticaClave = class
  public
    class function ValidarClave(const AClave, ALogin, ACedula: string;
      out AMotivosFallo: TStringList): Boolean;
    class function ValidarPin(const APin: string; out AMotivoFallo: string): Boolean;
  end;

implementation

class function TPoliticaClave.ValidarClave(const AClave, ALogin, ACedula: string;
  out AMotivosFallo: TStringList): Boolean;
var
  i, Categorias: Integer;
  TieneMayus, TieneMinus, TieneDigito, TieneSimbolo: Boolean;
  C: Char;
begin
  AMotivosFallo := TStringList.Create;

  // RF-001-03: Longitud mínima 10 caracteres
  if Length(AClave) < 10 then
    AMotivosFallo.Add('La contrasena debe tener al menos 10 caracteres');

  // No igual a login ni cédula
  if (ALogin <> '') and (AnsiLowerCase(AClave) = AnsiLowerCase(ALogin)) then
    AMotivosFallo.Add('La contrasena no puede ser igual al nombre de usuario');

  if (ACedula <> '') and (AnsiLowerCase(AClave) = AnsiLowerCase(ACedula)) then
    AMotivosFallo.Add('La contrasena no puede ser igual a la cedula');

  TieneMayus := False;
  TieneMinus := False;
  TieneDigito := False;
  TieneSimbolo := False;

  for i := 1 to Length(AClave) do
  begin
    C := AClave[i];
    if C in ['A'..'Z'] then TieneMayus := True
    else if C in ['a'..'z'] then TieneMinus := True
    else if C in ['0'..'9'] then TieneDigito := True
    else TieneSimbolo := True;
  end;

  Categorias := 0;
  if TieneMayus then Inc(Categorias);
  if TieneMinus then Inc(Categorias);
  if TieneDigito then Inc(Categorias);
  if TieneSimbolo then Inc(Categorias);

  // Al menos 3 de 4 categorías
  if Categorias < 3 then
    AMotivosFallo.Add('La contrasena debe contener al menos 3 de los siguientes: mayusculas, minusculas, numeros, simbolos');

  Result := (AMotivosFallo.Count = 0);
end;

class function TPoliticaClave.ValidarPin(const APin: string; out AMotivoFallo: string): Boolean;
var
  i: Integer;
begin
  AMotivoFallo := '';
  // PIN de firma: 6 a 8 dígitos numéricos
  if (Length(APin) < 6) or (Length(APin) > 8) then
  begin
    AMotivoFallo := 'El PIN de firma debe tener entre 6 y 8 digitos';
    Exit(False);
  end;

  for i := 1 to Length(APin) do
  begin
    if not (APin[i] in ['0'..'9']) then
    begin
      AMotivoFallo := 'El PIN de firma solo debe contener numeros';
      Exit(False);
    end;
  end;

  Result := True;
end;

end.

