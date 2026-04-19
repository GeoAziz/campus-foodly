#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const WORKSPACE_ROOT = path.resolve(__dirname, '../..');
const HOME_SCREEN_PATH = path.join(WORKSPACE_ROOT, 'lib/screens/home/home_screen.dart');
const HTTP_TIMEOUT_MS = 15000;

function parseArg(flagName) {
  const args = process.argv.slice(2);
  const prefix = `${flagName}=`;
  const direct = args.find((arg) => arg.startsWith(prefix));
  if (direct) {
    return direct.substring(prefix.length).trim();
  }

  const index = args.indexOf(flagName);
  if (index >= 0 && args[index + 1] && !args[index + 1].startsWith('--')) {
    return args[index + 1].trim();
  }

  return '';
}

function looksLikeHttpUrl(value) {
  return /^https?:\/\//i.test(value);
}

function looksLikeAssetPath(value) {
  return /^assets\//i.test(value);
}

async function checkHttpUrl(url) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), HTTP_TIMEOUT_MS);

  try {
    const headResponse = await fetch(url, {
      method: 'HEAD',
      signal: controller.signal,
    });

    if (headResponse.ok) {
      return { ok: true, mode: 'HEAD', status: headResponse.status };
    }
  } catch (_) {
    // Fallback to GET below.
  } finally {
    clearTimeout(timer);
  }

  const fallbackController = new AbortController();
  const fallbackTimer = setTimeout(() => fallbackController.abort(), HTTP_TIMEOUT_MS);

  try {
    const getResponse = await fetch(url, {
      method: 'GET',
      headers: { Range: 'bytes=0-1' },
      signal: fallbackController.signal,
    });

    return {
      ok: getResponse.ok,
      mode: 'GET',
      status: getResponse.status,
    };
  } catch (error) {
    return {
      ok: false,
      mode: 'GET',
      status: null,
      error: error?.message || String(error),
    };
  } finally {
    clearTimeout(fallbackTimer);
  }
}

function checkAssetPath(assetPath) {
  const fullPath = path.join(WORKSPACE_ROOT, assetPath);
  const exists = fs.existsSync(fullPath);
  return { ok: exists, fullPath };
}

function checkHomeHeroWiring() {
  if (!fs.existsSync(HOME_SCREEN_PATH)) {
    return {
      ok: false,
      reason: `Missing home screen file: ${HOME_SCREEN_PATH}`,
    };
  }

  const content = fs.readFileSync(HOME_SCREEN_PATH, 'utf8');
  const hasRestaurantsSource = content.includes('restaurants.map((restaurant) => restaurant.image)');
  const hasHeroWidget = content.includes('BigCardImageSlide');

  if (!hasRestaurantsSource || !hasHeroWidget) {
    return {
      ok: false,
      reason: 'Home hero wiring check failed (expected restaurants image map + BigCardImageSlide).',
      hasRestaurantsSource,
      hasHeroWidget,
    };
  }

  return { ok: true };
}

async function main() {
  const projectIdArg = parseArg('--project') || parseArg('--projectId') || process.env.GOOGLE_CLOUD_PROJECT || '';

  console.log('============================================================');
  console.log('🖼️  Home Hero Image Validator');
  console.log('============================================================');
  console.log(`Workspace: ${WORKSPACE_ROOT}`);
  console.log(`Project: ${projectIdArg || '<default from credentials>'}`);

  const wiring = checkHomeHeroWiring();
  if (!wiring.ok) {
    console.error(`✗ ${wiring.reason}`);
    process.exit(1);
  }
  console.log('✓ Home hero wiring check passed');

  try {
    if (!admin.apps.length) {
      if (projectIdArg) {
        admin.initializeApp({ projectId: projectIdArg });
      } else {
        admin.initializeApp();
      }
    }
  } catch (error) {
    console.error(`✗ Firebase Admin init failed: ${error.message}`);
    process.exit(1);
  }

  const db = admin.firestore();
  const snapshot = await db.collection('restaurants').get();
  const docs = snapshot.docs.map((doc) => {
    const data = doc.data() || {};
    const nestedData = data.data && typeof data.data === 'object' ? data.data : {};
    const image = typeof data.image === 'string' && data.image.trim().length > 0
      ? data.image.trim()
      : typeof nestedData.image === 'string'
        ? nestedData.image.trim()
        : '';

    return {
      id: doc.id,
      name: (data.name || nestedData.name || '').toString(),
      image,
      imageSource: typeof data.image === 'string' ? 'top-level' : 'nested-data',
    };
  });

  console.log(`Restaurants fetched: ${docs.length}`);
  if (docs.length === 0) {
    console.error('✗ restaurants collection is empty; hero cannot render dynamic images');
    process.exit(1);
  }

  const issues = [];
  let reachableCount = 0;
  let httpCount = 0;
  let assetCount = 0;
  let unknownCount = 0;

  for (const restaurant of docs) {
    if (!restaurant.image) {
      issues.push({
        id: restaurant.id,
        name: restaurant.name,
        reason: 'missing image field',
      });
      continue;
    }

    if (looksLikeHttpUrl(restaurant.image)) {
      httpCount += 1;
      const result = await checkHttpUrl(restaurant.image);
      if (result.ok) {
        reachableCount += 1;
      } else {
        issues.push({
          id: restaurant.id,
          name: restaurant.name,
          reason: 'unreachable network image',
          image: restaurant.image,
          status: result.status,
          error: result.error || null,
        });
      }
      continue;
    }

    if (looksLikeAssetPath(restaurant.image)) {
      assetCount += 1;
      const result = checkAssetPath(restaurant.image);
      if (result.ok) {
        reachableCount += 1;
      } else {
        issues.push({
          id: restaurant.id,
          name: restaurant.name,
          reason: 'missing local asset image',
          image: restaurant.image,
          fullPath: result.fullPath,
        });
      }
      continue;
    }

    unknownCount += 1;
    issues.push({
      id: restaurant.id,
      name: restaurant.name,
      reason: 'unsupported image format',
      image: restaurant.image,
    });
  }

  const mayfield = docs.find((doc) => doc.id === 'restaurants-mayfield-bakery-cafe' || doc.name.toLowerCase().includes('mayfield'));

  console.log('------------------------------------------------------------');
  console.log(`HTTP images: ${httpCount}`);
  console.log(`Local asset images: ${assetCount}`);
  console.log(`Unknown format images: ${unknownCount}`);
  console.log(`Reachable images: ${reachableCount}/${docs.length}`);
  console.log(`Issues: ${issues.length}`);
  if (mayfield) {
    console.log(`Mayfield image: ${mayfield.image || '<missing>'}`);
  }

  if (issues.length > 0) {
    console.log('--- Hero image issues (first 20) ---');
    issues.slice(0, 20).forEach((issue) => {
      console.log(`- ${issue.id} (${issue.name || 'unnamed'}): ${issue.reason}`);
      if (issue.image) {
        console.log(`    image: ${issue.image}`);
      }
      if (issue.status != null) {
        console.log(`    status: ${issue.status}`);
      }
      if (issue.error) {
        console.log(`    error: ${issue.error}`);
      }
      if (issue.fullPath) {
        console.log(`    fullPath: ${issue.fullPath}`);
      }
    });
    process.exit(1);
  }

  if (reachableCount === 0) {
    console.error('✗ No renderable hero images found.');
    process.exit(1);
  }

  console.log('✅ Hero image validation passed: all restaurant images used by Home hero are renderable.');
  console.log('============================================================');
}

main().catch((error) => {
  console.error(`✗ Validation crashed: ${error.message}`);
  process.exit(1);
});