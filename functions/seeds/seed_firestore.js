/**
 * Firebase Firestore Seeding Script
 * 
 * This script reads normalized JSON data files and populates Firestore collections
 * with image paths transformed to Cloudinary URLs.
 * 
 * Usage:
 *   node seed_firestore.js                    # Run with real Firebase writes
 *   node seed_firestore.js --dry-run          # Preview changes without writing
 *   node seed_firestore.js --dry-run --verbose # Detailed preview mode
 *   node seed_firestore.js --collections restaurants,menu_items
 *   node seed_firestore.js --reset            # Clear selected collections before seeding
 * 
 * Prerequisites:
 *   - Ensure GOOGLE_APPLICATION_CREDENTIALS environment variable points to your Firebase service account key
 *   - Or ensure you're authenticated with: firebase login:ci
 * 
 * Environment Setup:
 *   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"
 *   export FIREBASE_PROJECT_ID="your-project-id"
 */

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const WORKSPACE_ROOT = path.resolve(__dirname, '../..');
const CLOUDINARY_MANIFEST_PATH = path.join(
  WORKSPACE_ROOT,
  'data/meta/cloudinary_manifest.json',
);
const CLOUDINARY_URL_MAP_PATH = path.join(
  WORKSPACE_ROOT,
  'data/meta/cloudinary_url_map.json',
);

// Cloudinary configuration
const CLOUDINARY_CONFIG = {
  cloudName: 'dafacpu4x',
  folder: 'pro-grocery/production',
};

// Collections to process - maps JSON filename to Firestore collection name
const COLLECTION_MAPPING = {
  'restaurants.json': 'restaurants',
  'menu_items.json': 'menu_items',
  'categories.json': 'categories',
  'dietaries.json': 'dietaries',
  'dish_details.json': 'dish_details',
  'featured_items.json': 'featured_items',
  'choice_options.json': 'choice_options',
  'menu_tabs.json': 'menu_tabs',
  'assets_catalog.json': 'assets_catalog',
  'image_sets.json': 'image_sets',
  'nav_items.json': 'nav_items',
  'onboarding_slides.json': 'onboarding_slides',
  'order_items.json': 'order_items',
  'profile_menu_items.json': 'profile_menu_items',
  'restaurant_details.json': 'restaurant_details',
  'screen_literals.json': 'screen_literals',
  'tabs.json': 'tabs',
  'ui_config.json': 'ui_config',
};

// Batch write configuration
const BATCH_SIZE = 500; // Max writes per batch (Firestore limit is 500)

// Global state
let stats = {
  totalDocuments: 0,
  totalBatches: 0,
  processedCollections: 0,
  resetCollections: 0,
  deletedDocuments: 0,
  transformedAssetRefs: 0,
  errorCount: 0,
  errors: [],
};

function parseFlagValue(args, flagName) {
  const directPrefix = `${flagName}=`;
  const directMatch = args.find((arg) => arg.startsWith(directPrefix));
  if (directMatch) {
    return directMatch.substring(directPrefix.length);
  }

  const index = args.indexOf(flagName);
  if (index >= 0 && index + 1 < args.length) {
    const next = args[index + 1];
    if (!next.startsWith('--')) {
      return next;
    }
  }

  return '';
}

