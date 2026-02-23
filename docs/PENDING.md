# Ruta de Desarrollo (Bottom-Up) y Tareas Pendientes

Este documento define la hoja de ruta actual del proyecto `Cobrador`, estructurada de abajo hacia arriba (Bottom-Up) siguiendo los principios de Clean Architecture y nuestro enfoque técnico.

## 1. Capa Backend & Cloud (Firebase / TypeScript)

_La base absoluta donde viven las reglas duras de seguridad y lógica automatizada._

- [ ] **Firestore Security Rules:** Definir y desplegar en `firestore_rules/` reglas estrictas basadas en `providerId` para garantizar el multi-tenancy y aislamiento de datos.
- [ ] **Motor de WhatsApp (Cloud Function):** Desarrollar función programada (Cron Job) que busque saldos mayores a 0 e interactúe con la API de WhatsApp para enviar recordatorios.
- [ ] **Turnos Recurrentes (Cloud Function):** Diseñar e implementar lógica para la creación masiva/recurrente de turnos de manera atómica.

## 2. Capa Domain (Entidades y Contratos)

_La lógica abstracta independiente de la tecnología._

- [x] Entidades Base implementadas (`Patient`, `Appointment`, `Payment`).
- [ ] **Casos de Uso Específicos:** Crear casos de uso puros para reemplazar lógicas directas:
  - [ ] `CreatePatientUseCase` y `UpdatePatientUseCase`.
  - [ ] `UpdateProviderProfileUseCase` (para configuración profesional y plantillas de mensajes).
  - [ ] `TriggerWhatsAppRemindersUseCase` (para ejecuciones bajo demanda).

## 3. Capa Data (En Flutter - Repositorios)

_La comunicación de Flutter con Firebase._

- [x] Repositorios base creados (`patient_repository_impl.dart`, `ledger_repository_impl.dart`, etc.).
- [ ] **Validación de Casos Negativos (TDD):** Asegurar que las implementaciones de los repositorios parsean correctamente y devuelven objetos `Failure` personalizados ante errores de red, permisos (401) o data malformada.

## 4. Capa de Gestión de Estado (Providers / Riverpod)

_El puente inteligente._

- [x] `ledgerProvider` conectado a UI para listado y pagos rápidos.
- [ ] **Top Debtors Provider:** Crear un provider derivado (Computed State) que consuma `ledgerProvider`, analice y ordene los pacientes con deuda, devolviendo el "Top 5".
- [ ] **Inyección de Repositorios en Providers:** Conectar las funciones de escritura (ej. `createPatient`) en los providers (`patient_provider.dart`) para que interactúen con la capa Data, actualmente solo leen.

## 5. Capa de Presentación (UI & Enrutamiento)

_Lo visual y la experiencia de usuario final._

- [ ] **Enrutamiento (GoRouter):** Configurar sistema de rutas hijas (ej. `/patients`, `/settings`, `/finances`) y conectarlo al `home_drawer.dart`.
- [ ] **Cableado Final de Modales:**
  - [ ] `create_patient_sheet.dart`: Reemplazar variables simuladas por llamadas reales al provider.
  - [ ] `create_appointment_sheet.dart`: Conectar el Dropdown para que consuma datos reales desde `patientsProvider`.
- [ ] **Estados UX (Skeleton/Errores):** Implementar banners de reconexión y widgets de error elegantes si fallan las peticiones en Riverpod (ej. en Top Debtors o Dashboard).
