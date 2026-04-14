enum MealType { breakfast, lunch, dinner }

class MealModel {
  final String id;
  final String name;
  final int calories;
  final MealType type;
  final double protein;
  final double carbs;
  final double fat;
  final List<String> ingredients;
  final String instructions;
  final List<String> recipeSteps;
  final List<Map<String, dynamic>> components; // Added for structured meal building
  final String? imageUrl;
  bool isConsumed;

  MealModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.type,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.ingredients = const [],
    this.instructions = '',
    this.recipeSteps = const [],
    this.components = const [],
    this.imageUrl,
    this.isConsumed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'type': type.index,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'ingredients': ingredients,
      'instructions': instructions,
      'recipeSteps': recipeSteps,
      'components': components,
      'imageUrl': imageUrl,
      'isConsumed': isConsumed,
    };
  }

  factory MealModel.fromMap(Map<String, dynamic> map) {
    return MealModel(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] ?? '',
      calories: map['calories']?.toInt() ?? 0,
      type: MealType.values[map['type'] ?? 0],
      protein: map['protein']?.toDouble() ?? 0.0,
      carbs: map['carbs']?.toDouble() ?? 0.0,
      fat: map['fat']?.toDouble() ?? 0.0,
      ingredients: List<String>.from(map['ingredients'] ?? []),
      instructions: map['instructions'] ?? '',
      recipeSteps: List<String>.from(map['recipeSteps'] ?? []),
      components: List<Map<String, dynamic>>.from(map['components'] ?? []),
      imageUrl: map['imageUrl'],
      isConsumed: map['isConsumed'] ?? false,
    );
  }
}


