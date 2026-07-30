class CustomFilePickerModal extends StatefulWidget {
  const CustomFilePickerModal({super.key});

  @override
  State<CustomFilePickerModal> createState() => _CustomFilePickerModalState();
}

class _CustomFilePickerModalState extends State<CustomFilePickerModal> {
  String _currentPath = '/storage/emulated/0';
  List<FileSystemEntity> _entities = [];
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  void _loadDirectory() {
    try {
      final dir = Directory(_currentPath);
      if (!dir.existsSync()) {
        setState(() => _entities = []);
        return;
      }
      var list = dir.listSync().where((e) {
        final name = e.path.split(Platform.pathSeparator).last;
        return name.isNotEmpty && !name.startsWith('.');
      }).toList();
      
      list.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return a.path.compareTo(b.path);
      });
      setState(() {
        _entities = list;
      });
    } catch (e) {
      setState(() => _entities = []);
    }
  }

  void _goUp() {
    if (_currentPath == '/storage/emulated/0' || _currentPath == '/') return;
    final parent = Directory(_currentPath).parent;
    setState(() {
      _currentPath = parent.path;
    });
    _loadDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF222633),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "GUARDIAN FILE EXPLORER",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, color: Color(0xFF00FF40)),
                  onPressed: _goUp,
                ),
                Expanded(
                  child: Text(
                    _currentPath,
                    style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: _entities.isEmpty
                  ? Center(
                      child: Text(
                        "No files found",
                        style: GoogleFonts.inter(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _entities.length,
                      itemBuilder: (context, index) {
                        final entity = _entities[index];
                        final isDir = entity is Directory;
                        final name = entity.path.split(Platform.pathSeparator).last;
                        final isSelected = _selected.contains(entity.path);

                        return ListTile(
                          leading: Icon(
                            isDir ? Icons.folder : Icons.insert_drive_file,
                            color: isDir ? const Color(0xFFFF9100) : const Color(0xFFB0B0B0),
                          ),
                          title: Text(
                            name,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                          ),
                          trailing: isDir
                              ? null
                              : Checkbox(
                                  value: isSelected,
                                  activeColor: const Color(0xFFFF1744),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selected.add(entity.path);
                                      } else {
                                        _selected.remove(entity.path);
                                      }
                                    });
                                  },
                                ),
                          onTap: () {
                            if (isDir) {
                              setState(() {
                                _currentPath = entity.path;
                              });
                              _loadDirectory();
                            } else {
                              setState(() {
                                if (isSelected) {
                                  _selected.remove(entity.path);
                                } else {
                                  _selected.add(entity.path);
                                }
                              });
                            }
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("CANCEL", style: GoogleFonts.inter(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _selected.toList());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1744),
                  ),
                  child: Text("SELECT (${_selected.length})", style: GoogleFonts.inter(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
