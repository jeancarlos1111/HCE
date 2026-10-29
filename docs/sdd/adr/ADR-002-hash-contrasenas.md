# ADR-002 — Almacenamiento de contraseñas y PIN de firma

- Estado: Propuesto · Fecha: 2026-10-29

## Contexto
Constitución Art. 2, RNF-02. FPC estándar no trae Argon2/bcrypt.

## Opciones
| Opción | Pro | Contra |
|---|---|---|
| HashLib4Pascal (Argon2id, PBKDF2, scrypt) | Puro Pascal, MIT, FPC+Delphi, multiplataforma | Dependencia externa |
| DCPcrypt + PBKDF2 propio | Conocido | PBKDF2 a mano = riesgo |
| fcl-hash SHA-256 iterado | Sin dependencias | No es KDF estándar |

## Decisión
**HashLib4Pascal, Argon2id** (m=64 MiB, t=3, p=1; ajustar a ~300 ms en equipo objetivo). Sal aleatoria 16 bytes por usuario. Formato PHC: `$argon2id$v=19$m=65536,t=3,p=1$<sal>$<hash>`. Mismo esquema para PIN de firma (hash separado).

## Consecuencias
- Parámetros en string PHC → subir costo sin migración forzada (rehash en próximo login).
- Abstraer en `IPasswordHasher` → reemplazable.