function parseCollectionsArg(rawCollectionsArg) {
  if (!rawCollectionsArg) {
    return [];
  }

  return rawCollectionsArg
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

function getCollectionNameFromJsonFile(jsonFile) {
  return COLLECTION_MAPPING[jsonFile] || jsonFile.replace('.json', '');
}

function filterJsonFilesByCollections(jsonFiles, requestedCollections) {
  if (requestedCollections.length === 0) {
    return jsonFiles;
  }

  const requested = new Set(requestedCollections.map((value) => value.toLowerCase()));

  return jsonFiles.filter((jsonFile) => {
    const collectionName = getCollectionNameFromJsonFile(jsonFile);
    const stem = jsonFile.replace('.json', '');

    return (
      requested.has(collectionName.toLowerCase()) ||
      requested.has(stem.toLowerCase()) ||
      requested.has(jsonFile.toLowerCase())
    );
  });
}

/**
 * Transform image path to Cloudinary URL
 * Example: "assets/images/medium_1.png" -> "https://res.cloudinary.com/dafacpu4x/image/upload/pro-grocery/production/medium_1.png"
 */
function transformImageUrl(imagePath) {
  if (!imagePath || typeof imagePath !== 'string') {
    return imagePath;
  }

  if (/^https?:\/\//i.test(imagePath)) {
    return imagePath;
  }

  // Extract filename from path (e.g., "medium_1.png" from "assets/images/medium_1.png")
  const filename = path.basename(imagePath);
  
  // Construct Cloudinary URL
  return `https://res.cloudinary.com/${CLOUDINARY_CONFIG.cloudName}/image/upload/${CLOUDINARY_CONFIG.folder}/${filename}`;
}

/**
 * Recursively transform all image paths in an object
 */
function normalizeDynamicAssetPath(value, rootDoc) {
  if (typeof value !== 'string') {
    return value;
  }

  let normalized = value.trim().replace(/\\/g, '/');
  normalized = normalized.replace('featured _items_', 'featured_items_');

  if (normalized.includes('${index + 1}')) {
    const position = Number(rootDoc?.data?.position);
    if (Number.isFinite(position)) {
      normalized = normalized.replace('${index + 1}', `${position + 1}`);
    }
  }

  return normalized;
}

function resolveAssetReference(value, cloudinaryUrlMap, rootDoc) {
  if (typeof value !== 'string') {
    return value;
  }

  const normalized = normalizeDynamicAssetPath(value, rootDoc);
  const mappedUrl = cloudinaryUrlMap.get(normalized);
  if (mappedUrl) {
    stats.transformedAssetRefs += 1;
    return mappedUrl;
  }

  if (/^assets\//i.test(normalized)) {
    return transformImageUrl(normalized);
  }

  return value;
}

function transformImages(obj, cloudinaryUrlMap, rootDoc = null) {
  if (obj === null || obj === undefined) {
    return obj;
  }

  if (typeof obj !== 'object') {
    return obj;
  }

  if (Array.isArray(obj)) {
    return obj.map((item) => transformImages(item, cloudinaryUrlMap, rootDoc));
  }

  const transformed = {};
  const activeRootDoc = rootDoc || obj;

  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === 'string') {
      transformed[key] = resolveAssetReference(value, cloudinaryUrlMap, activeRootDoc);
    } else if (typeof value === 'object' && value !== null) {
      // Recursively transform nested objects
      transformed[key] = transformImages(value, cloudinaryUrlMap, activeRootDoc);
    } else {
      transformed[key] = value;
    }
  }

  return transformed;
}

/**
 * Add createdAt and updatedAt timestamps to document
 */
function addTimestamps(doc) {
  const now = admin.firestore.Timestamp.now();
  return {
    ...doc,
    createdAt: doc.createdAt || now,
    updatedAt: now,
  };
}

/**
 * Read and parse JSON file
 */
function readJsonFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(content);
  } catch (error) {
    throw new Error(`Failed to read JSON file ${filePath}: ${error.message}`);
  }
}

/**
 * Get all JSON files from normalized directory
 */
function getJsonFiles(normalizedDir) {
  try {
    const files = fs.readdirSync(normalizedDir);
    return files.filter((file) => file.endsWith('.json'));
  } catch (error) {
    throw new Error(`Failed to read normalized directory: ${error.message}`);
  }
}

/**
 * Batch write documents to Firestore
 */
