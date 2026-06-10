import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class MapLoader {
  static Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/offline_maps';
  }

  static Future<void> extractMapZip() async {
    try {
      final localPath = await getLocalPath();
      final dir = Directory(localPath);

      // always ensure clean extraction
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
      await dir.create(recursive: true);

      print("Starting extraction...");

      ByteData data = await rootBundle.load('assets/tiles_map.zip');
      final bytes = data.buffer.asUint8List();

      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final path = '$localPath/${file.name}';

        if (file.isFile) {
          final outFile = File(path);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(path).create(recursive: true);
        }
      }

      print("Map Extracted Successfully!");
    } catch (e) {
      print("Error extracting map: $e");
    }
  }

  static Future<void> clearCache() async {
    final localPath = await getLocalPath();
    final dir = Directory(localPath);

    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }
}
