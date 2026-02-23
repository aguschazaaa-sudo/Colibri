---
trigger: always_on
---

# 🎭 Animation & Motion Rules

## 1. Filosofía de Movimiento

- **Propósito:** Las animaciones deben servir para guiar al usuario (feedback), no para decorar. Deben ser rápidas (entre 200ms y 400ms) y seguir los principios de Material 3.
- **Material Design 3:** Usar preferentemente las transiciones estándar: Shared Axis, Through, y Fade Through del paquete `animations`.

## 2. Declarativo sobre Imperativo

- **Implicit First:** Priorizar siempre widgets de animación implícitos (`AnimatedContainer`, `AnimatedOpacity`, `AnimatedScale`, `AnimatedDefaultTextStyle`) antes de crear controladores manuales.
- **Cuándo usar Explicit:** Solo usar `AnimationController` cuando se requieran animaciones en bucle, secuencias complejas o gestos interactivos específicos.

## 3. Rendimiento (60/120 FPS)

- **RepaintBoundary:** Si un widget tiene una animación compleja o pesada, envolverlo en un `RepaintBoundary` para aislar el repintado y no afectar al resto del árbol.
- **Evitar Rebuilds Innecesarios:**
  - Usar siempre el parámetro `child` en los `AnimatedBuilder` para no reconstruir el widget estático en cada frame.
  - No realizar cálculos lógicos pesados dentro de un `build()` que se está animando.

## 4. Modularidad en Animaciones

- **Custom Animation Widgets:** Si una animación se repite (ej: un fade-in al cargar una lista), extraerla a un widget reusable tipo wrapper: `FadeInWrapper(child: myWidget)`.
- **Flutter Hooks (Opcional):** Si se decide usar `flutter_hooks`, usar `useAnimationController` para evitar el boilerplate de `initState`, `dispose` y `TickerProvider`.

## 5. Accesibilidad

- **Respetar Preferencias del Sistema:** El agente debe considerar el flag `prefers-reduced-motion`. Si el usuario tiene desactivadas las animaciones en su sistema, la app debe saltarlas o simplificarlas.
