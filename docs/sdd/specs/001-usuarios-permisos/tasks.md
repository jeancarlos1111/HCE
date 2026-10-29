# Tareas 001 — Usuarios y Permisos

Ref: [spec.md](spec.md) · [plan.md](plan.md). `[P]` = paralelizable.

| ID | Tarea | Traza | Est. | Estado |
|---|---|---|---|---|
| T-001-01 | Migración `002_usuarios.sql` (tablas, checks, trigger no-delete) | plan §3 | 0.5d | ☑ |
| T-001-02 | Migración `004_seed_roles.sql` (roles, permisos, matriz, incompatibles) | plan §4 | 0.5d | ☑ |
| T-001-03 | `uPermisos.pas` constantes + `uUsuario.pas` entidades | §5, RF-001-01/02 | 0.5d | ☑ |
| T-001-04 [P] | Tests + `uSha256` + `TPBKDF2PasswordHasher` | RF-001-04, ADR-002 | 1d | ☑ |
| T-001-05 [P] | Tests + `TPoliticaClave` | RF-001-03 | 0.5d | ☑ |
| T-001-06 | `IUsuarioRepository` en memoria + SQLite, test integración (`:memory:`) | plan §3 | 1d | ☑ |
| T-001-07 | Tests `TAutenticacionService` (login ok/fallido/inexistente/bloqueo/temporal) con `IReloj` falso | Gherkin autenticación | 1d | ☑ |
| T-001-08 | `TAutenticacionService` (login, logout, cambio clave/PIN, desbloqueo) | RF-001-05..07/10 | 1d | ☑ |
| T-001-09 | Tests + `TSesion` y `IAutorizacion` (matriz rol×permiso) | RF-001-12 | 1d | ☑ |
| T-001-10 | Tests + `TUsuarioService` (crear, M.P.P.S., cédula, roles incompatibles, inactivar, reset) | RF-001-01/02/11/16 | 1d | ☑ |
| T-001-11 | `frmPrimerArranque` (ADMIN inicial) | RF-001-15 | 0.5d | ☐ |
| T-001-12 | `frmLogin` + `frmCambioClave` (primer login: clave + PIN) | HU-002, HU-022 | 1d | ☑ |
| T-001-13 | `TMonitorInactividad` + `frmBloqueo` (conserva estado) | RF-001-08 | 1d | ☐ |
| T-001-14 | `frmUsuarios` + `frmUsuarioEditar` (sección profesional) | HU-001 | 1d | ☑ |
| T-001-15 | Menú principal habilitado por permisos | RF-001-12 | 0.5d | ☐ |
| T-001-16 | `TAccesoEmergenciaService` + diálogo motivo + alerta DIR_MED | HU-024, RF-001-13 | 1d | ☐ |
| T-001-17 | Check CI: sin clave/PIN en logs | plan §7 | 0.25d | ☐ |
| T-001-18 | Verificación manual Gherkin + demo PO | DoD | 0.5d | ☐ |

Total ≈ 13 d → HU-024 (T-001-16) puede pasar a Sprint 2 si no cabe.

