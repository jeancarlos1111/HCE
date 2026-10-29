# Sistema de Historia Clínica Electrónica (HCE)

Sistema de escritorio ligero, seguro y de alta eficiencia para la gestión de **Historias Clínicas Electrónicas (HCE)** e indicadores de salud en consultorios y centros ambulatorios, desarrollado en **Free Pascal** y **Lazarus (LCL)** con almacenamiento local en **SQLite**.

---

## 📌 Alcance y Propósito

El sistema está diseñado específicamente para el registro clínico asistencial y la vigilancia epidemiológica en Venezuela:

- **Registro Clínico SOAP**: Subjetivo, Objetivo, Análisis/Diagnóstico y Plan.
- **Codificación Diagnóstica**: Catálogo internacional **CIE-10** para clasificación de morbilidad.
- **Estadísticas de Salud**: Indicadores epidemiológicos y reportes agregados instantáneos (morbilidad por edad, sexo y período) exportables a CSV/Calc/Excel.
- **Exclusión por Diseño (Constitución Art. 9)**: Se eliminó intencionalmente la emisión e impresión de récipes, recetas y órdenes médicas para optimizar el rendimiento, garantizar ligereza y cumplir estrictamente el alcance asistencial.

---

## 🛡️ Principios Arquitectónicos y Seguridad

1. **Inmutabilidad de Datos Clínicos**:
   - Una nota clínica firmada **nunca se sobrescribe ni se elimina** (bloqueo por triggers a nivel de SQLite).
   - Cualquier rectificación se realiza como una nueva versión o enmienda auditada con autor, fecha y motivo.
2. **Auditoría Criptográfica Encadenada (Blockchain Local)**:
   - Todo acceso, creación o modificación registra un evento inmutable con fecha-hora UTC.
   - Cada registro de auditoría almacena el SHA-256 del registro anterior (`hash_anterior`), permitiendo detectar cualquier alteración o borrado malicioso en el archivo de base de datos.
3. **Autenticación Fuerte y Tiempo Constante**:
   - Contraseñas protegidas mediante **PBKDF2-HMAC-SHA256** (100.000 iteraciones).
   - Verificación de credenciales en tiempo constante (protección contra ataques de canal lateral / timing attacks).
   - Bloqueo automático temporal tras 5 intentos fallidos consecutivos.
4. **Separación de Funciones (SoD - Segregation of Duties)**:
   - El rol **AUDITOR** es estrictamente incompatible con **ADMINISTRADOR** y roles asistenciales clínicos.
5. **Cumplimiento Normativo (Venezuela)**:
   - Identificación con Cédula de Identidad (`V-` / `E-`).
   - Matrícula del Ministerio del Poder Popular para la Salud (**M.P.P.S.**) y número de colegiatura obligatorios para profesionales asistenciales (Ley del Ejercicio de la Medicina, Código de Deontología Médica y LOPNNA).
6. **Eficiencia en Hardware Modesto**:
   - Consumo de memoria RAM **< 100 MB**.
   - Inicio en menos de **3 segundos**.
   - Conexión SQLite en modo **WAL** (Write-Ahead Logging) nativo mediante SQLdb (`TSQLite3Connection`), sin dependencias pesadas ni frameworks externos.

---

## 📂 Estructura del Proyecto

El código fuente sigue una arquitectura limpia (*Clean Architecture*) desacoplada por capas:

