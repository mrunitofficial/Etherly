const fs = require('fs');
const path = require('path');

// Sanitization rule matching the one used to generate station_map.json
function cleanName(name) {
  return name.replace(/[^a-zA-Z0-9&!]/g, '');
}

async function run() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run') || args.includes('-d');
  const imagesDir = args.find(arg => arg !== '--dry-run' && arg !== '-d');

  if (!imagesDir) {
    console.error('Usage: node sync-images.js <path-to-images-dir> [--dry-run|-d]');
    process.exit(1);
  }

  if (!fs.existsSync(imagesDir)) {
    console.error(`Error: Source directory "${imagesDir}" does not exist.`);
    process.exit(1);
  }

  // Load the mapping file
  const mapPath = path.join(__dirname, '../station_map.json');
  if (!fs.existsSync(mapPath)) {
    console.error(`Error: station_map.json not found at "${mapPath}". Please run mapping generation first.`);
    process.exit(1);
  }
  const stationMap = JSON.parse(fs.readFileSync(mapPath, 'utf8'));
  console.log(`Loaded ${Object.keys(stationMap).length} station mappings.`);

  let bucket;
  if (dryRun) {
    console.log('--- DRY RUN MODE ACTIVATED (No files will be uploaded) ---');
  } else {
    // Initialize Firebase Admin
    console.log('Initializing Firebase Admin...');
    const admin = require('firebase-admin');
    admin.initializeApp({
      storageBucket: 'etherly-firebase.firebasestorage.app'
    });
    bucket = admin.storage().bucket();
  }

  // Walk through the directory and collect all PNG files
  const pngFiles = [];
  function walkDir(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        walkDir(fullPath);
      } else if (entry.isFile() && entry.name.toLowerCase().endsWith('.png')) {
        pngFiles.push(fullPath);
      }
    }
  }

  console.log(`Scanning directory "${imagesDir}" for PNG assets...`);
  walkDir(imagesDir);
  console.log(`Found ${pngFiles.length} PNG assets.`);

  let successCount = 0;
  let skippedCount = 0;
  let failedCount = 0;

  for (const filePath of pngFiles) {
    const filenameWithExt = path.basename(filePath);
    const filename = filenameWithExt.replace(/\.png$/i, '');
    const sanitizedKey = cleanName(filename);
    const stationId = stationMap[sanitizedKey];

    if (!stationId) {
      console.log(`[SKIPPED] "${filenameWithExt}" (Sanitized: "${sanitizedKey}") - No Firestore mapping found.`);
      skippedCount++;
      continue;
    }

    const destination = `stations/${stationId}/${stationId}.png`;

    if (dryRun) {
      console.log(`[DRY RUN] Would upload "${filenameWithExt}" -> "${destination}"`);
      successCount++;
    } else {
      console.log(`[UPLOADING] "${filenameWithExt}" -> "${destination}"...`);
      try {
        // Upload without generating Firebase storage download tokens
        // We pass a metadata object with a clean metadata sub-property to strip/omit token.
        await bucket.upload(filePath, {
          destination: destination,
          metadata: {
            contentType: 'image/png',
            metadata: {
              firebaseStorageDownloadTokens: '' 
            }
          }
        });
        console.log(`[SUCCESS] Uploaded "${filenameWithExt}" successfully.`);
        successCount++;
      } catch (error) {
        console.error(`[ERROR] Failed to upload "${filenameWithExt}":`, error.message);
        failedCount++;
      }
    }
  }

  console.log('\n--- Sync Summary ---');
  console.log(`Successfully Uploaded/Processed: ${successCount}`);
  console.log(`Skipped (unmapped):             ${skippedCount}`);
  console.log(`Failed:                         ${failedCount}`);

  if (failedCount > 0) {
    process.exit(1);
  }
}

run().catch(err => {
  console.error('Fatal execution error:', err);
  process.exit(1);
});

