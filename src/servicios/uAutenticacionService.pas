unit uAutenticacionService;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, DateUtils, Classes,
  uReloj, uPasswordHasher, uPoliticaClave, uUsuario, uUsuarioRepository,
  uAuditoria, uEventoAuditoria, uSesion;

type
  ECredencialesInvalidas = class(Exception);
  ECuentaBloqueada = class(Exception);
  EClaveInvalida = class(Exception);

  TAutenticacionService = class
  private
    FRepo: IUsuarioRepository;
    FHasher: IPasswordHasher;
    FAuditoria: IAuditoria;
    FReloj: IReloj;
  public
    constructor Create(ARepo: IUsuarioRepository; AHasher: IPasswordHasher;
      AAuditoria: IAuditoria; AReloj: IReloj);

    function Login(const ALogin, AClave, AEquipo, AIp: string): TSesion;
    procedure CambiarClaveYPin(AUsuarioId: Int64; const AClaveActual, ANuevaClave, ANuevoPin: string);
    procedure DesbloquearCuenta(AUsuarioId: Int64; AAdminId: Int64);
  end;

implementation

constructor TAutenticacionService.Create(ARepo: IUsuarioRepository; AHasher: IPasswordHasher;
  AAuditoria: IAuditoria; AReloj: IReloj);
begin
  inherited Create;
  FRepo := ARepo;
  FHasher := AHasher;
  FAuditoria := AAuditoria;
  FReloj := AReloj;
end;

function TAutenticacionService.Login(const ALogin, AClave, AEquipo, AIp: string): TSesion;
var
  Usuario: TUsuario;
  Evento: TEventoAuditoria;
  ClaveValida: Boolean;
  Ahora: TDateTime;
  BloqueadoHasta: TDateTime;
  Permisos: TStringArray;
  i: Integer;
  HashDummyVar: string;
const
  HASH_DUMMY = '$pbkdf2-sha256$i=1000$00000000000000000000000000000000$0000000000000000000000000000000000000000000000000000000000000000';
begin
  FillChar(Evento, SizeOf(Evento), 0);
  Evento.LoginTxt := ALogin;
  Evento.Equipo := AEquipo;
  Evento.Ip := AIp;
  Evento.Entidad := 'USUARIO';

  Usuario := FRepo.ObtenerPorLogin(ALogin);

  // 1. Caso: Usuario no existe (tiempo constante para no delatar existencia)
  if Usuario = nil then
  begin
    HashDummyVar := HASH_DUMMY;
    FHasher.VerificarClave(AClave, HashDummyVar);
    Evento.Accion := AUD_LOGIN_FALLIDO;
    Evento.Resultado := raDenegado;
    Evento.Motivo := 'Credenciales invalidas';
    FAuditoria.RegistrarIndependiente(Evento);
    raise ECredencialesInvalidas.Create('Usuario o contrasena invalidos');
  end;

  try
    Evento.UsuarioId := Usuario.Id;
    Evento.EntidadId := IntToStr(Usuario.Id);
    Evento.Roles := Usuario.Roles.CommaText;

    // 2. Caso: Usuario inactivo
    if Usuario.Estado = euInactivo then
    begin
      Evento.Accion := AUD_LOGIN_FALLIDO;
      Evento.Resultado := raDenegado;
      Evento.Motivo := 'Cuenta inactiva';
      FAuditoria.RegistrarIndependiente(Evento);
      raise ECredencialesInvalidas.Create('Usuario o contrasena invalidos');
    end;

    // 3. Caso: Usuario bloqueado temporalmente
    Ahora := FReloj.AhoraUtc;
    if (Usuario.Estado = euBloqueado) and (Usuario.BloqueadoHastaUtc <> '') then
    begin
      if TryISO8601ToDate(Usuario.BloqueadoHastaUtc, BloqueadoHasta, True) then
      begin
        if Ahora < BloqueadoHasta then
        begin
          Evento.Accion := AUD_LOGIN_BLOQUEADO;
          Evento.Resultado := raDenegado;
          Evento.Motivo := 'Cuenta bloqueada temporalmente';
          FAuditoria.RegistrarIndependiente(Evento);
          raise ECuentaBloqueada.CreateFmt('Cuenta bloqueada temporalmente por intentos fallidos hasta %s', [Usuario.BloqueadoHastaUtc]);
        end
        else
        begin
          // Expiró el bloqueo temporal de 15 min: restablecer
          Usuario.Estado := euActivo;
          Usuario.IntentosFallidos := 0;
          Usuario.BloqueadoHastaUtc := '';
          FRepo.ActualizarSeguridad(Usuario.Id, 0, euActivo, '');
        end;
      end;
    end;

    // 4. Verificar clave
    ClaveValida := FHasher.VerificarClave(AClave, Usuario.ClaveHash);
    if not ClaveValida then
    begin
      Usuario.IntentosFallidos := Usuario.IntentosFallidos + 1;

      // Regla RF-001-06: 5 intentos fallidos -> bloqueo 15 min
      if Usuario.IntentosFallidos >= 5 then
      begin
        Usuario.Estado := euBloqueado;
        Usuario.BloqueadoHastaUtc := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz', IncMinute(Ahora, 15));
        FRepo.ActualizarSeguridad(Usuario.Id, Usuario.IntentosFallidos, euBloqueado, Usuario.BloqueadoHastaUtc);

        Evento.Accion := AUD_CUENTA_BLOQUEADA;
        Evento.Resultado := raDenegado;
        Evento.Motivo := 'Bloqueo temporal por 5 intentos fallidos';
        FAuditoria.RegistrarIndependiente(Evento);
      end
      else
      begin
        FRepo.ActualizarSeguridad(Usuario.Id, Usuario.IntentosFallidos, Usuario.Estado, Usuario.BloqueadoHastaUtc);
        Evento.Accion := AUD_LOGIN_FALLIDO;
        Evento.Resultado := raDenegado;
        Evento.Motivo := Format('Intento fallido %d de 5', [Usuario.IntentosFallidos]);
        FAuditoria.RegistrarIndependiente(Evento);
      end;

      raise ECredencialesInvalidas.Create('Usuario o contrasena invalidos');
    end;

    // 5. Login Exitoso: resetear intentos
    if Usuario.IntentosFallidos > 0 then
      FRepo.ActualizarSeguridad(Usuario.Id, 0, euActivo, '');

    Result := TSesion.Create(
      Usuario.Id,
      Usuario.Login,
      Usuario.Nombres + ' ' + Usuario.Apellidos,
      Usuario.Cedula,
      AEquipo,
      AIp,
      Usuario.ClaveTemporal
    );

    for i := 0 to Usuario.Roles.Count - 1 do
      Result.AgregarRol(Usuario.Roles[i]);

    Permisos := FRepo.ObtenerPermisosDeRoles(Usuario.Roles);
    for i := 0 to High(Permisos) do
      Result.AgregarPermiso(Permisos[i]);

    Evento.Accion := AUD_LOGIN_OK;
    Evento.Resultado := raOK;
    Evento.Motivo := 'Inicio de sesion exitoso';
    FAuditoria.RegistrarIndependiente(Evento);
  finally
    Usuario.Free;
  end;
