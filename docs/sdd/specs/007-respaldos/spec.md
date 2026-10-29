# Spec 007 — Respaldo y Recuperación (SQLite)

- Épica: EP-13 · Historia: HU-019
- Estado: Borrador · PO: `[nombre]` · Fecha: 2026-10-29
- Depende de: Spec 001 (rol ADMIN), Spec 003 (auditoría y verificador de cadena), ADR-001, ADR-004
- Normativa: Constitución Art. 1 (dato clínico nunca se pierde), Art. 2 (datos cifrados en reposo/respaldos), RNF-04

## 1. Problema / Objetivo
En una instalación monopuesto con SQLite local y hardware modesto (incluyendo discos mecánicos propensos a fallas o cortes eléctricos), el archivo de base de datos es el único repositorio de las historias clínicas. Si el disco falla o el equipo sufre robo/daño sin respaldo externo válido y cifrado, se pierde toda la historia clínica de la institución.
Objetivo: copias de seguridad consistentes en caliente (sin corromper el archivo WAL), verificadas, comprimidas, cifradas con AES-256 y con restauración asistida a prueba de errores.

## 2. Actores
- **ADMIN**: configura carpetas destino (local + unidad externa/USB), ejecuta respaldo manual, ejecuta restauración o simulacro de restauración.
- **Sistema**: ejecuta respaldo automático diario al cerrar la aplicación o al primer arranque del día si han pasado > 24 h sin respaldo exitoso.

## 3. Historias de usuario
- **HU-019** Como administrador quiero respaldos cifrados automáticos y manuales, y poder verificar y restaurar copias de seguridad con garantía de integridad.

## 4. Requisitos funcionales

| ID | Requisito | Prioridad |
|---|---|---|
| RF-007-01 | **Copia en caliente consistente**: nunca copiar el archivo `.db` con `CopyFile` del SO mientras está abierto; usar exclusivamente `VACUUM INTO '<archivo_temp>'` o la Online Backup API de SQLite (`sqlite3_backup_*`) | Must |
| RF-007-02 | **Verificación previa al empaquetado**: sobre la copia temporal ejecutar `PRAGMA quick_check;` (debe devolver `'ok'`) y calcular su hash SHA-256 | Must |
| RF-007-03 | **Cifrado y compresión**: comprimir (zlib/`TCompressionStream` nativo de FPC) y cifrar con **AES-256** (clave derivada con Argon2id de la frase de respaldo institucional) generando un paquete `.hcebak` junto a su manifiesto JSON (`.meta`: fecha UTC, versión de esquema, último `seq` y `hash` de auditoría, SHA-256 de la BD en claro) | Must |
| RF-007-04 | **Doble destino configurable**: carpeta local de respaldos + ruta secundaria (ej. memoria USB / disco externo montado). Si la ruta secundaria no está conectada, guarda en local y muestra aviso persistente `"Pendiente copia en medio externo"` | Must |
| RF-007-05 | **Respaldo automático diario**: al cerrar sesión/aplicación (o en el primer inicio del día si el último respaldo exitoso tiene > 24 h) | Must |
| RF-007-06 | **Política de retención (rotación)**: conservar últimos 14 respaldos diarios, 8 semanales y 12 mensuales en carpeta local; no borrar respaldos si quedan menos de 5 copias válidas | Should |
| RF-007-07 | **Alerta de salud de respaldos**: mostrar aviso en barra de estado para todos los usuarios si han pasado > 48 h sin respaldo exitoso o > 30 días sin prueba de restauración | Must |
| RF-007-08 | **Simulacro de restauración (prueba mensual RNF-04)**: descifra un `.hcebak` en una carpeta temporal, ejecuta `PRAGMA integrity_check;` y `TVerificadorCadena` de auditoría sin tocar la BD en producción, y registra la prueba exitosa | Must |
| RF-007-09 | **Restauración real**: solo ADMIN, exige frase de cifrado y motivo; antes de sobrescribir la BD actual hace un respaldo de salvaguarda (`pre_restore_<timestamp>.hcebak`), verifica integridad del paquete entrante, reemplaza atómicamente y registra `RESTAURACION` en la auditoría de la BD restaurada | Must |

## 5. Criterios de aceptación (Gherkin)

```gherkin
Característica: Respaldo y recuperación

  Escenario: Respaldo manual exitoso con copia en caliente
    Dado el sistema en uso con transacciones confirmadas en modo WAL
    Cuando ADMIN ejecuta "Respaldar ahora"
    Entonces el sistema genera una instantánea consistente mediante VACUUM INTO
    Y verifica PRAGMA quick_check = "ok"
    Y comprime y cifra el archivo como ".hcebak" con su manifiesto ".meta"
    Y registra el evento de auditoría "RESPALDO_OK"

  Escenario: Detección de respaldo corrupto o contraseña incorrecta en simulacro
    Dado un archivo ".hcebak" alterado en disco o una frase de respaldo incorrecta
    Cuando ADMIN ejecuta "Probar restauración (Simulacro)"
    Entonces el sistema detecta que el hash SHA-256 no coincide
    Y aborta sin modificar la base de datos activa

  Escenario: Simulacro mensual exitoso
    Dado un archivo ".hcebak" válido
    Cuando ADMIN ejecuta "Probar restauración (Simulacro)" con la frase correcta
    Entonces el sistema descifra en temporal, valida PRAGMA integrity_check y la cadena de auditoría
    Y elimina el archivo temporal al finalizar
    Y actualiza la fecha de última prueba de restauración exitosa

  Escenario: Alerta por falta de respaldo reciente
    Dado que el último respaldo exitoso ocurrió hace 50 horas
    Cuando cualquier usuario inicia sesión
    Entonces la barra de estado muestra en ámbar "Atención: más de 48 h sin respaldo de base de datos"

  Escenario: Restauración real con salvaguarda previa
    Dado que ADMIN selecciona un archivo ".hcebak" válido e ingresa la frase y el motivo
    Cuando confirma la restauración
    Entonces el sistema crea primero una copia de salvaguarda de la BD actual
    Y reemplaza la BD activa por la restaurada tras verificar su integridad
    Y registra el evento "RESTAURACION" en la cadena de auditoría
```

## 6. Eventos de auditoría (Spec 003)
`RESPALDO_OK`, `RESPALDO_ERROR`, `RESPALDO_SIMULACRO_OK`, `RESPALDO_SIMULACRO_ERROR`, `RESTAURACION`.

