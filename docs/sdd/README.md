# HCE — Spec-Driven Development (SDD) + Scrum

Sistema de Historia Clínica Electrónica (HCE). Escritorio Lazarus/Free Pascal.

## Flujo SDD por feature

```mermaid
flowchart LR
    A["Backlog: Historia de usuario"] --> B["spec.md (QUÉ y POR QUÉ)"]
    B --> C["Refinamiento + DoR"]
    C --> D["plan.md (CÓMO técnico)"]
    D --> E["tasks.md (tareas ≤ 1 día)"]
    E --> F["Sprint: implementar + tests"]
    F --> G["Review contra criterios Gherkin"]
    G --> H["DoD cumplido → Done"]
```

Regla: sin `spec.md` aprobado no hay código. Cambio de comportamiento = cambio de spec primero.

## Estructura

```
docs/sdd/
├── README.md              # este archivo: proceso
├── constitution.md        # principios no negociables
├── normativa-venezuela.md # marco legal aplicable
├── scrum.md               # roles, ceremonias, DoR, DoD, estimación
├── product-backlog.md     # épicas + historias priorizadas
├── roadmap.md             # releases y sprints
├── adr/                   # Architecture Decision Records
└── specs/
    └── NNN-nombre/
        ├── spec.md        # requisitos funcionales, criterios Gherkin
        ├── plan.md        # diseño técnico, datos, unidades Pascal
        └── tasks.md       # tareas atómicas trazables
```

## Convenciones

- IDs: Épica `EP-NN`, Historia `HU-NNN`, Requisito `RF-NNN-xx`, No funcional `RNF-xx`, Tarea `T-NNN-xx`.
- Prioridad: MoSCoW (Must / Should / Could / Won't).
- Estimación: puntos Fibonacci (1,2,3,5,8,13). >8 → dividir.
- Marcador `[POR CONFIRMAR]` = pendiente validar con Product Owner / plan de trabajo.

