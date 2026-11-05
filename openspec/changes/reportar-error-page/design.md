## Context

La landing de Colibrí es una app Flutter Web desplegada en Firebase Hosting. Actualmente usa hash routing (`/#/ruta`). Los mensajes de WhatsApp incluyen el link `colibrimd.com.ar/reportar-error` — por eso es crítico que la URL funcione sin `#`. El backend es Firebase (Firestore + Cloud Functions TypeScript). No hay servidor propio.

El reporte llega a una sola persona (el admin, `aguschazaaa@gmail.com`) que actúa manualmente como intermediario entre el paciente y el profesional.

## Goals / Non-Goals

**Goals:**
- URL limpia `/reportar-error` funcional desde el mensaje de WhatsApp
- Formulario accesible sin login, mobile-first (la mayoría llega desde el celular)
- Notificación email al admin con todos los datos del reporte
- Persistencia del reporte en Firestore para auditoría
- Navegación de regreso a la landing

**Non-Goals:**
- Panel de gestión de reportes (el admin los ve en el email)
- Autenticación del reportante
- Anti-spam / rate limiting (volumen bajo esperado)
- Notificación al profesional (lo hace el admin manualmente)
- Internacionalización

## Decisions

### 1. Path URL Strategy sobre Hash Routing
**Decisión:** `usePathUrlStrategy()` + rewrite `"/**" → "/index.html"` en `firebase.json`.
**Alternativa descartada:** Mantener hash routing — no funciona porque el link en el mensaje de WhatsApp es `colibrimd.com.ar/reportar-error`, sin `#`.
**Riesgo aceptado:** Cualquier URL directa que no esté en el router retorna la app (no un 404 real), pero eso es aceptable para una SPA.

### 2. Firebase Extension "Trigger Email" para notificaciones
**Decisión:** Instalar la extensión oficial de Firebase "Trigger Email from Firestore" configurada con Gmail SMTP (cuenta del admin).
**Alternativa descartada:** SendGrid/Resend — requieren cuenta y configuración extra. Nodemailer directo en Cloud Function — más código a mantener.
**Ventaja:** La extensión escucha la colección `/mail`, envía el email y actualiza el estado del documento. Cero código adicional para el envío.

### 3. Cloud Function como intermediario (no escribir a `/mail` desde el cliente)
**Decisión:** El cliente escribe en `/error_reports`. Una Cloud Function `onDocumentCreated` formatea y escribe en `/mail`.
**Alternativa descartada:** Cliente escribe directamente en `/mail` — expone la estructura interna de la extensión y el formato del email al cliente web. Más difícil de validar y auditar.
**Ventaja:** Separación clara; el cliente solo necesita permiso de write en `/error_reports`.

### 4. Reglas Firestore: write público, read solo admin
**Decisión:** Cualquier usuario (incluso no autenticado) puede crear documentos en `error_reports`. Solo el admin (uid hardcodeado o custom claim `admin: true`) puede leer.
**Alternativa descartada:** Requerir autenticación anónima — agrega fricción innecesaria para el usuario que reporta.

### 5. Página Flutter en la landing existente (no microsite separado)
**Decisión:** Nueva ruta en el mismo proyecto Flutter, misma landing shell.
**Ventaja:** Comparte tema, navegación y deploy. Costo cero adicional.

## Risks / Trade-offs

- **Spam/abuso de Firestore write público** → Mitigación: documentos son pequeños (< 1KB), free tier soporta 20k writes/día; si hay abuso agregar reCAPTCHA en una iteración futura.
- **Gmail SMTP límites** → Gmail permite ~500 emails/día con cuenta personal, suficiente para el volumen esperado.
- **Path routing rompe rutas existentes si hay links con `#`** → Mitigación: verificar en QA que todos los deep links internos usen `go()` de GoRouter (no strings manuales con `#`).
- **Extension "Trigger Email" requiere configuración manual en consola Firebase** → Documentar el paso en tasks.md; no es automatizable vía CLI.

## Migration Plan

1. Habilitar path URL strategy en Flutter → rebuild → deploy web
2. Actualizar `firebase.json` rewrites → `firebase deploy --only hosting`
3. Instalar extensión "Trigger Email" desde consola Firebase (manual)
4. Desplegar nueva Cloud Function → `firebase deploy --only functions`
5. Desplegar nuevas reglas Firestore → `firebase deploy --only firestore:rules`
6. Verificar end-to-end en staging antes de anunciar el link en producción

**Rollback:** Revertir `usePathUrlStrategy()` y `firebase.json` en caso de problemas de routing. La colección `error_reports` y la función son aditivas y no afectan funcionalidad existente.

## Open Questions

- ¿La extensión "Trigger Email" se configura con la cuenta Gmail del admin (`aguschazaaa@gmail.com`) como SMTP sender, o se prefiere un alias como `noreply@colibrimd.com.ar`? (Por ahora: usar Gmail del admin)
- ¿Se quiere confirmación visual al usuario al enviar (pantalla de éxito inline o página separada)? (Por ahora: misma página, mensaje de éxito inline)
