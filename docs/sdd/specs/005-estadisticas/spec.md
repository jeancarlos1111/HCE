# Spec 005 — Estadísticas e Indicadores Clínicos

- Épica: EP-14 · Historias: HU-030 … HU-036
- Estado: Borrador · PO: `[nombre]` · Fecha: 2026-10-29
- Depende de: Spec 004 (consultas SOAP firmadas + diagnósticos CIE-10), Spec 001 (permisos), Spec 003 (auditoría)
- Normativa: reportes de morbilidad del MPPS (EPI-15 consolidado semanal) `[POR CONFIRMAR formato vigente]`

## 1. Problema / Objetivo
Dirección y Registros y Estadísticas de Salud necesitan cifras confiables de morbilidad, demografía y producción sin transcribir a mano. Objetivo: reportes agregados instantáneos sobre consultas firmadas, exportables a CSV, sin exponer datos identificables.

## 2. Actores
| Rol | Uso |
|---|---|
| ESTADISTICA (nuevo) | Personal de Registros y Estadísticas de Salud: todos los reportes + exportación. **Sin acceso a contenido clínico** |
| DIRECCION_MEDICA | Todos los reportes + exportación |
| MEDICO | Solo reportes de su propia producción `[POR CONFIRMAR]` |

## 3. Historias de usuario
- **HU-030** Como estadístico quiero consolidado de morbilidad CIE-10 (top N) por rango de fechas, semana epidemiológica, mes o año, desglosado por sexo.
- **HU-031** Como estadístico quiero distribución de consultas por grupo etario y sexo.
- **HU-032** Como dirección quiero volumen de consultas por médico, especialidad y turno.
- **HU-033** Como estadístico quiero exportar cualquier reporte a CSV para LibreOffice Calc / Excel.
- **HU-034** Como estadístico quiero consolidado semanal de morbilidad (diagnóstico × grupo etario EPI × sexo) en formato EPI-15.
- **HU-035** Como dirección quiero tablero de indicadores del período.
- **HU-036** Como estadístico quiero tendencia por semana epidemiológica de un código CIE-10.

## 4. Reglas de negocio (fuente de verdad de los números)

| ID | Regla |
|---|---|
| RN-01 | Solo cuentan consultas **firmadas** (`estado = 'F'`). Borradores y anuladas excluidas |
| RN-02 | Fecha de corte = `fecha_local` de la consulta (America/Caracas), rango **inclusivo** en ambos extremos |
| RN-03 | Edad = edad del paciente **a la fecha de la consulta**, no a hoy |
| RN-04 | Sexo = sexo biológico registrado; categorías M, F, I (intersexual/no determinado). Toda tabla muestra columna I aunque sea 0 → totales cuadran |
| RN-05 | Morbilidad cuenta **diagnósticos** (un caso por diagnóstico por consulta). Filtro opcional "solo diagnóstico principal" |
| RN-06 | Tipo de caso por diagnóstico: N = primera vez (nuevo), S = sucesivo/control. Morbilidad por defecto: todos; filtro N/S |
| RN-07 | Semana epidemiológica: domingo a sábado; semana 1 = primera semana con ≥ 4 días en enero. Un año puede tener 53 semanas (ej. 2025) |
| RN-08 | Turno según hora local de inicio de consulta: Mañana 07:00–12:59, Tarde 13:00–18:59, Noche 19:00–06:59 `[POR CONFIRMAR]` |
| RN-09 | Especialidad = especialidad bajo la cual se registró la consulta (médico puede tener varias) |
| RN-10 | Grupos etarios configurables. Conjuntos predefinidos: **Simple** (Pediátrico 0–17 [LOPNNA], Adulto 18–59, Adulto mayor ≥ 60 [Ley Orgánica de Adultos Mayores]) y **EPI** (`<1, 1–4, 5–6, 7–9, 10–11, 12–14, 15–19, 20–24, 25–44, 45–59, 60–64, ≥65` `[POR CONFIRMAR contra EPI-15 vigente]`) |
| RN-11 | Paciente único = `paciente_id` distinto en el período |
| RN-12 | Reportes muestran solo agregados; sin nombres, cédulas ni nro HC |

## 5. Requisitos funcionales

| ID | Requisito | Prioridad |
|---|---|---|
| RF-005-01 | Filtro de período: rango libre (2 `TDateEdit`), semana epidemiológica (año + semana), mes, año | Must |
| RF-005-02 | Filtros opcionales: médico, especialidad, turno, solo principal, tipo de caso | Must |
| RF-005-03 | Reporte Morbilidad: código, descripción, total, M, F, I, % del total; top N (10/20/50/todos); fila de totales | Must |
| RF-005-04 | Reporte Demografía: grupo etario × sexo (M, F, I, total, %); conjunto Simple o EPI | Must |
| RF-005-05 | Reporte Volumen: agrupado por médico / especialidad / turno; total consultas, pacientes únicos, primera vez, sucesivas | Must |
| RF-005-06 | Exportar CSV del reporte en pantalla (UTF-8 con BOM, separador `;`, CRLF, decimales con coma) | Must |
| RF-005-07 | Nombre de archivo sugerido: `<reporte>_<desde>_<hasta>.csv` | Must |
| RF-005-08 | EPI-15: filas = códigos CIE-10, columnas = grupos EPI × (M, F), totales | Should |
| RF-005-09 | Indicadores: total atenciones, pacientes únicos, consultas/paciente, % primera vez, promedio diario (días con atención), top 5 diagnósticos, distribución por sexo | Should |
| RF-005-10 | Tendencia: conteo por semana epidemiológica de un código o capítulo CIE-10 (tabla; gráfico `TChart` opcional) | Could |
| RF-005-11 | Reporte vacío muestra "Sin datos para el período" y no permite exportar | Must |
| RF-005-12 | Cálculo en hilo secundario si > 500 ms, con indicador de progreso y botón cancelar; UI no se congela | Should |

