DateTime? parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

DateTime requireDateTime(Map<String, dynamic> json, String key) {
  final parsed = parseDateTime(json[key]);
  if (parsed == null) {
    throw FormatException('Missing or invalid date for "$key"');
  }
  return parsed;
}

String requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) {
    return value;
  }
  return value?.toString() ?? '';
}

String? optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  return value.toString();
}

int readInt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double readDouble(Map<String, dynamic> json, String key, {double fallback = 0}) {
  final value = json[key];
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

double? readOptionalDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}