async function batchWriteDocuments(db, collectionName, documents, isDryRun = false) {
  const batches = [];
  let currentBatch = db.batch();
  let operationCount = 0;

  for (let i = 0; i < documents.length; i++) {
    const doc = documents[i];

    // Validate document has an ID
    if (!doc.id) {
      const error = `Document at index ${i} in ${collectionName} missing required 'id' field`;
      stats.errors.push(error);
      stats.errorCount++;
      console.warn(`⚠️  ${error}`);
      continue;
    }

    // Add timestamps
    const docWithTimestamps = addTimestamps(doc);

    // Add to batch
    const docRef = db.collection(collectionName).doc(doc.id);
    currentBatch.set(docRef, docWithTimestamps);
    operationCount++;

    // Check if batch is full
    if (operationCount === BATCH_SIZE) {
      batches.push(currentBatch);
      currentBatch = db.batch();
      operationCount = 0;
    }
  }

  // Add remaining operations
  if (operationCount > 0) {
    batches.push(currentBatch);
  }

  // Execute batches
  for (let i = 0; i < batches.length; i++) {
    if (!isDryRun) {
      try {
        await batches[i].commit();
        stats.totalBatches++;
        console.log(`✓ Batch ${i + 1}/${batches.length} committed to ${collectionName}`);
      } catch (error) {
        stats.errorCount++;
        const errorMsg = `Failed to commit batch ${i + 1} for ${collectionName}: ${error.message}`;
        stats.errors.push(errorMsg);
        console.error(`✗ ${errorMsg}`);
      }
    } else {
      stats.totalBatches++;
      console.log(`📋 [DRY RUN] Would commit batch ${i + 1}/${batches.length} to ${collectionName}`);
    }
  }

  return batches.length;
}

