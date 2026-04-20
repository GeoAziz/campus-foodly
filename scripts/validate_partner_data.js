#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

function readJson(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(raw);
}

function toIdSet(records, key) {
  return new Set(
    records
      .map((record) =>
        record && typeof record[key] === 'string' ? record[key].trim() : '',
      )
      .filter((value) => value.length > 0),
  );
}

function getDuplicateIds(records, idKey = 'id') {
  const counts = new Map();

  records.forEach((record) => {
    const value = record && typeof record[idKey] === 'string'
      ? record[idKey].trim()
      : '';
    if (!value) return;
    counts.set(value, (counts.get(value) || 0) + 1);
  });

  return Array.from(counts.entries())
    .filter(([, count]) => count > 1)
    .map(([id, count]) => ({ id, count }));
}

function getOrphanRestaurantIds(records, knownRestaurantIds) {
  const orphans = [];

  records.forEach((record) => {
    const restaurantId =
      record && typeof record.restaurantId === 'string'
        ? record.restaurantId.trim()
        : '';

    if (!restaurantId) return;
    if (!knownRestaurantIds.has(restaurantId)) {
      orphans.push({ id: record.id || '(missing id)', restaurantId });
    }
  });

  return orphans;
}

function missingSections(partner) {
  const missing = [];
  if (!partner.hasRestaurantDetail) missing.push('restaurant_details');
  if (!partner.hasFeaturedItems) missing.push('featured_items');
  if (!partner.hasMenuTabs) missing.push('menu_tabs');
  if (!partner.hasMenuItems) missing.push('menu_items');
  return missing;
}

function printDuplicateSection(title, duplicates) {
  if (duplicates.length === 0) return;
  console.log(title);
  duplicates.forEach((item) => {
    console.log(`- ${item.id} (count=${item.count})`);
  });
  console.log('');
}

function printOrphanSection(title, orphans) {
  if (orphans.length === 0) return;
  console.log(title);
  orphans.forEach((item) => {
    console.log(`- ${item.id} -> ${item.restaurantId}`);
  });
  console.log('');
}