```
HCE/
├── db/
│   └── migrations/            # Scripts SQL versionados (001_init, 002_usuarios, etc.)
├── docs/
│   └── sdd/                   # Documentación Spec-Driven Development (Specs, ADRs, Scrum)
├── src/
│   ├── comun/                 # Interfaces base y servicios de tiempo (IReloj, TRelojSistema)
│   ├── dominio/               # Entidades del negocio (TUsuario, TProfesional, uPermisos)
│   ├── seguridad/             # PBKDF2, SHA-256 nativo, políticas de contraseñas y sesión
│   ├── auditoria/             # Motor de auditoría SQLite, canónico y verificación SHA-256
│   ├── datos/                 # Conexión SQLite, migrador automático y repositorios
│   ├── servicios/             # Casos de uso (Autenticación, Gestión de Usuarios)
│   └── ui/                    # Formularios LCL (ufrmLogin, ufrmUsuarios, unit1)
├── tests/                     # Suite de pruebas automatizadas con FPCUnit
│   ├── doubles/               # Mocks y fakes para pruebas aisladas
│   ├── hce_tests.lpi          # Proyecto de pruebas para Lazarus
│   └── hce_tests.lpr          # Runner de pruebas de consola
├── project1.lpi               # Proyecto principal Lazarus
├── project1.lpr               # Punto de entrada de la aplicación
├── unit1.pas / unit1.lfm      # Formulario y panel principal de la aplicación
└── .gitignore                 # Exclusiones de binarios, caché y bases de datos
```

---

## 🚀 Requisitos del Sistema

- **Sistema Operativo**: Linux (Debian, Ubuntu, Fedora, Arch) o Windows (7 / 10 / 11).
- **Compilador**: Free Pascal Compiler (**FPC 3.2.2** o superior).
- **IDE**: **Lazarus 3.0** o superior (probado en Lazarus 4.0 con widgetset GTK2/Win32).
- **Base de Datos**: Biblioteca dinámica de SQLite 3 (`libsqlite3.so` en Linux / `sqlite3.dll` en Windows).
- **Paquetes Requeridos en Lazarus**:
  - `LCL` (Lazarus Component Library - estándar)
  - `SQLDBLaz` (Componentes SQLdb integrados en Lazarus)

---

## ⚙️ Compilación y Ejecución

### Opción 1: Desde la Interfaz Gráfica (Lazarus IDE)

1. Abrir Lazarus.
2. Ir a **Proyecto → Abrir Proyecto...** y seleccionar `project1.lpi`.
3. Presionar **F9** (o Menú **Ejecutar → Ejecutar**).

### Opción 2: Desde la Línea de Comandos (`lazbuild`)

```bash
# Compilar la aplicación principal
lazbuild project1.lpi

# Ejecutar la aplicación
./project1
```

### Ejecución de Pruebas Automatizadas (FPCUnit)

El proyecto cuenta con una batería de pruebas unitarias y de integración que validan criptografía, transacciones SQLite, triggers de inmutabilidad y reglas de autenticación:

```bash
# Compilar la suite de pruebas
lazbuild tests/hce_tests.lpi

# Ejecutar las pruebas
./bin/hce_tests --all --format=plain
```

---

## 🔑 Credenciales Iniciales de Acceso

Al ejecutarse por primera vez, el sistema crea automáticamente la base de datos `hce.db`, ejecuta las migraciones de esquema y registra el superusuario administrativo inicial:

- **Usuario:** `admin`
- **Cédula:** `V-00000001`
- **Contraseña Temporal:** `Admin2026!`

*(Por política de seguridad del sistema, se solicitará el cambio de contraseña en el primer inicio de sesión).*

---

## 📋 Metodología de Desarrollo

El desarrollo se rige por **Spec-Driven Development (SDD)** complementado con el marco de trabajo **Scrum**:

1. **Constitución**: Principios no negociables del producto (`docs/sdd/constitution.md`).
2. **Especificación (`spec.md`)**: Requisitos funcionales y criterios de aceptación en formato Gherkin (Given/When/Then).
3. **Diseño Técnico (`plan.md`)**: Arquitectura de componentes, modelos relacionales y contratos de interfaces.
4. **Tareas (`tasks.md`)**: Desglose de actividades atómicas trazables por sprint.
5. **Decisiones de Arquitectura (`docs/sdd/adr/`)**:
   - `ADR-001`: Uso de SQLite STRICT con modo WAL nativo.
   - `ADR-002`: Hash de contraseñas con PBKDF2-HMAC-SHA256 en tiempo constante.
   - `ADR-003`: Pista de auditoría append-only con hash SHA-256 encadenado.
   - `ADR-004`: Estrategia de cifrado de base de datos en reposo.

---

## 📄 Licencia

Este proyecto está bajo desarrollo para el sector salud. Todos los derechos reservados.

