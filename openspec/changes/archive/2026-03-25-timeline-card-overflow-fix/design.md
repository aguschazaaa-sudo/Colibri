## Context

`TodayAppointmentCard` fue diseñada para la tira horizontal de 220dp de ancho fijo. Al reutilizarla en el timeline vertical con `inTimeline: true`, el card hereda un layout de `Column` que falla en dos situaciones:

1. **Ancho insuficiente**: cuando `assignColumns` asigna 2–3 columnas paralelas, cada tarjeta recibe ~100–150dp de ancho. El `Row` de `_CardBottomRow` (monto + botón "Cobrar total") desborda horizontalmente.
2. **Altura insuficiente**: la altura mínima del card es `_kMinCardHeight = 48dp`, pero el contenido mínimo (TopRow + nombre + concepto + BottomRow con padding) ocupa ~100dp, generando overflow vertical.

El algoritmo `assignColumns` ya resuelve el posicionamiento; el problema es puramente de layout interno del card.

## Goals / Non-Goals

**Goals:**
- Eliminar overflows horizontales y verticales en `TodayAppointmentCard` cuando `inTimeline: true`.
- Mostrar progresivamente menos información a medida que la altura del card disminuye (progressive disclosure).
- Colapsar el botón "Cobrar total" a un ícono cuando el ancho es menor a un umbral.
- Para 4+ turnos simultáneos: mostrar máximo 2 columnas + badge `+N` claramente tappable que abre un `BottomSheet` con todos los turnos del slot.
- `clipBehavior: Clip.hardEdge` en el `Stack` del timeline como línea de defensa final.
- Clarificar el origen recurrente de los turnos proyectados: chip de frecuencia + tap navega al detalle del paciente.

**Non-Goals:**
- Rediseño visual del card (colores, tipografía, decoración).
- Cambiar la lógica de `assignColumns`.
- Virtualización del timeline (no hay problema de performance).
- Cambios en Domain, Data o Cloud Functions.

## Decisions

### D1 — Progressive disclosure basado en `LayoutBuilder`

**Elegido:** Envolver el contenido del card en un `LayoutBuilder` para conocer la altura real disponible y tomar decisiones de layout:
- `height < 56dp`: mostrar solo hora + ícono de estado (modo ultra-compacto).
- `56dp ≤ height < 80dp`: mostrar hora + nombre (sin concepto, sin BottomRow).
- `height ≥ 80dp`: mostrar todo (comportamiento actual), pero con BottomRow adaptado al ancho.

**Alternativa descartada:** `FittedBox` / `FractionallySizedBox` — escalan el texto visualmente, pero no suprimen elementos, generando contenido ilegible.

**Alternativa descartada:** Altura mínima mayor (`_kMinCardHeight = 100dp`) — cambiaría la escala del timeline y haría que turnos cortos (15min) ocupen mucho espacio visual.

### D2 — Botón adaptativo al ancho

**Elegido:** En `_CardBottomRow`, usar `LayoutBuilder` para detectar el ancho disponible:
- `width < 120dp`: mostrar solo ícono `Icons.payments_outlined` (compacto, sin texto).
- `width ≥ 120dp`: mostrar `FilledButton.tonal` con texto "Cobrar total" (comportamiento actual).

El monto siempre se muestra (texto corto, difícilmente desborda).

**Alternativa descartada:** Ocultar completamente el botón en cards angostas — el usuario pierde el acceso rápido a la acción principal.

### D3 — 4+ turnos simultáneos: 2 columnas + badge tappable `+N`

**Elegido:** Cuando `entry.cols > 2`, el timeline renderiza únicamente los primeros 2 items del grupo de solapamiento. Sobre el segundo card, en la esquina superior derecha, se superpone un `FilledButton` compacto (tamaño 28×28dp, sin padding, `FilledButton.icon` con `Icons.expand_more` + label `+N`) que abre un `BottomSheet` listando todos los turnos del slot horario. El badge usa color `colorScheme.primary` para que sea inequívocamente tappable (contraste alto, elevación visual implícita).

