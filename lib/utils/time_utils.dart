import 'package:intl/intl.dart';

class TimeUtils {
  static const int klUtcOffset = 8; // UTC+8 for Kuala Lumpur

  // Get current KL time
  static DateTime getNow() {
    final now = DateTime.now();
    final utcNow = now.toUtc();
    return utcNow.add(const Duration(hours: klUtcOffset));
  }

  // Format date for display
  static String formatDate(DateTime date) {
    final klTime = ensureKLTimeZone(date);
    return DateFormat('yyyy-MM-dd').format(klTime);
  }

  // Format time for display
  static String formatTime(DateTime time) {
    final klTime = ensureKLTimeZone(time);
    return DateFormat('HH:mm:ss').format(klTime);
  }

  // Format datetime for database (always store in UTC)
  static String formatForDatabase(DateTime dateTime) {
    final utcTime = dateTime.toUtc();
    return utcTime.toString();
  }

  // Parse database datetime to KL time
  static DateTime parseFromDatabase(String dateTime) {
    final utcTime = DateTime.parse(dateTime).toUtc();
    return utcTime.add(const Duration(hours: klUtcOffset));
  }

  // Ensure time is in KL timezone
  static DateTime ensureKLTimeZone(DateTime dateTime) {
    if (!dateTime.isUtc) {
      dateTime = dateTime.toUtc();
    }
    return dateTime.add(const Duration(hours: klUtcOffset));
  }

  // Format for message display
  static String formatMessageTime(DateTime dateTime) {
    final klTime = ensureKLTimeZone(dateTime);
    return DateFormat('h:mm a').format(klTime);
  }

  // Add this method for calculating time difference
  static String getTimeAgo(DateTime dateTime) {
    final now = getNow(); // Use getNow() to get current KL time
    final messageTime =
        ensureKLTimeZone(dateTime); // Ensure message time is in KL timezone
    final difference = now.difference(messageTime);

    if (difference.inSeconds < 0) {
      return 'Just now'; // Handle case where message time is slightly ahead
    } else if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(messageTime);
    }
  }

  // Add this method to TimeUtils class
  static String formatTaskTime(DateTime time) {
    final klTime = ensureKLTimeZone(time);
    return DateFormat('h:mm a').format(klTime); // Format as "9:30 AM"
  }

  // Add this method for task date comparison
  static bool isSameDate(DateTime date1, DateTime date2) {
    final d1 = ensureKLTimeZone(date1);
    final d2 = ensureKLTimeZone(date2);
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  static DateTime getLocalTime() {
    return DateTime.now().toUtc().add(const Duration(hours: 8)); // KL is UTC+8
  }
}
