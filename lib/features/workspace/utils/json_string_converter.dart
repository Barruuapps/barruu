import 'dart:convert';

/// A utility class for converting between JSON strings and Dart maps.
///
/// Provides methods to encode a [Map<String, dynamic>] to a JSON string
/// and decode a JSON string to a [Map<String, dynamic>].
class JsonStringConverter {
  /// Converts a [Map<String, dynamic>] to a JSON string.
  ///
  /// Throws an [ArgumentError] if [data] is null.
  /// Returns a JSON-encoded string representation of the provided map.
  String convertToJsonString(Map<String, dynamic>? data) {
    if (data == null) {
      throw ArgumentError('Input map cannot be null');
    }
    try {
      return jsonEncode(data);
    } catch (e) {
      throw FormatException('Failed to encode map to JSON: $e');
    }
  }

  /// Converts a JSON string to a [Map<String, dynamic>].
  ///
  /// Throws an [ArgumentError] if [jsonString] is null or empty.
  /// Throws a [FormatException] if [jsonString] is not valid JSON or
  /// does not represent a map with string keys.
  Map<String, dynamic> convertFromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      throw ArgumentError('JSON string cannot be null or empty');
    }
    try {
      final result = jsonDecode(jsonString);
      if (result is! Map<String, dynamic>) {
        throw const FormatException(
          'JSON string must represent a map with string keys',
        );
      }
      return result;
    } on FormatException catch (e) {
      throw FormatException('Invalid JSON format: $e');
    } catch (e) {
      throw FormatException('Failed to decode JSON string: $e');
    }
  }
}