**Énfasis del badge — animación con `flutter_animate`:**
El badge usa dos efectos encadenados para reforzar que es interactivo:
1. **Entrada (una vez):** `scale(begin: 0.5, end: 1.0, curve: Curves.elasticOut, duration: 400ms)` — bounce-in al aparecer.
2. **Idle pulse (continuo):** `then(delay: 1s)` → `scale(end: 1.14, duration: 550ms, curve: Curves.easeInOut)` + `then()` → `scale(end: 1.0, duration: 550ms)` con `.repeat(pause: Duration(seconds: 3))` — pulso sutil cada ~5 s que señala interactividad sin distraer del contenido.

El badge se envuelve en `RepaintBoundary` para aislar el repaint del pulse del resto del timeline. Se respeta `prefers-reduced-motion`: si `MediaQuery.of(context).disableAnimations` es `true`, se omite el idle pulse y solo se muestra estático.

El `BottomSheet` (`_SlotOverflowSheet`) muestra:
- Header: rango horario del slot (ej: "09:00 – 09:45") + total de turnos.
- Lista scrollable de `TodayAppointmentCard` (modo normal, ancho completo) para cada turno del grupo.
- Se cierra con swipe o tap fuera.

**Alternativa descartada:** Offset visual con opacidad (`0.85`) para columnas 4+ — no es evidente para el usuario que hay contenido oculto; parece un bug visual, no un estado navegable.

**Alternativa descartada:** Cap en 3 columnas con cards de ~80dp — en mobile (360dp) con 3 columnas y eje de tiempo, cada card queda a ~90dp de ancho, que con padding resulta en ~70dp útiles: insuficiente para cualquier información.

**Alternativa descartada:** Scroll horizontal dentro del slot — rompe la UX del scroll vertical del timeline.

### D4 — `clipBehavior` en el Stack del timeline

**Elegido:** Cambiar `clipBehavior: Clip.none` a `Clip.hardEdge` en el `Stack` de appointments. El `Clip.none` actual fue puesto para que el `CurrentTimeIndicator` no se corte — ese widget vive dentro del stack así que no necesita salir.

**Alternativa:** Mantener `Clip.none` y confiar únicamente en el layout adaptativo — riesgo de overflow residual en casos extremos.

### D5 — Turnos recurrentes proyectados: chip de frecuencia + tap al paciente

**Elegido:** Reemplazar el chip "Pendiente de confirmar" en `ProjectedAppointmentCard` por un chip que muestre la frecuencia de la regla (`Semanal`, `Quincenal`, `Mensual`, `Personalizado`) junto al ícono `repeat`. El `concept` se mantiene (es semánticamente correcto: es el tipo de sesión de la regla). El tap navega con `context.push('/patients/${rule.patientId}')` en lugar del `SnackBar`.

**Por qué:** El profesional NO agendó ese turno puntualmente; viene de una regla recurrente. Ver la frecuencia ("Semanal") le da contexto inmediato de por qué ese turno aparece. El tap al paciente es la acción útil: desde ahí puede confirmar, cancelar o ver el historial.

**Alternativa descartada:** `SnackBar` con texto explicativo — informacional puro, no genera ninguna acción ni navegación útil.

**Alternativa descartada:** Ocultar el `concept` y poner "Turno recurrente" fijo — pierde la información del tipo de sesión que el profesional configuró.

## Risks / Trade-offs

- **Información oculta en turnos cortos** → En modo ultra-compacto el concepto y el botón no se ven. Mitigación: tap en el card lleva a la página de detalle donde todo está disponible.
- **Badge `+N` puede solaparse con contenido del card** → Se posiciona con `Positioned` en la esquina superior derecha del segundo card con `z-order` superior; no afecta el tap del card subyacente porque el badge absorbe ese hit test.
- **`LayoutBuilder` agrega un frame de layout extra** → Impacto negligible para < 20 cards; no requiere `RepaintBoundary` adicional.
- **Navegación desde `ProjectedAppointmentCard` a paciente** → Requiere que `GoRouter` esté disponible en el contexto; es el caso en toda la app. No hay riesgo.

## Open Questions

- ¿El umbral de 80dp para mostrar el BottomRow es correcto para la escala de `_kPixelsPerMinute = 1.2`? (1h = 72dp → un turno de 1h llega justo al umbral). Si se ajusta `_kPixelsPerMinute` en el futuro, revisar estos umbrales.
- ¿La frecuencia de la regla (`RecurringAppointment.frequency`) ya tiene un label legible en español, o hay que agregar un helper de presentación?
