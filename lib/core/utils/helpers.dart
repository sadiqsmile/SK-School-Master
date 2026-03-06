class Helpers {
  Helpers._();

  static String safeString(dynamic value, {String fallback = ''}) {
    final text = value?.toString() ?? fallback;
    return text.trim();
  }
}
