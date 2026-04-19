#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '..');
const dataDir = path.join(rootDir, 'data');
const normalizedDir = path.join(dataDir, 'normalized');
const assetsCatalogPath = path.join(normalizedDir, 'assets_catalog.json');
const requiredEnv = [
  'CLOUDINARY_CLOUD_NAME',
  'CLOUDINARY_API_KEY',
  'CLOUDINARY_API_SECRET',
  'CLOUDINARY_FOLDER',
];

const missingEnv = requiredEnv.filter((name) => !process.env[name]);
if (missingEnv.length > 0) {
  console.error(`[ERROR] Missing required env vars: ${missingEnv.join(', ')}`);
  process.exit(1);
}

if (!fs.existsSync(normalizedDir)) {
  console.error(`[ERROR] Missing normalized directory: ${normalizedDir}`);
  process.exit(1);
}

if (!fs.existsSync(assetsCatalogPath)) {
  console.error(`[ERROR] Missing assets catalog: ${assetsCatalogPath}`);
  process.exit(1);
}

const assetsCatalog = readJson(assetsCatalogPath);
if (!Array.isArray(assetsCatalog)) {
  console.error('[ERROR] assets_catalog.json must contain an array');
  process.exit(1);
}

const assetPaths = new Set(assetsCatalog.map((entry) => normalizePath(entry.assetPath)));
const extractedPaths = assetsCatalog.map((entry) => normalizePath(entry.extractedCopyPath || path.join('data', entry.assetPath || '')));
const missingExtracted = extractedPaths.filter((relativePath) => !fs.existsSync(path.join(rootDir, relativePath)));

const normalizedFiles = fs
  .readdirSync(normalizedDir)
  .filter((name) => name.endsWith('.json') && name !== 'assets_catalog.json')
  .sort();

const unresolved = [];
for (const fileName of normalizedFiles) {
  const docs = readJson(path.join(normalizedDir, fileName));
  walkValues(docs, ({ value, doc }) => {
    if (typeof value !== 'string') {
      return;
    }

    const raw = value.trim();
    if (!raw.startsWith('assets/')) {
      return;
    }

    const normalized = normalizeDynamicAssetPath(raw, doc);
    if (!assetPaths.has(normalized)) {
      unresolved.push({ fileName, value: raw, normalized });
    }
  });
}

const restaurantDocsPath = path.join(normalizedDir, 'restaurants.json');
const restaurantDocs = fs.existsSync(restaurantDocsPath) ? readJson(restaurantDocsPath) : [];
const restaurantsMissingImages = Array.isArray(restaurantDocs)
  ? restaurantDocs.filter((doc) => doc && typeof doc === 'object' && !String(doc.image || '').trim())
  : [];

console.log('============================================================');
console.log('🔎 Cloudinary Sync Validation');
console.log('============================================================');
console.log(`Assets catalog records: ${assetsCatalog.length}`);
console.log(`Normalized files scanned: ${normalizedFiles.length}`);
console.log(`Missing extracted files: ${missingExtracted.length}`);
console.log(`Unresolved asset references: ${unresolved.length}`);
console.log(`Restaurants missing images: ${restaurantsMissingImages.length}`);

if (missingExtracted.length > 0) {
  console.log('--- Missing extracted files ---');
  missingExtracted.slice(0, 20).forEach((item) => console.log(`- ${item}`));
}

if (unresolved.length > 0) {
  console.log('--- Unresolved references (first 20) ---');
  unresolved.slice(0, 20).forEach((item) => {
    console.log(`- ${item.fileName}: ${item.value} -> ${item.normalized}`);
  });
}

if (restaurantsMissingImages.length > 0) {
  console.log('--- Restaurants missing image fields ---');
  restaurantsMissingImages.slice(0, 20).forEach((item) => {
    console.log(`- ${item.id}: ${item.name || '<unnamed restaurant>'}`);
  });
}

if (missingExtracted.length > 0 || unresolved.length > 0 || restaurantsMissingImages.length > 0) {
  process.exit(1);
}

console.log('✅ Validation passed');

function readJson(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(raw);
}

function normalizePath(value) {
  return String(value || '').replace(/\\/g, '/').trim();
}

function normalizeDynamicAssetPath(value, doc) {
  let output = normalizePath(value).replace('featured _items_', 'featured_items_');

  if (output.includes('${index + 1}')) {
    const position = Number(doc?.data?.position);
    if (Number.isFinite(position)) {
      output = output.replace('${index + 1}', `${position + 1}`);
    }
  }

  return output;
}

function walkValues(input, visitor, currentDoc = null) {
  if (Array.isArray(input)) {
    for (const item of input) {
      walkValues(item, visitor, item && typeof item === 'object' ? item : currentDoc);
    }
    return;
  }

  if (!input || typeof input !== 'object') {
    return;
  }

  const doc = currentDoc || input;
  for (const value of Object.values(input)) {
    visitor({ value, doc });
    walkValues(value, visitor, doc);
  }
}
