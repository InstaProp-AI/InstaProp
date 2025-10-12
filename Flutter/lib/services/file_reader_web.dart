/// Web implementation of file reading - should not be used
/// On web, always provide fileBytes directly
class FileReader {
  static Future<List<int>> readBytes(String path) async {
    throw UnsupportedError(
      'File path reading not supported on web. Use fileBytes parameter instead.',
    );
  }
}
