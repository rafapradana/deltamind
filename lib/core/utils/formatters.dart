import 'package:intl/intl.dart';

/// Format date to a readable string (e.g. "Jan 1, 2023")
String formatDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date);
}

/// Format date to a readable string with time (e.g. "Jan 1, 2023 2:30 PM")
String formatDateWithTime(DateTime date) {
  return DateFormat('MMM d, yyyy h:mm a').format(date);
}

/// Format date to a relative string (e.g. "2 days ago")
String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays > 365) {
    return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
  } else if (difference.inDays > 30) {
    return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
  } else if (difference.inDays > 0) {
    return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
  } else {
    return 'Just now';
  }
}

/// Format duration in minutes to readable string (e.g. "2h 30m" or "30m")
String formatDuration(int minutes) {
  if (minutes < 60) {
    return '${minutes}m';
  } else {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    if (remaining == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${remaining}m';
    }
  }
}
