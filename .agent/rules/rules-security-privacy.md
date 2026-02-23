---
trigger: always_on
---

# 🔒 Security & Data Privacy Rules

## 1. Aislamiento de Datos (Multi-tenancy)
- **Firestore Rules:** Cada query de Firestore DEBE incluir un filtro por `providerId`. El agente no debe confiar solo en las reglas de seguridad de Firebase; la lógica de la app debe prevenir filtraciones.
- **No PII en Logs:** Prohibido imprimir en consola (print/log) nombres de pacientes, números de teléfono o montos de deuda en entornos de producción.

## 2. Sensibilidad de Salud
- Aunque el sistema sea financiero, se considera que maneja datos de salud por contexto. 
- **Regla:** No almacenar diagnósticos ni notas médicas. Solo "Concepto del turno" (ej: "Consulta", "Sesión").