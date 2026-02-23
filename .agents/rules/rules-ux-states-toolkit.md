---
trigger: always_on
---

# ⚡ Robust UX & Modern Toolkit Rules

## 1. Gestión de Estados de Carga (Skeletons)

- **Prohibido el uso excesivo de `CircularProgressIndicator`:** Salvo en botones o procesos muy pequeños.
- **Skeleton First:** Para pantallas de carga de datos, usar el paquete `skeletonizer`. El agente debe diseñar la UI final y luego envolverla en el estado de carga.
- **Sensación de Velocidad:** Los skeletons deben aparecer instantáneamente mientras Riverpod resuelve el `AsyncValue`.

## 2. Manejo de Errores y Conectividad

- **Error States:** Cada pantalla debe tener un widget de error amigable que explique qué pasó y tenga un botón de "Reintentar".
- **Internet Awareness:** Antes de operaciones críticas (guardar turno, enviar WhatsApp), el sistema debe verificar la conexión usando `connectivity_plus`. Si no hay, mostrar un `SnackBar` persistente o un `Banner` de advertencia.
- **Empty States:** Si no hay pacientes o turnos, mostrar una ilustración o ícono minimalista con un llamado a la acción (ej: "Aún no tienes pacientes. ¡Agrega el primero!").

## 3. Feedback Visual (Micro-interacciones)

- **Haptic Feedback:** Usar `HapticFeedback.lightImpact()` en acciones exitosas (como marcar un turno como pagado).
- **Transiciones:** Usar `flutter_animate` para que los elementos no "aparezcan" de golpe, sino con un suave _fade-in_ o _slide_.

## 4. Riverpod Integration

- Usar `.when()` de los `AsyncValue` de forma estricta:
  ```dart
  asyncValue.when(
    data: (data) => SuccessWidget(data),
    error: (err, stack) => ErrorWidget(err),
    loading: () => SkeletonWidget(),
  );
  ```
