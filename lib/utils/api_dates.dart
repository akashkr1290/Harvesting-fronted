import 'package:intl/intl.dart';

final DateFormat _localDateFormat = DateFormat('yyyy-MM-dd');

/// Formats a DateTime as a plain date ("2026-07-25") for request bodies —
/// matches Jackson's serialization of Java's LocalDate fields.
String formatApiDate(DateTime date) => _localDateFormat.format(date);

/// Parses a LocalDate string ("2026-07-25") from a response body.
DateTime parseApiDate(String value) => DateTime.parse(value);

/// Parses an Instant timestamp from a response body. Java can serialize
/// with up to 9 fractional digits (nanoseconds); Dart's DateTime.parse only
/// accepts up to 6 (microseconds), so anything longer needs truncating
/// first or DateTime.parse throws a FormatException.
DateTime parseApiInstant(String value) {
  final match = RegExp(r'^(.*\.\d{6})\d*(Z|[+-]\d{2}:?\d{2})?$').firstMatch(value);
  if (match != null) {
    final truncated = '${match.group(1)}${match.group(2) ?? 'Z'}';
    return DateTime.parse(truncated);
  }
  return DateTime.parse(value);
}

/// Same truncation, but returns null for null input — convenient for
/// optional timestamp fields.
DateTime? parseApiInstantOrNull(String? value) => value == null ? null : parseApiInstant(value);

DateTime? parseApiDateOrNull(String? value) => value == null ? null : parseApiDate(value);
