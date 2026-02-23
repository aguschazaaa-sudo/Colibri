---
trigger: always_on
---

# 🏗️ Core Architecture & Workflow

## Workflow Obligatorio
1. **Fase de Diseño:** Antes de codificar, DEBES presentar un esquema de clases (Entidades, Repositorios, Providers) y la lógica de la funcionalidad.
2. **Contrato Primero:** Define siempre las clases abstractas (interfaces) en la capa de Domain antes de implementar en Data.
3. **Modularidad:** Evitar el código espagueti separando responsabilidades. Ninguna clase debe tener más de 200 líneas sin una justificación clara.

## Estructura de Capas (Clean Architecture)
- **Domain:** Entidades puras, Casos de Uso y Repositorios Abstractos. (0 dependencias externas).
- **Data:** Implementaciones de Repositorios, DataSources (Dio), y Modelos (Freezed/Json).
- **Presentation:** Widgets de Flutter y State Management (Riverpod).

## Stack Técnico
- **Estado:** Riverpod (usar generadores de Riverpod si es posible).
- **Navegación:** GoRouter.
- **Networking:** Dio con interceptores de errores.
- **Modelos:** Inmutabilidad estricta con Freezed.