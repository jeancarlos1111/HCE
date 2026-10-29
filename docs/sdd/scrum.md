# Marco Scrum

## Roles
| Rol | Responsabilidad |
|---|---|
| Product Owner | Prioriza backlog, aprueba `spec.md`, acepta historias. Idealmente con perfil clínico o asesor médico. |
| Scrum Master | Facilita ceremonias, elimina impedimentos. |
| Equipo Dev | Escribe `plan.md`/`tasks.md`, implementa, prueba. |
| Asesor clínico / legal | Valida reglas clínicas y normativa (stakeholder). |

## Sprint: 2 semanas
| Ceremonia | Duración | Salida |
|---|---|---|
| Refinamiento | 1–2 h/semana | Specs con DoR cumplido |
| Sprint Planning | 2 h | Sprint backlog + `tasks.md` |
| Daily | 15 min | Impedimentos |
| Sprint Review | 1 h | Demo vs criterios Gherkin |
| Retrospectiva | 1 h | Acciones de mejora |

## Definition of Ready (DoR) — historia entra a sprint si:
- [ ] Formato "Como… quiero… para…"
- [ ] `spec.md` aprobado por PO
- [ ] Criterios de aceptación en Gherkin
- [ ] Reglas clínicas/normativas validadas
- [ ] Estimada ≤ 8 puntos
- [ ] Dependencias resueltas o identificadas

## Definition of Done (DoD)
- [ ] Código en rama principal vía PR revisado
- [ ] Tests FPCUnit pasan; criterios Gherkin verificados
- [ ] Eventos de auditoría implementados (Art. 3)
- [ ] Permisos RBAC aplicados (Art. 2)
- [ ] Migración de BD incluida y reversible
- [ ] Sin warnings nuevos de compilación
- [ ] `spec.md`/`plan.md` actualizados si hubo cambios
- [ ] Demo aceptada por PO

## Métricas
Velocidad (puntos/sprint), burndown, defectos escapados, lead time por historia.

