#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const rootDir = path.resolve(__dirname, '..');
const dataDir = path.join(rootDir, 'data');
const normalizedDir = path.join(dataDir, 'normalized');
const metaDir = path.join(dataDir, 'meta');
const assetsCatalogPath = path.join(normalizedDir, 'assets_catalog.json');
const manifestPath = path.join(metaDir, 'cloudinary_manifest.json');
const urlMapPath = path.join(metaDir, 'cloudinary_url_map.json');

const cliArgs = process.argv.slice(2);
const dryRun = cliArgs.includes('--dry-run');
const force = cliArgs.includes('--force');
const verbose = cliArgs.includes('--verbose');
const limitRaw = getFlagValue(cliArgs, '--limit');
const limit = limitRaw ? Number(limitRaw) : null;

if (limitRaw && (!Number.isFinite(limit) || limit <= 0)) {
  console.error(`[ERROR] Invalid --limit value: ${limitRaw}`);
  process.exit(1);
}

const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
const apiKey = process.env.CLOUDINARY_API_KEY;
const apiSecret = process.env.CLOUDINARY_API_SECRET;
const folder = process.env.CLOUDINARY_FOLDER;

const requiredEnv = ['CLOUDINARY_CLOUD_NAME', 'CLOUDINARY_API_KEY', 'CLOUDINARY_API_SECRET', 'CLOUDINARY_FOLDER'];
const missingEnv = requiredEnv.filter((name) => !process.env[name]);
if (missingEnv.length > 0) {
  console.error(`[ERROR] Missing required env vars: ${missingEnv.join(', ')}`);
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

const previousManifest = fs.existsSync(manifestPath) ? readJson(manifestPath) : { assets: [] };
const previousByAssetPath = new Map(
  (previousManifest.assets || []).map((entry) => [entry.assetPath, entry]),
);

const supportedExtensions = new Set(['png', 'jpg', 'jpeg', 'webp', 'gif', 'svg']);
const uploadCandidates = assetsCatalog.filter((entry) => {
  if (!entry || typeof entry !== 'object') {
    return false;
  }
  const extension = (entry.extension || '').toString().toLowerCase();
  return supportedExtensions.has(extension) && typeof entry.assetPath === 'string';
});

const finalCandidates = limit ? uploadCandidates.slice(0, limit) : uploadCandidates;

console.log('============================================================');
console.log('☁️  Cloudinary Asset Sync');
console.log('============================================================');
console.log(`Assets catalog entries: ${assetsCatalog.length}`);
console.log(`Upload candidates: ${finalCandidates.length}`);
if (dryRun) {
  console.log('⚠️  DRY RUN MODE - No uploads will be performed');
}

(async () => {
  const results = [];
  let uploaded = 0;
  let skipped = 0;

  for (const entry of finalCandidates) {
    const assetPath = normalizeAssetPath(entry.assetPath);
    const contentHash = `${entry.contentHash ?? ''}`;
    const extension = (entry.extension || '').toString().toLowerCase();

    const previous = previousByAssetPath.get(assetPath);
    const publicId = buildPublicId(folder, assetPath);

    if (!force && previous && previous.contentHash === contentHash && previous.publicId === publicId && previous.secureUrl) {
      skipped += 1;
      results.push(previous);
      if (verbose) {
        console.log(`↷ Skip unchanged: ${assetPath}`);
      }
      continue;
    }

    const extractedCopyPath = entry.extractedCopyPath || toExtractedCopyPath(assetPath);
    const localFilePath = path.join(rootDir, extractedCopyPath);

    if (!fs.existsSync(localFilePath)) {
      throw new Error(`Local file not found for ${assetPath}: ${localFilePath}`);
    }

    if (dryRun) {
      uploaded += 1;
      const dryRecord = {
        assetPath,
        contentHash,
        extension,
        localFilePath: normalizeToPosix(path.relative(rootDir, localFilePath)),
        publicId,
        secureUrl: previous?.secureUrl || null,
        uploadedAt: new Date().toISOString(),
      };
      results.push(dryRecord);
      console.log(`📋 [DRY RUN] Would upload: ${assetPath} -> ${publicId}`);
      continue;
    }

    const uploadResult = await uploadToCloudinary({ cloudName, apiKey, apiSecret, localFilePath, publicId });
    uploaded += 1;

    const record = {
      assetPath,
      contentHash,
      extension,
      localFilePath: normalizeToPosix(path.relative(rootDir, localFilePath)),
      publicId,
      secureUrl: uploadResult.secure_url,
      version: uploadResult.version,
      resourceType: uploadResult.resource_type,
      bytes: uploadResult.bytes,
      uploadedAt: new Date().toISOString(),
    };

    results.push(record);
    console.log(`✓ Uploaded: ${assetPath}`);
  }

  const manifest = {
    generatedAt: new Date().toISOString(),
    cloudName,
    folder,
    totalAssets: results.length,
    uploaded,
    skipped,
    dryRun,
    assets: results.sort((a, b) => a.assetPath.localeCompare(b.assetPath)),
  };

  const urlMap = manifest.assets.reduce((acc, item) => {
    if (item.secureUrl) {
      acc[item.assetPath] = item.secureUrl;
    }
    return acc;
  }, {});

  fs.mkdirSync(metaDir, { recursive: true });
  fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
  fs.writeFileSync(urlMapPath, `${JSON.stringify(urlMap, null, 2)}\n`, 'utf8');

  console.log('------------------------------------------------------------');
  console.log(`Manifest written: ${normalizeToPosix(path.relative(rootDir, manifestPath))}`);
  console.log(`URL map written: ${normalizeToPosix(path.relative(rootDir, urlMapPath))}`);
  console.log(`Uploaded: ${uploaded}`);
  console.log(`Skipped unchanged: ${skipped}`);
  console.log('============================================================');
})().catch((error) => {
  console.error(`[ERROR] ${error.message}`);
  process.exit(1);
});

function getFlagValue(args, flagName) {
  const prefix = `${flagName}=`;
  const direct = args.find((item) => item.startsWith(prefix));
  if (direct) {
    return direct.substring(prefix.length);
  }

  const index = args.indexOf(flagName);
  if (index >= 0 && index + 1 < args.length && !args[index + 1].startsWith('--')) {
    return args[index + 1];
  }

  return '';
}

function readJson(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(raw);
}

function normalizeAssetPath(value) {
  return normalizeToPosix(String(value).trim());
}

function normalizeToPosix(value) {
  return value.replace(/\\/g, '/');
}

function toExtractedCopyPath(assetPath) {
  return normalizeToPosix(path.join('data', assetPath));
}

function buildPublicId(folderName, assetPath) {
  const withoutExtension = assetPath.replace(/\.[^.]+$/, '');
  const trimmedFolder = folderName.replace(/^\/+|\/+$/g, '');
  return `${trimmedFolder}/${withoutExtension}`;
}

function buildSignature(params, apiSecretValue) {
  const serialized = Object.keys(params)
    .sort()
    .map((key) => `${key}=${params[key]}`)
    .join('&');
  return crypto.createHash('sha1').update(`${serialized}${apiSecretValue}`).digest('hex');
}

async function uploadToCloudinary({ cloudName: cName, apiKey: aKey, apiSecret: aSecret, localFilePath, publicId }) {
  const uploadUrl = `https://api.cloudinary.com/v1_1/${cName}/auto/upload`;
  const timestamp = Math.floor(Date.now() / 1000).toString();
  const paramsToSign = {
    overwrite: 'true',
    public_id: publicId,
    timestamp,
    unique_filename: 'false',
    use_filename: 'false',
  };
  const signature = buildSignature(paramsToSign, aSecret);

  const fileBuffer = fs.readFileSync(localFilePath);
  const blob = new Blob([fileBuffer]);

  const form = new FormData();
  form.append('file', blob, path.basename(localFilePath));
  form.append('api_key', aKey);
  form.append('timestamp', timestamp);
  form.append('public_id', publicId);
  form.append('overwrite', 'true');
  form.append('unique_filename', 'false');
  form.append('use_filename', 'false');
  form.append('signature', signature);

  const response = await fetch(uploadUrl, {
    method: 'POST',
    body: form,
  });

  const payload = await response.json();
  if (!response.ok) {
    const message = payload?.error?.message || JSON.stringify(payload);
    throw new Error(`Cloudinary upload failed for ${publicId}: ${response.status} ${message}`);
  }

  if (!payload.secure_url) {
    throw new Error(`Cloudinary upload returned no secure_url for ${publicId}`);
  }

  return payload;
}
