class FileSaver {
  static Future<void> saveFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    // Mobile implementation
    // You can use path_provider or share_plus later
    print('Saving file on mobile: $fileName');
  }
}