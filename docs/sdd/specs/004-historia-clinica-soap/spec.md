# Spec 004 — Historia Clínica (SOAP, Antecedentes, Alergias, CIE-10 y Firma)

- Épicas: EP-04 (Consulta SOAP), EP-05 (Antecedentes y alergias), EP-06 (CIE-10), EP-08 (Firma y enmiendas)
- Historias: HU-008, HU-009, HU-010, HU-011, HU-012, HU-013, HU-014, HU-021
- Estado: Borrador · PO: `[nombre]` · Fecha: 2026-10-29
- Depende de: Spec 001 (usuarios/PIN/permisos), Spec 002 (pacientes), Spec 003 (auditoría)
- Alimenta a: Spec 005 (estadísticas e indicadores)
- FHIR: `Encounter`, `Observation`, `Condition`, `AllergyIntolerance`, `FamilyMemberHistory`, `Provenance`
- Normativa: Ley de Ejercicio de la Medicina y Código de Deontología Médica (HC veraz, completa, inalterable, identificada con M.P.P.S./C.M.), Decreto-Ley de Mensajes de Datos y Firmas Electrónicas

## 1. Problema / Objetivo
El registro clínico debe ser rápido (≤ 3 min por consulta), estructurado bajo el modelo **SOAP**, con alertas de alergias siempre visibles, diagnósticos codificados **CIE-10** compatibles con vigilancia epidemiológica (EPI-15) e inmutabilidad tras la firma del profesional.

> **Excluido por alcance (Constitución Art. 9):** emisión/impresión de récipes, prescripciones estructuradas y órdenes de laboratorio/imagen. La conducta terapéutica e indicaciones quedan registradas como texto clínico dentro de la sección **P (Plan)** del SOAP.

## 2. Actores
| Rol | Acciones permitidas |
|---|---|
| MEDICO | Leer HC, gestionar alergias/antecedentes, crear/editar borrador SOAP, codificar CIE-10, firmar con PIN, agregar enmienda |
| ENFERMERIA | Leer HC, registrar alergias, crear consulta en borrador con signos vitales (triaje) |
| DIRECCION_MEDICA | Leer HC completa (solo lectura) |
| ADMIN / RECEPCION / ESTADISTICA / AUDITOR | **Sin acceso** a contenido clínico |

## 3. Historias de usuario
- **HU-008** Como médico/enfermero quiero registrar alergias y verlas resaltadas en la cabecera del paciente en todo momento.
- **HU-009** Como médico quiero registrar y actualizar antecedentes (patológicos personales, familiares, quirúrgicos/traumáticos, gineco-obstétricos y hábitos psicobiológicos).
- **HU-010** Como médico quiero registrar la consulta siguiendo el modelo SOAP (Subjetivo, Objetivo + signos vitales, Análisis, Plan) con autoguardado de borrador.
- **HU-011** Como médico quiero codificar uno o más diagnósticos CIE-10 en la consulta (marcando principal/secundario y nuevo/sucesivo).
- **HU-012** Como médico quiero firmar electrónicamente la consulta con mi PIN para cerrarla de forma inmutable.
- **HU-013** Como médico quiero agregar una enmienda (addendum) justificada a una consulta ya firmada sin alterar el texto original.
- **HU-014** Como médico quiero visualizar la línea de tiempo cronológica de consultas previas del paciente.
- **HU-021** Como administrador quiero importar/actualizar el catálogo CIE-10 desde archivo CSV.

## 4. Requisitos funcionales

