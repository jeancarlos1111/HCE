# Tareas 006 — Consentimiento Informado

Ref: [spec.md](spec.md) · [plan.md](plan.md). Sprint 2 (HU-007).

| ID | Tarea | Traza | Est. | Estado |
|---|---|---|---|---|
| T-006-01 | Migración `006_consentimiento.sql` (tablas, triggers, seed plantilla `GEN_ATENCION_V1`) | plan §2 | 0.5d | ☐ |
| T-006-02 | `uConsentimiento.pas` + `TConsentimientoRepositorySQLite` + tests (`:memory:`) | RF-006-01/05 | 0.5d | ☐ |
| T-006-03 | `TConsentimientoService` (validación LOPNNA < 18 años, vigencia, revocación, impresión HTML ligera, auditoría) + tests | RF-006-01..06, Gherkin 1–5 | 1d | ☐ |
| T-006-04 | `ufrmConsentimiento` + integración en alta de paciente y cabecera de HC | HU-007, RF-006-03 | 1d | ☐ |

Total = 3 d.

