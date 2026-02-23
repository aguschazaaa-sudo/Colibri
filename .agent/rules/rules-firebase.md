---
trigger: always_on
---

# 🔥 Firebase Backend & Integration Rules

## 1. Estructura del Mono-repo
El proyecto debe mantener una separación clara de entornos:
- `/lib`: Código fuente de Flutter.
- `/firebase`: Raíz de la configuración de Firebase.
    - `/functions`: Lógica de Node.js/TypeScript.
    - `/firestore_rules`: Reglas de seguridad versionadas.
    - `/storage_rules`: Reglas de almacenamiento versionadas.

## 2. Local-First Development (Emulators)
- **Uso Obligatorio de Emuladores:** Antes de desplegar a producción, toda funcionalidad debe ser probada localmente usando `firebase emulators`.
- **Configuración en Flutter:** El agente debe asegurar que el código de inicialización de Firebase apunte a `10.0.2.2` (Android) o `localhost` (iOS/Web) si el flag `use_emulator` está activo.

## 3. Firebase en Clean Architecture
- **Data Source:** Firebase es un `DataSource`. Los plugins (`cloud_firestore`, `firebase_auth`) SOLO pueden vivir en la capa de **Data**.
- **Manejo de Tipos:** No se deben retornar objetos de Firebase (`DocumentSnapshot`, `UserCredential`) a la capa de Domain. Se deben mapear inmediatamente a **Entidades** puras en la capa de Data.
- **Failures:** Convertir los `FirebaseException` en objetos `Failure` personalizados (ej: `AuthFailure.emailAlreadyInUse()`).

## 4. Cloud Functions (si aplica)
- **Lenguaje:** TypeScript (para tipado fuerte).
- **Modularidad:** Dividir funciones por responsabilidad en archivos separados, no un solo `index.ts` gigante.
- **Tratamiento de Datos:** Siempre validar los datos de entrada con una librería como `zod` o validaciones manuales estrictas.

## 5. Seguridad y Despliegue
- **Rules Versioning:** No editar las reglas directamente en la consola de Firebase. Se editan en el archivo `.rules` del repo y se despliegan vía CLI.
- **Secrets:** Nunca hardcodear llaves de API o secrets. Usar `Firebase Secrets Manager` para las funciones y variables de entorno para Flutter.