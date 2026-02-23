---
trigger: always_on
---

# 💳 Subscription & Access Control

## 1. Grace Period
- El sistema debe manejar tres estados de cuenta para el profesional: `active`, `past_due` (mora), `suspended`.
- **Regla de Acceso:** Si el estado es `suspended`, la UI debe bloquear la creación de nuevos turnos, pero permitir la consulta de datos existentes (modo lectura).

## 2. Middleware de Suscripción
- Cada vez que el profesional entra a la app, un `Provider` de Riverpod debe validar el estado de su suscripción antes de permitir acciones de escritura.