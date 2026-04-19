# Firestore Data Seeding

This directory contains scripts to populate Firestore collections with normalized data from `/data/normalized/`.

## Setup

### 1. Install dependencies
```bash
cd functions
npm install
```

### 2. Set up Firebase authentication

Choose one of these methods:

**Option A: Service Account Key**
```bash
# Download your service account key from Firebase Console
# Project Settings → Service Accounts → Generate new private key

export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"
```

**Option B: Firebase CLI Authentication**
```bash
firebase login:ci
```

## Usage

### Preview changes (Dry Run)
```bash
npm run seed:dry-run
```

### Preview with verbose output
```bash
npm run seed:preview
```

### Actually seed the database
```bash
npm run seed
```

### Seed only specific collections
```bash
node seeds/seed_firestore.js --collections restaurants,menu_items
```

### Reset selected collections before reseeding
```bash
npm run seed:reset
```

### Preview reset mode without writing changes
```bash
npm run seed:reset:dry-run
```

## What the script does

- ✅ Reads all JSON files from `/data/normalized/`
- ✅ Transforms image paths to Cloudinary URLs
  - Example: `assets/images/medium_1.png` → `https://res.cloudinary.com/dafacpu4x/image/upload/pro-grocery/production/medium_1.png`
- ✅ Populates Firestore collections:
  - `restaurants`
  - `menu_items`
  - `categories`
  - `dietaries`
  - `dish_details`
  - `featured_items`
  - And 11 more standard collections
- ✅ Adds `createdAt` and `updatedAt` timestamps to all documents
- ✅ Uses batch writes (500 docs per batch) for optimal performance
- ✅ Provides detailed progress logging and error reporting
- ✅ Supports targeted reseed with `--collections`
- ✅ Supports reset mode with `--reset`

## Cloudinary Configuration

The script uses these credentials (hardcoded):
- **Cloud Name**: `dafacpu4x`
- **Folder**: `pro-grocery/production`

To update, edit `CLOUDINARY_CONFIG` in `seed_firestore.js`

## Troubleshooting

**"No JSON files found"**
- Ensure `/data/normalized/` directory exists with JSON files

**"Firebase is not initialized"**
- Check `GOOGLE_APPLICATION_CREDENTIALS` environment variable
- Or run `firebase login:ci`

**"Missing 'id' field in document"**
- Your JSON files must have an `id` field in each document
- Check `/data/normalized/*.json` for required structure

## Batch write limits

Firestore has a limit of 500 writes per batch transaction. The script automatically handles this and will:
- Group documents into batches of up to 500
- Commit each batch separately
- Report progress for each batch
