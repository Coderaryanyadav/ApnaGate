/// Input Validation and Sanitization Utilities
class InputValidator {
  /// Sanitize text input - remove dangerous characters
  static String sanitizeText(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[<>]'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ''); // Remove control characters
  }

  /// Validate and sanitize email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final sanitized = sanitizeText(value);
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (!emailRegex.hasMatch(sanitized)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }

  /// Validate and sanitize phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    final sanitized = value.replaceAll(RegExp(r'[^\d+]'), ''); // Keep only digits and +
    
    if (sanitized.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (sanitized.length > 15) {
      return 'Phone number is too long';
    }
    
    return null;
  }

  /// Validate name (letters, spaces, hyphens only)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    final sanitized = sanitizeText(value);
    
    if (sanitized.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (sanitized.length > 50) {
      return 'Name is too long';
    }
    
    final nameRegex = RegExp(r'^[a-zA-Z\s\-\.]+$');
    if (!nameRegex.hasMatch(sanitized)) {
      return 'Name can only contain letters, spaces, hyphens, and periods';
    }
    
    return null;
  }

  /// Validate flat number
  static String? validateFlatNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Flat number is required';
    }
    
    final sanitized = value.replaceAll(RegExp(r'[^\dA-Za-z]'), ''); // Alphanumeric only
    
    if (sanitized.isEmpty) {
      return 'Enter a valid flat number';
    }
    
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    if (value.length > 50) {
      return 'Password is too long';
    }
    
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Sanitize and validate description/message
  static String? validateDescription(String? value, {int maxLength = 500}) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    
    final sanitized = sanitizeText(value);
    
    if (sanitized.length > maxLength) {
      return 'Description must be less than $maxLength characters';
    }
    
    return null;
  }

  /// Format phone number for display
  static String formatPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return phone;
  }

  /// Check if string contains SQL injection patterns
  static bool containsSQLInjection(String input) {
    final sqlPatterns = [
      RegExp(r'(\bSELECT\b|\bINSERT\b|\bUPDATE\b|\bDELETE\b|\bDROP\b)', caseSensitive: false),
      RegExp(r'(--|;|\/\*|\*\/|xp_|sp_)', caseSensitive: false),
      RegExp(r'(\bOR\b|\bAND\b)\s+\d+\s*=\s*\d+', caseSensitive: false),
    ];
    
    return sqlPatterns.any((pattern) => pattern.hasMatch(input));
  }

  /// Check if string contains XSS patterns
  static bool containsXSS(String input) {
    final xssPatterns = [
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
    ];
    
    return xssPatterns.any((pattern) => pattern.hasMatch(input));
  }

  /// Comprehensive sanitization for database insertion
  static String sanitizeForDB(String input) {
    String sanitized = sanitizeText(input);
    
    // Remove SQL injection patterns
    if (containsSQLInjection(sanitized)) {
      sanitized = sanitized.replaceAll(RegExp(r"[;\-\']"), '');
    }
    
    // Remove XSS patterns
    if (containsXSS(sanitized)) {
      sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    }
    
    return sanitized;
  }
}
