## 1. Path URL Strategy (fix hash routing)

- [x] 1.1 Agregar `usePathUrlStrategy()` en `main.dart` antes de `runApp()`
- [x] 1.2 Actualizar `firebase.json` — agregar rewrite `{ "source": "/**", "destination": "/index.html" }` bajo `hosting.rewrites`
- [ ] 1.3 Verificar que las rutas existentes de la landing funcionen sin `#` en emulador local

## 2. GoRouter — nueva ruta pública

- [x] 2.1 Agregar ruta `/reportar-error` en `app_router.dart` sin auth guard
- [x] 2.2 Verificar que el redirect de autenticación NO intercepte `/reportar-error`

## 3. Página Flutter — ReportarErrorPage

- [x] 3.1 Crear `lib/presentation/landing/reportar_error_page.dart` con AppBar y link "Volver al inicio" (`/`)
- [x] 3.2 Implementar formulario con campos: teléfono (requerido), nombre del profesional (opcional), descripción (opcional)
- [x] 3.3 Agregar validación: teléfono no vacío → mostrar error inline si falta
- [x] 3.4 Implementar estado de carga en el botón "Enviar reporte" (disabled + CircularProgressIndicator)
- [x] 3.5 Implementar estado de éxito inline con mensaje de confirmación y botón "Volver al inicio"
- [x] 3.6 Implementar estado de error con mensaje y botón "Reintentar"
- [x] 3.7 Asegurar diseño mobile-first con Material 3 y colores de `Theme.of(context).colorScheme`

## 4. Firestore — colección error_reports

- [x] 4.1 Agregar reglas en `firebase/firestore.rules`: allow create en `error_reports` para cualquier usuario; deny read para no-admins
- [x] 4.2 Definir modelo de documento: `phone`, `professionalName`, `description`, `createdAt`, `status: "new"`

## 5. Cloud Function — onErrorReportCreated

- [x] 5.1 Crear `firebase/functions/src/admin/onErrorReportCreated.ts` — trigger `onDocumentCreated` en `error_reports/{id}`
- [x] 5.2 Formatear el email HTML con todos los campos del reporte + timestamp + document ID
- [x] 5.3 Escribir documento en colección `/mail` con `to: "aguschazaaa@gmail.com"`, `message.subject` y `message.html`
- [x] 5.4 Exportar la función desde `firebase/functions/src/admin/index.ts`

## 6. Firebase Extension "Trigger Email"

- [ ] 6.1 Instalar la extensión "Trigger Email from Firestore" desde la consola Firebase (manual)
- [ ] 6.2 Configurar con Gmail SMTP: host `smtp.gmail.com`, puerto 587, usuario `aguschazaaa@gmail.com`, app password de Gmail
- [ ] 6.3 Configurar la colección de emails como `mail`
- [ ] 6.4 Verificar que la extensión esté activa y la colección `mail` exista en Firestore

## 7. Deploy y verificación E2E

- [ ] 7.1 Ejecutar Security Guardian antes del deploy
- [ ] 7.2 `firebase deploy --only firestore:rules` — verificar reglas con `firebase_validate_security_rules`
- [ ] 7.3 `firebase deploy --only functions` — verificar logs de la nueva función
- [ ] 7.4 `firebase deploy --only hosting` — verificar URL limpia `/reportar-error` en producción
- [ ] 7.5 Prueba E2E: abrir `/reportar-error` desde un link directo (sin `#`), enviar reporte, verificar email recibido en `aguschazaaa@gmail.com`
