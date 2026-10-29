# Tareas 005 — Estadísticas

Ref: [spec.md](spec.md) · [plan.md](plan.md). `[P]` = paralelizable. Requiere Spec 004 con snapshot al firmar.

| ID | Tarea | Traza | Est. | Estado |
|---|---|---|---|---|
| T-005-01 [P] | Tests + `uSemanaEpi` (5 casos obligatorios + 53 semanas) | RN-07 | 0.5d | ☐ |
| T-005-02 [P] | Tests + `EdadCumplida` (29-feb, día de cumpleaños) + `TGruposEtarios`; migración `grupos_etarios` con seeds SIMPLE y EPI | RN-03, RN-10 | 0.5d | ☐ |
| T-005-03 [P] | `uTablaReporte` (columnas tipadas, totales, nombre sugerido) | plan §2 | 0.5d | ☐ |
| T-005-04 [P] | Tests + `uExportCSV` (BOM, `;`, CRLF, comillas, inyección, numéricos sin comillas, escritura atómica) | RF-005-06, Gherkin CSV | 0.5d | ☐ |
| T-005-05 | Migración índices estadísticos (`ix_cons_est`, `ix_cons_semana`, `ix_dx_consulta`) | plan §3 | 0.25d | ☐ |
| T-005-06 | Generador de datos sintéticos (300k consultas) para tests y rendimiento | RNF-11 | 0.5d | ☐ |
| T-005-07 | `TEstadisticaRepositorySQLite`: morbilidad con WHERE dinámico + tests con dataset Gherkin | RF-005-03, RN-01/02/05/06 | 1d | ☐ |
| T-005-08 | Repositorio: demografía + volumen (médico/especialidad/turno) | RF-005-04/05 | 1d | ☐ |
| T-005-09 | `TEstadisticaService`: permisos, rango por período, %, totales, auditoría exportación | RF-005-01/02, §7 spec | 1d | ☐ |
| T-005-10 | `frmEstadisticas`: filtros, grid, totales en negrita, exportar | HU-030..033 | 1d | ☐ |
| T-005-11 | Ejecución en hilo (`TThread`) si > 500 ms + cancelar | RF-005-12 | 0.5d | ☐ |
| T-005-12 | Rendimiento + `EXPLAIN QUERY PLAN` en VM hardware mínimo | RNF-11 | 0.5d | ☐ |
| T-005-13 | EPI-15 (pivot) — tras confirmar formato | HU-034 | 1d | ☐ |
| T-005-14 | Indicadores | HU-035 | 0.5d | ☐ |
| T-005-15 | Tendencia por semana epi (+ `TChart` opcional) | HU-036 | 0.5d | ☐ |
| T-005-16 | Seed permisos `ESTADISTICA.*` + rol `ESTADISTICA` (migración Spec 001) | plan §9 | 0.25d | ☐ |
| T-005-17 | Verificación manual Gherkin + demo PO | DoD | 0.5d | ☐ |

Sprint 5: T-005-01..12, 16, 17 (≈ 8.5 d). Sprint 6: T-005-13..15.

