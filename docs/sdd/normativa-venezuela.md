# Marco normativo — Venezuela

> [!WARNING]
> Resumen técnico para orientar requisitos. **Validar con asesor legal** antes de cada release.

| Norma | Artículos clave | Impacto en HCE |
|---|---|---|
| Constitución (CRBV 1999) | Art. 28 (habeas data), 48 (secreto de comunicaciones), 60 (privacidad), 83–85 (salud) | Paciente puede conocer, corregir y pedir uso legítimo de sus datos → exportar HC del paciente, registrar rectificaciones |
| Ley Orgánica de Salud (1998) | Art. 69 (derechos del paciente: confidencialidad, consentimiento, acceso a HC) | Consentimiento informado (EP-10), control de acceso, entrega de copia de HC |
| Ley de Ejercicio de la Medicina (2011) + Código de Deontología Médica (2003) | Secreto médico; HC obligatoria, veraz, no alterable | Notas firmadas inmutables, enmiendas, identificación del médico (M.P.P.S. y C.M.) |
| Decreto-Ley sobre Mensajes de Datos y Firmas Electrónicas (2001) | Arts. 4 (eficacia probatoria), 16–18 (firma electrónica), 38+ (certificados) | Firma con certificado de PSC acreditado ante **SUSCERTE** tiene validez plena; firma simple = valor probatorio menor |
| Ley Especial contra los Delitos Informáticos (2001) | Arts. 6 (acceso indebido), 20–22 (violación de privacidad de data) | Control de acceso, bloqueo, auditoría de accesos para prueba |
| LOPNNA | Representación de menores | Consentimiento por representante legal; vínculo paciente–representante |
| Ley de Infogobierno (2013) | Software libre, estándares abiertos (sector público) | Lazarus/FPC/SQLite cumplen; formatos abiertos (FHIR JSON, PDF/A) |

## Observaciones
- No existe ley general de protección de datos personales; aplica habeas data (CRBV art. 28) y jurisprudencia TSJ.
- Plazo de conservación de HC: no se identificó plazo uniforme → **política: no borrado, conservación indefinida** `[POR CONFIRMAR con asesor legal]`.
- Huso horario: `America/Caracas` (UTC−4, sin horario de verano).

## Identificación
| Tipo | Formato | Notas |
|---|---|---|
| Cédula venezolano | `V-` + 1–9 dígitos | Principal |
| Cédula extranjero | `E-` + 1–9 dígitos | |
| Pasaporte | alfanumérico 5–15 | + país emisor |
| Partida de nacimiento / menor sin cédula | `[cédula representante]-[orden]` | Ej. `V-12345678-1` |
| Sin documento (NN) | `NN-AAAAMMDD-NNN` | Temporal, se reemplaza al identificar |

## Profesionales de salud
- Médico: Matrícula **M.P.P.S.** + número de **Colegio de Médicos (C.M.)** + estado. Obligatorios en notas firmadas e informes.
- Enfermería, bioanálisis: registro del colegio respectivo + M.P.P.S.

