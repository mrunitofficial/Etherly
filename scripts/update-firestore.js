const admin = require('firebase-admin');

// Initialize Firebase Admin
// It will automatically pick up Application Default Credentials (ADC)
// or the GOOGLE_APPLICATION_CREDENTIALS environment variable.
console.log('Initializing Firebase Admin...');
admin.initializeApp({
  projectId: 'etherly-firebase'
});

const db = admin.firestore();

async function updateStations() {
  console.log('Fetching all stations from Firestore...');
  const stationsRef = db.collection('stations');
  const snapshot = await stationsRef.get();

  if (snapshot.empty) {
    console.log('No stations found.');
    return;
  }

  console.log(`Found ${snapshot.size} stations. Updating...`);
  
  const batch = db.batch();
  let count = 0;

  for (const doc of snapshot.docs) {
    const stationId = doc.id;
    
    // Construct the tokenless public webp image URLs based on the stationId
    const bucket = 'etherly-firebase.firebasestorage.app';
    const baseUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket}/o`;
    const art128 = `${baseUrl}/art%2F${stationId}%2F${stationId}_128x128.webp?alt=media`;
    const art512 = `${baseUrl}/art%2F${stationId}%2F${stationId}_512x512.webp?alt=media`;
    const art1024 = `${baseUrl}/art%2F${stationId}%2F${stationId}_1024x1024.webp?alt=media`;

    const docRef = stationsRef.doc(stationId);
    batch.update(docRef, {
      art128: art128,
      art512: art512,
      art1024: art1024,
      country: 'The Netherlands'
    });

    count++;
  }

  console.log(`Committing batch update for ${count} stations...`);
  await batch.commit();
  console.log('Successfully updated all stations in Firestore!');
}

updateStations().catch(err => {
  console.error('Error updating stations:', err);
  process.exit(1);
});
