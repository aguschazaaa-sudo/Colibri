# Arquitectura y Enfoques Técnicos (Technical Approaches)

Este documento define las decisiones arquitectónicas clave y los enfoques técnicos que gobernarán el desarrollo del proyecto `Cobrador`, alineados con las reglas de negocio y los requisitos de rendimiento.

## 1. Operaciones de Datos (Integración con Firebase)

**Enfoque Elegido:** Híbrido (CQRS ligero)

- **Lecturas (Queries):** Se realizarán directamente desde Flutter hacia Firestore para aprovechar la baja latencia y el caché offline nativo de Firebase. La seguridad se garantizará mediante reglas estrictas de Firestore basadas en `providerId`.
- **Escrituras Críticas (Pagos, Liquidaciones):** Se ejecutarán exclusivamente a través de **Cloud Functions** (`httpsCallable`). Estas funciones actuarán como el backend centralizado, encargándose de la lógica contable (ej. aplicar pago a una deuda específica o usar regla FIFO sobre los turnos impagos) mediante _Firestore Transactions_. Esto garantiza que los saldos no puedan ser alterados maliciosamente desde el cliente y mantiene la consistencia de los datos financieros.

## 2. Motor de WhatsApp y Tareas Programadas

**Enfoque Elegido:** Outbox Pattern / Cloud Tasks

- Para manejar el envío mensual o bajo demanda de recordatorios por WhatsApp, se descarta el procesamiento por lotes (batch) rígido debido a su fragilidad ante fallos parciales.
- En su lugar, una función Cron identificará a los deudores y encolará "Tareas" individuales (ej. en Google Cloud Tasks o una colección de `pending_messages`).
- Workers independientes procesarán cada tarea, aplicando el principio _Check-before-write_ para verificar la idempotencia (evitando envíos duplicados) antes de llamar a la API de Meta y registrar el envío. Esto asegura escalabilidad y resiliencia ante errores de red o límites de tasa de la API.

## 3. Sincronización de Estado en la UI (Riverpod)

**Enfoque Elegido:** Optimistic UI Updates

- Para ofrecer una sensación de inmediatez y rendimiento "SaaS de primer nivel", la interfaz de usuario implementará actualizaciones optimistas.
- Cuando un profesional realiza una acción (ej. registrar un pago), el estado local en Riverpod se actualiza instantáneamente, reflejando el cambio en la pantalla (ej. reduciendo el saldo a 0).
- En segundo plano, se envía la petición a la Cloud Function. Si la operación falla en el servidor, Riverpod capturará el error, revertirá el estado visual y mostrará una notificación adecuada, siguiendo las pautas de `UX States Toolkit`.
- Esto se combinará con estados de carga inicial elegantes (Skeleton) gestionados por los Riverpod `AsyncValue` `.when()`.

## 4. Arquitectura de Navegación (Router)

**Enfoque Elegido:** Rutas Declarativas Basadas en ID (GoRouter)

- Se utilizará `GoRouter` (idealmente con código generado `go_router_builder`) para definir rutas fuertemente tipadas y declarativas (ej. `/patients/123/payments/new`).
- Este enfoque garantiza la compatibilidad futura con Deep Links y soporte Web, permitiendo compartir enlaces directos a pantallas específicas sin depender de pasar objetos Dart complejos en la memoria de navegación. Los Providers locales se encargarán de buscar las entidades necesarias utilizando los IDs proporcionados en la ruta.

---

## Orden Recomendado de Desarrollo

Dada la naturaleza de la arquitectura `Clean Architecture` y el flujo de los datos desde la persistencia hasta la pantalla, el desarrollo debe seguir un enfoque "Bottom-Up" (de los cimientos hacia el techo):

1.  **Capa Domain (Contratos y Entidades):** Definir primero las entidades puras de Dart (`Patient`, `Appointment`, `Payment`) y las clases abstractas de los repositorios. Esto establece las reglas del juego sin preocuparnos aún por Firebase.
2.  **Capa Data (Firebase y DTOs):** Implementar los repositorios, los modelos de datos de Firestore (con sus serializadores JSON o Freezed), y configurar el entorno de emuladores locales obligatorios.
3.  **Cloud Functions (Lógica de Negocio Central):** Desarrollar en TypeScript las funciones transaccionales para cobros y el motor de encolamiento para WhatsApp antes de que la UI intente llamarlos.
4.  **Providers de Riverpod (Gestión de Estado):** Crear los Providers que conectarán la capa _Data_ con la la UI, implementando aquí la lógica de _Optimistic Updates_.
5.  **Capa Presentation (UI y Router):** Conectar finalmente los menús, botones y flujos `GoRouter` a los _Providers_ recientemente creados, reemplazando toda la data "mock" (hardcodeada) que actualmente reside en las vistas.
