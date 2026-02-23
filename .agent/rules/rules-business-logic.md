---
trigger: always_on
---

# 🧬 Business Logic & Product Vision (SaaS Health Debt Manager)

## 1. El Modelo de Negocio (SaaS)
- **Concepto:** Plataforma para prestadores de salud autónomos (SaaS B2B).
- **Multi-tenancy:** El sistema DEBE garantizar aislamiento total. El Profesional A no tiene existencia legal ni técnica sobre los datos del Profesional B.
- **Monetización:** Suscripción mensual del profesional para usar la herramienta.

## 2. El Motor de Deuda (The "Ledger")
Este es el corazón lógico de la aplicación. Se basa en una contabilidad de saldos:
- **Origen de Deuda:** Cada "Turno" (Appointment) creado genera automáticamente un saldo deudor equivalente a su precio.
- **Estado por Defecto:** Al crear un turno, su estado es `unpaid`.
- **Lógica de Pagos:** - Un pago puede ser parcial o total.
    - El saldo de un Turno es: `Monto_Turno - Suma_Pagos_Asociados`.
    - Un Turno solo se marca como `liquidated` (liquidado) cuando su saldo deudor llega a 0.
- **Prioridad de Cobro:** Si un paciente tiene múltiples deudas, los pagos se aplican por defecto al turno más antiguo (FIFO), a menos que el profesional especifique lo contrario.

## 3. Entidades Clave y Relaciones
- **Provider (Profesional):** Dueño de la cuenta, suscriptor.
- **Patient (Paciente):** Solo datos de contacto y financieros. Pertenece a 1 Provider.
- **Turno (Appointment):** Contiene fecha, monto y estado. Es la unidad de deuda.
- **Payment (Transacción):** Registro de dinero recibido. Debe estar vinculado a un Paciente y, opcionalmente, a un Turno específico.

## 4. El Motor de Notificaciones (WhatsApp Engine)
- **Trigger:** Automatizado una vez al mes (Cloud Function).
- **Criterio de Envío:** Se filtran pacientes que tengan `Total_Deuda > 0`.
- **Canal:** WhatsApp Business API (Meta).
- **Flexibilidad:** Aunque el monto del turno suele ser fijo, el sistema debe permitir al profesional editar el monto de un turno específico antes de que se liquide.

## 5. Filosofía de UX (Mobile-First)
- **Pantalla Crítica:** El "Registro de Pacientes" es el centro de control. Debe permitir ver de un vistazo quién debe y cuánto, con acceso rápido a "Añadir Pago" o "Agendar Turno".
- **Simplicidad:** El profesional está atendiendo pacientes; la carga de datos debe ser mínima (pocos clics).