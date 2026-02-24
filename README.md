<div align="center">
  <img src="assets/images/logo.png" alt="Colibrí Logo" width="120" />
</div>

<h1 align="center">Colibrí (Cobrador)</h1>

<p align="center">
  <strong>El motor financiero "en piloto automático" para prestadores de salud autónomos.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.7+-02569B?logo=flutter" alt="Flutter Version" />
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase" alt="Firebase Backend" />
  <img src="https://img.shields.io/badge/Riverpod-State%20Management-000000" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Architecture-Clean-4CAF50" alt="Clean Architecture" />
  <img src="https://img.shields.io/badge/Testing-TDD-E34F26" alt="TDD" />
</p>

---

## 🚀 ¿Qué es Colibrí?

Colibrí es un **SaaS B2B "Mobile-First"** diseñado para resolver el mayor problema de los profesionales de la salud independientes (psicólogos, odontólogos, kinesiólogos, etc.): **la gestión de cobros y el seguimiento de pacientes deudores**.

En lugar de depender de planillas de Excel desactualizadas y de la incomodidad de tener que reclamar dinero a sus pacientes, Colibrí automatiza la relación financiera: **Los turnos que se agendan generan deuda, los pagos la saldan, y el motor de WhatsApp se encarga de recordarle a los pacientes**. Todo con un aislamiento multi-tenant absoluto para proteger los datos médicos.

## ✨ Características Principales (Features)

- **Motor Financiero (The "Ledger"):**
  - Arquitectura tipo "contabilidad de saldos". Cuando se agenda un turno, el paciente asume una deuda. Cuando abona un pago parcial o total, el sistema liquida inteligentemente la deuda priorizando los turnos más antiguos (FIFO).
- **Cobranza "Touchless" con WhatsApp:**
  - Integración con WhatsApp Business API para notificar a pacientes morosos de forma automática o a demanda.
- **Interés Compuesto Automático:**
  - Los profesionales pueden configurar una tasa de interés mensual automatizada. Una Cloud Function programada aplica intereses automáticamente los días 28 a todo paciente que arrastre deudas de más de un mes.
- **Multi-Tenancy & Privacidad:**
  - Los médicos no "comparten" pacientes. Las reglas estricias de Firestore aíslan por completo los datos (`providerId`), garantizando que la información financiera y de asistencia nunca se mezcle ni filtre.
- **Diseño UX Moderno y Rápido:**
  - Implementación _skeleton-first_ en Riverpod, minimizando las transiciones de carga y garantizando la fluidez de 60FPS sin usar los clásicos y molestos "spinners" giratorios.

---

## 🏗️ Clean Architecture & Stack Técnico

El repositorio adopta el modelo de **Mono-Repo**. Alberga tanto el Front-end híbrido en Flutter como el Backend serverless en Firebase Node.js.

### Frontend (Flutter)

- **State Management:** Riverpod (`riverpod_annotation`, `riverpod_generator`) para reactividad robusta.
- **Enrutamiento:** GoRouter (manejo seguro de rutas protegidas y control de sesión).
- **Domain-Driven Design (DDD):** Casos de usos aislados agnósticos a Flutter, inyectados en la capa de UI. Inmutabilidad estricta con `freezed` y `fpdart`.
- **UI:** Material Design 3 impulsado por Riverpod, con manejo de carga elegante usando `skeletonizer`.

### Backend (Firebase)

- **Functions:** Lógica pesada, tareas recurrentes (`cron`), y comunicación transaccional hacia APIs externas escritas en **TypeScript**.
- **Reglas de Seguridad (Firestore/Storage):** Testeadas e integradas como código para validación de permisos de propietario `isOwner()`.
- **Testing:** Unit Testing riguroso basado en TDD (Test-Driven Development) cubriendo caminos felices y escenarios de excepción (Negative Path Testing) simulados con `fake_cloud_firestore`.

---

## 🛠️ Estructura del Mono-Repo

```text
cobrador/
├── lib/
│   ├── data/           # Repositorios (Firestore, API REST) y Modelos (DTOs)
│   ├── domain/         # Entidades de negocio centrales y Use Cases puros
│   ├── presentation/   # Widgets, Páginas y Providers (Riverpod)
│   └── router/         # Rutas seguras y redirecciones (GoRouter)
├── firebase/
│   ├── firestore.rules # Reglas atadas al dominio multi-tenant
│   └── functions/      # Cloud functions (Node & TypeScript)
└── test/               # Arquitectura espejo en pruebas unitarias y de integración
```

---

## 💻 Desarrollo Local

### Prerequisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=3.7.2)
- [Firebase CLI](https://firebase.google.com/docs/cli) y la suite de [Emuladores Locales](https://firebase.google.com/docs/emulator-suite).
- Node.js y npm (Para complilar cloud functions)

### Empezando en 3 pasos

1. **Clona el repositorio e instala paquetes:**

   ```bash
   git clone <repo-url>
   cd cobrador
   flutter pub get
   ```

2. **Generar código estático (Riverpod / Freezed):**

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Inicia el Backend Local:**
   ```bash
   cd firebase && firebase emulators:start
   ```
   Asegúrate de tener en Flutter la constante `useEmulator = true` en `main.dart` para apuntar tu app al backend de prueba.

---

<p align="center">
  <i>Desarrollado con ❤️ y mucho ☕ por Agustín Chazarreta.</i>
</p>
