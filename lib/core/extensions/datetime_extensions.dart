extension DateTimeExtensions on DateTime {
  /// Returns a compact ISO-8601 representation suitable for display.
  String toDisplayString() {
    final d = toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  /// True if this datetime is more than [hours] in the past.
  bool isOlderThan({required int hours}) =>
      DateTime.now().difference(this).inHours > hours;

  /// Converts to Unix milliseconds timestamp for storage / HLC comparison.
  int toUnixMillis() => millisecondsSinceEpoch;
}

extension NullableDateTimeExtensions on DateTime? {
  String toDisplayStringOrNever() => this?.toDisplayString() ?? 'Never';
}
