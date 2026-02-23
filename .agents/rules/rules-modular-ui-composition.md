---
trigger: always_on
---

# 🧩 Modular & Composable UI Rules

## 1. La Regla de las 60 Líneas
- **Límite de Tamaño:** Ningún método `build()` debe exceder las 60-80 líneas de código. Si es más largo, DEBES extraer componentes.
- **Extracción de Widgets:** Preferir siempre crear una nueva clase `StatelessWidget` o `ConsumerWidget` en un archivo separado (o al final del archivo si es muy pequeño) en lugar de métodos que devuelven widgets (ej: `_buildHeader()`).

## 2. Límite de Anidamiento (Nesting)
- **Máximo 3 Niveles:** Si un widget tiene más de 3 niveles de indentación/anidamiento (ej: Scaffold > Column > Padding > Row > ...), el contenido interno debe ser extraído a un widget independiente con nombre descriptivo.

## 3. Separación de Lógica y Layout
- **Widgets de Presentación Puros:** Los widgets deben ser "tontos". No deben contener lógica de cálculo ni transformaciones de datos complejas.
- **Transformación en el Provider:** Toda la lógica de "preparar el dato para la vista" debe ocurrir en el `Provider` o en un `ValueConverter`. El widget solo recibe y dibuja.
- **Acciones Limpias:** Las funciones de `onTap` o `onPressed` solo deben llamar a un método del controlador (ej: `ref.read(provider.notifier).handleAction()`).

## 4. Patrón de Composición (Slots/Children)
- **Widgets Contenedores:** Fomentar el uso de widgets que acepten un `child` o un `List<Widget> children` para permitir la inyectabilidad y evitar widgets rígidos.
- **Atomic Design:** Pensar en términos de:
    - **Atoms:** Botones, labels, inputs.
    - **Molecules:** Un campo de búsqueda con su botón.
    - **Organisms:** El Header completo o la Card del Paciente.

## 5. Parámetros de Configuración
- En lugar de pasar 10 variables a un widget (nombre, monto, fecha, estado...), pasar la **Entity** de Domain o un **UI Model** específico para esa vista.