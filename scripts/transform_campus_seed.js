#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const DEFAULT_INPUT = 'campus_foodly_seed.json';
const DEFAULT_OUTPUT_DIR = 'data/normalized_campus';

function parseArgs(argv) {
  const args = {
    input: DEFAULT_INPUT,
    outputDir: DEFAULT_OUTPUT_DIR,
    activeOnly: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const value = argv[index];
    if (value === '--active-only') {
      args.activeOnly = true;
      continue;
    }

    if (value === '--input' && argv[index + 1]) {
      args.input = argv[index + 1];
      index += 1;
      continue;
    }

    if (value === '--output-dir' && argv[index + 1]) {
      args.outputDir = argv[index + 1];
      index += 1;
      continue;
    }
  }

  return args;
}

function ensureArray(value, label) {
  if (!Array.isArray(value)) {
    throw new Error(`Expected '${label}' to be an array.`);
  }
  return value;
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function writeJson(filePath, data) {
  fs.writeFileSync(filePath, `${JSON.stringify(data, null, 2)}\n`, 'utf8');
}

function slugPart(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function toRestaurantId(campusId, vendorId) {
  const campusPart = slugPart(campusId).replace(/^campus-?/, '');
  const vendorPart = slugPart(vendorId).replace(/^vendor-?/, '');
  return `restaurants-${campusPart}-${vendorPart}`;
}

function toMenuItemId(sourceId) {
  return `menu-items-${slugPart(sourceId).replace(/^item-?/, '')}`;
}

function toRestaurantDetailId(restaurantId) {
  return `restaurant-details-${slugPart(restaurantId).replace(/^restaurants-/, '')}`;
}

function toMenuTabId(restaurantId, position, categoryId) {
  return `menu-tabs-${slugPart(restaurantId).replace(/^restaurants-/, '')}-${position}-${slugPart(categoryId).replace(/^cat-/, '')}`;
}

function toFeaturedId(restaurantId) {
  return `featured-items-${slugPart(restaurantId).replace(/^restaurants-/, '')}`;
}

function priceTierFromMenu(minPrice, maxPrice) {
  const avg = (Number(minPrice || 0) + Number(maxPrice || 0)) / 2;
  if (avg >= 250) return 4;
  if (avg >= 170) return 3;
  if (avg >= 90) return 2;
  return 1;
}

function priceRangeFromAmount(amount) {
  if (amount >= 300) return '$$$$';
  if (amount >= 200) return '$$$';
  if (amount >= 100) return '$$';
  return '$';
}

function dedupeStrings(values) {
  return Array.from(
    new Set(
      values
        .map((value) => (typeof value === 'string' ? value.trim() : ''))
        .filter(Boolean),
    ),
  );
}

function transform(source, options) {
  const campuses = ensureArray(source.campuses, 'campuses');
  const categories = ensureArray(source.categories, 'categories');
  const vendors = ensureArray(source.vendors, 'vendors');
  const menuItems = ensureArray(source.menu_items, 'menu_items');

  const selectedCampuses = options.activeOnly
    ? campuses.filter((campus) => campus && campus.is_active)
    : campuses;

  const campusById = new Map(
    selectedCampuses
      .filter((campus) => campus && campus._id)
      .map((campus) => [String(campus._id), campus]),
  );

  const categoryById = new Map(
    categories
      .filter((category) => category && category._id)
      .map((category) => [String(category._id), category]),
  );

  const scopedVendors = vendors.filter(
    (vendor) => vendor && vendor._id && campusById.has(String(vendor.campus_id)),
  );

  const restaurantIdByVendorId = new Map();
  const vendorByRestaurantId = new Map();
  const restaurants = [];

  for (const vendor of scopedVendors) {
    const campus = campusById.get(String(vendor.campus_id));
    const restaurantId = toRestaurantId(vendor.campus_id, vendor._id);
    restaurantIdByVendorId.set(String(vendor._id), restaurantId);
    vendorByRestaurantId.set(restaurantId, vendor);

    const vendorItems = menuItems.filter(
      (item) => item && String(item.vendor_id) === String(vendor._id),
    );
    const prices = vendorItems
      .map((item) => Number(item.price || 0))
      .filter((value) => Number.isFinite(value) && value > 0);
    const minPrice = prices.length > 0 ? Math.min(...prices) : 0;
    const maxPrice = prices.length > 0 ? Math.max(...prices) : 0;

    const categoryIds = ensureArray(vendor.category_ids || [], 'vendor.category_ids');
    const categoryNames = dedupeStrings(
      categoryIds.map((categoryId) => categoryById.get(String(categoryId))?.name),
    );

    restaurants.push({
      id: restaurantId,
      name: String(vendor.name || 'Campus Vendor'),
      image: String(vendor.logo_url || vendor.banner_url || ''),
      location: `${campus.short_name || campus.name || 'Campus'} - ${
        vendor.location_description || 'Near campus'
      }`,
      rating: Number(vendor.rating || 0),
      ratingCount: Number(vendor.rating_count || 0),
      deliveryTime: Number(vendor.preparation_time_minutes || 15),
      deliveryFee:
        campus.delivery_fee !== undefined && campus.delivery_fee !== null
          ? `KES ${campus.delivery_fee}`
          : 'Free',
      categories: categoryNames,
      dietaries: ['Any'],
      priceTier: priceTierFromMenu(minPrice, maxPrice),
      isFeatured: Boolean(vendor.is_featured),
      campusId: String(vendor.campus_id),
      isOpen: Boolean(vendor.is_open),
    });
  }

  const transformedMenuItems = [];
  for (const item of menuItems) {
    if (!item || !item._id) {
      continue;
    }

    const restaurantId = restaurantIdByVendorId.get(String(item.vendor_id));
    if (!restaurantId) {
      continue;
    }

    const category = categoryById.get(String(item.category_id));
    const categoryName = String(category?.name || 'General');

    transformedMenuItems.push({
      id: toMenuItemId(item._id),
      restaurantId,
      name: String(item.name || ''),
      price: Number(item.price || 0),
      image: String(item.image_url || ''),
      description: String(item.description || ''),
      category: categoryName,
      foodType: categoryName,
      priceRange: priceRangeFromAmount(Number(item.price || 0)),
      isAvailable: Boolean(item.is_available !== false),
      isPopular: Boolean(item.is_popular),
    });
  }

  const restaurantDetails = restaurants.map((restaurant) => {
    const vendor = vendorByRestaurantId.get(restaurant.id);

    const categoryIds = ensureArray(vendor?.category_ids || [], 'vendor.category_ids');
    const foodTypes = dedupeStrings(
      categoryIds.map((categoryId) => categoryById.get(String(categoryId))?.name),
    );

    return {
      id: toRestaurantDetailId(restaurant.id),
      restaurantId: restaurant.id,
      foodTypes,
      ratingCount: Number(vendor?.rating_count || 0),
      deliveryFee: restaurant.deliveryFee,
      deliveryTime: restaurant.deliveryTime,
      takeAwayLabel: 'Take away',
    };
  });

  const menuTabs = [];
  for (const vendor of scopedVendors) {
    const restaurantId = restaurantIdByVendorId.get(String(vendor._id));
    if (!restaurantId) {
      continue;
    }

    const categoryIds = dedupeStrings(ensureArray(vendor.category_ids || [], 'vendor.category_ids'));
    categoryIds.forEach((categoryId, position) => {
      const categoryName = String(categoryById.get(String(categoryId))?.name || 'General');
      menuTabs.push({
        id: toMenuTabId(restaurantId, position, categoryId),
        restaurantId,
        title: categoryName,
        position,
      });
    });
  }

  const featuredItems = [];
  const featuredVendors = scopedVendors.filter((vendor) => Boolean(vendor.is_featured));
  featuredVendors.forEach((vendor, position) => {
    const restaurantId = restaurantIdByVendorId.get(String(vendor._id));
    if (!restaurantId) {
      return;
    }

    const featuredMenu = transformedMenuItems.find(
      (item) => item.restaurantId === restaurantId && item.isPopular,
    ) || transformedMenuItems.find((item) => item.restaurantId === restaurantId);

    const primaryCategoryName = String(
      categoryById.get(String(vendor.primary_category || ''))?.name ||
        categoryById.get(String((vendor.category_ids || [])[0] || ''))?.name ||
        'Featured',
    );

    featuredItems.push({
      id: toFeaturedId(restaurantId),
      restaurantId,
      title: String(featuredMenu?.name || `${vendor.name} Special`),
      image: String(featuredMenu?.image || vendor.banner_url || vendor.logo_url || ''),
      foodType: primaryCategoryName,
      priceRange: featuredMenu?.priceRange || '$$',
      position,
    });
  });

  const transformedCategories = categories
    .filter((category) => category && category._id)
    .map((category) => ({
      id: String(category._id),
      title: String(category.name || ''),
      isActive: Boolean(category.is_active !== false),
      description: String(category.description || ''),
    }));

  return {
    restaurants,
    restaurantDetails,
    featuredItems,
    menuTabs,
    menuItems: transformedMenuItems,
    categories: transformedCategories,
  };
}

function validate(outputs) {
  const errors = [];

  const requiredFieldMap = {
    restaurants: ['id', 'name', 'image', 'location', 'rating', 'deliveryTime'],
    restaurantDetails: ['id', 'restaurantId', 'deliveryFee', 'deliveryTime'],
    featuredItems: ['id', 'restaurantId', 'title', 'image', 'position'],
    menuTabs: ['id', 'restaurantId', 'title', 'position'],
    menuItems: ['id', 'restaurantId', 'name', 'price', 'image', 'isAvailable'],
    categories: ['id', 'title'],
  };

  for (const [key, records] of Object.entries(outputs)) {
    const requiredFields = requiredFieldMap[key] || [];
    const ids = new Set();

    records.forEach((record, index) => {
      requiredFields.forEach((field) => {
        if (record[field] === undefined || record[field] === null || record[field] === '') {
          errors.push(`${key}[${index}] missing required field '${field}'`);
        }
      });

      const id = String(record.id || '').trim();
      if (!id) {
        errors.push(`${key}[${index}] has empty id`);
        return;
      }
      if (ids.has(id)) {
        errors.push(`${key}[${index}] has duplicate id '${id}'`);
      }
      ids.add(id);
    });
  }

  const restaurantIds = new Set(outputs.restaurants.map((restaurant) => restaurant.id));

  const scopedCollections = [
    ['restaurantDetails', outputs.restaurantDetails],
    ['featuredItems', outputs.featuredItems],
    ['menuTabs', outputs.menuTabs],
    ['menuItems', outputs.menuItems],
  ];

  for (const [name, records] of scopedCollections) {
    records.forEach((record) => {
      if (!restaurantIds.has(record.restaurantId)) {
        errors.push(`${name} record '${record.id}' has orphan restaurantId '${record.restaurantId}'`);
      }
    });
  }

  return errors;
}

function main() {
  const args = parseArgs(process.argv.slice(2));

  const root = path.resolve(__dirname, '..');
  const inputPath = path.resolve(root, args.input);
  const outputDir = path.resolve(root, args.outputDir);

  if (!fs.existsSync(inputPath)) {
    throw new Error(`Input file does not exist: ${inputPath}`);
  }

  const source = readJson(inputPath);
  const outputs = transform(source, args);
  const errors = validate(outputs);

  if (errors.length > 0) {
    console.error('Transformation validation failed:\n');
    errors.forEach((error) => console.error(`- ${error}`));
    process.exit(1);
  }

  fs.mkdirSync(outputDir, { recursive: true });

  writeJson(path.join(outputDir, 'restaurants.json'), outputs.restaurants);
  writeJson(path.join(outputDir, 'restaurant_details.json'), outputs.restaurantDetails);
  writeJson(path.join(outputDir, 'featured_items.json'), outputs.featuredItems);
  writeJson(path.join(outputDir, 'menu_tabs.json'), outputs.menuTabs);
  writeJson(path.join(outputDir, 'menu_items.json'), outputs.menuItems);
  writeJson(path.join(outputDir, 'categories.json'), outputs.categories);

  console.log('Campus dataset transformation completed.');
  console.log(`Input: ${inputPath}`);
  console.log(`Output directory: ${outputDir}`);
  console.log(`restaurants: ${outputs.restaurants.length}`);
  console.log(`restaurant_details: ${outputs.restaurantDetails.length}`);
  console.log(`featured_items: ${outputs.featuredItems.length}`);
  console.log(`menu_tabs: ${outputs.menuTabs.length}`);
  console.log(`menu_items: ${outputs.menuItems.length}`);
  console.log(`categories: ${outputs.categories.length}`);
}

main();
