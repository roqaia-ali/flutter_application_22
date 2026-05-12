import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class MapLoader {
  static Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    // بنخلي المسار لمجلد الخرائط العام
    return '${directory.path}/offline_maps';
  }

  static Future<void> extractMapZip() async {
    final localPath = await getLocalPath();
    final dir = Directory(localPath);

    if (await dir.exists()) return;

    ByteData data = await rootBundle.load('assets/tiles_map.zip');
    List<int> bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    Archive archive = ZipDecoder().decodeBytes(bytes);
    for (ArchiveFile file in archive) {
      String filename = '$localPath/${file.name}';
      if (file.isFile) {
        final data = file.content as List<int>;
        File(filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(filename).createSync(recursive: true);
      }
    }
    print("Map Extracted Successfully!");
  }
}
