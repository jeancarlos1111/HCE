unit uAuditoria;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, uEventoAuditoria;

type
  IAuditoria = interface
    ['{E4348270-4E11-477F-99F7-7033C8DEBE2E}']
    function Registrar(const Evento: TEventoAuditoria): Int64;
    function RegistrarIndependiente(const Evento: TEventoAuditoria): Int64;
  end;

implementation

end.

