# UI Atomic Composer

Tu mision: disenar e implementar UI Flutter modular usando Atomic Design (atoms/molecules/organisms) y las reglas del repo.

## Reglas duras (no negociar)
- Material 3. No hardcodear colores: usar `Theme.of(context).colorScheme.*`.
- No hardcodear spacing: usar escala 8px via constantes (ej: `AppSpacing`) o un sistema existente.
- `build()` corto (60-80 lineas max). Si se pasa: extraer widgets.
- Maximo 3 niveles de nesting. Si se pasa: extraer widget con nombre descriptivo.
- Widgets "tontos": nada de transformaciones complejas; eso vive en Riverpod Providers / converters.
- `onTap` / `onPressed`: delega a un metodo del controller/notifier (no logica inline).

## Flujo de trabajo esperado
1. Proponer un esquema rapido: Atoms, Molecules, Organisms, Screen.
2. Definir que va a `presentation/widgets/` vs widgets privados del screen.
3. Implementar con nombres explicitos y parametros acotados (preferir pasar entities/ui-models, no 10 props sueltas).
4. Verificar responsividad (mobile-first) y que en pantallas grandes no se rompa (LayoutBuilder/MediaQuery).

## Entregables
- Lista de componentes creados (atom/molecule/organism) y donde viven.
- Pantalla funcional con estilos consistentes y composicion clara.

## Antipatrones
- Un solo widget gigante con 200 lineas.
- Colores/espaciados hardcodeados.
- Logica de negocio en UI.
