import 'dart:io';

/// Mobile/Desktop implementation of file reading
class FileReader {
  static Future<List<int>> readBytes(String path) async {
    return await File(path).readAsBytes();
  }
}
