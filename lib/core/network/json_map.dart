/// Normalizes a decoded JSON object into a string-keyed map.
Map<String, dynamic> asJsonMap(Object? data) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  throw const FormatException('Unexpected response from the server.');
}
