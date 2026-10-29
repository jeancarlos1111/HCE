# Tareas 002 — Pacientes

Ref: [spec.md](spec.md) · [plan.md](plan.md). Cada tarea ≤ 1 día. `[P]` = paralelizable.

| ID | Tarea | Traza | Est. | Estado |
|---|---|---|---|---|
| T-002-01 | Migración `002_paciente.sql` (tablas, índices, trigger no-delete) | plan §3 | 0.5d | ☐ |
| T-002-02 | `uPaciente.pas`: entidad + enums | RF-002-01/02 | 0.5d | ☐ |
| T-002-03 | Tests validator (rojo) | RN-1..2, RF-002-01/04 | 0.5d | ☐ |
| T-002-04 | `uPacienteValidator.pas` (verde) | idem | 0.5d | ☐ |
| T-002-05 [P] | Tests + `NormalizarTexto` y `TDuplicadoDetector` | RF-002-05/07 | 1d | ☐ |
| T-002-06 | `IPacienteRepository` + implementación en memoria (tests) | plan §5 | 0.5d | ☐ |
| T-002-07 | `TPacienteRepositorySQLite` + test integración (`:memory:`) | plan §3 | 1d | ☐ |
| T-002-08 | Tests `TPacienteService` (registro, duplicado, edición, estado, permisos) | Gherkin 1–8 | 1d | ☐ |
| T-002-09 | `TPacienteService` + generación nro HC + historial + auditoría | RF-002-03/08/09 | 1d | ☐ |
| T-002-10 | `frmPacienteBuscar` (búsqueda incremental, teclado) | HU-005 | 1d | ☐ |
| T-002-11 | `frmPacienteEditar` (alta/edición, advertencia duplicado, motivo) | HU-004/006 | 1d | ☐ |
| T-002-12 | Vista historial de cambios | RF-002-08 | 0.5d | ☐ |
| T-002-13 | Prueba rendimiento 100k registros | RNF-01 | 0.5d | ☐ |
| T-002-14 | Verificación manual escenarios Gherkin + demo PO | DoD | 0.5d | ☐ |

