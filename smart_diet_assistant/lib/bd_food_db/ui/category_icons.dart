// category_icons.dart
//
// Maps each FoodCategory to a bundled SVG icon path. These are original,
// hand-drawn placeholder icons (single-color line art) — no licensing
// concerns, unlike photos. Swap them for real dish photography later
// via FoodItem.imageQuery + a licensed image source (see ai/README.md).
//
// Setup:
//   1. Add to pubspec.yaml:
//        flutter:
//          assets:
//            - assets/icons/
//   2. Add `flutter_svg` to dependencies to render them:
//        flutter_svg: ^2.0.0
//   3. Render with: SvgPicture.asset(categoryIconPath(item.category))

import '../models/food_models.dart';

const String _iconBase = 'assets/icons';

String categoryIconPath(FoodCategory category) {
  switch (category) {
    case FoodCategory.riceBased:
      return '$_iconBase/rice_based.svg';
    case FoodCategory.bhorta:
      return '$_iconBase/bhorta.svg';
    case FoodCategory.dal:
      return '$_iconBase/dal.svg';
    case FoodCategory.fishCurry:
      return '$_iconBase/fish_curry.svg';
    case FoodCategory.meatCurry:
      return '$_iconBase/meat_curry.svg';
    case FoodCategory.eggDish:
      return '$_iconBase/egg_dish.svg';
    case FoodCategory.vegetableCurry:
      return '$_iconBase/vegetable_curry.svg';
    case FoodCategory.shak:
      return '$_iconBase/shak.svg';
    case FoodCategory.snack:
      return '$_iconBase/snack.svg';
    case FoodCategory.breakfast:
      return '$_iconBase/breakfast.svg';
    case FoodCategory.sweet:
      return '$_iconBase/sweet.svg';
    case FoodCategory.soupStew:
      return '$_iconBase/soup_stew.svg';
  }
}
