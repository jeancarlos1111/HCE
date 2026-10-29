-- Migración 003: Esquema de Auditoría Encadenada (Spec 003)

CREATE TABLE auditoria (
  seq         INTEGER PRIMARY KEY,
  fecha_utc   TEXT    NOT NULL,
  usuario_id  INTEGER,
  login_txt   TEXT,
  roles       TEXT,
  sesion_id   INTEGER,
  equipo      TEXT,
  ip          TEXT,
  accion      TEXT    NOT NULL,
  entidad     TEXT,
  entidad_id  TEXT,
  paciente_id INTEGER,
  resultado   TEXT    NOT NULL CHECK (resultado IN ('O','D','E')),
  motivo      TEXT,
  datos       TEXT,
  hash_datos  TEXT,
  hash_prev   TEXT    NOT NULL CHECK (length(hash_prev) = 64),
  hash        TEXT    NOT NULL CHECK (length(hash) = 64)
) STRICT;

CREATE INDEX ix_aud_fecha    ON auditoria(fecha_utc);
CREATE INDEX ix_aud_usuario  ON auditoria(usuario_id, seq DESC);
CREATE INDEX ix_aud_paciente ON auditoria(paciente_id, seq DESC);
CREATE INDEX ix_aud_accion   ON auditoria(accion, seq DESC);

CREATE TABLE auditoria_cadena (
  id               INTEGER PRIMARY KEY CHECK (id = 1),
  ultimo_seq       INTEGER NOT NULL,
  ultimo_hash      TEXT    NOT NULL CHECK (length(ultimo_hash) = 64),
  ultima_fecha_utc TEXT    NOT NULL
) STRICT;

-- Estado génesis: seq 0 y hash génesis fijo
INSERT INTO auditoria_cadena (id, ultimo_seq, ultimo_hash, ultima_fecha_utc)
VALUES (1, 0, '0000000000000000000000000000000000000000000000000000000000000000', '1970-01-01T00:00:00.000');

CREATE TABLE auditoria_anclas (
  fecha   TEXT PRIMARY KEY,
  seq     INTEGER NOT NULL,
  hash    TEXT    NOT NULL,
  destino TEXT
) STRICT, WITHOUT ROWID;

-- Inmutabilidad de auditoría
CREATE TRIGGER tr_aud_no_update
BEFORE UPDATE ON auditoria
BEGIN
  SELECT RAISE(ABORT, 'Registro de auditoria inmutable');
END;

CREATE TRIGGER tr_aud_no_delete
BEFORE DELETE ON auditoria
BEGIN
  SELECT RAISE(ABORT, 'Registro de auditoria inmutable');
END;

CREATE TRIGGER tr_aud_check_chain
BEFORE INSERT ON auditoria
BEGIN
  SELECT CASE
    WHEN NEW.seq <> (SELECT ultimo_seq + 1 FROM auditoria_cadena WHERE id = 1)
      THEN RAISE(ABORT, 'Secuencia de auditoria invalida')
    WHEN NEW.hash_prev <> (SELECT ultimo_hash FROM auditoria_cadena WHERE id = 1)
      THEN RAISE(ABORT, 'Hash previo de auditoria invalido')
  END;
END;

CREATE TRIGGER tr_aud_advance_chain
AFTER INSERT ON auditoria
BEGIN
  UPDATE auditoria_cadena
     SET ultimo_seq = NEW.seq,
         ultimo_hash = NEW.hash,
         ultima_fecha_utc = NEW.fecha_utc
   WHERE id = 1;
END;

