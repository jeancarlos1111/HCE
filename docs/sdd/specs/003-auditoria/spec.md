# Spec 003 — Auditoría y Trazabilidad

- Épica: EP-09 · Historias: HU-003, HU-025, HU-026, HU-027
- Estado: Borrador · PO: `[nombre]` · Fecha: 2026-10-29
- FHIR: `AuditEvent`
- Normativa: CRBV art. 28 (habeas data), Ley Delitos Informáticos arts. 6, 20–22, Ley Mensajes de Datos art. 4 (eficacia probatoria) — ver [normativa-venezuela.md](../../normativa-venezuela.md)

## 1. Problema / Objetivo
Ante reclamo, peritaje o acceso indebido hay que probar **quién hizo qué, cuándo, desde dónde y sobre qué paciente**. Log debe ser completo, inalterable y verificable. Objetivo: registro de auditoría append-only, encadenado criptográficamente, consultable por rol AUDITOR.

## 2. Actores
Sistema (genera eventos), Auditor (consulta/exporta/verifica), Dirección médica (revisa accesos de emergencia), Paciente (indirecto: solicita quién accedió a su HC).

## 3. Historias de usuario
- **HU-003** Como auditor quiero que toda acción relevante quede registrada para trazabilidad legal.
- **HU-025** Como auditor quiero buscar y filtrar eventos (usuario, paciente, acción, fechas) para investigar incidentes.
- **HU-026** Como auditor quiero verificar integridad de la cadena para demostrar que el log no fue alterado.
- **HU-027** Como dirección médica quiero emitir informe de accesos a la HC de un paciente para responder solicitudes de habeas data.

## 4. Catálogo de eventos (mínimo)

| Categoría | Código | Datos antes/después |
|---|---|---|
| Sesión | `LOGIN_OK`, `LOGIN_FALLIDO`, `LOGIN_BLOQUEADO`, `CUENTA_BLOQUEADA`, `CUENTA_DESBLOQUEADA`, `LOGOUT`, `SESION_TIMEOUT`, `PANTALLA_BLOQUEADA` | No |
| Credenciales | `CLAVE_CAMBIADA`, `CLAVE_RESETEADA`, `PIN_CAMBIADO`, `PIN_FALLIDO` | No (nunca valores) |
| Usuarios | `USUARIO_CREAR`, `USUARIO_EDITAR`, `USUARIO_ROLES`, `USUARIO_INACTIVAR` | Sí |
| Autorización | `ACCESO_DENEGADO`, `ACCESO_EMERGENCIA`, `ACCESO_EMERGENCIA_REVISADO` | Motivo |
| Pacientes | `PACIENTE_CREAR`, `PACIENTE_EDITAR`, `PACIENTE_ESTADO`, `PACIENTE_FUSIONAR`, `PACIENTE_DUPLICADO_CONFIRMADO`, `PACIENTE_BUSCAR` | Sí (búsqueda: texto buscado) |
| Consentimiento | `CONSENTIMIENTO_REGISTRAR`, `CONSENTIMIENTO_REVOCAR`, `CONSENTIMIENTO_URGENCIA`, `CONSENTIMIENTO_IMPRIMIR` | Sí |
| HC (lectura) | `HC_ABRIR`, `HC_VER_NOTA` | No |
| HC (alergias/antecedentes) | `ALERGIA_REGISTRAR`, `ALERGIA_INACTIVAR`, `ANTECEDENTE_REGISTRAR`, `ANTECEDENTE_CAMBIAR_ESTADO` | Sí |
| HC (escritura) | `NOTA_CREAR`, `NOTA_EDITAR_BORRADOR`, `NOTA_FIRMAR`, `NOTA_ANULAR_BORRADOR`, `NOTA_ENMENDAR` | Sí |
| Salida de datos | `HC_IMPRIMIR`, `HC_EXPORTAR`, `ESTADISTICA_EXPORTAR`, `AUDITORIA_EXPORTAR` | Alcance |
| Sistema | `RESPALDO_OK`, `RESPALDO_ERROR`, `RESPALDO_SIMULACRO_OK`, `RESPALDO_SIMULACRO_ERROR`, `RESTAURACION`, `MIGRACION_BD`, `CATALOGO_ACTUALIZAR`, `CONFIG_CAMBIAR`, `AUDITORIA_VERIFICAR`, `AUDITORIA_ANCLA`, `RELOJ_RETROCEDIDO`, `CONSULTA_SNAPSHOT_RECALCULO` | Resumen |

Nuevas specs agregan eventos aquí (sección "Eventos de auditoría" obligatoria en cada spec).

## 5. Requisitos funcionales

