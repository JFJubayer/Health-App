enum RecommendationReasonType {
  lowProtein,
  lowCarbs,
  lowFat,
  notEatenRecently,
  matchesMacroTarget,
  diabetesFriendly,
  hypertensionFriendly,
  pcosOptimized,
  quickMeal,
  highEnergy,
  balancedMeal,
}

class RecommendationReason {
  final RecommendationReasonType type;
  final String displayText;
  final double confidence;

  RecommendationReason({
    required this.type,
    required this.displayText,
    this.confidence = 0.8,
  });

  static String getReasonEmoji(RecommendationReasonType type) {
    switch (type) {
      case RecommendationReasonType.lowProtein:
        return '💪';
      case RecommendationReasonType.lowCarbs:
        return '⚡';
      case RecommendationReasonType.lowFat:
        return '🫒';
      case RecommendationReasonType.notEatenRecently:
        return '🔄';
      case RecommendationReasonType.matchesMacroTarget:
        return '🎯';
      case RecommendationReasonType.diabetesFriendly:
        return '🩺';
      case RecommendationReasonType.hypertensionFriendly:
        return '❤️';
      case RecommendationReasonType.pcosOptimized:
        return '🌸';
      case RecommendationReasonType.quickMeal:
        return '⏱️';
      case RecommendationReasonType.highEnergy:
        return '🔥';
      case RecommendationReasonType.balancedMeal:
        return '⚖️';
    }
  }
}