### 4.1 Cabecera clínica y Alergias (EP-05)
| ID | Requisito | Prioridad |
|---|---|---|
| RF-004-01 | Cabecera fija en toda pantalla de HC: Nro HC, nombre completo, cédula, sexo, edad exacta (años/meses), grupo sanguíneo y **banda de alergias** | Must |
| RF-004-02 | Banda de alergias con 3 estados explícitos: `"Sin alergias conocidas (NKA)"` (verde), `"Alergias no evaluadas"` (ámbar), o lista de alergias activas en rojo (resaltando severas/anafilaxia) | Must |
| RF-004-03 | Alergia: categoría (`MEDICAMENTO`, `ALIMENTO`, `AMBIENTAL`, `OTRO`), sustancia, reacción, severidad (`LEVE`, `MODERADA`, `SEVERA`), estado (`ACTIVA`, `INACTIVA`), fecha y autor. Nunca se borra; se inactiva con motivo | Must |

### 4.2 Antecedentes (EP-05)
| ID | Requisito | Prioridad |
|---|---|---|
| RF-004-04 | Categorías: `PERSONAL_PATOLOGICO` (con código CIE-10 opcional), `FAMILIAR` (parentesco + condición), `QUIRURGICO_TRAUMATICO` (procedimiento + año), `GINECO_OBSTETRICO` (solo si `sexo = 'F'`: menarquia, FUM, G/P/A/C, MAC), `HABITO` (tabaco, alcohol, café, actividad física, otros) | Must |
| RF-004-05 | Antecedentes persisten a nivel de paciente (visibles en todas las consultas); cada adición o cambio de estado (`ACTIVO`/`RESUELTO`/`INACTIVO`) conserva autor, fecha y motivo | Must |

### 4.3 Consulta SOAP y Signos Vitales (EP-04)
| ID | Requisito | Prioridad |
|---|---|---|
| RF-004-06 | Estructura SOAP: **S — Subjetivo** (`motivo_consulta` obligatorio + `enfermedad_actual`), **O — Objetivo** (signos vitales + `examen_fisico`), **A — Análisis** (`analisis` clínico + diagnósticos CIE-10), **P — Plan** (`plan_tratamiento`: conducta, indicaciones no farmacológicas y farmacológicas en texto, educación, signos de alarma, próximo control) | Must |
| RF-004-07 | Signos vitales (opcionales pero validados en rango fisiológico): PA sistólica (40–300 mmHg), PA diastólica (20–200 mmHg, `< sistólica`), FC (20–260 lpm), FR (4–80 rpm), Temperatura (30.0–44.0 °C), SpO2 (50–100 %), Peso (0.3–350 kg), Talla (20–250 cm), Glucemia capilar (10–800 mg/dL) | Must |
| RF-004-08 | Cálculo automático de **IMC** ($\text{Peso} / \text{Talla m}^2$) y clasificación OMS cuando hay peso y talla; alerta visual (color) si un signo vital está fuera de rango normal para la edad | Should |
| RF-004-09 | Flujo triaje → consulta: ENFERMERIA puede iniciar consulta en borrador con signos vitales; MEDICO la toma, completa SOAP y firma | Should |
| RF-004-10 | Autoguardado de borrador en SQLite cada 30 s si hubo cambios y al bloquear pantalla por inactividad (Constitución Art. 8) | Must |
| RF-004-11 | Paciente en estado `Fallecido` no admite nuevas consultas ni edición de borradores (RN-2 Spec 002) | Must |

### 4.4 Diagnósticos CIE-10 (EP-06)
| ID | Requisito | Prioridad |
|---|---|---|
| RF-004-12 | Buscador CIE-10 instantáneo (< 100 ms) por código exacto/prefijo o palabras de la descripción sin acentos; prioriza los 30 códigos más usados por el médico | Must |
| RF-004-13 | Para firmar se exige **mínimo 1 diagnóstico CIE-10**, exactamente **1 marcado como principal** (`principal = 1`) y N secundarios (`principal = 0`) | Must |
| RF-004-14 | Cada diagnóstico indica: `tipo_caso` (`N` = Nuevo / primera vez por esa causa, `S` = Sucesivo / control), `certeza` (`PRESUNTIVO`, `CONFIRMADO`) y nota breve opcional | Must |
| RF-004-15 | Sugerencia automática: si el paciente ya tuvo el mismo `cie10_codigo` en una consulta firmada previa, preselecciona `tipo_caso = 'S'`; si no, `'N'` (editable por el médico) | Should |
| RF-004-16 | Validación de coherencia CIE-10: rechaza códigos exclusivos de sexo opuesto (`cie10_catalog.sexo_aplica <> paciente.sexo`) o fuera de edad (`edad_min_anios`/`edad_max_anios`) | Must |
| RF-004-17 | Importador CSV de catálogo CIE-10 (solo ADMIN): valida formato, inserta nuevos, actualiza descripciones e inactiva obsoletos sin borrar códigos referenciados | Must |

