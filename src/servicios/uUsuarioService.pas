unit uUsuarioService;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  uUsuario, uUsuarioRepository, uAutorizacion, uPermisos, uSesion,
  uAuditoria, uEventoAuditoria, uReloj, uPasswordHasher, uPoliticaClave;

type
  EUsuarioInvalido = class(Exception);

  TUsuarioService = class
  private
    FRepo: IUsuarioRepository;
    FAutorizacion: IAutorizacion;
    FAuditoria: IAuditoria;
    FReloj: IReloj;
    FHasher: IPasswordHasher;
  public
    constructor Create(ARepo: IUsuarioRepository; AAutorizacion: IAutorizacion;
      AAuditoria: IAuditoria; AReloj: IReloj; AHasher: IPasswordHasher);

    function CrearUsuario(AUsuario: TUsuario; const AClaveInicial: string): Int64;
    procedure ActualizarUsuario(AUsuario: TUsuario);
    procedure InactivarUsuario(AId: Int64; const AMotivo: string);
    function ResetearClave(AId: Int64; const AClaveTemporal: string): string;
  end;

implementation

constructor TUsuarioService.Create(ARepo: IUsuarioRepository; AAutorizacion: IAutorizacion;
  AAuditoria: IAuditoria; AReloj: IReloj; AHasher: IPasswordHasher);
begin
  inherited Create;
  FRepo := ARepo;
  FAutorizacion := AAutorizacion;
  FAuditoria := AAuditoria;
  FReloj := AReloj;
  FHasher := AHasher;
end;

function TUsuarioService.CrearUsuario(AUsuario: TUsuario; const AClaveInicial: string): Int64;
var
  i, j: Integer;
  RolA, RolB: string;
  Evento: TEventoAuditoria;
  Sesion: TSesion;
  AdminId: Int64;
begin
  AdminId := 0;
  if FAutorizacion <> nil then
  begin
    FAutorizacion.Exigir(PERM_USUARIO_GESTIONAR);
    Sesion := FAutorizacion.ObtenerSesion;
    if Sesion <> nil then AdminId := Sesion.UsuarioId;
  end;

  // 1. Validaciones básicas
  if Trim(AUsuario.Login) = '' then
    raise EUsuarioInvalido.Create('El nombre de usuario es obligatorio');

  if Trim(AUsuario.Cedula) = '' then
    raise EUsuarioInvalido.Create('La cedula es obligatoria');

  if Trim(AUsuario.Nombres) = '' then
    raise EUsuarioInvalido.Create('Los nombres son obligatorios');

  if Trim(AUsuario.Apellidos) = '' then
    raise EUsuarioInvalido.Create('Los apellidos son obligatorios');

  // 2. Unicidad de Login y Cédula
  if FRepo.ObtenerPorLogin(AUsuario.Login) <> nil then
    raise EUsuarioInvalido.CreateFmt('El usuario con login "%s" ya existe', [AUsuario.Login]);

  if FRepo.ObtenerPorCedula(AUsuario.Cedula) <> nil then
    raise EUsuarioInvalido.CreateFmt('El usuario con cedula "%s" ya existe', [AUsuario.Cedula]);

  // 3. Regla separación de funciones (Roles incompatibles)
  for i := 0 to AUsuario.Roles.Count - 1 do
  begin
    RolA := AUsuario.Roles[i];
    for j := i + 1 to AUsuario.Roles.Count - 1 do
    begin
      RolB := AUsuario.Roles[j];
      if FRepo.SonRolesIncompatibles(RolA, RolB) then
        raise EUsuarioInvalido.CreateFmt('Conflicto de separacion de funciones: roles %s y %s son incompatibles', [RolA, RolB]);
    end;
  end;

  // 4. Regla profesional de salud (M.P.P.S. obligatorio para médico y enfermería)
  if (AUsuario.Roles.IndexOf(ROL_MEDICO) <> -1) or (AUsuario.Roles.IndexOf(ROL_ENFERMERIA) <> -1) then
  begin
    if not AUsuario.EsProfesional or (Trim(AUsuario.Profesional.Mpps) = '') then
      raise EUsuarioInvalido.Create('La matricula M.P.P.S. es obligatoria para medicos y enfermeros');

    if FRepo.MppsExiste(AUsuario.Profesional.Mpps) then
      raise EUsuarioInvalido.CreateFmt('La matricula M.P.P.S. "%s" ya esta registrada', [AUsuario.Profesional.Mpps]);
  end;

  // 5. Cifrado de clave inicial
  AUsuario.ClaveHash := FHasher.HashClave(AClaveInicial);
  AUsuario.ClaveTemporal := True;
  AUsuario.CreadoUtc := FReloj.AhoraUtcIso;
  AUsuario.CreadoPor := AdminId;

  Result := FRepo.Crear(AUsuario);

  FillChar(Evento, SizeOf(Evento), 0);
  Evento.UsuarioId := AdminId;
  Evento.Accion := AUD_USUARIO_CREAR;
  Evento.Entidad := 'USUARIO';
  Evento.EntidadId := IntToStr(Result);
  Evento.Resultado := raOK;
  Evento.Motivo := Format('Creacion de usuario %s (%s)', [AUsuario.Login, AUsuario.Roles.CommaText]);
  FAuditoria.RegistrarIndependiente(Evento);
