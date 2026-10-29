# Tareas 004 — Historia Clínica SOAP, Antecedentes, CIE-10 y Firma

Ref: [spec.md](spec.md) · [plan.md](plan.md). `[P]` = paralelizable. Dividida entre Sprint 3 y Sprint 4.

## Sprint 3 — Alergias, Antecedentes e inicio SOAP

| ID | Tarea | Traza | Est. | Estado |
|---|---|---|---|---|
| T-004-01 | Migración `004_hc_soap.sql`: tablas (`alergias`, `antecedentes`, `cie10_catalog`, `consultas`, `diagnosticos_consulta`, `consulta_enmiendas`), índices y triggers de inmutabilidad | plan §3 | 1d | ☐ |
| T-004-02 [P] | `uAntecedente.pas`, `uConsulta.pas`, `uCie10.pas` (entidades y enums) | RF-004-01..07 | 0.5d | ☐ |
| T-004-03 [P] | `TAntecedenteRepositorySQLite` + `TAntecedenteService` + tests (alergias NKA/activas, inactivar, antecedentes por sexo) | RF-004-02..05, Gherkin 1–2 | 1d | ☐ |
| T-004-04 [P] | Tests + `TConsultaValidator` (rangos fisiológicos, PA diastólica < sistólica, cálculo IMC) | RF-004-07/08, Gherkin 4 | 0.5d | ☐ |
| T-004-05 | `TConsultaRepositorySQLite` (borradores, signos vitales, timeline) + tests | RF-004-06/10/23 | 1d | ☐ |
| T-004-06 | `ufrmHistoriaClinica` parte 1: cabecera fija con banda de alergias, pestañas Alergias y Antecedentes, línea de tiempo lateral | HU-008, HU-009, HU-014 | 1.5d | ☐ |

## Sprint 4 — CIE-10, SOAP completo, Firma e Inmutabilidad

| ID | Tarea | Traza | Est. | Estado |
|---|---|---|---|---|
| T-004-07 [P] | `TCie10RepositorySQLite` + `TCie10Service` (importador CSV, búsqueda sin acentos, top frecuentes por médico, validación sexo/edad) + tests | HU-011, HU-021, RF-004-12..17 | 1d | ☐ |
| T-004-08 [P] | `TFirmadorPIN` (verificación PIN Argon2id + serialización canónica SHA-256 de consulta y enmienda) + tests | RF-004-18/19/22 | 0.5d | ☐ |
| T-004-09 | `TConsultaService`: autoguardado, sugerencia Nuevo/Sucesivo, cálculo snapshot estadístico (`uSemanaEpi` + `EdadCumplida`), `Firmar`, `AnularBorrador`, `AgregarEnmienda` + tests | RF-004-10..22, Gherkin 3,5–10 | 1.5d | ☐ |
| T-004-10 | Tests de inmutabilidad en SQLite: verificar que triggers bloquean `UPDATE`/`DELETE` sobre consultas firmadas, diagnósticos y enmiendas | RF-004-20, Gherkin 9 | 0.5d | ☐ |
| T-004-11 | `ufrmBuscadorCie10` (búsqueda rápida por teclado) + grilla de diagnósticos en pestaña SOAP | HU-011 | 1d | ☐ |
| T-004-12 | `ufrmHistoriaClinica` parte 2: editor SOAP + signos vitales con IMC + timer autoguardado 30 s + integración con bloqueo de inactividad | HU-010, RF-004-08/10 | 1.5d | ☐ |
| T-004-13 | `ufrmFirmarPin` + `ufrmEnmienda` + vista solo lectura de nota firmada con sus enmiendas | HU-012, HU-013 | 1d | ☐ |
| T-004-14 | Verificación manual escenarios Gherkin + demo PO (cierre Release 1.0 MVP) | DoD | 0.5d | ☐ |

Total ≈ 12 d (5.5 d en Sprint 3 + 6.5 d en Sprint 4).

