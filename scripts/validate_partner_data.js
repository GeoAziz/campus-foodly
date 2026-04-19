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
      .map((record) => (record && typeof record[key] === 'string' ? record[key].trim() : ''))
      .filter((value) => value.length > 0),
  );
}

function main() {
  const rootDir = path.resolve(__dirname, '..');
  const normalizedDir = path.join(rootDir, 'data', 'normalized');

  const restaurants = readJson(path.join(normalizedDir, 'restaurants.json'));
  const details = readJson(path.join(normalizedDir, 'restaurant_details.json'));
  const featuredItems = readJson(path.join(normalizedDir, 'featured_items.json'));
  const menuTabs = readJson(path.join(normalizedDir, 'menu_tabs.json'));
  const menuItems = readJson(path.join(normalizedDir, 'menu_items.json'));

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

  const featuredWithoutFlag = report.filter(
    (partner) =>
      !partner.isFeatured &&
      (partner.hasRestaurantDetail || partner.hasFeaturedItems || partner.hasMenuTabs || partner.hasMenuItems),
  );

  console.log('Partner data integrity report');
  console.log('-----------------------------');
  console.log(`Total restaurants: ${report.length}`);
  console.log(`Restaurants missing at least one partner-scoped section: ${incomplete.length}`);
  console.log(`Restaurants with scoped data but missing isFeatured flag: ${featuredWithoutFlag.length}`);
  console.log('');

  if (incomplete.length > 0) {
    console.log('Missing sections by restaurant:');
    incomplete.forEach((partner) => {
      const missing = [];
      if (!partner.hasRestaurantDetail) missing.push('restaurant_details');
      if (!partner.hasFeaturedItems) missing.push('featured_items');
      if (!partner.hasMenuTabs) missing.push('menu_tabs');
      if (!partner.hasMenuItems) missing.push('menu_items');
      console.log(`- ${partner.id} (${partner.name}): ${missing.join(', ')}`);
    });
    console.log('');
  }

  if (featuredWithoutFlag.length > 0) {
    console.log('Needs isFeatured=true (has scoped data):');
    featuredWithoutFlag.forEach((partner) => {
      console.log(`- ${partner.id} (${partner.name})`);
    });
  }

  if (incomplete.length === 0 && featuredWithoutFlag.length === 0) {
    console.log('All checks passed.');
  }

  process.exitCode = incomplete.length > 0 ? 1 : 0;
}

main();
