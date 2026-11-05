import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

const db = admin.firestore();

const VALID_MESSAGE_TYPES = ["payment_reminder", "appointment_reminder"] as const;
export type MessageType = typeof VALID_MESSAGE_TYPES[number];

// ─── Template resolution ────────────────────────────────────────────────────

/**
 * Thrown when no Content SID is configured for a given messageType,
 * neither at the provider level nor at the global level.
 */
export class TemplateNotConfiguredError extends Error {
  constructor(providerId: string, messageType: string) {
    super(
      `No Content SID configured for messageType="${messageType}" (providerId="${providerId}")`
    );
    this.name = "TemplateNotConfiguredError";
  }
}

/** In-memory cache: cacheKey → { sid, expiresAt } */
const templateCache = new Map<string, { sid: string; expiresAt: number }>();
const TEMPLATE_CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Resolves the Twilio Content SID for a given provider and message type.
 *
 * Resolution order:
 *  1. Provider-level override: `providers/{providerId}.messageTemplates[messageType]`
 *  2. Global template (with in-memory TTL cache): `metadata/messaging.templates[messageType].contentSid`
 *  3. Throws `TemplateNotConfiguredError` if neither is found.
 */
export async function resolveTemplateContentSid(
  providerId: string,
  messageType: MessageType
): Promise<string> {
  // 1. Provider-level override (never cached — provider can change it at any time)
  const providerSnap = await db.collection("providers").doc(providerId).get();
  const providerData = providerSnap.data();
  const providerSid = providerData?.messageTemplates?.[messageType] as string | undefined;
  if (providerSid) {
    return providerSid;
  }

  // 2. Global template with TTL cache (keyed by providerId:messageType so tests don't bleed)
  const cacheKey = `${providerId}:${messageType}`;
  const cached = templateCache.get(cacheKey);
  if (cached && cached.expiresAt > Date.now()) {
    return cached.sid;
  }

  const metaSnap = await db.collection("metadata").doc("messaging").get();
  const metaData = metaSnap.data();
  const globalSid = metaData?.templates?.[messageType]?.contentSid as string | undefined;
  if (globalSid) {
    templateCache.set(cacheKey, { sid: globalSid, expiresAt: Date.now() + TEMPLATE_CACHE_TTL_MS });
    return globalSid;
  }

  throw new TemplateNotConfiguredError(providerId, messageType);
}

/**
 * Formats a currency amount in Argentine pesos.
 * e.g. 15000 → "$15.000"
 */
