extension StringExtensions on String {
  /// Capitalises the first character only.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Truncates to [maxLength] and appends '…' if needed.
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';

  /// True if this string is a non-empty, non-whitespace value.
  bool get isNotBlank => trim().isNotEmpty;
}
