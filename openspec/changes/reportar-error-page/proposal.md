## Why

Los mensajes de WhatsApp de Colibrí pueden llegar a pacientes equivocados (número reasignado, error de carga, etc.). Se necesita un canal público y sin login para que esa persona reporte el error, de modo que el equipo de Colibrí pueda contactar al profesional y resolverlo.

## What Changes

- Nueva página pública `/reportar-error` en la web landing (Flutter Web)
- Formulario con: número de teléfono receptor, nombre del profesional mencionado, descripción libre (todos opcionales excepto teléfono)
- Al enviar: guarda documento en Firestore colección `error_reports` y dispara email a `aguschazaaa@gmail.com` vía Cloud Function + Firebase Extension "Trigger Email"
- Fix de hash routing: `usePathUrlStrategy()` + rewrites en `firebase.json` → URLs limpias sin `#`
- Navegación de vuelta a la landing (`/`) desde la página de reporte

## Capabilities

### New Capabilities

- `error-report-submission`: Formulario público para reportar mensajes recibidos por error, con persistencia en Firestore y notificación por email al administrador
- `clean-url-routing`: Eliminación del hash (`#`) en las URLs de Flutter Web mediante path URL strategy y rewrites en Firebase Hosting

### Modified Capabilities

- `landing-navigation`: Se agrega la ruta `/reportar-error` al router de la landing y un link de navegación desde la página de reporte hacia `/`

## Impact

- **Flutter Web**: `main.dart` (usePathUrlStrategy), `app_router.dart` (nueva ruta), nueva página `lib/presentation/landing/reportar_error_page.dart`
- **Firebase Hosting**: `firebase.json` — rewrites para path routing
- **Firestore**: nueva colección `error_reports`, reglas de seguridad (write público anónimo, read solo admin)
- **Cloud Functions**: nueva function `onErrorReportCreated` (TypeScript)
- **Firebase Extension**: "Trigger Email" configurada con Gmail SMTP
- **Dependencias nuevas**: ninguna (se usa stack existente)
