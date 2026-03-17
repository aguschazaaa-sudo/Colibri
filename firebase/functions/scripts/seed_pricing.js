const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'quiz-hoot-7ymbj0',
});

const db = admin.firestore();

async function main() {
  await db.collection('metadata').doc('pricing').set({
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
  });

  console.log('✅ Documento metadata/pricing creado exitosamente.');
  process.exit(0);
}

main().catch((err) => {
  console.error('❌ Error:', err.message || err);
  process.exit(1);
});
