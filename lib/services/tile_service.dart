import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class MapLoader {
  // 1. تحديد المسار الذي سيتم تخزين الخرائط فيه
  static Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/offline_maps';
  }

  // 2. فك ضغط الخريطة من الـ Assets إلى ذاكرة الهاتف
  static Future<void> extractMapZip() async {
    try {
      final localPath = await getLocalPath();
      final dir = Directory(localPath);

      // تجنب إعادة فك الضغط إذا كانت الملفات موجودة مسبقاً (لتوفير الوقت والبطارية)
      if (await dir.exists()) {
        print("Maps already extracted.");
        return;
      }

      print("Starting extraction...");

      // تحميل ملف الـ ZIP من الـ Assets
      ByteData data = await rootBundle.load('assets/tiles_map.zip');
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // فك التشفير (Decoding)
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
    } catch (e) {
      print("Error extracting map: $e");
    }
  }

  // 3. دالة لمسح الخرائط (إذا أردت توفير مساحة للمستخدم لاحقاً)
  static Future<void> clearCache() async {
    final localPath = await getLocalPath();
    final dir = Directory(localPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
