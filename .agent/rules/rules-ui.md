---
trigger: always_on
---

# 🎨 UI & UX Standards

## Diseño Material 3
- Usar componentes nativos de M3 (`NavigationBar`, `FilledButton`, `Card`, etc.).
- **Prohibido Hardcodear Colores:** Usar siempre `Theme.of(context).colorScheme.primary`, `surface`, etc.
- **Prohibido Hardcodear Spacing:** Usar una clase de constantes (ej: `AppSpacing.md`) o `SizedBox` basados en una escala de 8px.

## Adaptabilidad (Mobile First)
- Diseñar principalmente para móvil, pero usar `LayoutBuilder` o `MediaQuery` para evitar que la UI se rompa en pantallas grandes (Tablets/Web).
- Los diálogos y menús deben ser coherentes en diferentes tamaños de pantalla.

## Código Limpio en UI
- Extraer Widgets pequeños: Si un widget tiene más de 3 niveles de nesting, extraerlo a un widget privado o a un archivo independiente en `presentation/widgets/`.
- Comentar solo lógica de UI compleja o animaciones personalizadas.