# Spec 002 — Gestión de Pacientes (MPI)

- Épica: EP-02 · Historias: HU-004, HU-005, HU-006
- Estado: Borrador · PO: `[nombre]` · Fecha: 2026-10-29
- FHIR: `Patient`

## 1. Problema / Objetivo
Cada paciente debe tener identidad única y confiable. Duplicados o errores de identidad = riesgo clínico (información en HC equivocada). Objetivo: registrar, buscar y actualizar pacientes sin duplicados y con trazabilidad.

## 2. Actores
Recepcionista (crea/edita), Médico/Enfermería (consulta, edita contacto), Administrador (fusiona duplicados), Auditor (lee log).

## 3. Historias de usuario

### HU-004 Registrar paciente
Como recepcionista quiero registrar paciente con datos demográficos para abrir su historia clínica.

### HU-005 Buscar paciente
Como recepcionista quiero buscar paciente por documento o nombre para evitar duplicados y acceder rápido a su HC.

### HU-006 Editar datos demográficos
Como recepcionista quiero corregir datos del paciente conservando historial para mantener trazabilidad.

## 4. Requisitos funcionales

| ID | Requisito | Prioridad |
|---|---|---|
| RF-002-01 | Campos obligatorios: tipo doc, nro doc, nombres, primer apellido, fecha nacimiento, sexo biológico | Must |
| RF-002-02 | Campos opcionales: segundo apellido, género, estado civil, ocupación, dirección, teléfonos, email, grupo sanguíneo, contacto de emergencia, aseguradora | Must |
| RF-002-03 | Nro. de HC autogenerado, único, inmutable | Must |
| RF-002-04 | (tipo doc + nro doc) único; validación formato según tipo | Must |
| RF-002-05 | Antes de guardar, buscar posibles duplicados (mismo doc, o nombre+apellido+fecha nac. similares) y advertir | Must |
| RF-002-06 | Paciente sin documento (RN, indocumentado, NN): identificador temporal + marca | Should |
| RF-002-07 | Búsqueda por nro HC, doc, nombre/apellidos (parcial, sin acentos, sin mayúsculas) | Must |
| RF-002-08 | Edición guarda versión anterior (quién, cuándo, motivo) | Must |
| RF-002-09 | Nunca borrado físico; solo estado Inactivo/Fallecido (con fecha) | Must |
| RF-002-10 | Edad calculada, no almacenada | Must |
| RF-002-11 | Fusión de duplicados solo por Administrador, reversible, auditada | Could |

## 5. Criterios de aceptación (Gherkin)

```gherkin
Característica: Gestión de pacientes

  Escenario: Registro exitoso
    Dado un usuario con rol "Recepcionista" autenticado
    Y no existe paciente con documento "CI 12345678"
    Cuando registra paciente con todos los campos obligatorios válidos
    Entonces el sistema asigna un número de HC único
    Y el paciente queda en estado "Activo"
    Y se registra evento de auditoría "PACIENTE_CREAR"

  Escenario: Documento duplicado
    Dado existe paciente con documento "CI 12345678"
    Cuando se intenta registrar otro paciente con "CI 12345678"
    Entonces el sistema rechaza el registro
    Y muestra el paciente existente con opción de abrirlo

  Escenario: Posible duplicado por datos similares
    Dado existe paciente "María José Pérez" nacida "1980-05-10"
    Cuando se registra "Maria Jose Perez" nacida "1980-05-10" con otro documento
    Entonces el sistema muestra advertencia de posible duplicado
    Y exige confirmación explícita para continuar
    Y la confirmación queda auditada

  Escenario: Campo obligatorio faltante
    Cuando se intenta guardar sin fecha de nacimiento
    Entonces el sistema no guarda e indica el campo faltante

  Escenario: Búsqueda insensible a acentos
    Dado existe paciente "José Ñáñez"
    Cuando busca "jose nanez"
    Entonces aparece en resultados en menos de 1 segundo

  Escenario: Edición con historial
    Dado paciente con teléfono "0414-1111111"
    Cuando recepcionista cambia teléfono a "0414-2222222" con motivo "actualización"
    Entonces se guarda nuevo valor
    Y el historial muestra valor anterior, usuario, fecha y motivo
    Y se registra evento "PACIENTE_EDITAR" con valores antes/después

  Escenario: No se permite borrar
    Cuando cualquier usuario intenta eliminar un paciente
    Entonces la opción no existe; solo puede marcarse "Inactivo" o "Fallecido"

  Escenario: Acceso no autorizado
    Dado usuario con rol "Auditor"
    Cuando intenta editar un paciente
    Entonces el sistema deniega la acción y la audita
```

## 6. Reglas de negocio
- RN-1: Fecha nacimiento ≤ hoy y ≥ 1900-01-01.
- RN-2: Fecha fallecimiento ≥ fecha nacimiento; paciente fallecido no admite nuevas consultas (sí lectura).
- RN-3: Tipos doc Venezuela: Cédula `V-`, Cédula `E-`, Pasaporte (+ país), Menor sin cédula (`[cédula representante]-[orden]`, vincula representante — LOPNNA), Sin documento `NN-AAAAMMDD-NNN`. Ver [normativa-venezuela.md](../../normativa-venezuela.md).
- RN-4: Nro HC formato `HC-AAAA-NNNNNN` `[POR CONFIRMAR]`.

## 7. Mapeo FHIR Patient
| Campo | FHIR |
|---|---|
| Nro HC | `identifier[use=usual]` |
| Documento | `identifier[use=official]` (system por tipo) |
| Nombres/apellidos | `name.given` / `name.family` |
| Sexo biológico | `extension` sex / `gender` (administrativo) |
| Fecha nac. | `birthDate` |
| Fallecido | `deceasedDateTime` |
| Teléfono/email | `telecom` |
| Dirección | `address` |
| Contacto emergencia | `contact` |
| Activo | `active` |

## 8. Fuera de alcance
Agenda, foto/biometría, integración con registro nacional de identidad.

## 9. Preguntas abiertas
- ¿País y tipos de documento oficiales?
- ¿Se requiere registrar etnia/pueblo indígena por normativa?
- ¿Formato de nro HC heredado de sistema previo (migración)?

