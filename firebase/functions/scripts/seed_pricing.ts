/**
 * Script de seed para crear el documento metadata/pricing en Firestore.
 * Uso: npx ts-node scripts/seed_pricing.ts
 */
import * as admin from "firebase-admin";

// Inicializar con las credenciales por defecto (Application Default Credentials)
admin.initializeApp();

const db = admin.firestore();

async function main() {
  const pricingData = {
    basic: {
      priceUsd: 7.14,
      exchangeRate: 1400.0,
      priceArs: 10000.0,
    },
    premium: {
      priceUsd: 14.28,
      exchangeRate: 1400.0,
      priceArs: 20000.0,
    },
    lastUpdated: admin.firestore.Timestamp.now(),
  };

  await db.collection("metadata").doc("pricing").set(pricingData);
  console.log("✅ Documento metadata/pricing creado exitosamente.");
  console.log(JSON.stringify(pricingData, null, 2));
  process.exit(0);
}

main().catch((err) => {
  console.error("❌ Error:", err);
  process.exit(1);
});
