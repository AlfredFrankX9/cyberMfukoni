import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

// Conditional imports for native-only dart:io
import 'vault_storage_native.dart' if (dart.library.html) 'vault_storage_web.dart' as platform;

class VaultStorageService {
  static const _storage = FlutterSecureStorage();
  static const _uuid = Uuid();

  // Keys for different storage categories
  static const _kPasswords = 'vault_passwords';
  static const _kNotes = 'vault_notes';
  static const _kCards = 'vault_cards';
  static const _kRecoveryCodes = 'vault_recovery_codes';
  static const _kPhotos = 'vault_photos';
  static const _kFiles = 'vault_files';

  // ─── GENERIC JSON LIST HELPERS ─────────────────────────
  static Future<List<Map<String, dynamic>>> _getList(String key) async {
    final data = await _storage.read(key: key);
    if (data == null || data.isEmpty) return [];
    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _saveList(String key, List<Map<String, dynamic>> list) async {
    await _storage.write(key: key, value: json.encode(list));
  }

  // ─── PASSWORDS ──────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPasswords() => _getList(_kPasswords);
  static Future<void> addPassword(Map<String, dynamic> item) async {
    final list = await getPasswords();
    item['id'] = _uuid.v4();
    list.add(item);
    await _saveList(_kPasswords, list);
  }
  static Future<void> deletePassword(String id) async {
    final list = await getPasswords();
    list.removeWhere((e) => e['id'] == id);
    await _saveList(_kPasswords, list);
  }

  // ─── NOTES ──────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getNotes() => _getList(_kNotes);
  static Future<void> addNote(Map<String, dynamic> item) async {
    final list = await getNotes();
    item['id'] = _uuid.v4();
    item['timestamp'] = DateTime.now().toIso8601String();
    list.add(item);
    await _saveList(_kNotes, list);
  }
  static Future<void> updateNote(String id, String title, String content) async {
    final list = await getNotes();
    final index = list.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      list[index]['title'] = title;
      list[index]['content'] = content;
      list[index]['timestamp'] = DateTime.now().toIso8601String();
      await _saveList(_kNotes, list);
    }
  }
  static Future<void> deleteNote(String id) async {
    final list = await getNotes();
    list.removeWhere((e) => e['id'] == id);
    await _saveList(_kNotes, list);
  }

  // ─── CREDIT CARDS ───────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getCards() => _getList(_kCards);
  static Future<void> addCard(Map<String, dynamic> item) async {
    final list = await getCards();
    item['id'] = _uuid.v4();
    list.add(item);
    await _saveList(_kCards, list);
  }
  static Future<void> deleteCard(String id) async {
    final list = await getCards();
    list.removeWhere((e) => e['id'] == id);
    await _saveList(_kCards, list);
  }

  // ─── RECOVERY CODES ─────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getRecoveryCodes() => _getList(_kRecoveryCodes);
  static Future<void> addRecoveryCode(Map<String, dynamic> item) async {
    final list = await getRecoveryCodes();
    item['id'] = _uuid.v4();
    list.add(item);
    await _saveList(_kRecoveryCodes, list);
  }
  static Future<void> deleteRecoveryCode(String id) async {
    final list = await getRecoveryCodes();
    list.removeWhere((e) => e['id'] == id);
    await _saveList(_kRecoveryCodes, list);
  }

  // ─── FILES & PHOTOS ─────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPhotos() => _getList(_kPhotos);
  static Future<List<Map<String, dynamic>>> getFiles() => _getList(_kFiles);

  /// Add a file/photo to the vault.
  /// On web, stores bytes as base64 in secure storage.
  /// On native, copies file to a hidden internal directory.
  static Future<void> addHiddenFileFromBytes({
    required Uint8List bytes,
    required String fileName,
    required bool isPhoto,
  }) async {
    try {
      final id = _uuid.v4();

      if (kIsWeb) {
        // Web: store bytes as base64 in secure storage
        final base64Data = base64Encode(bytes);
        await _storage.write(key: 'vault_file_$id', value: base64Data);

        final metadata = {
          'id': id,
          'original_name': fileName,
          'storage_key': 'vault_file_$id',
          'size': bytes.length,
          'timestamp': DateTime.now().toIso8601String(),
        };

        if (isPhoto) {
          final list = await getPhotos();
          list.add(metadata);
          await _saveList(_kPhotos, list);
        } else {
          final list = await getFiles();
          list.add(metadata);
          await _saveList(_kFiles, list);
        }
      } else {
        // Native: use filesystem
        await platform.addHiddenFileNative(
          bytes: bytes,
          fileName: fileName,
          isPhoto: isPhoto,
          id: id,
          storage: _storage,
          getPhotos: getPhotos,
          getFiles: getFiles,
          savePhotos: (list) => _saveList(_kPhotos, list),
          saveFiles: (list) => _saveList(_kFiles, list),
        );
      }
    } catch (e) {
      print('Error hiding file: $e');
    }
  }

  /// Get file bytes by ID (for displaying on web)
  static Future<Uint8List?> getFileBytes(String id) async {
    final storageKey = 'vault_file_$id';
    final base64Data = await _storage.read(key: storageKey);
    if (base64Data == null) return null;
    return base64Decode(base64Data);
  }

  /// Remove a hidden file from the vault.
  static Future<void> removeHiddenFile(String id, bool isPhoto, {bool deleteCompletely = false}) async {
    final list = isPhoto ? await getPhotos() : await getFiles();
    final itemIndex = list.indexWhere((e) => e['id'] == id);
    if (itemIndex == -1) return;

    final item = list[itemIndex];

    try {
      if (kIsWeb) {
        // Web: just delete from secure storage
        final storageKey = item['storage_key'] ?? 'vault_file_$id';
        if (!deleteCompletely) {
          final base64Data = await _storage.read(key: storageKey);
          if (base64Data != null) {
            await platform.restoreHiddenFileWeb(base64Data, item['original_name']);
          }
        }
        await _storage.delete(key: storageKey);
      } else {
        // Native: handle filesystem
        await platform.removeHiddenFileNative(
          item: item,
          deleteCompletely: deleteCompletely,
        );
      }

      list.removeAt(itemIndex);
      if (isPhoto) {
        await _saveList(_kPhotos, list);
      } else {
        await _saveList(_kFiles, list);
      }
    } catch (e) {
      print('Error removing file: $e');
    }
  }
}
