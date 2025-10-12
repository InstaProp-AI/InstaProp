/// Stub for file reading - will be replaced by platform-specific implementation
class FileReader {
  static Future<List<int>> readBytes(String path) async {
    throw UnsupportedError('File reading not supported on this platform');
  }
}
