import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/vault_storage_service.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;
  bool _isImporting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _photos = await VaultStorageService.getPhotos();
    setState(() => _isLoading = false);
  }

  Future<void> _importPhoto() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        setState(() => _isImporting = true);
        for (var image in images) {
          final bytes = await image.readAsBytes();
          
          await VaultStorageService.addHiddenFileFromBytes(
            bytes: bytes,
            fileName: image.name,
            isPhoto: true,
          );
        }
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showPhotoOptions(Map<String, dynamic> photo) {
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
                photo['original_name'] ?? 'Unknown Photo',
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
                  await VaultStorageService.removeHiddenFile(photo['id'], true, deleteCompletely: false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Photo restored to Downloads')),
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
                  await VaultStorageService.removeHiddenFile(photo['id'], true, deleteCompletely: true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Photo deleted permanently')),
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
        title: Text('Private Photos', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
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
          : _photos.isEmpty
              ? const Center(child: Text('No photos hidden yet. Tap + to import.', style: TextStyle(color: Colors.white54)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final item = _photos[index];
                    
                    return GestureDetector(
                      onTap: () {
                        // Show full screen image
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => _FullScreenImage(
                              item: item,
                            ),
                          ),
                        );
                      },
                      onLongPress: () => _showPhotoOptions(item),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImageThumbnail(item),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFB380),
        onPressed: _importPhoto,
        child: const Icon(Icons.add_photo_alternate, color: Colors.white),
      ),
    );
  }

  Widget _buildImageThumbnail(Map<String, dynamic> item) {
    if (kIsWeb) {
      // On web, we must load from secure storage
      return FutureBuilder<Uint8List?>(
        future: VaultStorageService.getFileBytes(item['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.white12,
              child: const Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFB380)),
                ),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          }
          return Container(color: Colors.white12, child: const Icon(Icons.broken_image, color: Colors.white54));
        },
      );
    } else {
      // On native, we can load from file path
      final file = File(item['path']);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
      return Container(color: Colors.white12, child: const Icon(Icons.broken_image, color: Colors.white54));
    }
  }
}

class _FullScreenImage extends StatelessWidget {
  final Map<String, dynamic> item;

  const _FullScreenImage({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item['original_name'] ?? 'Photo';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(name, style: const TextStyle(fontSize: 14)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: _buildFullImage(),
        ),
      ),
    );
  }

  Widget _buildFullImage() {
    if (kIsWeb) {
      return FutureBuilder<Uint8List?>(
        future: VaultStorageService.getFileBytes(item['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(color: Color(0xFFFFB380));
          }
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(snapshot.data!);
          }
          return const Icon(Icons.broken_image, color: Colors.white54, size: 64);
        },
      );
    } else {
      final file = File(item['path']);
      if (file.existsSync()) {
        return Image.file(file);
      }
      return const Icon(Icons.broken_image, color: Colors.white54, size: 64);
    }
  }
}
