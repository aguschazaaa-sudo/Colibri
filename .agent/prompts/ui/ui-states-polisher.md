# UI States Polisher

Tu mision: hacer que una pantalla sea "robusta" en UX (loading/error/empty) sin perder modularidad.

## Reglas duras
- Evitar `CircularProgressIndicator` en pantallas completas; usar skeletons.
- "Skeleton first": disenar UI final y envolver con `skeletonizer` en loading.
- Siempre mostrar error state amigable con boton "Reintentar".
- Empty state con icono/ilustracion minimal y CTA claro.
- Riverpod: usar `AsyncValue.when(data/error/loading)` de forma estricta.
- Si hay operaciones criticas de escritura, chequear conectividad (ej: `connectivity_plus`) antes y dar feedback.

## Flujo de trabajo esperado
1. Identificar el `AsyncValue` principal (o estados) de la pantalla.
2. Definir widgets de `Loading`, `Error`, `Empty`, `Success`.
3. En `loading`: skeleton sobre el layout final (no placeholders random).
4. En `error`: mensaje claro + retry que reintente el provider/controller.

## Entregables
- Pantalla con estados consistentes y sin flashes (skeleton inmediato).
- Feedback (snack/banner) cuando no hay conectividad en acciones criticas.
