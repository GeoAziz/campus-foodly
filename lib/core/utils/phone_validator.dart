/// Kenyan phone number validator and formatter
class PhoneValidator {
  static const _kenyaCountryCode = '254';
  static const _kenyaPrefix = '+254';
  static const _minDigits = 10;
  static const _maxDigits = 15;

  /// Validates and formats a Kenyan phone number
  ///
  /// Accepts formats:
  /// - +254712345678 (international)
  /// - 0712345678 (local with leading 0)
  /// - 712345678 (without leading 0)
  ///
  /// Returns formatted number with +254 prefix, or null if invalid
  static String? validate(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null;
    }

    // Remove spaces and special characters
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Handle different formats
    late String normalized;

    if (cleaned.startsWith(_kenyaPrefix)) {
      // Already in +254 format
      normalized = cleaned;
    } else if (cleaned.startsWith(_kenyaCountryCode)) {
      // Has 254 without +
      normalized = '+$cleaned';
    } else if (cleaned.startsWith('0')) {
      // Local format with leading 0
      normalized = '+$_kenyaCountryCode${cleaned.substring(1)}';
    } else if (cleaned.length == _minDigits) {
      // Assume it's without leading 0
      normalized = '+$_kenyaCountryCode$cleaned';
    } else {
      return null;
    }

    // Validate format and length
    if (!_isValidFormat(normalized)) {
      return null;
    }

    return normalized;
  }

  /// Check if phone number is valid (but doesn't format it)
  static bool isValid(String? phone) {
    return validate(phone) != null;
  }

  /// Extract digits only from phone number
  static String extractDigits(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Get the last 9 digits (used for some systems)
  static String getLast9Digits(String phone) {
    final digits = extractDigits(phone);
    if (digits.length >= 9) {
      return digits.substring(digits.length - 9);
    }
    return digits;
  }

  static bool _isValidFormat(String phone) {
    // Must start with +254
    if (!phone.startsWith(_kenyaPrefix)) {
      return false;
    }

    // Remove country code and validate remaining digits
    final digitsPart = phone.substring(_kenyaPrefix.length);

    // Must have correct number of digits (9-10 after country code)
    if (digitsPart.length < 9 || digitsPart.length > 10) {
      return false;
    }

    // Must be all digits
    if (!RegExp(r'^[0-9]+$').hasMatch(digitsPart)) {
      return false;
    }

    return true;
  }

  /// Format phone for display (e.g., +254 712 345 678)
  static String formatForDisplay(String phone) {
    final validated = validate(phone);
    if (validated == null) return phone;

    final digits = extractDigits(validated);
    if (digits.length < 12) return validated; // +254 + 9 digits

    return '+${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)} ${digits.substring(9)}';
  }
}
