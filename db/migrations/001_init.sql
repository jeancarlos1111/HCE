-- Migración 000: Inicialización técnica
CREATE TABLE secuencias (
  nombre TEXT PRIMARY KEY,
  valor  INTEGER NOT NULL
) STRICT, WITHOUT ROWID;

INSERT INTO secuencias VALUES ('HC', 0);
