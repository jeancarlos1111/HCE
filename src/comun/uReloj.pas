unit uReloj;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, DateUtils;

type
  IReloj = interface
    ['{7E99A371-5588-4A59-8664-9F8C63E97F10}']
    function AhoraUtc: TDateTime;
    function AhoraUtcIso: string;
    function AhoraLocal: TDateTime;
    function FechaLocalIso: string;
  end;

  TRelojSistema = class(TInterfacedObject, IReloj)
  public
    function AhoraUtc: TDateTime;
    function AhoraUtcIso: string;
    function AhoraLocal: TDateTime;
    function FechaLocalIso: string;
  end;

implementation

{ TRelojSistema }

function TRelojSistema.AhoraUtc: TDateTime;
begin
  Result := LocalTimeToUniversal(Now);
end;

function TRelojSistema.AhoraUtcIso: string;
begin
  // Formato: YYYY-MM-DDTHH:NN:SS.ZZZ
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz', AhoraUtc);
end;

function TRelojSistema.AhoraLocal: TDateTime;
begin
  Result := Now;
end;

function TRelojSistema.FechaLocalIso: string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd', AhoraLocal);
end;

end.

