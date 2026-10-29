-- Migración 002: Esquema de Usuarios, Roles y Permisos (Spec 001)

CREATE TABLE usuarios (
  id                INTEGER PRIMARY KEY,
  login             TEXT    NOT NULL UNIQUE COLLATE NOCASE,
  cedula            TEXT    NOT NULL UNIQUE,
  nombres           TEXT    NOT NULL,
  apellidos         TEXT    NOT NULL,
  email             TEXT,
  telefono          TEXT,
  clave_hash        TEXT    NOT NULL,
  clave_temporal    INTEGER NOT NULL DEFAULT 1 CHECK (clave_temporal IN (0,1)),
  clave_cambiada_utc TEXT,
  pin_hash          TEXT,
  estado            TEXT    NOT NULL DEFAULT 'A' CHECK (estado IN ('A','B','I')),
  bloqueado_hasta_utc TEXT,
  intentos_fallidos INTEGER NOT NULL DEFAULT 0,
  creado_utc        TEXT    NOT NULL,
  creado_por        INTEGER REFERENCES usuarios(id),
  version           INTEGER NOT NULL DEFAULT 1,
  CHECK (cedula GLOB '[VE]-[0-9]*' AND length(cedula) BETWEEN 3 AND 11)
) STRICT;

CREATE TRIGGER tr_usuarios_no_delete
BEFORE DELETE ON usuarios
BEGIN
  SELECT RAISE(ABORT, 'Prohibido eliminar usuarios');
END;

CREATE TABLE profesionales (
  usuario_id     INTEGER PRIMARY KEY REFERENCES usuarios(id),
  tipo           TEXT NOT NULL,
  mpps           TEXT NOT NULL UNIQUE,
  colegio        TEXT,
  nro_colegio    TEXT,
  especialidades TEXT
) STRICT;

CREATE TABLE claves_hist (
  id         INTEGER PRIMARY KEY,
  usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
  clave_hash TEXT    NOT NULL,
  creado_utc TEXT    NOT NULL
) STRICT;

CREATE TABLE roles (
  codigo  TEXT PRIMARY KEY,
  nombre  TEXT NOT NULL,
  sistema INTEGER NOT NULL DEFAULT 0 CHECK (sistema IN (0,1))
) STRICT, WITHOUT ROWID;

CREATE TABLE permisos (
  codigo      TEXT PRIMARY KEY,
  descripcion TEXT NOT NULL
) STRICT, WITHOUT ROWID;

CREATE TABLE rol_permisos (
  rol     TEXT NOT NULL REFERENCES roles(codigo),
  permiso TEXT NOT NULL REFERENCES permisos(codigo),
  PRIMARY KEY (rol, permiso)
) STRICT, WITHOUT ROWID;

CREATE TABLE usuario_roles (
  usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
  rol        TEXT    NOT NULL REFERENCES roles(codigo),
  PRIMARY KEY (usuario_id, rol)
) STRICT, WITHOUT ROWID;

CREATE TABLE roles_incompatibles (
  rol_a TEXT NOT NULL REFERENCES roles(codigo),
  rol_b TEXT NOT NULL REFERENCES roles(codigo),
  PRIMARY KEY (rol_a, rol_b)
) STRICT, WITHOUT ROWID;

CREATE TABLE sesiones (
  id         INTEGER PRIMARY KEY,
  usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
  equipo     TEXT    NOT NULL,
  ip         TEXT,
  inicio_utc TEXT    NOT NULL,
  fin_utc    TEXT,
  motivo_fin TEXT
) STRICT;

CREATE TABLE accesos_emergencia (
  id           INTEGER PRIMARY KEY,
  usuario_id   INTEGER NOT NULL REFERENCES usuarios(id),
  paciente_id  INTEGER NOT NULL,
  motivo       TEXT    NOT NULL CHECK (length(motivo) >= 20),
  inicio_utc   TEXT    NOT NULL,
  expira_utc   TEXT    NOT NULL,
  revisado_por INTEGER REFERENCES usuarios(id),
  revisado_utc TEXT,
  dictamen     TEXT
) STRICT;
