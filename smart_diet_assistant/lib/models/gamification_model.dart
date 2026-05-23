class GamificationModel {
  int currentStreak;
  int longestStreak;
  DateTime? lastActiveDate;
  int consecutivePerfectGoalDays;
  int consecutivePerfectWaterDays;
  List<String> badges;

  GamificationModel({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.consecutivePerfectGoalDays = 0,
    this.consecutivePerfectWaterDays = 0,
    this.badges = const [],
  });

  GamificationModel copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? consecutivePerfectGoalDays,
    int? consecutivePerfectWaterDays,
    List<String>? badges,
  }) {
    return GamificationModel(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      consecutivePerfectGoalDays: consecutivePerfectGoalDays ?? this.consecutivePerfectGoalDays,
      consecutivePerfectWaterDays: consecutivePerfectWaterDays ?? this.consecutivePerfectWaterDays,
      badges: badges ?? this.badges,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'consecutivePerfectGoalDays': consecutivePerfectGoalDays,
      'consecutivePerfectWaterDays': consecutivePerfectWaterDays,
      'badges': badges,
    };
  }

  factory GamificationModel.fromMap(Map<String, dynamic> map) {
    return GamificationModel(
      currentStreak: map['currentStreak']?.toInt() ?? 0,
      longestStreak: map['longestStreak']?.toInt() ?? 0,
      lastActiveDate: map['lastActiveDate'] != null ? DateTime.tryParse(map['lastActiveDate']) : null,
      consecutivePerfectGoalDays: map['consecutivePerfectGoalDays']?.toInt() ?? 0,
      consecutivePerfectWaterDays: map['consecutivePerfectWaterDays']?.toInt() ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
    );
  }
}
