const admin = require('firebase-admin');

// Initialize Firebase Admin
console.log('Initializing Firebase Admin...');
admin.initializeApp({
  projectId: 'etherly-firebase',
  storageBucket: 'etherly-firebase.firebasestorage.app'
});

const bucket = admin.storage().bucket();

async function setStorageTokens() {
  console.log('Listing all files in the art/ folder...');
  const [files] = await bucket.getFiles({ prefix: 'art/' });

  console.log(`Found ${files.length} files. Updating metadata...`);

  let updatedCount = 0;
  for (const file of files) {
    // Expected path format: art/{stationId}/{filename}
    const pathParts = file.name.split('/');
    if (pathParts.length < 3) continue; // Skip if not inside a station folder
    
    const stationId = pathParts[1];
    
    // Skip if it's a directory placeholder (ends with /)
    if (file.name.endsWith('/')) continue;

    console.log(`Setting download token for "${file.name}" to "${stationId}"...`);

    try {
      await file.setMetadata({
        metadata: {
          firebaseStorageDownloadTokens: stationId
        }
      });
      updatedCount++;
    } catch (err) {
      console.error(`Failed to update metadata for "${file.name}":`, err.message);
    }
  }

  console.log(`\nSuccessfully updated metadata for ${updatedCount} files.`);
}

setStorageTokens().catch(err => {
  console.error('Fatal error setting metadata:', err);
  process.exit(1);
});
