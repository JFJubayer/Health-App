class SugarReading {
  final double? preMeal;
  final double? postMeal;

  SugarReading({
    this.preMeal,
    this.postMeal,
  });

  bool get isPreMealSpike => preMeal != null && preMeal! >= 130.0;
  bool get isPostMealSpike => postMeal != null && postMeal! >= 180.0;

  SugarReading copyWith({
    double? preMeal,
    double? postMeal,
    bool clearPreMeal = false,
    bool clearPostMeal = false,
  }) {
    return SugarReading(
      preMeal: clearPreMeal ? null : (preMeal ?? this.preMeal),
      postMeal: clearPostMeal ? null : (postMeal ?? this.postMeal),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preMeal': preMeal,
      'postMeal': postMeal,
    };
  }

  factory SugarReading.fromMap(Map<String, dynamic> map) {
    return SugarReading(
      preMeal: map['preMeal']?.toDouble(),
      postMeal: map['postMeal']?.toDouble(),
    );
  }
}
