# ADR-004 — Cifrado en reposo con SQLite

- Estado: **Pendiente decisión PO** · Fecha: 2026-10-29

## Contexto
Constitución Art. 2 exige cifrado en reposo. SQLite estándar no cifra. Robo de PC/disco = filtración de HC (secreto médico, CRBV art. 60).

## Opciones
| Opción | Pro | Contra |
|---|---|---|
| A. **SQLCipher** (edición comunitaria, BSD) | Cifra BD + WAL + temporales (AES-256). Misma API C: SQLdb carga la librería cambiando `SQLiteLibraryName`; clave vía `PRAGMA key` | Compilar/distribuir librería por plataforma; ~5–15 % más CPU; gestión de clave |
| B. Cifrado de disco del SO (LUKS / BitLocker) | Cero cambios en código | Depende de configuración del cliente; no protege con equipo encendido/sesión abierta; no protege copias de BD |
| C. Cifrar solo campos sensibles en app | Selectivo | Rompe búsquedas/estadísticas, complejo, propenso a errores |

## Propuesta
**A (SQLCipher)** + respaldos cifrados. B como recomendación adicional de instalación.

Gestión de clave: clave maestra aleatoria 256 bits, guardada envuelta (cifrada) con clave derivada (Argon2id) de una **frase de instalación** que el ADMIN ingresa en primer arranque; copia en sobre sellado/custodia institucional. Sin frase → BD irrecuperable (documentar).

`[POR CONFIRMAR]`: ¿pedir frase en cada arranque (más seguro) o guardar envuelta con clave del equipo/usuario SO (más cómodo)?

