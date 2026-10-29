# Product Backlog

> Alcance: HC (SOAP, antecedentes, CIE-10) + estadísticas. Récipes/prescripciones/órdenes **eliminados**. IDs descartados no se reutilizan.

## Épicas

| ID | Épica | Prioridad | FHIR | Spec |
|---|---|---|---|---|
| EP-01 | Seguridad, usuarios y roles | Must | Practitioner, PractitionerRole | 001 |
| EP-02 | Gestión de pacientes | Must | Patient | 002 |
| EP-09 | Auditoría | Must | AuditEvent | 003 |
| EP-04 | Historia clínica — consulta SOAP | Must | Encounter, Observation, Condition | 004 |
| EP-05 | Antecedentes y alergias | Must | AllergyIntolerance, Condition, FamilyMemberHistory | 004 |
| EP-06 | Diagnósticos CIE-10 | Must | Condition (code CIE-10) | 004 |
| EP-08 | Firma electrónica y enmiendas | Must | Provenance | 004 |
| EP-14 | Estadísticas e indicadores de salud | Must | — | 005 |
| EP-10 | Consentimiento informado | Must | Consent | 006 |
| EP-13 | Respaldo y recuperación | Must | — | 007 |
| EP-11 | Impresión de HC / informe (copia paciente, habeas data) | Should | — | 008 |
| ~~EP-03~~ | ~~Agenda y admisión~~ | Won't (versión actual) `[POR CONFIRMAR]` | | |
| ~~EP-07~~ | ~~Prescripción y órdenes~~ | **Descartada** | | |
| ~~EP-12~~ | ~~Exportación FHIR~~ | Won't (versión actual) | | |

## Historias de usuario

| ID | Épica | Historia | MoSCoW | Pts | Sprint |
|---|---|---|---|---|---|
| HU-001 | EP-01 | Como administrador quiero crear usuarios con rol para controlar acceso | Must | 5 | 1 |
| HU-002 | EP-01 | Como usuario quiero iniciar sesión con credenciales seguras | Must | 3 | 1 |
| HU-022 | EP-01 | Como usuario quiero cambiar mi contraseña y PIN de firma | Must | 2 | 1 |
| HU-023 | EP-01 | Como sistema quiero bloquear sesión inactiva y cuentas con intentos fallidos | Must | 3 | 1 |
| HU-024 | EP-01 | Como médico quiero acceso de emergencia justificado y auditado | Should | 3 | 2 |
| HU-003 | EP-09 | Como auditor quiero que toda acción quede registrada | Must | 5 | 1 |
| HU-025 | EP-09 | Como auditor quiero buscar y filtrar eventos | Must | 3 | 1 |
| HU-026 | EP-09 | Como auditor quiero verificar integridad de la cadena | Must | 3 | 1 |
| HU-027 | EP-09 | Como dirección médica quiero informe de accesos a HC de un paciente | Should | 3 | 6 |
| HU-004 | EP-02 | Como recepcionista quiero registrar paciente | Must | 5 | 2 |
| HU-005 | EP-02 | Como recepcionista quiero buscar paciente sin duplicados | Must | 3 | 2 |
| HU-006 | EP-02 | Como recepcionista quiero editar datos demográficos con historial | Must | 3 | 2 |
| HU-007 | EP-10 | Como profesional quiero registrar consentimiento informado | Must | 3 | 2 |
| HU-008 | EP-05 | Como médico quiero registrar alergias y verlas siempre en cabecera | Must | 5 | 3 |
| HU-009 | EP-05 | Como médico quiero registrar antecedentes personales/familiares/quirúrgicos/gineco-obstétricos/hábitos | Must | 5 | 3 |
| HU-010 | EP-04 | Como médico quiero registrar consulta SOAP (Subjetivo, Objetivo + signos vitales, Análisis, Plan) | Must | 8 | 3–4 |
| HU-011 | EP-06 | Como médico quiero codificar diagnósticos con buscador CIE-10 (principal/secundarios, nuevo/sucesivo) | Must | 5 | 4 |
| HU-012 | EP-08 | Como médico quiero firmar la nota para cerrarla de forma inmutable | Must | 5 | 4 |
| HU-021 | EP-06 | Como administrador quiero cargar/actualizar catálogo CIE-10 | Must | 3 | 4 |
| HU-019 | EP-13 | Como administrador quiero respaldos cifrados programados | Must | 3 | 3 |
| HU-013 | EP-08 | Como médico quiero agregar enmienda a nota firmada con motivo | Must | 3 | 5 |
| HU-014 | EP-04 | Como médico quiero ver línea de tiempo de consultas del paciente | Should | 5 | 5 |
| HU-030 | EP-14 | Como estadístico quiero consolidado de morbilidad CIE-10 por rango/semana epidemiológica | Must | 5 | 5 |
| HU-031 | EP-14 | Como estadístico quiero distribución de consultas por grupo etario y sexo | Must | 3 | 5 |
| HU-032 | EP-14 | Como dirección quiero volumen de consultas por médico, especialidad y turno | Must | 3 | 5 |
| HU-033 | EP-14 | Como estadístico quiero exportar cualquier reporte a CSV (LibreOffice/Excel) | Must | 2 | 5 |
| HU-034 | EP-14 | Como estadístico quiero consolidado semanal de morbilidad en formato EPI-15 | Should | 5 | 6 |
| HU-035 | EP-14 | Como dirección quiero tablero de indicadores (atenciones, pacientes únicos, % primera vez, promedio diario) | Should | 3 | 6 |
| HU-036 | EP-14 | Como estadístico quiero tendencia semanal de un diagnóstico CIE-10 | Could | 3 | 6 |
| HU-018 | EP-11 | Como médico quiero imprimir/exportar PDF de HC completa | Should | 5 | 6 |
| ~~HU-015~~ | ~~EP-07~~ | ~~Receta médica imprimible~~ | Descartada | | |
| ~~HU-016~~ | ~~EP-07~~ | ~~Solicitud de exámenes~~ | Descartada | | |
| ~~HU-017~~ | ~~EP-03~~ | ~~Agenda de citas~~ | Won't | | |
| ~~HU-020~~ | ~~EP-12~~ | ~~Bundle FHIR JSON~~ | Won't | | |

