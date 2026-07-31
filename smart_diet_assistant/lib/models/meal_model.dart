import 'package:hive/hive.dart';

part 'meal_model.g.dart';

@HiveType(typeId: 8)
enum MealType {
  @HiveField(0)
  breakfast,
  
  @HiveField(1)
  lunch,
  
  @HiveField(2)
  dinner,
  
  @HiveField(3)
  snack
}

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
  final int prepTimeMinutes;
  final List<String>? tags;
  bool isConsumed;

  // New fields for bd_food_db integration
  final double? sodiumMg;
  final String? glycemicImpact; // 'low' | 'medium' | 'high'
  final String? diabetesFlag; // 'favorable' | 'neutral' | 'useCaution'
  final String? diabetesNote;
  final String? hypertensionFlag;
  final String? hypertensionNote;
  final String? pcosFlag;
  final String? pcosNote;
  final String? imageQuery;
  final String? category; // 'riceBased', 'bhorta', etc.

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
    this.tags = const [],
    this.prepTimeMinutes = 15,
    this.isConsumed = false,
    this.sodiumMg,
    this.glycemicImpact,
    this.diabetesFlag,
    this.diabetesNote,
    this.hypertensionFlag,
    this.hypertensionNote,
    this.pcosFlag,
    this.pcosNote,
    this.imageQuery,
    this.category,
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
      'tags': tags,
      'prepTimeMinutes': prepTimeMinutes,
      'isConsumed': isConsumed,
      'sodiumMg': sodiumMg,
      'glycemicImpact': glycemicImpact,
      'diabetesFlag': diabetesFlag,
      'diabetesNote': diabetesNote,
      'hypertensionFlag': hypertensionFlag,
      'hypertensionNote': hypertensionNote,
      'pcosFlag': pcosFlag,
      'pcosNote': pcosNote,
      'imageQuery': imageQuery,
      'category': category,
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
      tags: List<String>.from(map['tags'] ?? []),
      prepTimeMinutes: map['prepTimeMinutes']?.toInt() ?? 15,
      isConsumed: map['isConsumed'] ?? false,
      sodiumMg: map['sodiumMg']?.toDouble(),
      glycemicImpact: map['glycemicImpact'],
      diabetesFlag: map['diabetesFlag'],
      diabetesNote: map['diabetesNote'],
      hypertensionFlag: map['hypertensionFlag'],
      hypertensionNote: map['hypertensionNote'],
      pcosFlag: map['pcosFlag'],
      pcosNote: map['pcosNote'],
      imageQuery: map['imageQuery'],
      category: map['category'],
    );
  }
}