end;

procedure TAutenticacionService.CambiarClaveYPin(AUsuarioId: Int64; const AClaveActual, ANuevaClave, ANuevoPin: string);
var
  Usuario: TUsuario;
  Motivos: TStringList;
  MotivoPin: string;
  NuevaClaveHash, NuevoPinHash, FechaUtc: string;
  Evento: TEventoAuditoria;
begin
  Usuario := FRepo.ObtenerPorId(AUsuarioId);
  if Usuario = nil then
    raise Exception.Create('Usuario no encontrado');

  try
    // 1. Validar clave actual si no es obligatoriamente primer arranque
    if (AClaveActual <> '') and not FHasher.VerificarClave(AClaveActual, Usuario.ClaveHash) then
      raise EClaveInvalida.Create('La contrasena actual no coincide');

    // 2. Validar política de nueva clave
    if not TPoliticaClave.ValidarClave(ANuevaClave, Usuario.Login, Usuario.Cedula, Motivos) then
    begin
      try
        raise EClaveInvalida.Create(Motivos.Text);
      finally
        Motivos.Free;
      end;
    end;
    Motivos.Free;

    // 3. Validar PIN
    NuevoPinHash := '';
    if ANuevoPin <> '' then
    begin
      if not TPoliticaClave.ValidarPin(ANuevoPin, MotivoPin) then
        raise EClaveInvalida.Create(MotivoPin);
      NuevoPinHash := FHasher.HashPin(ANuevoPin);
    end;

    NuevaClaveHash := FHasher.HashClave(ANuevaClave);
    FechaUtc := FReloj.AhoraUtcIso;

    FRepo.CambiarClaveYPin(AUsuarioId, NuevaClaveHash, NuevoPinHash, FechaUtc);

    FillChar(Evento, SizeOf(Evento), 0);
    Evento.UsuarioId := AUsuarioId;
    Evento.LoginTxt := Usuario.Login;
    Evento.Accion := AUD_CLAVE_CAMBIADA;
    Evento.Entidad := 'USUARIO';
    Evento.EntidadId := IntToStr(AUsuarioId);
    Evento.Resultado := raOK;
    Evento.Motivo := 'Actualizacion de contrasena y PIN';
    FAuditoria.RegistrarIndependiente(Evento);
  finally
    Usuario.Free;
  end;
end;

procedure TAutenticacionService.DesbloquearCuenta(AUsuarioId: Int64; AAdminId: Int64);
var
  Usuario: TUsuario;
  Evento: TEventoAuditoria;
begin
  Usuario := FRepo.ObtenerPorId(AUsuarioId);
  if Usuario = nil then
    raise Exception.Create('Usuario no encontrado');

  try
    FRepo.ActualizarSeguridad(AUsuarioId, 0, euActivo, '');

    FillChar(Evento, SizeOf(Evento), 0);
    Evento.UsuarioId := AAdminId;
    Evento.Accion := AUD_CUENTA_DESBLOQUEADA;
    Evento.Entidad := 'USUARIO';
    Evento.EntidadId := IntToStr(AUsuarioId);
    Evento.Resultado := raOK;
    Evento.Motivo := Format('Cuenta %s desbloqueada por administrador', [Usuario.Login]);
    FAuditoria.RegistrarIndependiente(Evento);
  finally
    Usuario.Free;
  end;
end;

end.
