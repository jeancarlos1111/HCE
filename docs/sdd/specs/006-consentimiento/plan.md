# Plan técnico 006 — Consentimiento Informado

Ref: [spec.md](spec.md) · ADR-001 (SQLite) · Constitución Art. 2, 3, 6, 10

## 1. Unidades Pascal

| Unidad | Contenido |
|---|---|
| `src/dominio/uConsentimiento.pas` | `TConsentimiento`, `TPlantillaConsentimiento`, enums `TTipoConsentimiento`, `TOtorgante`, `TModalidadConsentimiento`, `TEstadoConsentimiento` |
| `src/servicios/uConsentimientoService.pas` | `Registrar`, `Revocar`, `TieneVigente(pacienteId, tipo)`, `GenerarDocumentoImprimible` |
| `src/datos/uConsentimientoRepository.pas` | `IConsentimientoRepository` + `TConsentimientoRepositorySQLite` |
| `src/ui/ufrmConsentimiento.pas/.lfm` | Diálogo de alta, impresión de formato y revocación |
| `tests/TestConsentimientoService.pas` | FPCUnit |

## 2. Modelo de datos (SQLite STRICT)

```sql
CREATE TABLE plantillas_consentimiento (
  codigo     TEXT PRIMARY KEY,               -- 'GEN_ATENCION_V1', 'PROC_MENOR_V1'
  tipo       TEXT NOT NULL CHECK (tipo IN ('TRATAMIENTO_DATOS_ATENCION','PROCEDIMIENTO_ESPECIFICO')),
  titulo     TEXT NOT NULL,
  cuerpo_txt TEXT NOT NULL,                  -- texto con marcadores {{PACIENTE_NOMBRE}}, {{CEDULA}}, etc.
  activo     INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0,1))
) STRICT, WITHOUT ROWID;

CREATE TABLE consentimientos (
  id                INTEGER PRIMARY KEY,
  paciente_id       INTEGER NOT NULL REFERENCES pacientes(id),
  consulta_id       INTEGER REFERENCES consultas(id),
  tipo              TEXT    NOT NULL CHECK (tipo IN (
                      'TRATAMIENTO_DATOS_ATENCION','PROCEDIMIENTO_ESPECIFICO','EXCEPCION_URGENCIA')),
  plantilla_codigo  TEXT    REFERENCES plantillas_consentimiento(codigo),
  otorgante         TEXT    NOT NULL CHECK (otorgante IN ('PACIENTE','REPRESENTANTE','MEDICO_URGENCIA')),
  otorgante_nombre  TEXT    NOT NULL,
  otorgante_cedula  TEXT    NOT NULL,
  otorgante_parentesco TEXT,
  modalidad         TEXT    NOT NULL CHECK (modalidad IN (
                      'FORMULARIO_FIRMADO','ACTA_TESTIGO','EXCEPCION_URGENCIA')),
  folio_fisico      TEXT,                    -- referencia opcional a carpeta/archivo en papel
  observaciones     TEXT,
  estado            TEXT    NOT NULL DEFAULT 'VIGENTE' CHECK (estado IN ('VIGENTE','REVOCADO')),
  creado_utc        TEXT    NOT NULL,
  registrado_por    INTEGER NOT NULL REFERENCES usuarios(id),
  revocado_utc      TEXT,
  revocado_por      INTEGER REFERENCES usuarios(id),
  motivo_revocacion TEXT,
  hash_constancia   TEXT    NOT NULL CHECK (length(hash_constancia) = 64)
) STRICT;

CREATE INDEX ix_consent_paciente ON consentimientos(paciente_id, tipo, estado);

CREATE TRIGGER tr_consent_no_delete
BEFORE DELETE ON consentimientos
BEGIN
  SELECT RAISE(ABORT, 'Prohibido eliminar consentimientos');
END;

-- Solo se permite UPDATE para pasar de VIGENTE a REVOCADO
CREATE TRIGGER tr_consent_inmutable
BEFORE UPDATE ON consentimientos
WHEN OLD.estado = 'REVOCADO' OR NEW.estado <> 'REVOCADO' OR
     NEW.paciente_id <> OLD.paciente_id OR
     NEW.tipo <> OLD.tipo OR
     NEW.otorgante_cedula <> OLD.otorgante_cedula OR
     NEW.hash_constancia <> OLD.hash_constancia OR
     NEW.motivo_revocacion IS NULL OR length(NEW.motivo_revocacion) < 5
BEGIN
  SELECT RAISE(ABORT, 'Consentimiento solo puede actualizarse para revocacion con motivo');
END;
```

## 3. Impresión ligera sin dependencias pesadas
`GenerarDocumentoImprimible` reemplaza los marcadores `{{...}}` de `plantillas_consentimiento` en un archivo HTML autónomo temporal (`/tmp/consentimiento_<id>.html` con estilos `@media print` limpios) y lo abre con `OpenURL` del LCL (`LCLIntf`) para imprimir desde el visor del sistema, evitando incrustar motores de reporte pesados.

## 4. Pruebas
- Unitarias: regla LOPNNA (< 18 años exige representante con cédula y parentesco), bloqueo de nueva consulta si consentimiento está revocado salvo urgencia.
- Integración SQLite (`:memory:`): triggers `tr_consent_no_delete` y `tr_consent_inmutable`.