### 4.5 Firma electrónica, Snapshot e Inmutabilidad (EP-08)
| ID | Requisito | Prioridad |
|---|---|---|
| RF-004-18 | Firma requiere rol `MEDICO` con M.P.P.S. registrado, permiso `HC.FIRMAR` e ingreso del **PIN de firma** (Spec 001 RF-001-10) | Must |
| RF-004-19 | Al firmar se congelan en la consulta: datos del profesional firmante (nombre, cédula, M.P.P.S., Colegio/nro, especialidad), fecha-hora UTC, **snapshot estadístico** (`fecha_local` Caracas, `turno`, `anio_epi`, `semana_epi`, `sexo`, `edad_anios`, `edad_meses`, `primera_vez`) y **hash SHA-256** del contenido clínico canónico | Must |
| RF-004-20 | Consulta firmada (`estado = 'F'`) es **inmutable**: BD (triggers) y servicio bloquean cualquier `UPDATE` de campos clínicos, cambio/borrado de diagnósticos o `DELETE` | Must |
| RF-004-21 | Un borrador (`estado = 'B'`) nunca firmado puede ser **Anulado** (`estado = 'A'`) con motivo por su autor o DIRECCION_MEDICA; nunca borrado físico | Must |
| RF-004-22 | **Enmienda (`HU-013`)**: sobre consulta firmada se puede añadir enmienda (`motivo` obligatorio + `contenido` + firma con PIN + hash propio). La nota original permanece intacta y las enmiendas se muestran debajo en orden cronológico | Must |

### 4.6 Línea de tiempo (EP-04)
| ID | Requisito | Prioridad |
|---|---|---|
| RF-004-23 | Panel lateral de historial de consultas del paciente (más reciente primero): fecha local, especialidad, médico, motivo, diagnóstico principal CIE-10 e indicador de enmiendas. Clic abre detalle completo en solo lectura | Must |

## 5. Criterios de aceptación (Gherkin)

