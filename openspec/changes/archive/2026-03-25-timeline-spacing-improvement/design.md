## Context

El timeline vertical usa `_kPixelsPerMinute = 1.2`, lo que resulta en cards demasiado bajos para turnos comunes (30 min → 36dp, 60 min → 72dp). Esto activó un sistema de progressive disclosure que oculta el nombre del paciente y el botón "Cobrar" — las dos piezas más valiosas para el profesional. La solución anterior (overflow-fix) añadió la lógica de disclosure, pero la raíz del problema es la escala insuficiente.

## Goals / Non-Goals

**Goals:**
- Que turnos de ≥ 30 min muestren siempre nombre + botón "Cobrar" sin recortes.
- Mantener el auto-scroll y el indicador de hora actual funcionando correctamente con la nueva escala.
- Para días que no son hoy, auto-scroll al primer turno del día.
- Simplificar los thresholds de progressive disclosure ahora que la mayoría de turnos tienen espacio suficiente.

**Non-Goals:**
- Rediseño visual del card (colores, tipografía).
- Virtualización del timeline (no hay problema de performance con ~20 cards).
- Cambios en la lógica de `assignColumns` o el overflow badge.

## Decisions

### D1 — `_kPixelsPerMinute` de 1.2 a 2.0

**Elegido:** 2.0 px/min. Resultados:
| Duración | Antes (1.2) | Después (2.0) | Threshold superado |
|----------|-------------|---------------|-------------------|
| 15 min   | 18dp → 48dp (clamp) | 30dp → 56dp (clamp) | Solo hora+nombre |
| 30 min   | 36dp → 48dp (clamp) | 60dp | Hora+nombre |
| 45 min   | 54dp | 90dp | Layout completo |
| 60 min   | 72dp | 120dp | Layout completo |

Con 2.0, turnos de ≥ 45 min (el caso más común en salud) muestran layout completo. Turnos de 30 min muestran hora + nombre, y solo turnos rarísimos de 15 min quedan en modo compacto.

**Alternativa descartada:** 1.6 px/min — mejora parcial, 30 min = 48dp aún forzaría clamp; no resuelve el caso de 45 min que queda en 72dp (sin botón Cobrar).

**Alternativa descartada:** 2.4 px/min — timeline demasiado largo (2160px para 15h), scrolleo excesivo sin ganancia significativa vs 2.0.

### D2 — `_kMinCardHeight` de 48.0 a 56.0

**Elegido:** 56dp mínimo. Con la nueva escala, solo turnos de < 28 min necesitan clamp. A 56dp cabe hora + nombre (el mínimo útil). Con 48dp solo cabía la hora.

### D3 — Thresholds de progressive disclosure

**Elegido:** Mantener la lógica de 3 niveles pero ajustar:
- `height < 56dp`: no ocurre en la práctica (mínimo clamp es 56dp), pero se mantiene como safety net → solo `_CardTopRow`.
- `56dp ≤ height < 90dp`: `_CardTopRow` + nombre.
- `height ≥ 90dp`: layout completo (nombre, concepto, botón Cobrar).

El threshold para layout completo sube de 80 a 90dp para dar un poco más de padding vertical al card cuando incluye la `_CardBottomRow`.

### D4 — Auto-scroll inteligente para otros días

**Elegido:** Cuando `isToday` es `false` y hay items, hacer auto-scroll al primer turno del día con un margen de ~30 min arriba para dar contexto visual. Usar la misma mecánica de `_scrollToNow` pero calculando el offset a partir del `startTime` del primer item en vez de `DateTime.now()`.

Implementación: agregar un método `_scrollToFirstItem()` que calcula el offset del primer turno y lo usa como target de `animateTo`. Se llama en `initState` y `didUpdateWidget` cuando `!isToday && items.isNotEmpty`.

**Alternativa descartada:** No hacer scroll para otros días — el usuario ve 3+ horas vacías antes del primer turno y tiene que scrollear manualmente.

### D5 — Skeleton placeholder

**Elegido:** Ajustar las alturas de los bloques skeleton en `DayTimelineSkeleton` para que reflejen la nueva escala (bloques de ~100dp en vez de 60dp).

## Risks / Trade-offs

- **Timeline más largo:** 15h × 120px/h = 1800px vs 1080px antes (+67%). Mitigación: el auto-scroll ya posiciona al usuario en la hora actual; el scroll adicional es natural.
- **Menos turnos visibles sin scroll:** En un viewport de ~600dp, antes se veían ~8h, ahora ~5h. Mitigación: los profesionales típicamente miran las próximas 2-3h, no el día entero.
- **Turnos de 15 min en modo compacto:** Siguen sin mostrar botón Cobrar. Mitigación: son raros en el dominio de salud; el tap lleva al detalle donde se puede cobrar.
