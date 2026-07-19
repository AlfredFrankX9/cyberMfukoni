import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Web stub — file operations on web are handled entirely
/// inside VaultStorageService using base64 in secure storage.
/// These functions should never actually be called on web
/// because VaultStorageService checks kIsWeb first.

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
  // No-op on web — handled by VaultStorageService directly
  throw UnsupportedError('addHiddenFileNative should not be called on web');
}

Future<void> removeHiddenFileNative({
  required Map<String, dynamic> item,
  required bool deleteCompletely,
}) async {
  // No-op on web — handled by VaultStorageService directly
  throw UnsupportedError('removeHiddenFileNative should not be called on web');
}

Future<void> restoreHiddenFileWeb(String base64Data, String fileName) async {
  final bytes = base64Decode(base64Data);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
