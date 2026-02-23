---
trigger: always_on
---

# 🧪 TDD & Error Handling Rules

## Proceso TDD
1. Escribir el Test (Rojo).
2. Escribir la implementación mínima (Verde).
3. Refactorizar.

## Requerimientos de Testing
- **Caminos Negativos:** Es OBLIGATORIO testear qué pasa cuando:
  - La API devuelve 401, 404 o 500.
  - El JSON está mal formado o faltan campos.
  - No hay conexión a internet.
  - El usuario cancela una acción.
- **Unit Tests:** Para cada Caso de Uso y Lógica de Repositorio.
- **Mocks:** Usar `mocktail` o `mockito` para simular dependencias de red y storage.

## Manejo de Errores
- No usar `try-catch` genéricos en la UI.
- La capa de Data debe capturar excepciones y transformarlas en `Failure` (objetos de error personalizados).
- La UI debe reaccionar a estados de error de Riverpod (`AsyncError`).