| ID | Requisito | Prioridad |
|---|---|---|
| RF-003-01 | Evento contiene: secuencia, fecha-hora UTC, usuario, roles activos, sesión, equipo, IP, acción, entidad, id entidad, paciente (si aplica), resultado (OK/DENEGADO/ERROR), motivo, datos antes/después (JSON) | Must |
| RF-003-02 | Append-only: triggers `BEFORE UPDATE/DELETE` abortan cualquier intento de modificación o borrado | Must |
| RF-003-03 | Encadenamiento SHA-256: `hash_n = SHA256(canon(evento_n) ‖ hash_{n-1})`; evento génesis con hash fijo documentado | Must |
| RF-003-04 | Cambio de estado clínico/administrativo y su evento se confirman en **misma transacción** (`BEGIN IMMEDIATE`) | Must |
| RF-003-05 | Eventos de denegación, fallos de login y errores se registran tras `ROLLBACK` en transacción independiente inmediata | Must |
| RF-003-06 | Nunca registrar contraseñas, PIN, hashes de credenciales ni claves de cifrado | Must |
| RF-003-07 | Si auditoría no puede escribirse → la operación se aborta (fail-closed) y se muestra error | Must |
| RF-003-08 | Visor: filtros por rango fechas, usuario, paciente, acción, resultado; orden por secuencia; paginado | Must |
| RF-003-09 | Detalle de evento muestra diff antes/después legible | Should |
| RF-003-10 | Verificación de cadena (completa o por rango) con reporte: OK / primer evento roto / huecos de secuencia | Must |
| RF-003-11 | Anclaje diario: exportar (secuencia, hash) del último evento a archivo externo firmado; verificación compara contra anclas | Should |
| RF-003-12 | Exportar resultado filtrado a CSV y JSON (FHIR AuditEvent); exportación auditada | Should |
| RF-003-13 | Informe "accesos a HC de paciente X" (quién, cuándo, qué acción) imprimible PDF | Should |
| RF-003-14 | Retención indefinida; sin purga | Must |
| RF-003-15 | Visor solo con `AUDITORIA.LEER`; consultar auditoría también se audita | Must |

## 6. Criterios de aceptación (Gherkin)

```gherkin
Característica: Registro de auditoría

  Escenario: Acción exitosa auditada atómicamente
    Dado recepcionista edita teléfono del paciente "HC-2026-000001"
    Cuando guarda el cambio
    Entonces existe evento "PACIENTE_EDITAR" con valor anterior y nuevo
    Y el cambio y el evento tienen la misma transacción

  Escenario: Rollback no deja evento huérfano
    Dado una edición de paciente que falla al guardar
    Entonces no existe evento "PACIENTE_EDITAR" para ese intento
    Y existe evento con resultado "ERROR" registrado de forma autónoma

  Escenario: Denegación se registra
    Dado usuario RECEPCION
    Cuando intenta abrir HC clínica
    Entonces existe evento "ACCESO_DENEGADO" con resultado "DENEGADO"

  Escenario: Lectura de HC se registra
    Cuando médico abre HC del paciente "HC-2026-000001"
    Entonces existe evento "HC_ABRIR" con paciente, usuario, equipo y fecha UTC

  Escenario: Credenciales nunca en log
    Cuando usuario cambia su contraseña
    Entonces evento "CLAVE_CAMBIADA" no contiene la clave, su hash ni el PIN

  Escenario: Inmutabilidad por triggers
    Dado cualquier conexión a la base de datos SQLite
    Cuando ejecuta UPDATE o DELETE sobre auditoria
    Entonces el trigger aborta la sentencia con "Registro de auditoria inmutable"

  Escenario: Fail-closed
    Dado que la inserción de auditoría falla
    Cuando médico intenta firmar una nota
    Entonces la transacción completa hace rollback y la firma no se confirma

Característica: Integridad

  Escenario: Cadena íntegra
    Dado 10 000 eventos sin alteración
    Cuando auditor ejecuta verificación completa
    Entonces resultado "Íntegra" con primer y último número de secuencia

  Escenario: Detección de alteración externa
    Dado alguien con acceso al archivo desactiva triggers y modifica el campo accion del evento 500
    Cuando auditor ejecuta verificación
    Entonces resultado "Alterada" señalando evento 500

  Escenario: Detección de borrado externo
    Dado alguien elimina externamente el evento 700
    Cuando auditor verifica
    Entonces se reporta hueco de secuencia en 700

  Escenario: Reescritura total detectada por ancla
    Dado ancla externa del día anterior con secuencia 9 000 y hash H
    Y la cadena fue recalculada completa por un atacante
    Cuando auditor verifica contra anclas
    Entonces se reporta discrepancia en secuencia 9 000

Característica: Consulta

  Escenario: Informe habeas data
    Dado paciente "HC-2026-000001" con accesos de 3 usuarios
    Cuando dirección médica genera informe de accesos del último año
    Entonces el PDF lista usuario, rol, fecha-hora (America/Caracas) y acción
    Y se audita "HC_EXPORTAR"

  Escenario: Consulta auditada
    Cuando auditor filtra eventos del usuario "jperez"
    Entonces se registra evento de consulta de auditoría con los filtros usados
```

## 7. Requisitos no funcionales
- RNF-003-a: Escritura de evento < 10 ms p95.
- RNF-003-b: Visor: filtro sobre 5 M eventos < 2 s (índices por fecha, usuario, paciente, acción).
- RNF-003-c: Verificación 1 M eventos < 5 min.

## 8. Fuera de alcance
SIEM externo, alertas en tiempo real por email, sellado de tiempo de PSC (evaluar con firma SUSCERTE, Spec 008).

## 9. Preguntas abiertas
- ¿Registrar `PACIENTE_BUSCAR` (volumen alto) o solo aperturas? Propuesta: sí, con texto buscado.
- ¿Destino del ancla diaria: USB, otro servidor, email a dirección?

