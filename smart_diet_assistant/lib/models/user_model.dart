class UserModel {
  int age;
  String gender; // 'Male' or 'Female'
  double heightCm;
  double weightKg;
  List<String> conditions;

  UserModel({
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    this.conditions = const [],
  });

  UserModel copyWith({
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    List<String>? conditions,
  }) {
    return UserModel(
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      conditions: conditions ?? this.conditions,
    );
  }
}
