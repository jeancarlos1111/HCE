# Tareas 007 — Respaldo y Recuperación

Ref: [spec.md](spec.md) · [plan.md](plan.md). Sprint 3 (HU-019). `[P]` = paralelizable.

| ID | Tarea | Traza | Est. | Estado |
|---|---|---|---|---|
| T-007-01 | Migración `007_respaldos.sql` (`config_respaldo`, `historial_respaldos`) | plan §3 | 0.25d | ☐ |
| T-007-02 [P] | Tests + `TCifradorRespaldo` (compresión `zstream` + AES-256 + HMAC-SHA256 en streaming de 64 KB) | RF-007-03, plan §4 | 1d | ☐ |
| T-007-03 | `TRespaldoService`: `VACUUM INTO`, `PRAGMA quick_check`, doble destino, rotación, simulacro y restauración con salvaguarda + tests | RF-007-01..09, Gherkin 1–5 | 1d | ☐ |
| T-007-04 | `ufrmRespaldos` + indicador en barra de estado (> 48 h sin respaldo / > 30 d sin simulacro) + disparo al cerrar app | RF-007-05/07 | 0.75d | ☐ |

Total = 3 d.

