class SecurityUtils {
  /// Basic sanitize input: trims whitespace and removes common HTML tags.
  /// This helps in preventing certain forms of script injection in the UI,
  /// although Flutter's Text widget already prevents executing strings as code.
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;
    
    // Trim leading/trailing whitespaces
    String sanitized = input.trim();
    
    // Remove scripts and HTML tags loosely
    // This removes content between <script> and </script> using a regex
    sanitized = sanitized.replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false), '');
    // Remove generic HTML tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    
    return sanitized;
  }
}
