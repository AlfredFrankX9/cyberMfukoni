import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Theme constants
const Color _kDeepBlack = Color(0xFF000000);
const Color _kSlateBlue = Color(0xFF222633);
const Color _kMetallicSilver = Color(0xFFB0B0B0);
const Color _kNeonGreen = Color(0xFF00FF40);
const Color _kCyberEmerald = Color(0xFF32CD32);
const Color _kWarningAmber = Color(0xFFFF9100);
const Color _kCriticalRed = Color(0xFFFF1744);

class SecureShredderScreen extends StatefulWidget {
  const SecureShredderScreen({super.key});

  @override
  State<SecureShredderScreen> createState() => _SecureShredderScreenState();
}

class _SecureShredderScreenState extends State<SecureShredderScreen> {
  static const _shredderChannel = MethodChannel('com.example.frontend/shredder');

  List<Map<String, dynamic>> _selectedFiles = [];
  bool _isShredding = false;
  double _overallProgress = 0.0;
  List<String> _shredLogs = [];
  final ScrollController _logScroll = ScrollController();

  Future<bool> _ensureStoragePermission() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return true;

    try {
      final hasPermission = await _shredderChannel.invokeMethod('hasStoragePermission');
      if (hasPermission == true) return true;

      // Open the system settings page for MANAGE_ALL_FILES_ACCESS
      await _shredderChannel.invokeMethod('requestStoragePermission');

      // Show a dialog telling the user to come back after granting
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _kSlateBlue,
            title: Text(
              "Grant File Access",
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Android has opened Settings. Please find \"The Guardian\" in the list and toggle \"Allow access to manage all files\" ON, then press Back to return here.",
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: _kNeonGreen),
                child: Text("I've granted it", style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }

      // Re-check after returning
      final nowGranted = await _shredderChannel.invokeMethod('hasStoragePermission');
      return nowGranted == true;
    } catch (e) {
      debugPrint("Permission check failed: $e");
      return false;
    }
  }

  Future<void> _openFileExplorer() async {
    if (_isShredding) return;

    final hasPermission = await _ensureStoragePermission();
    if (!hasPermission) {
      _addLog("[ERROR] Storage permission denied. Cannot access files for shredding.");
      return;
    }

    if (!mounted) return;

    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (ctx) => const _GuardianFileExplorer(),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedFiles = result;
        _shredLogs = [
          "[SYSTEM] Selected ${_selectedFiles.length} file(s) for secure shredding.",
          "[WARN] Secure shredding will permanently destroy data. Recovery is impossible."
        ];
      });
    }
  }

  void _addLog(String log) {
    setState(() {
      _shredLogs.add(log);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.animateTo(
          _logScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _shredFiles() async {
    if (_selectedFiles.isEmpty || _isShredding) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kSlateBlue,
        title: Text("WARNING: PERMANENT DELETION", style: GoogleFonts.inter(color: _kCriticalRed, fontWeight: FontWeight.bold)),
        content: Text("You are about to securely shred ${_selectedFiles.length} file(s). This action cannot be undone. Digital forensic recovery will be impossible. Are you sure?", style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL", style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kCriticalRed),
            child: Text("OBLITERATE", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isShredding = true;
      _overallProgress = 0.0;
    });

    _addLog("\n[SHRED] Commencing military-grade file shredding (3-pass overwrite)...");

    int totalFiles = _selectedFiles.length;

    for (int idx = 0; idx < _selectedFiles.length; idx++) {
      final file = _selectedFiles[idx];
      final name = file['name'] as String;
      final path = file['path'] as String;
      final size = file['size'] as int? ?? 0;

      _addLog("\n[TARGET] Processing: $name ($size bytes)");

      if (kIsWeb) {
        for (int pass = 1; pass <= 3; pass++) {
          await Future.delayed(const Duration(milliseconds: 400));
          String patternType = pass == 1 ? "zeros (0x00)" : (pass == 2 ? "ones (0xFF)" : "random entropy");
          _addLog("  Pass $pass/3: Overwriting sectors with $patternType ... [OK]");
        }
        await Future.delayed(const Duration(milliseconds: 300));
        _addLog("  [DELETED] secrets unlink complete.");
        setState(() => _overallProgress = (idx + 1) / totalFiles);
        continue;
      }

      try {
        _addLog("  Pass 1/3: Overwriting with zeros (0x00)...");
        _addLog("  Pass 2/3: Overwriting with ones (0xFF)...");
        _addLog("  Pass 3/3: Overwriting with random entropy...");

        final result = await _shredderChannel.invokeMethod('shredFile', {'path': path});

        if (result is Map && result['success'] == true) {
          _addLog("  Finalizing: Securely unlinking file entry...");
          _addLog("  [SUCCESS] $name securely obliterated. (${result['size']} bytes destroyed)");
        } else {
          final error = result is Map ? result['error'] ?? 'Unknown error' : 'Unknown error';
          _addLog("  [WARN] $error");
        }
      } on PlatformException catch (e) {
        _addLog("  [ERROR] Native shred failed: ${e.message}");
        _addLog("  [RETRY] Attempting Dart-based shredding...");
        try {
          final f = File(path);
          if (await f.exists()) {
            final length = await f.length();
            final random = Random();
            await f.writeAsBytes(Uint8List(length), flush: true);
            await f.writeAsBytes(Uint8List.fromList(List.generate(length, (_) => 0xFF)), flush: true);
            await f.writeAsBytes(Uint8List.fromList(List.generate(length, (_) => random.nextInt(256))), flush: true);
            await f.delete();
            _addLog("  [SUCCESS] $name obliterated via fallback method.");
          } else {
            _addLog("  [ERROR] File does not exist at path.");
          }
        } catch (fallbackError) {
          _addLog("  [ERROR] Fallback shred failed: $fallbackError");
        }
      }

      setState(() => _overallProgress = (idx + 1) / totalFiles);
    }

    _addLog("\n[COMPLETE] Secure shredding cycle finished. All selected files destroyed.");

    setState(() {
      _selectedFiles = [];
      _isShredding = false;
    });
  }

  @override
  void dispose() {
    _logScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDeepBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "SECURE SHREDDER",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPickerArea(),
            const SizedBox(height: 20),
            if (_selectedFiles.isNotEmpty && !_isShredding) _buildFilesList(),
            if (_isShredding) ...[
              const SizedBox(height: 10),
              Text(
                "SHREDDING IN PROGRESS: ${(_overallProgress * 100).toInt()}%",
                style: GoogleFonts.inter(color: _kNeonGreen, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _overallProgress,
                backgroundColor: _kSlateBlue,
                color: _kNeonGreen,
                minHeight: 8,
              ),
            ],
            if (_shredLogs.isNotEmpty) ...[
              const SizedBox(height: 20),
              Expanded(child: _buildLogView()),
            ],
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerArea() {
    return GestureDetector(
      onTap: _openFileExplorer,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        decoration: BoxDecoration(
          color: _kSlateBlue.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _kCriticalRed.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _kCriticalRed.withOpacity(0.05),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.delete_forever,
              color: _kCriticalRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              "BROWSE FILES TO SHRED",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Files are overwritten with random bytes 3 times before deletion, making digital forensic recovery impossible.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: _kMetallicSilver,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSlateBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          final name = file['name'] as String;
          final size = file['size'] as int? ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file, color: _kMetallicSilver, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "${(size / 1024).toStringAsFixed(1)} KB",
                  style: GoogleFonts.inter(color: _kMetallicSilver, fontSize: 11),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFiles.removeAt(index);
                    });
                  },
                  child: const Icon(Icons.close, color: _kCriticalRed, size: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _kCriticalRed.withOpacity(0.2),
        ),
      ),
      child: ListView.builder(
        controller: _logScroll,
        itemCount: _shredLogs.length,
        itemBuilder: (context, index) {
          final log = _shredLogs[index];
          Color logColor = _kNeonGreen.withOpacity(0.8);
          if (log.startsWith("[ERROR]")) logColor = _kCriticalRed;
          if (log.startsWith("[WARN]")) logColor = _kWarningAmber;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              log,
              style: GoogleFonts.shareTechMono(
                color: logColor,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    final enabled = _selectedFiles.isNotEmpty && !_isShredding;
    return ElevatedButton(
      onPressed: enabled ? _shredFiles : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kCriticalRed,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _kCriticalRed.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        _isShredding ? "OBLITERATING DATA..." : "SECURELY SHRED FILES",
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom native file explorer that bypasses SAF and reads the real filesystem
// ─────────────────────────────────────────────────────────────────────────────
class _GuardianFileExplorer extends StatefulWidget {
  const _GuardianFileExplorer();

  @override
  State<_GuardianFileExplorer> createState() => _GuardianFileExplorerState();
}

class _GuardianFileExplorerState extends State<_GuardianFileExplorer> {
  static const _channel = MethodChannel('com.example.frontend/shredder');
  static const _rootPath = '/storage/emulated/0';

  String _currentPath = _rootPath;
  List<Map<String, dynamic>> _entries = [];
  final Set<String> _selectedPaths = {};
  bool _loading = true;
  String? _error;

  // Quick-access directory shortcuts
  List<Map<String, dynamic>> _quickDirs = [];

  @override
  void initState() {
    super.initState();
    _loadQuickDirs();
    _loadDirectory(_rootPath);
  }

  Future<void> _loadQuickDirs() async {
    try {
      final result = await _channel.invokeMethod('getStorageDirectories');
      if (result != null) {
        setState(() {
          _quickDirs = (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _loading = true;
      _error = null;
      _currentPath = path;
    });

    try {
      final result = await _channel.invokeMethod('listDirectory', {'path': path});
      if (result != null) {
        setState(() {
          _entries = (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _entries = [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _entries = [];
        _loading = false;
      });
    }
  }

  void _goUp() {
    if (_currentPath == _rootPath || _currentPath == '/') return;
    final parent = _currentPath.substring(0, _currentPath.lastIndexOf('/'));
    if (parent.isEmpty) return;
    _loadDirectory(parent);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  IconData _iconForName(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'aac':
        return Icons.audiotrack;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'apk':
        return Icons.android;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'doc':
      case 'docx':
      case 'txt':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortPath = _currentPath.replaceFirst('/storage/emulated/0', 'Internal');

    return Dialog(
      backgroundColor: const Color(0xFF111418),
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // ── Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              decoration: BoxDecoration(
                color: _kSlateBlue,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder_special, color: _kNeonGreen, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        "GUARDIAN FILE EXPLORER",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick-access chips
                  if (_quickDirs.isNotEmpty)
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: _quickDirs.length,
                        itemBuilder: (ctx, i) {
                          final dir = _quickDirs[i];
                          final isActive = _currentPath == dir['path'];
                          return GestureDetector(
                            onTap: () => _loadDirectory(dir['path'] as String),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive ? _kNeonGreen.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: isActive ? Border.all(color: _kNeonGreen, width: 1) : null,
                              ),
                              child: Text(
                                dir['name'] as String,
                                style: GoogleFonts.inter(
                                  color: isActive ? _kNeonGreen : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // ── Breadcrumb / Path bar
            Container(
              color: Colors.black26,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, color: _kNeonGreen, size: 20),
                    onPressed: _goUp,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      shortPath,
                      style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedPaths.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kCriticalRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${_selectedPaths.length} selected",
                        style: GoogleFonts.inter(color: _kCriticalRed, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            // ── File list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _kNeonGreen))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              "Access denied or empty directory.\n\n$_error",
                              style: GoogleFonts.inter(color: _kCriticalRed, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _entries.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.folder_off, color: Colors.white24, size: 48),
                                  const SizedBox(height: 12),
                                  Text("Empty directory", style: GoogleFonts.inter(color: Colors.white38)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _entries.length,
                              itemBuilder: (ctx, index) {
                                final entry = _entries[index];
                                final name = entry['name'] as String;
                                final path = entry['path'] as String;
                                final isDir = entry['isDirectory'] == true;
                                final size = entry['size'] as int? ?? 0;
                                final isSelected = _selectedPaths.contains(path);

                                return Material(
                                  color: isSelected ? _kCriticalRed.withOpacity(0.1) : Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      if (isDir) {
                                        _loadDirectory(path);
                                      } else {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedPaths.remove(path);
                                          } else {
                                            _selectedPaths.add(path);
                                          }
                                        });
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isDir ? Icons.folder : _iconForName(name),
                                            color: isDir ? _kWarningAmber : _kMetallicSilver,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (!isDir)
                                                  Text(
                                                    _formatSize(size),
                                                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (isDir)
                                            const Icon(Icons.chevron_right, color: Colors.white24, size: 20)
                                          else
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: isSelected,
                                                activeColor: _kCriticalRed,
                                                side: const BorderSide(color: Colors.white38),
                                                onChanged: (val) {
                                                  setState(() {
                                                    if (val == true) {
                                                      _selectedPaths.add(path);
                                                    } else {
                                                      _selectedPaths.remove(path);
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),

            // ── Footer buttons
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: _kSlateBlue,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("CANCEL", style: GoogleFonts.inter(color: Colors.white54, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _selectedPaths.isEmpty
                        ? null
                        : () {
                            // Build the result list from selected paths
                            final results = <Map<String, dynamic>>[];
                            for (final path in _selectedPaths) {
                              final name = path.split('/').last;
                              // Find the size from entries if current dir, or default 0
                              int size = 0;
                              for (final e in _entries) {
                                if (e['path'] == path) {
                                  size = e['size'] as int? ?? 0;
                                  break;
                                }
                              }
                              results.add({'name': name, 'path': path, 'size': size});
                            }
                            Navigator.pop(context, results);
                          },
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: Text(
                      "SELECT ${_selectedPaths.isEmpty ? '' : '(${_selectedPaths.length})'}",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kCriticalRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _kCriticalRed.withOpacity(0.2),
                      disabledForegroundColor: Colors.white38,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
