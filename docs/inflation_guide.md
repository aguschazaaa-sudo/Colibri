# 📈 Guía: Actualización de Precios por Inflación

Dado que implementamos **"Suscripciones al Vuelo"** (Preapproval API) para permitir descuentos personalizados por usuario, el proceso de actualización de precios no se hace con un solo botón en el dashboard de Mercado Pago, sino mediante un script o función administrativa.

## ¿Cómo funciona?

### 1. Para Nuevos Usuarios
Es muy simple. Solo debés actualizar el documento en Firestore:
- **Colección:** `metadata`
- **Documento:** `pricing`
- **Campos:** `basic.priceArs` y `premium.priceArs`

Cualquier persona que se suscriba a partir de ese momento, lo hará con el nuevo valor (y se le aplicará su descuento correspondiente si lo tiene).

### 2. Para Usuarios con Suscripción Activa
Mercado Pago no permite cambiar el precio de un "Plan Fijo" y que afecte a todos automáticamente si los montos son custom. Como cada usuario tiene un `transaction_amount` específico (por su descuento), debemos:

1. **Iterar** sobre los usuarios con suscripción activa en Firestore.
2. **Identificar** su `preapproval_id` de Mercado Pago (que guardaremos en su perfil al momento del pago).
3. **Llamar a la API de MP** (`PUT /preapproval/{id}`) enviando el nuevo `transaction_amount`.

---

## 🛠️ Ejemplo de lógica para un Script de Inflación

Podemos crear una Cloud Function administrativa que haga lo siguiente:

```typescript
// Pseudo-código de la función de aumento
async function applyInflation(percentage: number) {
  const activeSubscribers = await db.collection("providers")
    .where("subscriptionStatus", "==", "active")
    .get();

  for (const doc of activeSubscribers.docs) {
    const user = doc.data();
    const currentAmount = user.currentMonthlyPrice;
    const newAmount = Math.round(currentAmount * (1 + percentage));

    // Llamada a Mercado Pago para actualizar el cobro recurrente
    await mpClient.preapproval.update({
      id: user.mpPreapprovalId,
      body: {
        auto_recurring: {
          transaction_amount: newAmount
        }
      }
    });

    // Actualizamos Firestore para que la UI refleje el nuevo monto
    await doc.ref.update({ currentMonthlyPrice: newAmount });
  }
}
```

### Ventajas de este método:
- **Respetás los descuentos:** Si alguien tiene un 20% de descuento vitalicio, el aumento se aplica sobre su base ya descontada, manteniendo el beneficio.
- **Transparencia:** Podés enviar un email/WhatsApp automático avisando: "Debido a la inflación, tu suscripción pasará de $X a $Y a partir del próximo mes".

> [!IMPORTANT]
> Mercado Pago permite actualizar el monto de una suscripción activa siempre y cuando el usuario no tenga un pago "pendiente" en ese momento. Generalmente se recomienda hacerlo unos días antes del próximo ciclo de facturación.
