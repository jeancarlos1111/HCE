# Spec 006 — Consentimiento Informado

- Épica: EP-10 · Historia: HU-007
- Estado: Borrador · PO: `[nombre]` · Fecha: 2026-10-29
- Depende de: Spec 001 (usuarios/roles/PIN), Spec 002 (pacientes y representante legal), Spec 003 (auditoría)
- FHIR: `Consent`
- Normativa: Ley Orgánica de Salud art. 69 (consentimiento informado previo), Código de Deontología Médica, LOPNNA (consentimiento por padre/madre/representante en menores de 18 años)

## 1. Problema / Objetivo
La atención médica, el tratamiento de datos clínicos y los procedimientos ambulatorios requieren el consentimiento libre e informado del paciente o de su representante legal.En un sistema de escritorio sin hardware de firma biométrica, el sistema debe registrar la constancia del consentimiento (y el soporte en papel firmado o aceptación verbal ante testigo en urgencias), verificar su vigencia antes de abrir o continuar la HC y permitir su revocación trazable.

## 2. Actores
| Rol | Acciones permitidas |
|---|---|
| RECEPCION | Registrar consentimiento general de admisión / tratamiento de datos e imprimir formato para firma en papel |
| MEDICO / ENFERMERIA | Registrar consentimiento general o de procedimiento específico, registrar excepción de urgencia, revocar a solicitud del paciente |
| DIRECCION_MEDICA | Consultar todos los consentimientos |

## 3. Historias de usuario
- **HU-007** Como profesional/recepcionista quiero registrar, imprimir y consultar el consentimiento informado del paciente (o de su representante legal) y gestionar su eventual revocación.

## 4. Tipos de consentimiento
1. `TRATAMIENTO_DATOS_ATENCION`: Consentimiento general de atención ambulatoria y resguardo de historia clínica electrónica (requisito en primera admisión).
2. `PROCEDIMIENTO_ESPECIFICO`: Procedimiento ambulatorio menor o acto médico específico (vinculado opcionalmente a una consulta).
3. `EXCEPCION_URGENCIA`: Atención de urgencia cuando el paciente no está en capacidad de consentir y no hay representante presente (Ley de Ejercicio de la Medicina).

## 5. Requisitos funcionales

| ID | Requisito | Prioridad |
|---|---|---|
| RF-006-01 | Registrar consentimiento indicando: paciente, tipo, plantilla/versión de texto legal, otorgante (`PACIENTE` o `REPRESENTANTE`), datos del otorgante (nombre, cédula, parentesco si es representante), modalidad de constancia (`FORMULARIO_FIRMADO`, `ACTA_TESTIGO`, `EXCEPCION_URGENCIA`), observaciones y usuario que da fe | Must |
| RF-006-02 | **Regla LOPNNA**: si el paciente es menor de 18 años a la fecha actual (salvo emancipado), el sistema exige que `otorgante = 'REPRESENTANTE'` con nombre, cédula y parentesco obligatorios (precargados desde `pacientes.representante_id` si existe) | Must |
| RF-006-03 | Al abrir la HC de un paciente sin `TRATAMIENTO_DATOS_ATENCION` vigente, mostrar aviso destacado en cabecera con botón directo para registrarlo o marcar `EXCEPCION_URGENCIA` | Must |
| RF-006-04 | Impresión ligera (HTML/texto para navegador del sistema o impresora, sin dependencias pesadas) del formato de consentimiento con los datos del paciente/representante y del médico/institución listos para firma manuscrita y archivo físico | Must |
| RF-006-05 | **Inmutabilidad y Revocación**: un consentimiento registrado no se edita ni se borra. El paciente o representante puede **Revocarlo** (`estado = 'REVOCADO'`) indicando fecha-hora, motivo y profesional que recibe la revocación | Must |
| RF-006-06 | Si el consentimiento general está `REVOCADO`, la HC queda en modo solo lectura para consultas históricas y exige nuevo consentimiento (o excepción de urgencia) para registrar nuevas consultas | Must |

## 6. Criterios de aceptación (Gherkin)

```gherkin
Característica: Consentimiento informado

  Escenario: Consentimiento de adulto por sí mismo
    Dado un paciente de 30 años con cédula "V-15000000"
    Cuando recepcionista registra consentimiento "TRATAMIENTO_DATOS_ATENCION" otorgado por "PACIENTE" con modalidad "FORMULARIO_FIRMADO"
    Entonces el consentimiento queda en estado "VIGENTE"
    Y se audita "CONSENTIMIENTO_REGISTRAR"

  Escenario: Paciente menor de edad exige representante (LOPNNA)
    Dado un paciente de 10 años
    Cuando se intenta registrar consentimiento con otorgante "PACIENTE"
    Entonces el sistema rechaza el registro indicando "Paciente menor de 18 años requiere consentimiento de su representante legal"

  Escenario: Registro con representante legal
    Dado un paciente de 10 años con madre representante "María Pérez" "V-12345678"
    Cuando registra consentimiento con otorgante "REPRESENTANTE"
    Entonces se precargan los datos de la madre y el consentimiento queda "VIGENTE"

  Escenario: Revocación de consentimiento
    Dado un paciente con consentimiento "VIGENTE"
    Cuando solicita revocar su consentimiento con motivo "Cambio de centro de salud"
    Entonces el consentimiento pasa a estado "REVOCADO" con fecha UTC y usuario receptor
    Y se audita "CONSENTIMIENTO_REVOCAR"
    Y no se permite iniciar nueva consulta sin registrar nuevo consentimiento o urgencia

  Escenario: Excepción de urgencia
    Dado un paciente sin consentimiento vigente que ingresa por urgencia
    Cuando el médico registra "EXCEPCION_URGENCIA" con justificación clínica
    Entonces puede registrar y firmar la consulta de urgencia
    Y se audita "CONSENTIMIENTO_URGENCIA"
```

## 7. Eventos de auditoría (Spec 003)
`CONSENTIMIENTO_REGISTRAR`, `CONSENTIMIENTO_REVOCAR`, `CONSENTIMIENTO_URGENCIA`, `CONSENTIMIENTO_IMPRIMIR`.

## 8. Fuera de alcance
Tabletas digitalizadoras de firma manuscrita (Wacom), escaneo/almacenamiento de PDFs pesados dentro de SQLite (para mantener la BD liviana; se guarda el código de ubicación del folio físico si aplica).

