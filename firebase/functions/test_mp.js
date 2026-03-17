const mpToken = 'APP_USR-1196473919663080-030315-1ba110c37efb2eb2c088ab5c3c945d92-811814776';

async function testMP() {
  const result = await fetch('https://api.mercadopago.com/preapproval', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${mpToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      back_url: "https://colibrimd.com.ar",
      reason: "Suscripción - Plan Básico (Cobrador)",
      auto_recurring: {
        frequency: 1,
        frequency_type: "months",
        transaction_amount: 10000,
        currency_id: "ARS"
      },
      payer_email: "suscriptor@cobrador.app",
      external_reference: "TEST_UID"
    })
  });
  
  const text = await result.text();
  console.log("STATUS:", result.status);
  console.log("BODY:", text);
}

testMP();