## 6. Criterios de aceptación (Gherkin)

```gherkin
Característica: Morbilidad CIE-10

  Antecedentes:
    Dado consultas firmadas en octubre 2026:
      | paciente | sexo | fecha      | diagnósticos (principal primero) |
      | P1       | F    | 2026-10-01 | J00, R50.9                       |
      | P2       | M    | 2026-10-15 | J00                              |
      | P3       | F    | 2026-10-31 | A09                              |
    Y una consulta en borrador del 2026-10-20 con J00
    Y una consulta firmada del 2026-11-01 con J00

  Escenario: Rango inclusivo y solo firmadas
    Cuando genera morbilidad del 2026-10-01 al 2026-10-31
    Entonces J00 tiene total 2, M 1, F 1, I 0
    Y A09 tiene total 1 (consulta del último día incluida)
    Y la consulta en borrador y la de noviembre no se cuentan
    Y la fila de totales suma 4 diagnósticos

  Escenario: Solo diagnóstico principal
    Cuando genera morbilidad del mismo rango con "solo principal"
    Entonces R50.9 no aparece y el total es 3

  Escenario: Semana epidemiológica que cruza años
    Cuando selecciona semana epidemiológica 53 de 2025
    Entonces el rango aplicado es 2025-12-28 al 2026-01-03

  Escenario: Hora local vs UTC
    Dado consulta firmada iniciada el 2026-10-31 22:30 hora de Caracas (2026-11-01 02:30 UTC)
    Cuando genera morbilidad de octubre 2026
    Entonces la consulta se cuenta en octubre

Característica: Demografía

  Escenario: Edad a la fecha de consulta
    Dado paciente nacido 2008-11-10 atendido el 2026-10-29
    Cuando genera demografía con conjunto Simple
    Entonces se cuenta como Pediátrico (17 años), no como Adulto

  Escenario: Totales cuadran
    Cuando genera demografía de cualquier período
    Entonces la suma de todos los grupos es igual al total de consultas firmadas del período

Característica: Volumen

  Escenario: Pacientes únicos
    Dado paciente P1 con 3 consultas firmadas en el período con el mismo médico
    Cuando genera volumen por médico
    Entonces ese médico muestra 3 consultas y 1 paciente único

Característica: Exportación CSV

  Escenario: CSV compatible con Calc y Excel
    Dado reporte de morbilidad con diagnóstico "Faringitis aguda, no especificada"
    Cuando exporta a CSV
    Entonces el archivo empieza con BOM UTF-8
    Y usa ";" como separador y CRLF como fin de línea
    Y al abrirlo en Excel/Calc los acentos se ven correctos y los totales son numéricos

  Escenario: Comillas y caracteres especiales
    Dado una descripción que contiene comillas dobles y punto y coma
    Cuando exporta
    Entonces la celda sale entre comillas con comillas internas duplicadas

  Escenario: Inyección de fórmulas neutralizada
    Dado un texto que empieza con "=" "+" "-" o "@"
    Cuando exporta
    Entonces la celda se antepone con apóstrofo y no se ejecuta como fórmula

  Escenario: Exportación auditada
    Cuando exporta un reporte
    Entonces se registra "ESTADISTICA_EXPORTAR" con tipo de reporte, filtros y nombre de archivo

Característica: Seguridad

  Escenario: Rol ESTADISTICA sin contenido clínico
    Dado usuario con rol ESTADISTICA
    Cuando intenta abrir la HC de un paciente
    Entonces el sistema deniega y audita "ACCESO_DENEGADO"

  Escenario: Rendimiento
    Dado 300 000 consultas firmadas (5 años) en hardware mínimo RNF-09
    Cuando genera morbilidad de 1 año
    Entonces el resultado aparece en menos de 1 segundo
```

## 7. Eventos de auditoría
`ESTADISTICA_EXPORTAR` (siempre). `ESTADISTICA_CONSULTAR` `[POR CONFIRMAR: útil o ruido]`.

## 8. Fuera de alcance
Tasas poblacionales (incidencia/prevalencia: requieren población de referencia), envío electrónico al MPPS, enfermedades de notificación obligatoria (EPI-12), gráficos avanzados, drill-down a pacientes.

## 9. Preguntas abiertas
- Formato EPI-15 vigente (grupos etarios exactos, columnas).
- ¿Médico ve producción de otros médicos?
- Horarios de turno de la institución.
- ¿Se requiere reporte por procedencia (municipio/parroquia)? Implica campo en Spec 002.

