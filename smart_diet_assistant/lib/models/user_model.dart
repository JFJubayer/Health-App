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

  Map<String, dynamic> toMap() {
    return {
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'conditions': conditions,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      age: map['age']?.toInt() ?? 0,
      gender: map['gender'] ?? 'Male',
      heightCm: map['heightCm']?.toDouble() ?? 0.0,
      weightKg: map['weightKg']?.toDouble() ?? 0.0,
      conditions: List<String>.from(map['conditions'] ?? []),
    );
  }
}

