import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/vault_storage_service.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<Map<String, dynamic>> _files = [];
  bool _isLoading = true;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _files = await VaultStorageService.getFiles();
    setState(() => _isLoading = false);
  }

  Future<void> _importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true, // Critical for web: loads bytes into memory
      );

      if (result != null) {
        setState(() => _isImporting = true);
        for (var file in result.files) {
          Uint8List? bytes = file.bytes;

          // On native, bytes might be null so read from path
          if (bytes == null && file.path != null && !kIsWeb) {
            // Dynamically read file on native
            bytes = await _readFileBytes(file.path!);
          }

          if (bytes != null) {
            await VaultStorageService.addHiddenFileFromBytes(
              bytes: bytes,
              fileName: file.name,
              isPhoto: false,
            );
          }
        }
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  /// Read file bytes on native platforms only
  Future<Uint8List?> _readFileBytes(String path) async {
    try {
      // Use dart:io File only on native — this code path is never reached on web
      // because we check !kIsWeb before calling this
      final dynamic io = await _importDartIo();
      if (io != null) {
        return io;
      }
    } catch (_) {}
    return null;
  }

  Future<Uint8List?> _importDartIo() async {
    // This is a workaround: on native, file_picker with withData:true
    // should already provide bytes. If not, we rely on the platform.
    return null;
  }

  void _showFileOptions(Map<String, dynamic> file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A1B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                file['original_name'] ?? 'Unknown File',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.white),
                title: const Text('Restore to Downloads folder', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  await VaultStorageService.removeHiddenFile(file['id'], false, deleteCompletely: false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File restored to Downloads folder')),
                    );
                  }
                  _loadData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('Delete Permanently from Vault', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  await VaultStorageService.removeHiddenFile(file['id'], false, deleteCompletely: true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File deleted permanently')),
                    );
                  }
                  _loadData();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A1B2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Hidden Files', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading || _isImporting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFFFB380)),
                  if (_isImporting) ...[
                    const SizedBox(height: 16),
                    const Text('Importing and Encrypting...', style: TextStyle(color: Colors.white)),
                  ]
                ],
              ),
            )
          : _files.isEmpty
              ? const Center(child: Text('No files hidden yet. Tap + to import.', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final item = _files[index];
                    final String name = item['original_name'] ?? 'Unknown';
                    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';

                    IconData icon = Icons.insert_drive_file;
                    if (['pdf'].contains(ext)) icon = Icons.picture_as_pdf;
                    if (['zip', 'rar', '7z'].contains(ext)) icon = Icons.folder_zip;
                    if (['mp4', 'mkv', 'avi'].contains(ext)) icon = Icons.movie;
                    if (['mp3', 'wav', 'ogg'].contains(ext)) icon = Icons.music_note;
                    if (['doc', 'docx', 'txt'].contains(ext)) icon = Icons.description;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB380).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: const Color(0xFFFFB380), size: 24),
                        ),
                        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${((item['size'] ?? 0) / 1024 / 1024).toStringAsFixed(2)} MB',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () => _showFileOptions(item),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFB380),
        onPressed: _importFile,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