export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat("es-AR", {
    style: "currency",
    currency: "ARS",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

type AppointmentDebtItem = {
  date: Date;
  amount: number;
};

/**
 * Generates {{4}} (detalle_origen) and {{5}} (fechas) variables for the
 * `payment_reminder` WhatsApp template.
 *
 * - {{4}} `detalleOrigen`: If 1 appointment → "el turno".
 *                          If multiple → "la suma de X turnos pendientes".
 * - {{5}} `fechas`: List "- 15/03/2026: $5.000\n- 22/03/2026: $3.000".
 *                   Max 7 most recent dates. If more than 7: shows 7 + "... y X turnos anteriores".
 *
 * Dates are displayed in America/Argentina/Buenos_Aires timezone.
 */
export function formatDebtDetail(appointments: AppointmentDebtItem[]): {
  detalleOrigen: string;
  fechas: string;
} {
  if (appointments.length === 0) {
    return { detalleOrigen: "", fechas: "" };
  }

  // Sort by date descending (most recent first)
  const sorted = [...appointments].sort(
    (a, b) => b.date.getTime() - a.date.getTime()
  );

  // {{4}} detalle_origen
  let detalleOrigen: string;
  if (appointments.length === 1) {
    detalleOrigen = "el turno";
  } else {
    detalleOrigen = `la suma de ${appointments.length} turnos pendientes`;
  }

  // {{5}} fechas — max 7 most recent
  const MAX_DATES = 7;
  const displayed = sorted.slice(0, MAX_DATES);
  const remaining = sorted.length - MAX_DATES;

  const lines = displayed.map((a) => {
    const dateStr = a.date.toLocaleDateString("es-AR", {
      timeZone: "America/Argentina/Buenos_Aires",
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
    });
    return `- ${dateStr}: ${formatCurrency(a.amount)}`;
  });

  if (remaining > 0) {
    lines.push(`... y ${remaining} turnos anteriores`);
  }

  return { detalleOrigen, fechas: lines.join("\n") };
}

/**
 * Maps semantic variable names to the positional keys expected by Twilio Content API.
 *
 * Position mapping for `appointment_reminder`:
 *  - 1: nombre_paciente
 *  - 2: fecha_turno
 *  - 4: hora_turno
 *  - 5: nombre_profesional
 *  - 6: concepto_turno
 *
 * Position mapping for `payment_reminder`:
 *  - 1: nombre_paciente
 *  - 2: profesional_profesion
 *  - 3: monto_total
 *  - 4: detalle_origen
 *  - 5: fechas (newlines replaced with " · " before sending to avoid Meta API rejection)
 */
export function buildTwilioContentVariables(
  messageType: MessageType,
  variables: Record<string, unknown>
): Record<string, string> {
  if (messageType === "appointment_reminder") {
    return {
      "1": String(variables.nombre_paciente ?? ""),
      "2": String(variables.fecha_turno ?? ""),
      "4": String(variables.hora_turno ?? ""),
      "5": String(variables.nombre_profesional ?? ""),
      "6": String(variables.concepto_turno ?? ""),
    };
  }

  if (messageType === "payment_reminder") {
    return {
      "1": String(variables.nombre_paciente ?? ""),
      "2": String(variables.profesional_profesion ?? ""),
      "3": String(variables.monto_total ?? ""),
      "4": String(variables.detalle_origen ?? ""),
      "5": String(variables.fechas ?? "").replace(/\n/g, " · "),
    };
  }

  throw new Error(`Unknown messageType: "${messageType}"`);
}

/**
 * Normalizes an Argentine phone number to E.164 format required by Twilio WhatsApp.
 *
 * Handles common input formats:
 *  - `+5493511234567`  → already correct, returned as-is
 *  - `+543511234567`   → landline format, `9` inserted → `+5493511234567`
 *  - `5493511234567`   → no leading `+` → `+5493511234567`
 *  - `3511234567`      → 10-digit local number → `+5493511234567`
 *  - `03511234567`     → 11-digit with leading `0` → `+5493511234567`
 *  - `93511234567`     → 11-digit with leading `9` (no country code) → `+5493511234567`
 *  - Numbers with spaces, dashes, parentheses are stripped first.
 */
export function normalizeArgentinePhone(raw: string): string {
  // Strip non-digits (keep leading + for detection)
  const hasPlus = raw.startsWith("+");
  const digits = raw.replace(/\D/g, "");

  // Already E.164 mobile: +549 + 10 digits = 13 total digits
  if (digits.startsWith("549") && digits.length === 13) {
    return `+${digits}`;
  }

  // +54 + 10 digits (no 9) = 12 digits — insert 9 for WhatsApp mobile
  if (digits.startsWith("54") && digits.length === 12) {
    return `+549${digits.slice(2)}`;
  }

  // Leading 0 + 10 digits = 11 digits (common local format: 0AREA+NUMBER)
  if (digits.startsWith("0") && digits.length === 11) {
    return `+549${digits.slice(1)}`;
  }

  // 9 + 10 digits = 11 digits (mobile without country code)
  if (digits.startsWith("9") && digits.length === 11) {
    return `+54${digits}`;
  }

  // Plain 10-digit local number (area code + number, no prefix)
  if (digits.length === 10) {
    return `+549${digits}`;
  }

  // Fallback: return with leading + if it had one, otherwise as digits
  return hasPlus ? `+${digits}` : digits;
}

// ─── Interfaces ────────────────────────────────────────────────────────────────

/**
 * Configuración del sistema de mensajería WhatsApp.
 *
 * Se lee desde el documento `metadata/messaging` de Firestore. Si el documento
 * no existe, se aplican los valores por defecto definidos en `DEFAULT_CONFIG`.
 * Puede modificarse en tiempo real sin redesplegar las funciones.
 */
export interface MessagingConfig {
  /**
   * Máximo de conversaciones WhatsApp por ventana de 24 horas.
   * @deprecated No longer consumed by the orchestrator. Kept for backwards compatibility.
   */
  dailyConversationLimit: number;
  /**
   * Fracción del límite diario reservada exclusivamente para mensajes urgentes (0–1).
   * @deprecated No longer consumed by the orchestrator. Kept for backwards compatibility.
   */
  urgentReservePercentage: number;
  /** Hora de inicio de la ventana de envío normal, en hora de Buenos Aires (0–23). */
  sendWindowStart: number;
  /** Hora de fin de la ventana de envío (aplica a todos los tipos), en hora de Buenos Aires (0–23). */
  sendWindowEnd: number;
  /** Kill-switch global: si es `false`, el orquestador no procesa ningún mensaje. */
  enabled: boolean;
  /**
   * Maximum number of `communications` documents created per second in a single orchestrator run.
   * Defends against exceeding Twilio/Meta's 80 MPS throughput limit.
   * Defaults to 40 (half the hard limit).
   */
  maxDispatchRatePerSecond?: number;
  /**
   * Duration in milliseconds to pause dispatch after a Meta tier exhaustion error
   * (codes 63038 or 63032). Defaults to 30 minutes.
   */
  tierExhaustedPauseMs?: number;
  /**
   * If set and the timestamp is in the future, the orchestrator skips dispatch for this run.
   * Written by `sendWhatsAppReminder` on tier exhaustion; read by `messageOrchestrator`.
   */
  pausedUntil?: FirebaseFirestore.Timestamp;
}

/**
 * Documento de la colección `message_queue`.
 *
 * Representa un mensaje en cualquier estado de su ciclo de vida.
 * El orquestador (`messageOrchestrator`) lo promueve a `communications`
 * cuando hay slots disponibles dentro de la ventana horaria y el límite diario.
 */
export interface QueuedMessage {
  /** Identificador del proveedor. Obligatorio para multi-tenancy. */
  providerId: string;
  /** Identificador del paciente destinatario. */
  patientId: string;
  /** Nombre del paciente, incluido en las variables de plantilla. */
  patientName: string;
  /** Tipo de mensaje. Determina la plantilla de WhatsApp a usar. */
  messageType: MessageType;
  /**
   * Variables de plantilla del mensaje.
   * Claves posibles: `nombre_paciente`, `monto_total`, `fecha_turno`, `hora_turno`.
   */
  variables: Record<string, unknown>;
  /**
   * Prioridad de envío. Menor número = mayor prioridad.
   * Convención: 10=urgente, 20=turno normal, 25=manual, 30=auto-pago.
   */
  priority: number;
  /** Si es `true`, consume el cupo reservado para urgentes. */
  isUrgent: boolean;
  /**
   * Estado del ciclo de vida del mensaje.
   * - `queued`: esperando ser procesado por el orquestador.
   * - `processing`: promovido a `communications`, aguardando callback de `sendWhatsAppReminder`.
   * - `sent`: enviado exitosamente.
   * - `failed`: falló el envío; `attempts` y `lastError` indican el detalle.
   * - `expired`: llegó a `expiresAt` sin enviarse.
   * - `duplicate`: descartado porque ya existía un mensaje activo del mismo tipo para el paciente.
   * - `cancelled`: cancelado por eliminación o cambio de fecha del turno origen. Limpiado por `queueCleanup` a los 7 días.
   */
  status: "queued" | "processing" | "sent" | "failed" | "expired" | "duplicate" | "cancelled";
  /** El orquestador no envía el mensaje antes de este timestamp. */
  scheduledFor: FirebaseFirestore.Timestamp;
  /** Si el mensaje no se envía antes de este timestamp, pasa a estado `expired`. */
  expiresAt: FirebaseFirestore.Timestamp;
  /**
   * Nivel de escalamiento para `appointment_reminder`.
   * 0=48h antes (normal), 1=24h antes (normal), 2=2h antes (urgente).
   */
  escalationLevel?: number;
  /** ID del turno origen. Usado para garantizar idempotencia en `appointmentReminderGenerator`. */
  sourceAppointmentId?: string;
  /** ID de la regla recurrente origen, si aplica. */
  sourceRecurringId?: string;
  /** Timestamp de creación del documento. */
  createdAt: FirebaseFirestore.Timestamp;
  /** Timestamp en que el orquestador promovió el mensaje a `communications`. */
  processedAt?: FirebaseFirestore.Timestamp;
  /** Cantidad de intentos de envío realizados por `sendWhatsAppReminder`. */
  attempts: number;
  /** Último mensaje de error registrado por `sendWhatsAppReminder`. */
  lastError?: string;
}

/**
 * Estado del contador de conversaciones WhatsApp en la ventana de 24 horas activa.
 *
 * Almacenado en `metadata/messaging_counters/current/current`.
 * `getOrResetCounter` lo resetea automáticamente cuando la ventana expira.
 */
export interface MessagingCounter {
  /** Inicio de la ventana de 24 horas activa. */
  windowStart: FirebaseFirestore.Timestamp;
  /** Total de mensajes enviados (urgentes + normales) en la ventana. */
  sentCount: number;
  /** Total de mensajes urgentes enviados en la ventana. */
  urgentSentCount: number;
  /** Última vez que se actualizó el contador. */
  lastUpdated: FirebaseFirestore.Timestamp;
}

/**
 * Parámetros de entrada para `enqueueMessage`.
 *
 * Equivalente a `QueuedMessage` pero sin los campos auto-generados
 * (`status`, `createdAt`, `attempts`). Acepta `Date` nativo en lugar
 * de `Timestamp` para mayor comodidad en los productores.
 */
export interface EnqueueParams {
  providerId: string;
  patientId: string;
  patientName: string;
  messageType: MessageType;
  variables: Record<string, unknown>;
  priority: number;
  isUrgent: boolean;
  scheduledFor: Date;
  expiresAt: Date;
  escalationLevel?: number;
  sourceAppointmentId?: string;
  sourceRecurringId?: string;
  /** Deterministic document ID for idempotency. If provided, enqueueMessage
   *  will skip writing if a non-terminal document with this ID already exists. */
  idempotencyKey?: string;
}

/** Result of enqueueMessage indicating whether the message was created or skipped. */
export interface EnqueueResult {
  /** The document ID in message_queue. */
  id: string;
  /** True if a non-terminal document already existed and the write was skipped. */
  wasSkipped: boolean;
}

// ─── Defaults ──────────────────────────────────────────────────────────────────

const DEFAULT_CONFIG: MessagingConfig = {
  dailyConversationLimit: 250,
  urgentReservePercentage: 0.15,
  sendWindowStart: 8,
  sendWindowEnd: 20,
  enabled: true,
  maxDispatchRatePerSecond: 40,
  tierExhaustedPauseMs: 30 * 60 * 1000,
  pausedUntil: undefined,
};

// ─── Functions ─────────────────────────────────────────────────────────────────

/**
 * Lee la configuración del sistema de mensajería desde `metadata/messaging`.
 *
 * Si el documento no existe, devuelve los valores por defecto: 250 conversaciones
 * diarias, 15% de reserva para urgentes, ventana 8-20 h, sistema habilitado.
 * Cada campo faltante en el documento se rellena individualmente con su valor
 * por defecto, por lo que la configuración puede ser parcial en Firestore.
 */
export async function getMessagingConfig(): Promise<MessagingConfig> {
  const doc = await db.collection("metadata").doc("messaging").get();
  if (!doc.exists) {
    functions.logger.info("messaging config not found, using defaults");
    return DEFAULT_CONFIG;
  }
  const data = doc.data()!;
  return {
    dailyConversationLimit: data.dailyConversationLimit ?? DEFAULT_CONFIG.dailyConversationLimit,
    urgentReservePercentage: data.urgentReservePercentage ?? DEFAULT_CONFIG.urgentReservePercentage,
    sendWindowStart: data.sendWindowStart ?? DEFAULT_CONFIG.sendWindowStart,
    sendWindowEnd: data.sendWindowEnd ?? DEFAULT_CONFIG.sendWindowEnd,
    enabled: data.enabled ?? DEFAULT_CONFIG.enabled,
    maxDispatchRatePerSecond: data.maxDispatchRatePerSecond ?? DEFAULT_CONFIG.maxDispatchRatePerSecond,
    tierExhaustedPauseMs: data.tierExhaustedPauseMs ?? DEFAULT_CONFIG.tierExhaustedPauseMs,
    pausedUntil: data.pausedUntil ?? undefined,
  };
}

/**
 * Obtiene el contador diario de conversaciones dentro de una transacción Firestore.
 *
 * Si el contador existe y la ventana de 24 h no ha expirado, devuelve los valores
 * actuales sin modificar nada. Si la ventana expiró o el documento no existe,
 * escribe un nuevo contador con `sentCount` y `urgentSentCount` en cero y una
 * nueva `windowStart`. El uso de transacción garantiza que dos invocaciones
 * simultáneas no lean un contador desactualizado.
 */
export async function getOrResetCounter(): Promise<MessagingCounter> {
  const counterRef = db
    .collection("metadata")
    .doc("messaging_counters")
    .collection("current")
    .doc("current");

  return db.runTransaction(async (transaction) => {
    const snap = await transaction.get(counterRef);
    const now = admin.firestore.Timestamp.now();

    if (snap.exists) {
      const data = snap.data()!;
      const windowStart = data.windowStart as FirebaseFirestore.Timestamp;
      const hoursSinceWindow = (now.toMillis() - windowStart.toMillis()) / (1000 * 60 * 60);

      if (hoursSinceWindow < 24) {
        return {
          windowStart,
          sentCount: data.sentCount ?? 0,
          urgentSentCount: data.urgentSentCount ?? 0,
          lastUpdated: data.lastUpdated as FirebaseFirestore.Timestamp,
        };
      }
    }

    const freshCounter: MessagingCounter = {
      windowStart: now,
      sentCount: 0,
      urgentSentCount: 0,
      lastUpdated: now,
    };
    transaction.set(counterRef, freshCounter);
    return freshCounter;
  });
}

/**
 * Incrementa atómicamente el contador de conversaciones diarias.
 *
 * Usa `FieldValue.increment` para evitar condiciones de carrera sin necesitar
 * una transacción. Si `isUrgent` es `true`, también incrementa `urgentSentCount`.
 * Se llama una vez por cada mensaje promovido a `communications` por el orquestador.
 *
 * @param isUrgent - Si el mensaje consumido era urgente.
 */
export async function incrementCounter(isUrgent: boolean): Promise<void> {
  const counterRef = db
    .collection("metadata")
    .doc("messaging_counters")
    .collection("current")
    .doc("current");

  const updates: Record<string, admin.firestore.FieldValue> = {
    sentCount: admin.firestore.FieldValue.increment(1),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp() as unknown as admin.firestore.FieldValue,
  };

  if (isUrgent) {
    updates.urgentSentCount = admin.firestore.FieldValue.increment(1);
  }

  await counterRef.set(updates, {merge: true});
}

/** Statuses that are considered terminal — a new enqueue may overwrite them. */
const RETRIABLE_STATUSES: ReadonlySet<string> = new Set(["failed", "expired", "cancelled"]);

/**
 * Crea un nuevo documento en `message_queue` con estado `queued`.
 *
 * Es el único punto de entrada para agregar mensajes a la cola; todos los
 * productores (cron jobs, triggers y callables) deben pasar por esta función.
 * Valida que `messageType` sea uno de los valores permitidos antes de escribir
 * en Firestore para evitar documentos con tipos inválidos.
 *
 * When `idempotencyKey` is provided, the document ID is deterministic:
 *  - If a document with that ID already exists in a non-terminal status
 *    (`queued`, `processing`, `sent`, `duplicate`), the write is skipped.
 *  - If the document is in a terminal status (`failed`, `expired`, `cancelled`)
 *    or does not exist, a new document is written (overwriting the old one).
 *
 * When `idempotencyKey` is NOT provided, the legacy `.add()` behavior is used
 * for backward compatibility.
 *
 * @param params - Datos del mensaje a encolar. Ver `EnqueueParams`.
 * @returns An `EnqueueResult` with the document ID and whether it was skipped.
 * @throws Error si `messageType` no es un valor permitido.
 */
export async function enqueueMessage(params: EnqueueParams): Promise<EnqueueResult> {
  if (!VALID_MESSAGE_TYPES.includes(params.messageType)) {
    throw new Error(`Invalid messageType: "${params.messageType}". Must be one of: ${VALID_MESSAGE_TYPES.join(", ")}`);
  }

  const data = {
    providerId: params.providerId,
    patientId: params.patientId,
    patientName: params.patientName,
    messageType: params.messageType,
    variables: params.variables,
    priority: params.priority,
    isUrgent: params.isUrgent,
    status: "queued",
    scheduledFor: admin.firestore.Timestamp.fromDate(params.scheduledFor),
    expiresAt: admin.firestore.Timestamp.fromDate(params.expiresAt),
    ...(params.escalationLevel !== undefined && {escalationLevel: params.escalationLevel}),
    ...(params.sourceAppointmentId && {sourceAppointmentId: params.sourceAppointmentId}),
    ...(params.sourceRecurringId && {sourceRecurringId: params.sourceRecurringId}),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    attempts: 0,
  };

  if (params.idempotencyKey) {
    const docRef = db.collection("message_queue").doc(params.idempotencyKey);
    const existing = await docRef.get();

    if (existing.exists) {
      const existingStatus = existing.data()?.status as string | undefined;
      if (existingStatus && !RETRIABLE_STATUSES.has(existingStatus)) {
        functions.logger.info("message enqueue skipped (idempotent)", {
          docId: params.idempotencyKey,
          existingStatus,
        });
        return { id: params.idempotencyKey, wasSkipped: true };
      }
    }

    await docRef.set(data);
    functions.logger.info("message enqueued (deterministic)", {
      docId: params.idempotencyKey,
      messageType: params.messageType,
    });
    return { id: params.idempotencyKey, wasSkipped: false };
  }

  // Legacy path: no idempotency key — use auto-generated ID
  const docRef = await db.collection("message_queue").add(data);
  functions.logger.info("message enqueued", {docId: docRef.id, messageType: params.messageType});
  return { id: docRef.id, wasSkipped: false };
}

/**
 * Calculates the scheduled send time for an urgent appointment reminder.
 *
 * Rules:
 *  - If the appointment is **more than 24 h away** → 24 h before the appointment.
 *  - If the appointment is **24 h or less away**   → 2 h before the appointment.
 *  - If the calculated time is already in the past → `now` (send ASAP).
 *
 * The messageOrchestrator enforces the 8-20 BA send window, so there is no
 * need to clamp here: a scheduledFor of 06:00 simply means the orchestrator
 * will pick it up at the first 08:00+ run.
 */
export function calculateUrgentScheduledFor(appointmentDate: Date): Date {
  const now = new Date();
  const msUntil = appointmentDate.getTime() - now.getTime();
  const twentyFourH = 24 * 60 * 60 * 1000;
  const twoH = 2 * 60 * 60 * 1000;

  const ideal = msUntil > twentyFourH
    ? new Date(appointmentDate.getTime() - twentyFourH)
    : new Date(appointmentDate.getTime() - twoH);

  return ideal < now ? now : ideal;
}

/**
 * Enqueues an urgent appointment reminder for a premium provider
 * when the appointment is less than 48h away.
 *
 * Used by onAppointmentCreated (new appointment fast-path) and
 * onAppointmentUpdated (date changed fast-path).
 *
 * @param appointmentId - The appointment document ID.
 * @param appointmentData - Appointment date (Firestore Timestamp) and optional concept.
 * @param providerData - Provider name and profession for template variables.
 * @param providerId - Provider document ID (multi-tenancy key).
 * @param patientId - Patient document ID.
 * @param patientName - Patient display name for the WhatsApp template.
 * @returns The ID of the created message_queue document.
 */
export async function enqueueUrgentAppointmentReminder(
  appointmentId: string,
  appointmentData: {
    date: FirebaseFirestore.Timestamp;
    concept?: string;
  },
  providerData: {
    name?: string;
    profession?: string;
  },
  providerId: string,
  patientId: string,
  patientName: string
): Promise<string> {
  const apptDate = appointmentData.date.toDate();
  const dateStr = apptDate.toLocaleDateString("es-AR", {
    timeZone: "America/Argentina/Buenos_Aires",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
  const timeStr = apptDate.toLocaleTimeString("es-AR", {
    timeZone: "America/Argentina/Buenos_Aires",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });

  const nombreProfesional = [providerData.profession, providerData.name]
    .filter(Boolean)
    .join(" ");
  const conceptoTurno = appointmentData.concept?.trim() || "Consulta";

  const result = await enqueueMessage({
    providerId,
    patientId,
    patientName,
    messageType: "appointment_reminder",
    variables: {
      nombre_paciente: patientName,
      fecha_turno: dateStr,
      hora_turno: timeStr,
      nombre_profesional: nombreProfesional,
      concepto_turno: conceptoTurno,
    },
    priority: 10,
    isUrgent: true,
    scheduledFor: calculateUrgentScheduledFor(apptDate),
    expiresAt: apptDate,
    escalationLevel: 2,
    sourceAppointmentId: appointmentId,
    idempotencyKey: `appt_${appointmentId}_2`,
  });
  return result.id;
}

/**
 * Devuelve la hora actual (0–23) en la zona horaria de Buenos Aires.
 *
 * Usada por el orquestador para verificar si el momento actual cae dentro
 * de la ventana de envío permitida, independientemente de la zona horaria
 * del servidor donde corra la Cloud Function.
 */
export function getBuenosAiresHour(): number {
  const now = new Date();
  const baTime = now.toLocaleString("en-US", {
    timeZone: "America/Argentina/Buenos_Aires",
    hour: "numeric",
    hour12: false,
  });
  const parsed = parseInt(baTime, 10);
  return parsed === 24 ? 0 : parsed;
}
