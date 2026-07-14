// ingredient_prices.dart
//
// ⚠️ THESE PRICES ARE ROUGH, ILLUSTRATIVE DEFAULTS — NOT LIVE DATA. ⚠️
// Food prices in Bangladesh move fast (weekly, sometimes daily for produce
// and cooking oil) and vary by district/bazaar. Treat every number here as
// a placeholder to seed the app, then:
//   1. Let users edit prices in a Settings > "Bazaar Prices" screen
//      (each IngredientPrice.copyWithPrice() stamps lastUpdated for you).
//   2. Optionally surface a "prices last updated X days ago" nudge so
//      stale defaults don't quietly produce wrong budget math.
//   3. If you ever want semi-live data, DAM (Department of Agricultural
//      Marketing) publishes daily wholesale/retail price bulletins —
//      that's a realistic future data source, not something to hardcode.
//
// All prices normalized to BDT per KG (see displayUnit for how the
// ingredient is actually bought/sold).

import '../models/food_models.dart';

final DateTime _seedDate = DateTime(2026, 7, 1);

final Map<String, IngredientPrice> ingredientPriceDb = {
  for (final p in _seedPrices) p.id: p,
};

final List<IngredientPrice> _seedPrices = [
  // ---- Grains & staples ----
  _p('rice_coarse', 'Coarse rice (mota chal)', 'মোটা চাল', 52, 'kg', 'grain'),
  _p('rice_miniket', 'Miniket rice', 'মিনিকেট চাল', 68, 'kg', 'grain'),
  _p('rice_atap', 'Atap/parboiled rice', 'আতপ চাল', 60, 'kg', 'grain'),
  _p('flour_atta', 'Whole wheat flour (atta)', 'আটা', 58, 'kg', 'grain'),
  _p('flour_maida', 'Refined flour (maida)', 'ময়দা', 62, 'kg', 'grain'),
  _p('suji', 'Semolina (suji)', 'সুজি', 70, 'kg', 'grain'),
  _p('muri', 'Puffed rice (muri)', 'মুড়ি', 90, 'kg', 'grain'),

  // ---- Lentils / pulses ----
  _p('dal_masoor', 'Red lentil (masoor dal)', 'মসুর ডাল', 130, 'kg', 'pulse'),
  _p('dal_mug', 'Mung dal', 'মুগ ডাল', 155, 'kg', 'pulse'),
  _p('dal_chola', 'Chickpea/chola dal', 'ছোলার ডাল', 120, 'kg', 'pulse'),
  _p('dal_khesari', 'Khesari dal', 'খেসারি ডাল', 95, 'kg', 'pulse'),

  // ---- Oils & fats ----
  _p('oil_soybean', 'Soybean oil', 'সয়াবিন তেল', 175, 'liter', 'oil'),
  _p('oil_mustard', 'Mustard oil', 'সরিষার তেল', 220, 'liter', 'oil'),
  _p('ghee', 'Ghee', 'ঘি', 900, 'kg', 'oil'),

  // ---- Vegetables ----
  _p('potato', 'Potato', 'আলু', 30, 'kg', 'vegetable'),
  _p('onion', 'Onion', 'পেঁয়াজ', 75, 'kg', 'vegetable'),
  _p('garlic', 'Garlic', 'রসুন', 160, 'kg', 'vegetable'),
  _p('ginger', 'Ginger', 'আদা', 180, 'kg', 'vegetable'),
  _p('green_chili', 'Green chili', 'কাঁচা মরিচ', 90, 'kg', 'vegetable'),
  _p('tomato', 'Tomato', 'টমেটো', 55, 'kg', 'vegetable'),
  _p('eggplant', 'Eggplant (begun)', 'বেগুন', 50, 'kg', 'vegetable'),
  _p('bean_sim', 'Flat bean (sim)', 'শিম', 60, 'kg', 'vegetable'),
  _p('pumpkin', 'Pumpkin (kumra)', 'কুমড়া', 35, 'kg', 'vegetable'),
  _p('bottle_gourd', 'Bottle gourd (lau)', 'লাউ', 30, 'kg', 'vegetable'),
  _p('bitter_gourd', 'Bitter gourd (korola)', 'করলা', 65, 'kg', 'vegetable'),
  _p('ridge_gourd', 'Ridge gourd (jhinga)', 'ঝিঙা', 55, 'kg', 'vegetable'),
  _p('okra', 'Okra (dherosh)', 'ঢেঁড়স', 50, 'kg', 'vegetable'),
  _p('potol', 'Pointed gourd (potol)', 'পটল', 45, 'kg', 'vegetable'),
  _p('cauliflower', 'Cauliflower', 'ফুলকপি', 45, 'kg', 'vegetable'),
  _p('cabbage', 'Cabbage', 'বাঁধাকপি', 35, 'kg', 'vegetable'),
  _p('carrot', 'Carrot', 'গাজর', 55, 'kg', 'vegetable'),
  _p('green_pea', 'Green pea', 'মটরশুঁটি', 90, 'kg', 'vegetable'),
  _p('radish', 'Radish (mula)', 'মুলা', 30, 'kg', 'vegetable'),
  _p('cucumber', 'Cucumber', 'শসা', 40, 'kg', 'vegetable'),
  _p('lemon', 'Lemon', 'লেবু', 8, 'piece', 'vegetable'),
  _p('coriander_leaf', 'Coriander leaf (dhonepata)', 'ধনেপাতা', 120, 'kg',
      'vegetable'),
  _p('coconut', 'Coconut', 'নারিকেল', 70, 'piece', 'vegetable'),
  _p('tamarind', 'Tamarind', 'তেঁতুল', 180, 'kg', 'vegetable'),

  // ---- Leafy greens (shak) ----
  _p('lal_shak', 'Red amaranth (lal shak)', 'লাল শাক', 40, 'kg', 'shak'),
  _p('pui_shak', 'Malabar spinach (pui shak)', 'পুঁই শাক', 35, 'kg', 'shak'),
  _p('kolmi_shak', 'Water spinach (kolmi shak)', 'কলমি শাক', 30, 'kg',
      'shak'),
  _p('pat_shak', 'Jute leaf (pat shak)', 'পাট শাক', 35, 'kg', 'shak'),

  // ---- Fish ----
  _p('rui', 'Rui fish', 'রুই মাছ', 320, 'kg', 'fish'),
  _p('katla', 'Katla fish', 'কাতলা মাছ', 340, 'kg', 'fish'),
  _p('ilish', 'Hilsa (ilish)', 'ইলিশ মাছ', 1600, 'kg', 'fish'),
  _p('pangas', 'Pangas fish', 'পাঙ্গাশ মাছ', 190, 'kg', 'fish'),
  _p('tilapia', 'Tilapia', 'তেলাপিয়া মাছ', 210, 'kg', 'fish'),
  _p('shrimp_small', 'Small shrimp (chingri)', 'চিংড়ি মাছ', 420, 'kg',
      'fish'),
  _p('shutki', 'Dried fish (shutki)', 'শুটকি মাছ', 550, 'kg', 'fish'),
  _p('pabda', 'Pabda fish', 'পাবদা মাছ', 450, 'kg', 'fish'),

  // ---- Meat & eggs ----
  _p('chicken', 'Broiler chicken', 'মুরগি', 200, 'kg', 'meat'),
  _p('beef', 'Beef', 'গরুর মাংস', 720, 'kg', 'meat'),
  _p('mutton', 'Mutton (khasi)', 'খাসির মাংস', 1050, 'kg', 'meat'),
  _p('egg', 'Egg', 'ডিম', 12, 'piece', 'dairy'),
  _p('milk', 'Milk', 'দুধ', 85, 'liter', 'dairy'),
  _p('doi', 'Yogurt (doi)', 'দই', 140, 'kg', 'dairy'),
  _p('condensed_milk', 'Condensed milk', 'কনডেন্সড মিল্ক', 220, 'kg',
      'dairy'),

  // ---- Spices (bought in small qty, priced per kg for calc) ----
  _p('turmeric_powder', 'Turmeric powder', 'হলুদ গুঁড়া', 320, 'kg', 'spice'),
  _p('chili_powder', 'Red chili powder', 'মরিচ গুঁড়া', 380, 'kg', 'spice'),
  _p('cumin_powder', 'Cumin powder (jeera)', 'জিরা গুঁড়া', 600, 'kg',
      'spice'),
  _p('coriander_powder', 'Coriander powder', 'ধনিয়া গুঁড়া', 350, 'kg',
      'spice'),
  _p('garam_masala', 'Garam masala mix', 'গরম মসলা', 1200, 'kg', 'spice'),
  _p('mustard_seed', 'Mustard seed', 'সরিষা', 220, 'kg', 'spice'),
  _p('salt', 'Salt', 'লবণ', 35, 'kg', 'spice'),
  _p('sugar', 'Sugar', 'চিনি', 130, 'kg', 'spice'),
  _p('date_molasses', 'Date molasses (khejur gur)', 'খেজুর গুড়', 200, 'kg',
      'spice'),

  // ---- Snack-specific ----
  _p('besan', 'Gram flour (besan)', 'বেসন', 140, 'kg', 'grain'),
];

IngredientPrice _p(String id, String en, String bn, double pricePerKg,
    String unit, String category) {
  return IngredientPrice(
    id: id,
    nameEn: en,
    nameBn: bn,
    pricePerKgBDT: pricePerKg,
    displayUnit: unit,
    category: category,
    lastUpdated: _seedDate,
  );
}
