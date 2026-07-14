class UserModel {
  String name;
  int age;
  String gender; // 'Male' or 'Female'
  double heightCm;
  double weightKg;
  List<String> conditions;
  bool weightManagementEnabled;
  double weightDeficitCal;

  UserModel({
    required this.name,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    this.conditions = const [],
    this.weightManagementEnabled = true,
    this.weightDeficitCal = 500.0,
  });

  UserModel copyWith({
    String? name,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    List<String>? conditions,
    bool? weightManagementEnabled,
    double? weightDeficitCal,
  }) {
    return UserModel(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      conditions: conditions ?? this.conditions,
      weightManagementEnabled: weightManagementEnabled ?? this.weightManagementEnabled,
      weightDeficitCal: weightDeficitCal ?? this.weightDeficitCal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'conditions': conditions,
      'weightManagementEnabled': weightManagementEnabled,
      'weightDeficitCal': weightDeficitCal,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? 'User',
      age: map['age']?.toInt() ?? 0,
      gender: map['gender'] ?? 'Male',
      heightCm: map['heightCm']?.toDouble() ?? 0.0,
      weightKg: map['weightKg']?.toDouble() ?? 0.0,
      conditions: List<String>.from(map['conditions'] ?? []),
      weightManagementEnabled: map['weightManagementEnabled'] ?? true,
      weightDeficitCal: map['weightDeficitCal']?.toDouble() ?? 500.0,
    );
  }
}

