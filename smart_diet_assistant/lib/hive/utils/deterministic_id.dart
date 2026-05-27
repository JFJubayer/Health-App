class DeterministicId {
  static String ingredient(String name) {
    return 'ing_${_slug(name)}';
  }

  static String meal(String type, String name) {
    return 'meal_${type}_${_slug(name)}';
  }

  static String _slug(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('-', '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}