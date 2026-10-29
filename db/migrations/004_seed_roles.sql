-- Migración 004: Catálogo de Roles, Permisos y Matriz Inicial (Spec 001 Plan §4)

-- Roles
INSERT INTO roles (codigo, nombre, sistema) VALUES
  ('ADMIN', 'Administrador del Sistema', 1),
  ('MEDICO', 'Medico Tratante', 1),
  ('ENFERMERIA', 'Personal de Enfermeria', 1),
  ('RECEPCION', 'Admision y Recepcion', 1),
  ('ESTADISTICA', 'Registros y Estadisticas de Salud', 1),
  ('AUDITOR', 'Auditoria y Control Interno', 1),
  ('DIR_MED', 'Direccion Medica', 1);

-- Permisos
INSERT INTO permisos (codigo, descripcion) VALUES
  ('USUARIO.GESTIONAR', 'Crear y editar usuarios'),
  ('ROL.GESTIONAR', 'Asignar roles y permisos'),
  ('CATALOGO.GESTIONAR', 'Cargar o actualizar catalogos'),
  ('RESPALDO.EJECUTAR', 'Ejecutar o probar respaldos'),
  ('PACIENTE.LEER', 'Consultar datos de pacientes'),
  ('PACIENTE.CREAR', 'Registrar nuevos pacientes'),
  ('PACIENTE.EDITAR', 'Modificar datos demograficos'),
  ('PACIENTE.CAMBIAR_ESTADO', 'Inactivar o marcar fallecido'),
  ('PACIENTE.FUSIONAR', 'Fusionar historias duplicadas'),
  ('HC.LEER', 'Consultar historia clinica SOAP'),
  ('HC.ESCRIBIR', 'Redactar notas o triaje'),
  ('HC.FIRMAR', 'Firmar electronicamente notas'),
  ('HC.ENMENDAR', 'Agregar enmiendas a notas firmadas'),
  ('HC.IMPRIMIR', 'Imprimir o generar copia de HC'),
  ('HC.EXPORTAR', 'Exportar datos clinicos'),
  ('HC.ACCESO_EMERGENCIA', 'Romper el cristal para urgencias'),
  ('ESTADISTICA.VER', 'Ver reportes e indicadores'),
  ('ESTADISTICA.VER_PROPIA', 'Ver estadisticas de atencion propia'),
  ('ESTADISTICA.EXPORTAR', 'Exportar reportes a CSV'),
  ('AUDITORIA.LEER', 'Consultar log de auditoria'),
  ('AUDITORIA.EXPORTAR', 'Exportar log o verificar integridad');

-- Matriz ROL - PERMISO
-- ADMIN
INSERT INTO rol_permisos VALUES
  ('ADMIN', 'USUARIO.GESTIONAR'),
  ('ADMIN', 'ROL.GESTIONAR'),
  ('ADMIN', 'CATALOGO.GESTIONAR'),
  ('ADMIN', 'RESPALDO.EJECUTAR');

-- MEDICO
INSERT INTO rol_permisos VALUES
  ('MEDICO', 'PACIENTE.LEER'),
  ('MEDICO', 'PACIENTE.CREAR'),
  ('MEDICO', 'PACIENTE.EDITAR'),
  ('MEDICO', 'PACIENTE.CAMBIAR_ESTADO'),
  ('MEDICO', 'HC.LEER'),
  ('MEDICO', 'HC.ESCRIBIR'),
  ('MEDICO', 'HC.FIRMAR'),
  ('MEDICO', 'HC.ENMENDAR'),
  ('MEDICO', 'HC.IMPRIMIR'),
  ('MEDICO', 'HC.ACCESO_EMERGENCIA'),
  ('MEDICO', 'ESTADISTICA.VER_PROPIA');

-- ENFERMERIA
INSERT INTO rol_permisos VALUES
  ('ENFERMERIA', 'PACIENTE.LEER'),
  ('ENFERMERIA', 'HC.LEER'),
  ('ENFERMERIA', 'HC.ESCRIBIR');

-- RECEPCION
INSERT INTO rol_permisos VALUES
  ('RECEPCION', 'PACIENTE.LEER'),
  ('RECEPCION', 'PACIENTE.CREAR'),
  ('RECEPCION', 'PACIENTE.EDITAR'),
  ('RECEPCION', 'PACIENTE.CAMBIAR_ESTADO');

-- ESTADISTICA
INSERT INTO rol_permisos VALUES
  ('ESTADISTICA', 'ESTADISTICA.VER'),
  ('ESTADISTICA', 'ESTADISTICA.EXPORTAR');

-- AUDITOR
INSERT INTO rol_permisos VALUES
  ('AUDITOR', 'AUDITORIA.LEER'),
  ('AUDITOR', 'AUDITORIA.EXPORTAR');

-- DIR_MED
INSERT INTO rol_permisos VALUES
  ('DIR_MED', 'PACIENTE.LEER'),
  ('DIR_MED', 'PACIENTE.CAMBIAR_ESTADO'),
  ('DIR_MED', 'PACIENTE.FUSIONAR'),
  ('DIR_MED', 'HC.LEER'),
  ('DIR_MED', 'HC.IMPRIMIR'),
  ('DIR_MED', 'HC.EXPORTAR'),
  ('DIR_MED', 'ESTADISTICA.VER'),
  ('DIR_MED', 'ESTADISTICA.EXPORTAR'),
  ('DIR_MED', 'AUDITORIA.LEER');

-- Incompatibilidad ADMIN y AUDITOR (separación de funciones)
INSERT INTO roles_incompatibles (rol_a, rol_b) VALUES ('ADMIN', 'AUDITOR');
INSERT INTO roles_incompatibles (rol_a, rol_b) VALUES ('AUDITOR', 'ADMIN');
