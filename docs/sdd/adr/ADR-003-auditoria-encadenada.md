# ADR-003 — Auditoría encadenada en SQLite

- Estado: Propuesto (reescrito para SQLite) · Fecha: 2026-10-29

## Contexto
Constitución Art. 3. Log debe servir como prueba (Ley Delitos Informáticos, Ley Mensajes de Datos art. 4). SQLite no tiene procedimientos, privilegios ni transacciones autónomas.

## Decisión
- Hash SHA-256 encadenado calculado **en Pascal** (HashLib4Pascal, misma dependencia que ADR-002): `hash_n = SHA256(canon(evento_n) || hash_{n-1})`.
- Serialización: toda escritura en `BEGIN IMMEDIATE` → un solo escritor → leer `auditoria_cadena`, calcular, insertar, sin carreras.
- Triggers:
  - `BEFORE UPDATE/DELETE ON auditoria` → `RAISE(ABORT)`.
  - `BEFORE INSERT` valida `seq = ultimo_seq + 1` y `hash_prev = ultimo_hash`.
  - `AFTER INSERT` avanza `auditoria_cadena`.
- Eventos de error/denegación: tras `ROLLBACK`, en transacción propia corta (sustituye transacción autónoma).
- Hora: reloj del equipo en UTC. Si hora actual < última hora registrada − 5 min → evento `RELOJ_RETROCEDIDO` + aviso.
- Anclaje externo diario (archivo con HMAC, destino configurable) → detecta reescritura total de la cadena.

## Consecuencias
- Quien tenga el archivo (y la clave si hay cifrado, ADR-004) puede borrar triggers y alterar → **detectado** por verificador y anclas, no impedido. Aceptable para monopuesto; documentar en política de seguridad.
- Sin dependencia de funciones SQL especiales → portable.
- Volumen consultorio (< 1 evento/s) muy por debajo del límite de un escritor.
