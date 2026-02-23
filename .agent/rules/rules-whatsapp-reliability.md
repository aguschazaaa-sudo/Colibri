---
trigger: always_on
---

# 💬 WhatsApp & Automation Reliability

## 1. Registro de Comunicación (Logs)
- Cada mensaje enviado debe quedar registrado en una sub-colección `communications` dentro del paciente.
- **Campos obligatorios:** `messageId`, `sentAt`, `status`, `totalDebtAtThatTime`.

## 2. Idempotencia (No Duplicidad)
- Antes de enviar un mensaje, la función debe verificar si ya se envió un recordatorio en el ciclo actual (ventana de 24h).
- **Regla:** "Check-before-write". Nunca disparar el API de Meta sin verificar el estado del último envío.

## 3. Formato de Mensajes
- Los mensajes deben ser personalizables por el profesional, pero el agente debe validar que incluyan variables obligatorias como `{{monto_total}}` y `{{nombre_paciente}}`.