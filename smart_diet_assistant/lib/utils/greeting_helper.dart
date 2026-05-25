class GreetingHelper {
  static String getTimeBasedGreeting(DateTime now) {
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  static String getMotivationalMessage(int streak) {
    if (streak == 0) {
      return 'Ready to start your journey?';
    } else if (streak < 3) {
      return 'You\'re building momentum!';
    } else if (streak < 7) {
      return 'Great consistency this week!';
    } else if (streak < 14) {
      return 'You\'re on fire! Two weeks strong.';
    } else if (streak < 30) {
      return 'Incredible dedication! Keep crushing it.';
    } else {
      return 'Unstoppable! Over a month of consistency!';
    }
  }

  static String getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  static String getFormattedDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${getDayName(date)}, ${months[date.month - 1]} ${date.day}';
  }
}