## Specs
| Spec | Historias | Estado |
|---|---|---|
| [001-usuarios-permisos](specs/001-usuarios-permisos/spec.md) | HU-001, 002, 022, 023, 024 | Borrador |
| [002-pacientes](specs/002-pacientes/spec.md) | HU-004, 005, 006 | Borrador |
| [003-auditoria](specs/003-auditoria/spec.md) | HU-003, 025, 026, 027 | Borrador |
| [004-historia-clinica-soap](specs/004-historia-clinica-soap/spec.md) | HU-008..012, 013, 014, 021 | Borrador |
| [005-estadisticas](specs/005-estadisticas/spec.md) | HU-030..036 | Borrador |
| [006-consentimiento](specs/006-consentimiento/spec.md) | HU-007 | Borrador |
| [007-respaldos](specs/007-respaldos/spec.md) | HU-019 | Borrador |

## Requisitos no funcionales

| ID | Requisito |
|---|---|
| RNF-01 | Búsqueda de paciente < 1 s con 100 000 registros |
| RNF-02 | Contraseñas con Argon2id (ADR-002) |
| RNF-03 | Bloqueo de pantalla tras 10 min inactividad |
| RNF-04 | Backups cifrados (API backup SQLite), prueba de restauración mensual |
| RNF-05 | Retención de HC y auditoría indefinida, sin borrado `[POR CONFIRMAR con asesor legal]` |
| RNF-06 | Linux y Windows (Lazarus multiplataforma) |
| RNF-07 | Fechas `*_utc` en UTC; `fecha_local` en `America/Caracas` (UTC−4) |
| RNF-08 | UTF-8 en BD e interfaz; CSV UTF-8 con BOM |
| RNF-09 | Hardware mínimo objetivo: CPU 2 núcleos, 2 GB RAM, HDD mecánico `[POR CONFIRMAR]` |
| RNF-10 | RAM de proceso ≤ 100 MB; arranque ≤ 3 s |
| RNF-11 | Reportes estadísticos: 1 año (~60 000 consultas) ≤ 1 s; 5 años ≤ 3 s en hardware RNF-09 |
| RNF-12 | Monopuesto; BD nunca en carpeta de red compartida |
