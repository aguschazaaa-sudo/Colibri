import * as functions from "firebase-functions";
import * as crypto from "crypto";

/**
 * Manual HTTP trigger to inspect the Twilio WhatsApp Sender configuration.
 *
 * Calls multiple Twilio REST endpoints and dumps the full JSON responses to
 * the Cloud Functions logs so we can manually inspect:
 *   - Messaging / throughput limits (e.g. 250 msgs/day tier)
 *   - Business profile
 *   - Quality rating
 *   - Webhook configuration
 *   - Account status / balance
 *
 * Endpoints hit:
 *   1. GET https://messaging.twilio.com/v2/Channels/Senders        (WhatsApp Senders v2)
 *   2. GET https://api.twilio.com/2010-04-01/Accounts/{sid}.json    (Account info)
 *   3. GET https://api.twilio.com/2010-04-01/Accounts/{sid}/Balance.json (Balance)
 *
 * Security: requires header `X-Admin-Secret` matching env var `ADMIN_SECRET`.
 *
 * Example:
 *   curl -X POST \
 *     -H "X-Admin-Secret: <secret>" \
 *     https://<region>-<project>.cloudfunctions.net/migrations-getTwilioSenderInfo
 */
export const getTwilioSenderInfo = functions
  .runWith({
    maxInstances: 1,
    secrets: [
      "ADMIN_SECRET",
      "TWILIO_ACCOUNT_SID",
      "TWILIO_AUTH_TOKEN",
      "TWILIO_WHATSAPP_FROM",
    ],
  })
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method Not Allowed. Use POST." });
      return;
    }

    // ── Auth ──────────────────────────────────────────────────────────
    const adminSecret = process.env.ADMIN_SECRET;
    if (!adminSecret) {
      console.error("[getTwilioSenderInfo] ADMIN_SECRET not set.");
      res.status(500).json({ error: "Internal server error." });
      return;
    }
    const providedSecret = req.headers["x-admin-secret"];
    const secretsMatch =
      typeof providedSecret === "string" &&
      providedSecret.length === adminSecret.length &&
      crypto.timingSafeEqual(
        Buffer.from(providedSecret),
        Buffer.from(adminSecret),
      );
    if (!secretsMatch) {
      res.status(403).json({ error: "Forbidden." });
      return;
    }

    // ── Twilio credentials ────────────────────────────────────────────
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;
    const whatsappFrom = process.env.TWILIO_WHATSAPP_FROM; // e.g. "whatsapp:+14155551234"
    if (!accountSid || !authToken) {
      console.error("[getTwilioSenderInfo] Twilio creds missing.");
      res.status(500).json({ error: "Twilio credentials not configured." });
      return;
    }

    const basicAuth =
      "Basic " + Buffer.from(`${accountSid}:${authToken}`).toString("base64");

    // ── Helper ────────────────────────────────────────────────────────
    const fetchJson = async (url: string): Promise<unknown> => {
      const resp = await fetch(url, {
        method: "GET",
        headers: {
          Authorization: basicAuth,
          Accept: "application/json",
        },
      });
      const text = await resp.text();
      let parsed: unknown;
      try {
        parsed = JSON.parse(text);
      } catch {
        parsed = text;
      }
      return { status: resp.status, ok: resp.ok, body: parsed };
    };

    const results: Record<string, unknown> = {};

    try {
      // 1. WhatsApp Senders v2 (messaging limit tier, profile, quality rating, webhooks…)
      //    Requires Channel=whatsapp query param.
      const sendersListResp = (await fetchJson(
        "https://messaging.twilio.com/v2/Channels/Senders?Channel=whatsapp",
      )) as {
        body?: { senders?: Array<{ sid?: string; sender_id?: string }> };
      };
      results.whatsappSendersV2 = sendersListResp;

      // 1b. Individual GET per sender (v2) — the list endpoint may omit fields
      //     that only the individual resource returns (e.g. messaging_limit tier).
      const senderSids =
        sendersListResp?.body?.senders
          ?.map((s) => s.sid)
          .filter((sid): sid is string => typeof sid === "string") ?? [];
      const sendersIndividualV2: Record<string, unknown> = {};
      for (const sid of senderSids) {
        sendersIndividualV2[sid] = await fetchJson(
          `https://messaging.twilio.com/v2/Channels/Senders/${sid}`,
        );
      }
      results.sendersIndividualV2 = sendersIndividualV2;

      // 1c. Legacy v1 senders endpoint — sometimes exposes fields v2 hides.
      results.sendersListV1 = await fetchJson(
        "https://messaging.twilio.com/v1/Channels/Senders",
      );
      const sendersIndividualV1: Record<string, unknown> = {};
      for (const sid of senderSids) {
        sendersIndividualV1[sid] = await fetchJson(
          `https://messaging.twilio.com/v1/Channels/Senders/${sid}`,
        );
      }
      results.sendersIndividualV1 = sendersIndividualV1;

      // 1d. Monitor Alerts API — captures tier-exhaustion errors (63032/63038)
      //     as a reactive signal even if the tier number itself isn't exposed.
      results.monitorAlerts = await fetchJson(
        "https://monitor.twilio.com/v1/Alerts?PageSize=20",
      );

      // 2. Account info (status, type, date created…)
      const accountResp = (await fetchJson(
        `https://api.twilio.com/2010-04-01/Accounts/${accountSid}.json`,
      )) as { status?: number; ok?: boolean; body?: unknown };
      // Redact auth_token before logging to avoid leaking credentials.
      if (
        accountResp &&
        typeof accountResp.body === "object" &&
        accountResp.body !== null &&
        "auth_token" in (accountResp.body as Record<string, unknown>)
      ) {
        (accountResp.body as Record<string, unknown>).auth_token = "[redacted]";
      }
      results.account = accountResp;

      // 3. Account balance
      results.balance = await fetchJson(
        `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Balance.json`,
      );

      // 4. Messaging services (if any)
      const messagingServicesResp = (await fetchJson(
        "https://messaging.twilio.com/v1/Services",
      )) as { body?: { services?: Array<{ sid?: string }> } };
      results.messagingServices = messagingServicesResp;

      // 5. Channel senders for each messaging service (shows linked WhatsApp senders).
      const serviceSids =
        messagingServicesResp?.body?.services
          ?.map((s) => s.sid)
          .filter((sid): sid is string => typeof sid === "string") ?? [];
      const channelSenders: Record<string, unknown> = {};
      for (const sid of serviceSids) {
        channelSenders[sid] = await fetchJson(
          `https://messaging.twilio.com/v1/Services/${sid}/ChannelSenders`,
        );
      }
      results.channelSenders = channelSenders;

      // Normalize trimmed WhatsApp "from" for logs (secret may carry trailing whitespace).
      functions.logger.info("[getTwilioSenderInfo] configured from", {
        whatsappFrom: whatsappFrom?.trim(),
      });
      functions.logger.info(
        "[getTwilioSenderInfo] result",
        // Stringify so the whole payload lands in a single log entry and
        // nested fields are fully visible (logger otherwise truncates objects).
        { payload: JSON.stringify(results, null, 2) },
      );

      res.status(200).json({
        ok: true,
        hint: "Revisá los logs de la función (firebase functions:log --only migrations-getTwilioSenderInfo) para ver el payload completo.",
      });
    } catch (err) {
      functions.logger.error("[getTwilioSenderInfo] fetch failed", {
        error: err instanceof Error ? err.message : String(err),
      });
      res.status(500).json({ error: "Failed to query Twilio." });
    }
  });
