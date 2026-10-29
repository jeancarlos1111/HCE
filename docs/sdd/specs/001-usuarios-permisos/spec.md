# Spec 001 — Usuarios, Autenticación y Permisos

- Épica: EP-01 · Historias: HU-001, HU-002, HU-022, HU-023, HU-024
- Estado: Borrador · PO: `[nombre]` · Fecha: 2026-10-29
- FHIR: `Practitioner`, `PractitionerRole`
- Normativa: [normativa-venezuela.md](../../normativa-venezuela.md) — CRBV art. 60, LOS art. 69, Ley Delitos Informáticos art. 6

## 1. Problema / Objetivo
HC contiene datos protegidos por secreto médico. Solo personal autorizado accede, cada acceso atribuible a persona identificada (con M.P.P.S./C.M. si es profesional). Objetivo: identidad única por usuario, autenticación robusta, permisos por rol con mínimo privilegio.

## 2. Actores
Administrador del sistema, Usuario (cualquier rol), Sistema (bloqueos automáticos).

## 3. Historias de usuario
- **HU-001** Como administrador quiero crear usuarios con rol(es) para controlar quién accede a qué.
- **HU-002** Como usuario quiero iniciar sesión con credenciales seguras para acceder al sistema.
- **HU-022** Como usuario quiero cambiar mi contraseña y PIN de firma para mantener mis credenciales seguras.
- **HU-023** Como sistema quiero bloquear sesión inactiva y cuentas con intentos fallidos para impedir accesos indebidos.
- **HU-024** Como médico quiero acceso de emergencia ("romper el cristal") a HC fuera de mi asignación, justificado y auditado, para atender urgencias.

## 4. Roles predefinidos (7)

| Rol | Descripción | Permisos clave |
|---|---|---|
| ADMIN | Administra sistema | Usuarios, roles, catálogos, respaldos. **Sin acceso a contenido clínico** |
| MEDICO | Médico tratante | Pacientes (L/E), HC SOAP (L/E/firmar/enmendar), antecedentes, diagnósticos CIE-10, estadística propia |
| ENFERMERIA | Enfermería | Pacientes (L), signos vitales (E), notas enfermería (E/firmar), HC (L) |
| RECEPCION | Admisión | Pacientes (L/E demográficos). **Sin contenido clínico** |
| ESTADISTICA | Registros y Estadísticas de Salud | Reportes estadísticos agregados + exportar CSV. **Sin contenido clínico** |
| AUDITOR | Auditoría / calidad | Log de auditoría (L), exportar auditoría. Sin editar nada |
| DIRECCION_MEDICA | Director médico | HC (L) todos los pacientes, estadísticas, aprobar fusiones, revisar accesos de emergencia |

Usuario puede tener varios roles; permisos = unión. Separación de funciones: ADMIN y AUDITOR incompatibles en mismo usuario.

## 5. Catálogo de permisos (granular)

Formato `RECURSO.ACCION`. Ejemplos:
`USUARIO.GESTIONAR`, `ROL.GESTIONAR`, `PACIENTE.LEER`, `PACIENTE.CREAR`, `PACIENTE.EDITAR`, `PACIENTE.CAMBIAR_ESTADO`, `PACIENTE.FUSIONAR`, `HC.LEER`, `HC.ESCRIBIR`, `HC.FIRMAR`, `HC.ENMENDAR`, `HC.IMPRIMIR`, `HC.EXPORTAR`, `HC.ACCESO_EMERGENCIA`, `ESTADISTICA.VER`, `ESTADISTICA.VER_PROPIA`, `ESTADISTICA.EXPORTAR`, `AUDITORIA.LEER`, `AUDITORIA.EXPORTAR`, `CATALOGO.GESTIONAR`, `RESPALDO.EJECUTAR`.

Matriz rol–permiso inicial en `plan.md` §4 (seed de migración).

## 6. Requisitos funcionales

| ID | Requisito | Prioridad |
|---|---|---|
| RF-001-01 | Usuario: login único, nombre completo, cédula (V/E) única, email, teléfono, rol(es), estado (Activo/Bloqueado/Inactivo) | Must |
| RF-001-02 | Profesional de salud: tipo (médico, enfermería, bioanalista…), M.P.P.S., Colegio + nro + estado, especialidad(es). M.P.P.S. obligatorio si rol MEDICO o ENFERMERIA | Must |
| RF-001-03 | Contraseña: ≥ 10 caracteres, al menos 3 de 4 tipos (mayús, minús, dígito, símbolo), no igual a login/cédula, no repetir últimas 5 | Must |
| RF-001-04 | Contraseña almacenada con Argon2id (ADR-002); nunca en claro ni en logs | Must |
| RF-001-05 | Alta de usuario genera contraseña temporal; cambio obligatorio en primer login | Must |
| RF-001-06 | 5 intentos fallidos consecutivos → bloqueo 15 min; 10 en 24 h → bloqueo hasta desbloqueo por ADMIN | Must |
| RF-001-07 | Mensaje de error genérico ("credenciales inválidas"), sin revelar si existe el usuario | Must |
| RF-001-08 | Inactividad 10 min → pantalla bloqueada (requiere contraseña, conserva borradores) | Must |
| RF-001-09 | Caducidad de contraseña 180 días `[POR CONFIRMAR]` | Should |
| RF-001-10 | PIN de firma (6–8 dígitos) separado de contraseña, para HC.FIRMAR (Spec 008) | Must |
| RF-001-11 | Usuarios nunca se borran; se inactivan (preserva autoría de registros) | Must |
| RF-001-12 | Toda verificación de permiso pasa por servicio central `IAutorizacion`; UI oculta/deshabilita opciones sin permiso, pero servicio **siempre** revalida | Must |
| RF-001-13 | Acceso de emergencia: requiere `HC.ACCESO_EMERGENCIA`, motivo obligatorio (≥ 20 caracteres), vigencia 24 h, notifica a DIRECCION_MEDICA | Should |
| RF-001-14 | Una sesión activa por usuario por equipo; registrar equipo (hostname, IP) | Should |
| RF-001-15 | Primer arranque: asistente crea ADMIN inicial; sin credenciales por defecto | Must |
| RF-001-16 | ADMIN puede resetear contraseña (genera temporal) pero no verla ni fijarla | Must |

