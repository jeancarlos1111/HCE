# Constitución del Proyecto HCE

Principios no negociables. Toda spec, plan y PR se valida contra esto.

## Art. 1 — Seguridad del paciente primero
Dato clínico nunca se pierde ni se sobrescribe. Registros clínicos firmados son **inmutables**: corrección = nueva versión/enmienda con motivo, autor y fecha. Alertas (alergias, interacciones) visibles siempre en cabecera del paciente.

## Art. 2 — Privacidad y confidencialidad
- Acceso mínimo necesario (RBAC por rol + relación asistencial).
- Datos sensibles cifrados en reposo (BD/backups) y en tránsito (si cliente-servidor).
- Cumplimiento marco venezolano: CRBV arts. 28 y 60, Ley Orgánica de Salud art. 69, Código de Deontología Médica (secreto médico), Ley Especial contra los Delitos Informáticos. Ver [normativa-venezuela.md](normativa-venezuela.md).
- Consentimiento informado registrado y consultable.

## Art. 3 — Trazabilidad total (auditoría)
Toda lectura de HC, creación, modificación, firma, impresión y exportación genera evento de auditoría: usuario, rol, fecha-hora (UTC + local), equipo, acción, entidad, valor anterior/nuevo. Log de auditoría append-only, encadenado por hash.

## Art. 4 — Firma electrónica
Nota clínica se cierra con firma electrónica del profesional (credencial + PIN/certificado). Tras firmar: solo lectura. Base: firma electrónica simple (credencial + PIN). Diseño preparado para certificado X.509 de PSC acreditado ante SUSCERTE (Decreto-Ley sobre Mensajes de Datos y Firmas Electrónicas, arts. 16–18) `[POR CONFIRMAR: exigencia institucional]`.

## Art. 5 — Interoperabilidad por estándares
- Modelo interno mapeable a **HL7 FHIR R4** (Patient, Practitioner, Encounter, Condition, Observation, AllergyIntolerance, FamilyMemberHistory, Procedure, Consent, AuditEvent). Exportación FHIR fuera del alcance actual; el modelo no debe impedirla.
- Diagnósticos codificados **CIE-10** (soporte futuro CIE-11 vía tabla de mapeo).
- Nada de texto libre donde existe catálogo codificado (texto libre complementa, no reemplaza).

## Art. 6 — Arquitectura
- Lazarus/FPC, capas separadas: UI (LCL forms) → Servicios (lógica dominio) → Repositorios (SQLdb) → BD.
- Formularios **sin SQL ni lógica de negocio**.
- BD: SQLite ≥ 3.37 monopuesto, WAL, `STRICT`. Cifrado según ADR-004. Ver ADR-001.
- Migraciones de esquema versionadas, nunca cambios manuales.

## Art. 7 — Calidad
- Test-first en capa servicios (FPCUnit). Cobertura servicios ≥ 70 %.
- Cada criterio Gherkin de spec tiene test o caso de prueba manual documentado.
- Compila sin warnings nuevos. Revisión de código obligatoria.

## Art. 8 — Usabilidad clínica
Registro de consulta típica ≤ 3 min. Navegación completa por teclado. Sin pérdida de datos ante cierre inesperado (autoguardado borrador cada 30 s).

## Art. 9 — Simplicidad y alcance
YAGNI. Feature fuera de backlog priorizado no se construye. Dependencias externas justificadas en ADR.

**Alcance:** registro de historia clínica (SOAP, antecedentes, alergias, CIE-10, firma) + estadísticas e indicadores. **Excluido:** emisión/impresión de récipes, prescripciones y órdenes médicas.

## Art. 10 — Eficiencia
Aplicación apta para hardware antiguo: RAM de proceso ≤ 100 MB en uso normal, arranque ≤ 3 s, reportes estadísticos de 1 año ≤ 1 s en HDD mecánico. Sin dependencias pesadas (sin motores de reportes externos, sin runtime adicional).