end;

procedure TUsuarioService.ActualizarUsuario(AUsuario: TUsuario);
var
  i, j: Integer;
  RolA, RolB: string;
  Evento: TEventoAuditoria;
  Sesion: TSesion;
  AdminId: Int64;
begin
  AdminId := 0;
  if FAutorizacion <> nil then
  begin
    FAutorizacion.Exigir(PERM_USUARIO_GESTIONAR);
    Sesion := FAutorizacion.ObtenerSesion;
    if Sesion <> nil then AdminId := Sesion.UsuarioId;
  end;

  // Incompatibilidad
  for i := 0 to AUsuario.Roles.Count - 1 do
  begin
    RolA := AUsuario.Roles[i];
    for j := i + 1 to AUsuario.Roles.Count - 1 do
    begin
      RolB := AUsuario.Roles[j];
      if FRepo.SonRolesIncompatibles(RolA, RolB) then
        raise EUsuarioInvalido.CreateFmt('Conflicto de roles incompatibles: %s y %s', [RolA, RolB]);
    end;
  end;

  if (AUsuario.Roles.IndexOf(ROL_MEDICO) <> -1) or (AUsuario.Roles.IndexOf(ROL_ENFERMERIA) <> -1) then
  begin
    if not AUsuario.EsProfesional or (Trim(AUsuario.Profesional.Mpps) = '') then
      raise EUsuarioInvalido.Create('M.P.P.S. es obligatorio para personal asistencial');

    if FRepo.MppsExiste(AUsuario.Profesional.Mpps, AUsuario.Id) then
      raise EUsuarioInvalido.CreateFmt('La matricula M.P.P.S. "%s" ya pertenece a otro profesional', [AUsuario.Profesional.Mpps]);
  end;

  FRepo.Actualizar(AUsuario);

  FillChar(Evento, SizeOf(Evento), 0);
  Evento.UsuarioId := AdminId;
  Evento.Accion := AUD_USUARIO_EDITAR;
  Evento.Entidad := 'USUARIO';
  Evento.EntidadId := IntToStr(AUsuario.Id);
  Evento.Resultado := raOK;
  Evento.Motivo := 'Actualizacion de datos y roles de usuario';
  FAuditoria.RegistrarIndependiente(Evento);
end;

procedure TUsuarioService.InactivarUsuario(AId: Int64; const AMotivo: string);
var
  Usuario: TUsuario;
  Evento: TEventoAuditoria;
  Sesion: TSesion;
  AdminId: Int64;
begin
  AdminId := 0;
  if FAutorizacion <> nil then
  begin
    FAutorizacion.Exigir(PERM_USUARIO_GESTIONAR);
    Sesion := FAutorizacion.ObtenerSesion;
    if Sesion <> nil then AdminId := Sesion.UsuarioId;
  end;

  Usuario := FRepo.ObtenerPorId(AId);
  if Usuario = nil then
    raise Exception.Create('Usuario no encontrado');

  try
    Usuario.Estado := euInactivo;
    FRepo.ActualizarSeguridad(AId, Usuario.IntentosFallidos, euInactivo, '');

    FillChar(Evento, SizeOf(Evento), 0);
    Evento.UsuarioId := AdminId;
    Evento.Accion := AUD_USUARIO_INACTIVAR;
    Evento.Entidad := 'USUARIO';
    Evento.EntidadId := IntToStr(AId);
    Evento.Resultado := raOK;
    Evento.Motivo := AMotivo;
    FAuditoria.RegistrarIndependiente(Evento);
  finally
    Usuario.Free;
  end;
end;

function TUsuarioService.ResetearClave(AId: Int64; const AClaveTemporal: string): string;
var
  Usuario: TUsuario;
  ClaveHash, FechaUtc: string;
  Evento: TEventoAuditoria;
  Sesion: TSesion;
  AdminId: Int64;
begin
  AdminId := 0;
  if FAutorizacion <> nil then
  begin
    FAutorizacion.Exigir(PERM_USUARIO_GESTIONAR);
    Sesion := FAutorizacion.ObtenerSesion;
    if Sesion <> nil then AdminId := Sesion.UsuarioId;
  end;

  Usuario := FRepo.ObtenerPorId(AId);
  if Usuario = nil then
    raise Exception.Create('Usuario no encontrado');

  try
    ClaveHash := FHasher.HashClave(AClaveTemporal);
    FechaUtc := FReloj.AhoraUtcIso;

    FRepo.CambiarClaveYPin(AId, ClaveHash, '', FechaUtc);
    // Vuelve a marcar temporal
    FRepo.ActualizarSeguridad(AId, 0, euActivo, '');

    FillChar(Evento, SizeOf(Evento), 0);
    Evento.UsuarioId := AdminId;
    Evento.Accion := AUD_CLAVE_CAMBIADA;
    Evento.Entidad := 'USUARIO';
    Evento.EntidadId := IntToStr(AId);
    Evento.Resultado := raOK;
    Evento.Motivo := 'Reseteo de contrasena por administrador';
    FAuditoria.RegistrarIndependiente(Evento);

    Result := AClaveTemporal;
  finally
    Usuario.Free;
  end;
end;

end.
