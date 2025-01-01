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
    final klTime = _ensureKLTimeZone(date);
    return DateFormat('yyyy-MM-dd').format(klTime);
  }

  // Format time for display
  static String formatTime(DateTime time) {
    final klTime = _ensureKLTimeZone(time);
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
  static DateTime _ensureKLTimeZone(DateTime dateTime) {
    if (!dateTime.isUtc) {
      dateTime = dateTime.toUtc();
    }
    return dateTime.add(const Duration(hours: klUtcOffset));
  }

  // Format for message display
  static String formatMessageTime(DateTime dateTime) {
    final klTime = _ensureKLTimeZone(dateTime);
    return DateFormat('h:mm a').format(klTime);
  }

  // Add this method for calculating time difference
  static String getTimeAgo(DateTime dateTime) {
    final now = getNow(); // Use getNow() to get current KL time
    final messageTime =
        _ensureKLTimeZone(dateTime); // Ensure message time is in KL timezone
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
}