function main() {
  const rootDir = path.resolve(__dirname, '..');
  const normalizedDir = path.join(rootDir, 'data', 'normalized');

  const restaurants = readJson(path.join(normalizedDir, 'restaurants.json'));
  const details = readJson(path.join(normalizedDir, 'restaurant_details.json'));
  const featuredItems = readJson(path.join(normalizedDir, 'featured_items.json'));
  const menuTabs = readJson(path.join(normalizedDir, 'menu_tabs.json'));
  const menuItems = readJson(path.join(normalizedDir, 'menu_items.json'));

  const restaurantIdSet = toIdSet(restaurants, 'id');

  const detailSet = toIdSet(details, 'restaurantId');
  const featuredSet = toIdSet(featuredItems, 'restaurantId');
  const tabSet = toIdSet(menuTabs, 'restaurantId');
  const itemSet = toIdSet(menuItems, 'restaurantId');

  const report = restaurants.map((restaurant) => {
    const id = restaurant.id;
    return {
      id,
      name: restaurant.name,
      isFeatured: Boolean(restaurant.isFeatured),
      hasRestaurantDetail: detailSet.has(id),
      hasFeaturedItems: featuredSet.has(id),
      hasMenuTabs: tabSet.has(id),
      hasMenuItems: itemSet.has(id),
    };
  });

  const incomplete = report.filter(
    (partner) =>
      !partner.hasRestaurantDetail ||
      !partner.hasFeaturedItems ||
      !partner.hasMenuTabs ||
      !partner.hasMenuItems,
  );

  const featuredPartners = report.filter((partner) => partner.isFeatured);
  const featuredIncomplete = featuredPartners.filter(
    (partner) => missingSections(partner).length > 0,
  );

  const featuredWithoutFlag = report.filter(
    (partner) =>
      !partner.isFeatured &&
      (partner.hasRestaurantDetail ||
        partner.hasFeaturedItems ||
        partner.hasMenuTabs ||
        partner.hasMenuItems),
  );

  const duplicateRestaurants = getDuplicateIds(restaurants);
  const duplicateDetails = getDuplicateIds(details);
  const duplicateFeaturedItems = getDuplicateIds(featuredItems);
  const duplicateMenuTabs = getDuplicateIds(menuTabs);
  const duplicateMenuItems = getDuplicateIds(menuItems);

  const orphanDetails = getOrphanRestaurantIds(details, restaurantIdSet);
  const orphanFeaturedItems = getOrphanRestaurantIds(
    featuredItems,
    restaurantIdSet,
  );
  const orphanMenuTabs = getOrphanRestaurantIds(menuTabs, restaurantIdSet);
  const orphanMenuItems = getOrphanRestaurantIds(menuItems, restaurantIdSet);

  console.log('Partner data integrity report');
  console.log('-----------------------------');
  console.log(`Total restaurants: ${report.length}`);
  console.log(`Featured restaurants: ${featuredPartners.length}`);
  console.log(`Restaurants missing at least one partner-scoped section: ${incomplete.length}`);
  console.log(`Featured restaurants missing required sections: ${featuredIncomplete.length}`);
  console.log(`Restaurants with scoped data but missing isFeatured flag: ${featuredWithoutFlag.length}`);
  console.log(
    `Duplicate IDs detected: ${
      duplicateRestaurants.length +
      duplicateDetails.length +
      duplicateFeaturedItems.length +
      duplicateMenuTabs.length +
      duplicateMenuItems.length
    }`,
  );
  console.log(
    `Orphan restaurantId references: ${
      orphanDetails.length +
      orphanFeaturedItems.length +
      orphanMenuTabs.length +
      orphanMenuItems.length
    }`,
  );
  console.log('');

  if (incomplete.length > 0) {
    console.log('Missing sections by restaurant:');
    incomplete.forEach((partner) => {
      console.log(
        `- ${partner.id} (${partner.name}): ${missingSections(partner).join(', ')}`,
      );
    });
    console.log('');
  }

  if (featuredIncomplete.length > 0) {
    console.log('Featured restaurants missing required scoped sections:');
    featuredIncomplete.forEach((partner) => {
      console.log(
        `- ${partner.id} (${partner.name}): ${missingSections(partner).join(', ')}`,
      );
    });
    console.log('');
  }

  if (featuredWithoutFlag.length > 0) {
    console.log('Needs isFeatured=true (has scoped data):');
    featuredWithoutFlag.forEach((partner) => {
      console.log(`- ${partner.id} (${partner.name})`);
    });
    console.log('');
  }

  printDuplicateSection('Duplicate IDs in restaurants:', duplicateRestaurants);
  printDuplicateSection('Duplicate IDs in restaurant_details:', duplicateDetails);
  printDuplicateSection('Duplicate IDs in featured_items:', duplicateFeaturedItems);
  printDuplicateSection('Duplicate IDs in menu_tabs:', duplicateMenuTabs);
  printDuplicateSection('Duplicate IDs in menu_items:', duplicateMenuItems);

  printOrphanSection('Orphan restaurant_details references:', orphanDetails);
  printOrphanSection('Orphan featured_items references:', orphanFeaturedItems);
  printOrphanSection('Orphan menu_tabs references:', orphanMenuTabs);
  printOrphanSection('Orphan menu_items references:', orphanMenuItems);

  if (
    featuredIncomplete.length === 0 &&
    featuredWithoutFlag.length === 0 &&
    duplicateRestaurants.length === 0 &&
    duplicateDetails.length === 0 &&
    duplicateFeaturedItems.length === 0 &&
    duplicateMenuTabs.length === 0 &&
    duplicateMenuItems.length === 0 &&
    orphanDetails.length === 0 &&
    orphanFeaturedItems.length === 0 &&
    orphanMenuTabs.length === 0 &&
    orphanMenuItems.length === 0
  ) {
    console.log('All checks passed.');
  }

  // Release gate: fail on featured contract violations and structural data integrity.
  process.exitCode =
    incomplete.length > 0 ||
    featuredIncomplete.length > 0 ||
    duplicateRestaurants.length > 0 ||
    duplicateDetails.length > 0 ||
    duplicateFeaturedItems.length > 0 ||
    duplicateMenuTabs.length > 0 ||
    duplicateMenuItems.length > 0 ||
    orphanDetails.length > 0 ||
    orphanFeaturedItems.length > 0 ||
    orphanMenuTabs.length > 0 ||
    orphanMenuItems.length > 0
      ? 1
      : 0;
}

main();