async function clearCollection(db, collectionName, isDryRun = false) {
  console.log(`  🧹 Reset requested for ${collectionName}`);

  if (isDryRun) {
    console.log(`  📋 [DRY RUN] Would delete all existing documents from ${collectionName}`);
    stats.resetCollections++;
    return;
  }

  let totalDeleted = 0;

  while (true) {
    const snapshot = await db.collection(collectionName).limit(BATCH_SIZE).get();

    if (snapshot.empty) {
      break;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    totalDeleted += snapshot.size;
  }

  stats.resetCollections++;
  stats.deletedDocuments += totalDeleted;
  console.log(`  ✓ Cleared ${collectionName}: deleted ${totalDeleted} documents`);
}

function loadCloudinaryUrlMap() {
  if (fs.existsSync(CLOUDINARY_URL_MAP_PATH)) {
    const urlMapJson = readJsonFile(CLOUDINARY_URL_MAP_PATH);
    const entries = Object.entries(urlMapJson || {}).filter(
      ([assetPath, url]) => typeof assetPath === 'string' && typeof url === 'string' && url.length > 0,
    );
    return new Map(entries);
  }

  if (fs.existsSync(CLOUDINARY_MANIFEST_PATH)) {
    const manifest = readJsonFile(CLOUDINARY_MANIFEST_PATH);
    const entries = (manifest.assets || [])
      .filter((entry) => entry && typeof entry.assetPath === 'string' && typeof entry.secureUrl === 'string')
      .map((entry) => [entry.assetPath, entry.secureUrl]);

    return new Map(entries);
  }

  return new Map();
}

/**
 * Seed a single collection
 */
async function seedCollection(
  db,
  jsonFilePath,
  collectionName,
  cloudinaryUrlMap,
  isDryRun = false,
  verbose = false,
  shouldReset = false,
) {
  try {
    console.log(`\n📂 Processing ${collectionName}...`);

    if (shouldReset) {
      await clearCollection(db, collectionName, isDryRun);
    }

    // Read JSON file
    let data = readJsonFile(jsonFilePath);

    // Ensure data is an array
    if (!Array.isArray(data)) {
      data = [data];
    }

    if (data.length === 0) {
      console.log(`  ℹ️  ${collectionName} is empty, skipping`);
      return 0;
    }

    console.log(`  Found ${data.length} documents in ${collectionName}`);

    // Transform images in all documents
    const transformedData = data.map((doc) => transformImages(doc, cloudinaryUrlMap, doc));

    if (verbose && isDryRun) {
      console.log(`  Sample document (first):`);
      console.log(`    ${JSON.stringify(transformedData[0], null, 2)}`);
    }

    // Batch write documents
    const batchCount = await batchWriteDocuments(db, collectionName, transformedData, isDryRun);
    stats.totalDocuments += transformedData.length;
    stats.processedCollections++;

    console.log(`  ✓ ${collectionName}: ${transformedData.length} documents in ${batchCount} batch(es)`);
    return transformedData.length;
  } catch (error) {
    stats.errorCount++;
    const errorMsg = `Error seeding ${collectionName}: ${error.message}`;
    stats.errors.push(errorMsg);
    console.error(`  ✗ ${errorMsg}`);
    return 0;
  }
}

/**
 * Main seeding function
 */
async function seedFirestore() {
  const cliArgs = process.argv.slice(2);
  const isDryRun = cliArgs.includes('--dry-run');
  const verbose = cliArgs.includes('--verbose');
  const shouldReset = cliArgs.includes('--reset');
  const requestedCollections = parseCollectionsArg(
    parseFlagValue(cliArgs, '--collections'),
  );

  console.log('\n' + '='.repeat(60));
  console.log('🔥 Firebase Firestore Seeding Script');
  console.log('='.repeat(60));

  if (isDryRun) {
    console.log('⚠️  DRY RUN MODE - No data will be written to Firestore');
  }

  if (shouldReset) {
    console.log('🧹 RESET MODE - Existing docs in selected collections will be cleared before seeding');
  }

  if (requestedCollections.length > 0) {
    console.log(`🎯 Collection filter: ${requestedCollections.join(', ')}`);
  }

  // Initialize Firebase Admin
  try {
    if (!admin.apps.length) {
      admin.initializeApp();
    }
    console.log('✓ Firebase Admin initialized');
  } catch (error) {
    console.error(`✗ Failed to initialize Firebase Admin: ${error.message}`);
    process.exit(1);
  }

  const db = admin.firestore();
  const cloudinaryUrlMap = loadCloudinaryUrlMap();

  // Get normalized data directory
  const normalizedDir = path.join(__dirname, '../../data/normalized');

  if (!fs.existsSync(normalizedDir)) {
    console.error(`✗ Normalized data directory not found: ${normalizedDir}`);
    process.exit(1);
  }

  console.log(`📁 Reading from: ${normalizedDir}\n`);
  console.log(`☁️  Cloudinary URL mappings loaded: ${cloudinaryUrlMap.size}`);

  // Get all JSON files
  const jsonFiles = filterJsonFilesByCollections(
    getJsonFiles(normalizedDir),
    requestedCollections,
  );

  if (jsonFiles.length === 0) {
    console.error('✗ No matching JSON files found for the provided filters');
    process.exit(1);
  }

  console.log(`Found ${jsonFiles.length} JSON files to process\n`);

  // Process each JSON file
  for (const jsonFile of jsonFiles) {
    const collectionName = getCollectionNameFromJsonFile(jsonFile);
    const jsonFilePath = path.join(normalizedDir, jsonFile);

    await seedCollection(
      db,
      jsonFilePath,
      collectionName,
      cloudinaryUrlMap,
      isDryRun,
      verbose,
      shouldReset,
    );
  }

  // Print summary
  console.log('\n' + '='.repeat(60));
  console.log('📊 Seeding Summary');
  console.log('='.repeat(60));
  console.log(`Collections processed: ${stats.processedCollections}`);
  console.log(`Total documents: ${stats.totalDocuments}`);
  console.log(`Total batches: ${stats.totalBatches}`);
  console.log(`Reset collections: ${stats.resetCollections}`);
  console.log(`Deleted documents: ${stats.deletedDocuments}`);
  console.log(`Asset refs transformed: ${stats.transformedAssetRefs}`);
  console.log(`Errors: ${stats.errorCount}`);

  if (stats.errors.length > 0) {
    console.log('\n⚠️  Errors encountered:');
    stats.errors.forEach((error, index) => {
      console.log(`  ${index + 1}. ${error}`);
    });
  }

  if (isDryRun) {
    console.log('\n✓ Dry run completed successfully. No changes were made.');
  } else {
    console.log('\n✓ Seeding completed!');
  }

  console.log('='.repeat(60) + '\n');

  // Exit with error code if there were failures
  if (stats.errorCount > 0) {
    process.exit(1);
  }
}

// Run seeding
seedFirestore().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
