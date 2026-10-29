# Tareas 003 — Auditoría

Ref: [spec.md](spec.md) · [plan.md](plan.md). `[P]` = paralelizable.

| ID | Tarea | Traza | Est. | Estado |
|---|---|---|---|---|
| T-003-01 | `uEventoAuditoria.pas`, `IAuditoria` + doble en memoria (desbloquea Spec 001) | plan §2 | 0.5d | ☑ |
| T-003-02 | Migración `003_auditoria.sql`: tablas `STRICT`, índices, génesis, triggers (`no_update`, `no_delete`, `check_chain`, `advance_chain`) | plan §3 | 0.5d | ☑ |
| T-003-03 [P] | Tests + `uDiffJson` (campos sensibles excluidos) | RF-003-06 | 0.5d | ☐ |
| T-003-04 [P] | Tests + `uCanonico` (SHA-256 canónico) | RF-003-03, plan §4 | 0.5d | ☑ |
| T-003-05 | `TAuditoriaSQLite` + tests integración (`:memory:`: encadena, independiente tras rollback, triggers rechazan UPDATE/DELETE/secuencia rota, retroceso de reloj) | RF-003-02..05/07 | 1d | ☑ |
| T-003-06 | Tests + `TVerificadorCadena` (íntegra, alterada desactivando triggers en test, hueco) | RF-003-10 | 1d | ☑ |
| T-003-07 | `TAnclaService` + verificación contra anclas | RF-003-11 | 0.5d | ☐ |
| T-003-08 | `TAuditoriaConsultaService` (filtros, keyset, auditar consulta) | RF-003-08/15 | 1d | ☐ |
| T-003-09 | `frmAuditoriaVisor` + `frmAuditoriaDetalle` (diff) | HU-025 | 1d | ☐ |
| T-003-10 | `frmVerificarCadena` (progreso, reporte) | HU-026 | 0.5d | ☐ |
| T-003-11 | Exportar CSV (`uExportCSV`) + JSON | RF-003-12 | 0.5d | ☐ |
| T-003-12 | Informe habeas data PDF (accesos por paciente) | HU-027 | 1d | ☐ |
| T-003-13 | Rendimiento 1 M eventos en SQLite | RNF-003 | 0.5d | ☐ |
| T-003-14 | Verificación manual Gherkin + demo PO | DoD | 0.5d | ☐ |

Total ≈ 9.5 d (SQLite elimina stored procedures y test cruzado SQL/Pascal, reduciendo 3 días respecto a Firebird).
Sprint 1: T-003-01..06, 08..10 (7 d). Sprint 2/6: T-003-07, 11..13.
