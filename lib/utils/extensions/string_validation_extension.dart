extension StringValidationExtension on String {
  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final _phoneRegex = RegExp(r'^\+?\d{10,15}$');
  static final _nonDigitRegex = RegExp(r'\D');
  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  bool get isValidEmail => _emailRegex.hasMatch(this);

  bool get isValidPhone => _phoneRegex.hasMatch(this);

  /// True when the string is a canonical UUID. The backend rejects
  /// non-UUID `user_id` / `post_id` values with a 400 "Must be a valid
  /// UUID." — use this before sending IDs to API endpoints that demand
  /// the canonical form (e.g. `POST /chat/start/`).
  bool get isValidUuid => _uuidRegex.hasMatch(this);

  /// Validates as email or phone based on selection.
  bool isValidContact({required bool isEmail}) {
    return isEmail ? isValidEmail : isValidPhone;
  }

  /// Removes all non-digit characters from a phone number string.
  String get sanitizedPhone => replaceAll(_nonDigitRegex, '');
}