## 7. Criterios de aceptación (Gherkin)

```gherkin
Característica: Autenticación

  Escenario: Login exitoso
    Dado usuario "jperez" activo con contraseña válida
    Cuando ingresa login y contraseña correctos
    Entonces accede al menú principal según sus roles
    Y se audita "LOGIN_OK" con equipo e IP

  Escenario: Credenciales inválidas
    Cuando ingresa contraseña incorrecta
    Entonces ve "Usuario o contraseña inválidos"
    Y se audita "LOGIN_FALLIDO"
    Y el mismo mensaje aparece si el usuario no existe

  Escenario: Bloqueo temporal por intentos
    Dado "jperez" falló 4 veces consecutivas
    Cuando falla por quinta vez
    Entonces la cuenta queda bloqueada 15 minutos
    Y se audita "CUENTA_BLOQUEADA"
    Y aun con contraseña correcta no puede entrar hasta que expire

  Escenario: Primer login con contraseña temporal
    Dado usuario recién creado
    Cuando inicia sesión con contraseña temporal
    Entonces debe definir nueva contraseña y PIN de firma antes de continuar

  Escenario: Contraseña débil
    Cuando intenta definir contraseña "clinica123"
    Entonces el sistema la rechaza indicando reglas incumplidas

  Escenario: Bloqueo por inactividad
    Dado usuario con sesión abierta y nota en borrador
    Cuando pasan 10 minutos sin actividad
    Entonces la pantalla se bloquea
    Y al reingresar contraseña continúa con el borrador intacto

Característica: Gestión de usuarios

  Escenario: Alta de médico
    Dado ADMIN autenticado
    Cuando crea usuario con rol MEDICO sin M.P.P.S.
    Entonces el sistema rechaza indicando M.P.P.S. obligatorio

  Escenario: Cédula duplicada
    Dado existe usuario con cédula "V-12345678"
    Cuando ADMIN crea otro usuario con "V-12345678"
    Entonces el sistema lo rechaza

  Escenario: Separación de funciones
    Cuando ADMIN asigna roles ADMIN y AUDITOR al mismo usuario
    Entonces el sistema lo rechaza

  Escenario: ADMIN sin acceso clínico
    Dado usuario solo con rol ADMIN
    Cuando intenta abrir la HC de un paciente
    Entonces el sistema deniega y audita "ACCESO_DENEGADO"

  Escenario: Inactivar usuario con registros
    Dado médico con notas firmadas
    Cuando ADMIN lo inactiva
    Entonces no puede iniciar sesión
    Y sus notas siguen mostrando su nombre y M.P.P.S.

Característica: Autorización

  Escenario: Revalidación en servicio
    Dado usuario RECEPCION
    Cuando se invoca HCService.Escribir directamente (sin UI)
    Entonces el servicio lanza EAccesoDenegado y audita

  Escenario: Acceso de emergencia
    Dado médico con permiso HC.ACCESO_EMERGENCIA sin relación con paciente X
    Cuando solicita acceso de emergencia con motivo "Paciente inconsciente en emergencia, sin médico tratante"
    Entonces obtiene acceso de lectura/escritura por 24 h
    Y se audita "ACCESO_EMERGENCIA" con motivo
    Y DIRECCION_MEDICA ve alerta pendiente de revisión
```

## 8. Requisitos no funcionales
- RNF-001-a: Verificación de contraseña 200–500 ms (frena fuerza bruta, tolerable para usuario).
- RNF-001-b: Chequeo de permiso en memoria < 1 ms (caché de permisos de sesión, invalidada al cambiar roles).

## 9. Fuera de alcance
LDAP/Active Directory, 2FA (OTP), SSO, certificado X.509 SUSCERTE (va en Spec 008 Firma).

## 10. Preguntas abiertas
- ¿Relación asistencial obligatoria (médico solo ve pacientes asignados/atendidos) o médico ve todos? Propuesta MVP: todos los médicos ven todo, auditado; restricción por relación en release 2.
- ¿Caducidad de contraseña requerida por la institución?
- ¿Roles adicionales (bioanalista, farmacia, psicología)?

