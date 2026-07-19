import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

/// Native-only implementation for file hiding using the local filesystem.
Future<void> addHiddenFileNative({
  required Uint8List bytes,
  required String fileName,
  required bool isPhoto,
  required String id,
  required FlutterSecureStorage storage,
  required Future<List<Map<String, dynamic>>> Function() getPhotos,
  required Future<List<Map<String, dynamic>>> Function() getFiles,
  required Future<void> Function(List<Map<String, dynamic>>) savePhotos,
  required Future<void> Function(List<Map<String, dynamic>>) saveFiles,
}) async {
  final dir = await path_provider.getApplicationDocumentsDirectory();
  final secureDir = Directory('${dir.path}/.cyber_vault');
  if (!await secureDir.exists()) {
    await secureDir.create(recursive: true);
  }

  final ext = fileName.contains('.') ? fileName.split('.').last : '';
  final newFileName = '$id.$ext';
  final destPath = '${secureDir.path}/$newFileName';

  // Write bytes to hidden directory
  final destFile = File(destPath);
  await destFile.writeAsBytes(bytes);

  final metadata = {
    'id': id,
    'original_name': fileName,
    'path': destPath,
    'size': bytes.length,
    'timestamp': DateTime.now().toIso8601String(),
  };

  if (isPhoto) {
    final list = await getPhotos();
    list.add(metadata);
    await savePhotos(list);
  } else {
    final list = await getFiles();
    list.add(metadata);
    await saveFiles(list);
  }
}

Future<void> removeHiddenFileNative({
  required Map<String, dynamic> item,
  required bool deleteCompletely,
}) async {
  final internalFile = File(item['path']);

  if (await internalFile.exists()) {
    if (!deleteCompletely) {
      // Export to Downloads folder
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await path_provider.getDownloadsDirectory();
      }

      if (downloadsDir != null && await downloadsDir.exists()) {
        final exportPath = '${downloadsDir.path}/${item['original_name']}';
        await internalFile.copy(exportPath);
      }
    }
    await internalFile.delete();
  }
}

Future<void> restoreHiddenFileWeb(String base64Data, String fileName) async {
  // No-op on native
  throw UnsupportedError('restoreHiddenFileWeb should not be called on native');
}

