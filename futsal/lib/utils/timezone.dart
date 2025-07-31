/// Timezone utilities for Somalia (EAT - East Africa Time)
/// Somalia is UTC+3
class SomaliaTimezone {
  static const String _timezone = 'Africa/Mogadishu';
  
  /// Get current time in Somalia timezone
  static DateTime getSomaliaTime() {
    final now = DateTime.now();
    return now.toUtc().add(const Duration(hours: 3)); // UTC+3
  }
  
  /// Convert a date to Somalia timezone
  static DateTime toSomaliaTime(DateTime date) {
    return date.toUtc().add(const Duration(hours: 3)); // UTC+3
  }
  
  /// Convert Somalia time to UTC for API calls
  static DateTime somaliaToUTC(DateTime somaliaDate) {
    return somaliaDate.toUtc().subtract(const Duration(hours: 3)); // UTC+3
  }
  
  /// Convert UTC date to Somalia timezone for display
  static DateTime utcToSomalia(DateTime utcDate) {
    return utcDate.add(const Duration(hours: 3)); // UTC+3
  }
  
  /// Get current Somalia date in YYYY-MM-DD format
  static String getSomaliaDateString() {
    final somaliaTime = getSomaliaTime();
    return _formatDate(somaliaTime);
  }
  
  /// Get Somalia date string from a date
  static String getSomaliaDateStringFromDate(DateTime date) {
    final somaliaTime = toSomaliaTime(date);
    return _formatDate(somaliaTime);
  }
  
  /// Check if a date is today in Somalia timezone
  static bool isTodayInSomalia(DateTime date) {
    final somaliaToday = getSomaliaDateString();
    final somaliaDate = getSomaliaDateStringFromDate(date);
    return somaliaToday == somaliaDate;
  }
  
  /// Check if a date is in the past in Somalia timezone
  static bool isPastDateInSomalia(DateTime date) {
    final somaliaToday = getSomaliaTime();
    final somaliaDate = toSomaliaTime(date);
    
    // Set both dates to midnight for comparison
    final todayMidnight = DateTime(somaliaToday.year, somaliaToday.month, somaliaToday.day);
    final dateMidnight = DateTime(somaliaDate.year, somaliaDate.month, somaliaDate.day);
    
    return dateMidnight.isBefore(todayMidnight);
  }
  
  /// Get Somalia time string in HH:MM format
  static String getSomaliaTimeString(DateTime date) {
    final somaliaTime = toSomaliaTime(date);
    return _formatTime(somaliaTime);
  }
  
  /// Create a date object for a specific date in Somalia timezone
  static DateTime createSomaliaDate(String dateString) {
    final parts = dateString.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    
    return DateTime(year, month, day);
  }
  
  /// Validate if a booking date is valid (not in past) in Somalia timezone
  static bool isValidBookingDateInSomalia(DateTime date) {
    return !isPastDateInSomalia(date);
  }
  
  /// Get current Somalia timestamp
  static int getSomaliaTimestamp() {
    return getSomaliaTime().millisecondsSinceEpoch;
  }
  
  /// Format date for display in Somalia timezone
  static String formatDateForDisplay(DateTime date) {
    final somaliaDate = utcToSomalia(date);
    return _formatDate(somaliaDate);
  }
  
  /// Format date for API calls (convert to UTC)
  static String formatDateForAPI(DateTime date) {
    final utcDate = somaliaToUTC(date);
    return _formatDate(utcDate);
  }
  
  /// Get today's date in Somalia timezone for date pickers
  static DateTime getTodayInSomalia() {
    final somaliaTime = getSomaliaTime();
    return DateTime(somaliaTime.year, somaliaTime.month, somaliaTime.day);
  }
  
  /// Get tomorrow's date in Somalia timezone
  static DateTime getTomorrowInSomalia() {
    final today = getTodayInSomalia();
    return today.add(const Duration(days: 1));
  }
  
  /// Get a date 30 days from now in Somalia timezone
  static DateTime getDateIn30DaysInSomalia() {
    final today = getTodayInSomalia();
    return today.add(const Duration(days: 30));
  }
  
  /// Check if a date is in the future in Somalia timezone
  static bool isFutureDateInSomalia(DateTime date) {
    final somaliaToday = getSomaliaTime();
    final somaliaDate = toSomaliaTime(date);
    
    // Set both dates to midnight for comparison
    final todayMidnight = DateTime(somaliaToday.year, somaliaToday.month, somaliaToday.day);
    final dateMidnight = DateTime(somaliaDate.year, somaliaDate.month, somaliaDate.day);
    
    return dateMidnight.isAfter(todayMidnight);
  }
  
  /// Helper method to format date as YYYY-MM-DD
  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
  
  /// Helper method to format time as HH:MM
  static String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
} 