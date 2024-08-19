const http = require('http');
const admin = require('firebase-admin');
const url = require('url');

// Initialize Firebase Admin SDK
// Make sure to replace 'path/to/your/serviceAccountKey.json' with the actual path
const serviceAccount = require('/root/staybusfirebase.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  console.log('Received request:', req.method, parsedUrl.pathname);
  console.log('Query parameters:', parsedUrl.query);

  if (parsedUrl.pathname === '/traccar-webhook' && req.method === 'GET') {
    handleTraccarData(parsedUrl.query, res);
  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not Found' }));
  }
});

async function handleTraccarData(data, res) {
  console.log('Processing data:', data);

  try {
    const deviceId = data.id;
    const latitude = parseFloat(data.latitude);
    const longitude = parseFloat(data.longitude);
    const fixTime = parseInt(data.fixtime);

    if (!deviceId || isNaN(latitude) || isNaN(longitude) || isNaN(fixTime)) {
      throw new Error('Missing or invalid data');
    }

    // Create a JavaScript Date object
    const fixTimeDate = new Date(fixTime);

    // Log the parsed data
    console.log('Parsed data:', { deviceId, latitude, longitude, fixTime, fixTimeDate });

    // Store data in Firestore
    await storeDataInFirestore(deviceId, latitude, longitude, fixTime);

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ message: 'Data received and processed' }));
  } catch (error) {
    console.error('Error processing data:', error);
    res.writeHead(400, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: error.message }));
  }
}

async function storeDataInFirestore(deviceId, latitude, longitude, fixTime) {
  const docRef = db.collection('deviceLocations').doc(deviceId);

  await docRef.set({
    latitude,
    longitude,
    fixTime: admin.firestore.Timestamp.fromMillis(fixTime),
    lastUpdate: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });

  console.log(`Data stored in Firestore for device ${deviceId}`);
}

const PORT = 3001;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});