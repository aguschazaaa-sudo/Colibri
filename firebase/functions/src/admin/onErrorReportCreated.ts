import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { defineString } from "firebase-functions/params";

// ─── Runtime config ────────────────────────────────────────────────────────────
// Set via: firebase functions:secrets:set ADMIN_NOTIFICATION_EMAIL
const adminNotificationEmail = defineString("ADMIN_NOTIFICATION_EMAIL");

// ─── onErrorReportCreated ─────────────────────────────────────────────────────
//
// Firestore trigger: fires whenever a new document is created in `error_reports`.
// Formats an HTML email and writes it to the `/mail` collection so that the
// "Trigger Email from Firestore" Firebase Extension delivers it to the admin.
//
// Security: no PII is logged — only the document ID is emitted to Cloud Logging.

/**
 * Escapes a string for safe interpolation inside an HTML document.
 * Replaces the five characters that can introduce XSS with their named entities.
 */
function escapeHtml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

export const onErrorReportCreated = functions.firestore
  .document("error_reports/{id}")
  .onCreate(async (snapshot, context) => {
    const docId = context.params.id as string;

    const data = snapshot.data();
    if (!data) {
      functions.logger.warn(
        `[onErrorReportCreated] No data found for document id=${docId}. Skipping.`,
      );
      return;
    }

    const phone: string = escapeHtml(
      typeof data.phone === "string" ? data.phone : "—",
    );
    const professionalName: string = escapeHtml(
      typeof data.professionalName === "string" && data.professionalName !== ""
        ? data.professionalName
        : "(no especificado)",
    );
    const description: string = escapeHtml(
      typeof data.description === "string" && data.description !== ""
        ? data.description
        : "(sin descripción)",
    );
    const status: string = escapeHtml(
      typeof data.status === "string" ? data.status : "new",
    );

    // Use the server timestamp stored on the document when available; fall back
    // to the current time so the email always contains a readable date.
    let timestampLabel: string;
    if (data.createdAt && typeof data.createdAt.toDate === "function") {
      timestampLabel = escapeHtml(
        (data.createdAt.toDate() as Date).toISOString(),
      );
    } else {
      timestampLabel = escapeHtml(new Date().toISOString());
    }

    const emailHtml = `
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <title>Nuevo reporte de error — Colibrí</title>
  <style>
    body { font-family: Arial, sans-serif; color: #333; background: #f5f5f5; margin: 0; padding: 24px; }
    .card { background: #fff; border-radius: 8px; padding: 24px; max-width: 600px; margin: 0 auto;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
    h2 { color: #1a73e8; margin-top: 0; }
    table { width: 100%; border-collapse: collapse; margin-top: 16px; }
    th { text-align: left; color: #666; font-weight: normal; padding: 8px 4px; white-space: nowrap; width: 180px; }
    td { padding: 8px 4px; border-bottom: 1px solid #f0f0f0; word-break: break-word; }
    .footer { margin-top: 24px; font-size: 12px; color: #999; text-align: center; }
  </style>
</head>
<body>
  <div class="card">
    <h2>Nuevo reporte de error — Colibrí</h2>
    <table>
      <tr>
        <th>ID del reporte</th>
        <td><code>${docId}</code></td>
      </tr>
      <tr>
        <th>Teléfono</th>
        <td>${phone}</td>
      </tr>
      <tr>
        <th>Nombre del profesional</th>
        <td>${professionalName}</td>
      </tr>
      <tr>
        <th>Descripción</th>
        <td>${description}</td>
      </tr>
      <tr>
        <th>Estado</th>
        <td>${status}</td>
      </tr>
      <tr>
        <th>Fecha y hora (UTC)</th>
        <td>${timestampLabel}</td>
      </tr>
    </table>
    <div class="footer">Este email fue generado automáticamente por Colibrí.</div>
  </div>
</body>
</html>
    `.trim();

    try {
      await admin
        .firestore()
        .collection("mail")
        .add({
          to: adminNotificationEmail.value(),
          message: {
            subject: `[Colibrí] Nuevo reporte de error — ${docId}`,
            html: emailHtml,
          },
        });

      functions.logger.info(
        `[onErrorReportCreated] Mail queued successfully for report id=${docId}.`,
      );
    } catch (err) {
      functions.logger.error(
        `[onErrorReportCreated] Failed to queue mail for report id=${docId}.`,
        err,
      );
    }
  });
