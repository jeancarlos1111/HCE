# ADR-001 — Motor de base de datos

- Estado: **Aceptado** (reemplaza propuesta Firebird) · Fecha: 2026-10-29

## Contexto
Alcance reducido a HC (SOAP, antecedentes, CIE-10) + estadísticas. Prioridad: bajo consumo de memoria, cero instalación de servidor, hardware antiguo (HDD mecánico, CPU modesta). Instalación **monopuesto**: una PC por consultorio, varios usuarios en turnos `[POR CONFIRMAR]`.

## Opciones
| Opción | Pro | Contra |
|---|---|---|
| **SQLite 3** | Archivo único, sin servicio, ~1 MB librería, agregaciones rápidas, respaldo = copiar archivo (API backup) | Un escritor a la vez; **no apto sobre carpeta compartida en red**; sin usuarios/privilegios BD; sin cifrado nativo |
| Firebird 4 | Multiusuario, privilegios, cifrado | Servicio, más RAM, instalación/administración |

## Decisión
**SQLite ≥ 3.37** vía `TSQLite3Connection` (SQLdb).
- Tablas `STRICT`, nombres `snake_case` plural (`pacientes`, `consultas`, `diagnosticos_consulta`, `cie10_catalog`).
- Fechas `TEXT` ISO-8601: `*_utc` = `YYYY-MM-DDTHH:NN:SS.ZZZZ` (UTC); `fecha_local` = `YYYY-MM-DD` (America/Caracas) para filtros y estadísticas.
- Booleanos `INTEGER CHECK (x IN (0,1))`.
- PRAGMAs por conexión:

```sql
PRAGMA foreign_keys = ON;        -- por conexión, obligatorio
PRAGMA journal_mode = WAL;       -- persistente; lectores no bloquean escritor
PRAGMA synchronous = FULL;       -- durabilidad de dato clínico ante corte eléctrico
PRAGMA busy_timeout = 5000;
PRAGMA cache_size = -8000;       -- 8 MB, acotar RAM
PRAGMA temp_store = FILE;
```
- Al cerrar: `PRAGMA optimize;`. Tras carga masiva (catálogo CIE-10): `ANALYZE;`.
- Escrituras con `BEGIN IMMEDIATE` (toma lock de escritura al inicio → sin deadlocks, serializa auditoría).
- Windows: distribuir `sqlite3.dll` fijado; Linux: verificar versión al arrancar (`sqlite_version()` ≥ 3.37), abortar si menor.

## Consecuencias
- Sin privilegios BD → inmutabilidad vía triggers `RAISE(ABORT)` + cadena hash + anclas (ADR-003). Alteración con acceso al archivo es **detectable, no impedible**.
- Cifrado en reposo → ADR-004.
- Multi-PC / red: fuera de alcance. Si surge, revisar ADR (Firebird o servicio central).
- Repositorios detrás de interfaces → cambio de motor localizado.
- Migraciones: `db/migrations/NNN_descripcion.sql`, versión en `PRAGMA user_version`.
