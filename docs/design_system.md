# 🎨 Design System: SaaS Health Debt Manager

## 1. Tipografía (Typography)

La combinación elegida fusiona la identidad tecnológica (SaaS) con la extrema legibilidad requerida para herramientas financieras.

* **Display, Headline & Title:** `Space Grotesk`
  * *Uso:* Nombres de pantallas (Ej. "Pacientes", "Dashboard"), saldos totales grandes, pop-ups de alerta.
  * *Por qué:* Su geometría particular le quita la "frialdad" a la contabilidad y le da un aspecto moderno, tecnológico y premium.
* **Body, Label & Data (Numbers):** `Source Sans 3` (o `Inter`)
  * *Uso:* Listado de pacientes, montos adeudados individuales, fechas, inputs de texto, botones.
  * *Por qué:* Excelente alineación tabular (los números de una misma columna ocupan el mismo ancho) clave para la lectura de deudas.

---

## 2. Paleta de Colores M3 (Color Palette)

El sistema de Material 3 se basa en colores principales y sus respectivos "Containers" (versiones pastel/suaves para fondos de componentes) y "On-Colors" (colores de texto/ícono que van por encima para máxima legibilidad).

**Modo Claro (Light Mode) Exclusivo:** Para mantener una interfaz súper limpia, quirúrgica y sin sobrecarga visual, la app funcionará exclusivamente en modo claro.

### 🔵 Primary: Azul Verdoso (Confianza, Salud, Clínico)
El color principal de la marca. Se usa en AppBars, barra de navegación, botones principales (Guardar, Confirmar).

| Token M3 | Hex | Uso Principal |
| :--- | :--- | :--- |
| **Primary** | `#00695C` | Botones CTA principales, Floating Action Builders |
| **On Primary** | `#FFFFFF` | Texto/Ícono dentro del botón Primary |
| **Primary Container** | `#6FF9E8` | Fondos de tarjetas destacadas, badges de selección |
| **On Primary Container**| `#00201B` | Texto/Ícono dentro del Primary Container |

### 🟠 Secondary: Naranja Vibrante (Acción, Energía, Urgencia)
Color de acento. Guía el ojo del usuario a acciones rápidas. Ideal para "Nuevo Turno", recordatorios o features premium.

| Token M3 | Hex | Uso Principal |
| :--- | :--- | :--- |
| **Secondary** | `#FF6D00` | Floating Action Buttons (opcional), switches activos |
| **On Secondary** | `#FFFFFF` | Texto/Ícono dentro del botón Secondary |
| **Secondary Container** | `#FFDCC2` | Fondos llamativos, alertas amistosas de pago |
| **On Secondary Container**| `#331400` | Texto/Ícono dentro del Secondary Container |

### 🟢 Tertiary: Verde Esmeralda (Dinero, Liquidado, Éxito)
Exclusivo para la lógica financiera positiva. Turnos pagados, balances a favor, confirmaciones de éxito.

| Token M3 | Hex | Uso Principal |
| :--- | :--- | :--- |
| **Tertiary** | `#10B981` | Texto o ícono de "¡Pagado!" / "Saldo $0" |
| **On Tertiary** | `#FFFFFF` | Texto sobre botón verde |
| **Tertiary Container** | `#D1FAE5` | Fondo de la etiqueta/badge "Liquidado" |
| **On Tertiary Container**| `#065F46` | Texto dentro del badge de Liquidado |

### 🔴 Error: Rojo Coral (Deuda, Peligro)
Exclusivo para saldos negativos vencidos, o eliminar un registro accidentalmente.

| Token M3 | Hex | Uso Principal |
| :--- | :--- | :--- |
| **Error** | `#BA1A1A` | Texto de deudas críticas, ícono de borrar |
| **On Error** | `#FFFFFF` | Texto sobre botón de borrar |
| **Error Container** | `#FFDAD6` | Fondo de tarjeta de "Paciente Moroso" |
| **On Error Container** | `#410002` | Texto dentro de la tarjeta morosa |

### ⚪ Background & Surfaces (Grises Azulados / Slate)
Los fondos no deben ser blancos puros (`#FFFFFF`) ni negros absolutos (`#000000`). Tienen un levísimo tinte azulado para reducir la fatiga visual.

| Token M3 | Hex | Uso Principal |
| :--- | :--- | :--- |
| **Background** | `#F8FAFC` | Fondo general de toda la aplicación (Scaffold) |
| **On Background** | `#0F172A` | Texto de lectura habitual |
| **Surface** | `#FFFFFF` | Fondo de las Cards (Tarjetas de pacientes) |
| **Surface Container** | `#F1F5F9` | Elementos de separación, inputs deshabilitados |
| **On Surface Variant** | `#475569` | Textos secundarios, subtítulos, placeholders |
| **Outline** | `#CBD5E1` | Bordes de botones Outline o TextFields |

---

## 3. Ejemplo Práctico de UI

Para una **Tarjeta de Turno / Paciente:**
* Fondo de tarjeta: `Surface`
* Nombre del paciente (Space Grotesk): `On Surface`
* Especialidad / Concepto (Source Sans 3): `On Surface Variant`
* Botón "Añadir Pago": `Primary Container` con texto `On Primary Container`
* Monto Restante a pagar grande: Si está al día (`Tertiary`), si hay deuda (`Secondary` o `Error` dependiendo de la urgencia).
