const https = require('https');

const data = JSON.stringify({
  data: {
    planId: 'premium'
  }
});

const req = https.request({
  hostname: 'us-central1-quiz-hoot-7ymbj0.cloudfunctions.net',
  path: '/subscriptions-createSubscription',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
}, (res) => {
  console.log(`STATUS: ${res.statusCode}`);
  let body = '';
  res.on('data', (chunk) => {
    body += chunk;
  });
  res.on('end', () => {
    console.log(`BODY: ${body}`);
  });
});

req.on('error', (e) => {
  console.error(`problem with request: ${e.message}`);
});

req.write(data);
req.end();