```gherkin
Característica: Alergias y Antecedentes

  Escenario: Alerta de alergia severa siempre visible
    Dado paciente con alergia activa a "Penicilina" de severidad "SEVERA"
    Cuando el médico abre la historia clínica o inicia una consulta SOAP
    Entonces la cabecera muestra en rojo "ALERGIA SEVERA: Penicilina (Anafilaxia)"

  Escenario: Antecedentes gineco-obstétricos según sexo
    Dado un paciente con sexo biológico "M"
    Cuando el médico abre la pestaña de antecedentes
    Entonces la sección gineco-obstétrica no está habilitada

Característica: Consulta SOAP y CIE-10

  Escenario: Autoguardado y recuperación de borrador
    Dado un médico redactando una consulta con motivo "Cefalea"
    Cuando pasan 30 segundos o la sesión se bloquea por inactividad
    Entonces el borrador queda guardado en SQLite con estado "B"
    Y al volver a abrir la HC puede retomar el borrador sin pérdida de texto

  Escenario: Validación de signos vitales incoherentes
    Cuando ingresa PA sistólica "90" y PA diastólica "110"
    Entonces el sistema rechaza el valor indicando "PA diastólica debe ser menor que sistólica"

  Escenario: Prohibido firmar sin motivo o sin diagnóstico principal
    Dado un borrador con motivo "Fiebre" pero sin diagnósticos CIE-10
    Cuando el médico intenta firmar la consulta
    Entonces el sistema impide la firma e indica "Debe registrar al menos un diagnóstico CIE-10 principal"

  Escenario: Restricción de código CIE-10 por sexo
    Dado un paciente de sexo "M"
    Cuando el médico intenta agregar el diagnóstico "O80" (Parto único espontáneo)
    Entonces el sistema rechaza el diagnóstico por incompatibilidad con el sexo del paciente

  Escenario: Sugerencia de caso Sucesivo
    Dado que el paciente tuvo una consulta firmada previa con diagnóstico "I10" (Hipertensión esencial)
    Cuando el médico selecciona "I10" en una nueva consulta
    Entonces el tipo de caso se preselecciona como "S" (Sucesivo)

Característica: Firma, Inmutabilidad y Enmiendas

  Escenario: Firma exitosa congela snapshot y hash
    Dado un borrador válido con motivo, examen, plan y diagnóstico principal "J00"
    Cuando el médico ingresa su PIN de firma correcto
    Entonces la consulta pasa a estado "F" con fecha UTC, fecha local Caracas, semana epidemiológica y hash SHA-256
    Y queda disponible inmediatamente para los reportes de Estadísticas (Spec 005)
    Y se registra el evento de auditoría "NOTA_FIRMAR" en la misma transacción

  Escenario: Inmutabilidad de consulta firmada y sus diagnósticos
    Dada una consulta en estado "F"
    Cuando se intenta modificar el texto SOAP o eliminar un diagnóstico por servicio o por SQL directo
    Entonces la operación es abortada por el sistema y por los triggers de SQLite

  Escenario: Enmienda sobre nota firmada
    Dada una consulta firmada con ID 50
    Cuando el médico registra una enmienda con motivo "Omisión de hallazgo" y firma con su PIN
    Entonces la nota original de la consulta 50 no cambia su texto ni su hash
    Y la enmienda aparece adjunta con fecha, médico, M.P.P.S., motivo y hash propio
    Y se registra el evento "NOTA_ENMENDAR"
```

## 6. Eventos de auditoría (Spec 003)
`HC_ABRIR`, `HC_VER_NOTA`, `ALERGIA_REGISTRAR`, `ALERGIA_INACTIVAR`, `ANTECEDENTE_REGISTRAR`, `ANTECEDENTE_CAMBIAR_ESTADO`, `NOTA_CREAR`, `NOTA_EDITAR_BORRADOR`, `NOTA_FIRMAR`, `NOTA_ANULAR_BORRADOR`, `NOTA_ENMENDAR`, `CATALOGO_ACTUALIZAR`.

## 7. Mapeo HL7 FHIR R4
| Entidad HCE | Recurso FHIR |
|---|---|
| `consultas` | `Encounter` (`status`: `in-progress` / `finished` / `cancelled`) + `Composition` (secciones SOAP) |
| Signos vitales | `Observation` (`category = vital-signs`, códigos LOINC estándar) |
| `diagnosticos_consulta` | `Condition` (`code` system `http://hl7.org/fhir/sid/icd-10`, `verificationStatus`) |
| `alergias` | `AllergyIntolerance` (`criticality`, `clinicalStatus`) |
| `antecedentes` | `Condition` (`problem-list-item`), `FamilyMemberHistory`, `Procedure` |
| Firma / Enmienda | `Provenance` (`signature`) |

## 8. Fuera de alcance
Récipes/prescripciones, órdenes médicas, adjuntos multimedia pesados (DICOM/imágenes), plantillas por especialidad configurables por usuario (versión futura), certificado X.509 SUSCERTE (interfaz `IFirmador` queda lista para enchufarlo en versión futura).

