import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/vault_storage_service.dart';

class PasswordsScreen extends StatefulWidget {
  const PasswordsScreen({super.key});

  @override
  State<PasswordsScreen> createState() => _PasswordsScreenState();
}

class _PasswordsScreenState extends State<PasswordsScreen> {
  List<Map<String, dynamic>> _passwords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _passwords = await VaultStorageService.getPasswords();
    setState(() => _isLoading = false);
  }

  void _showAddDialog() {
    final websiteController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1B2E).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.password, color: Color(0xFFFFB380)),
                          const SizedBox(width: 12),
                          Text('Add Password', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(websiteController, 'Website / App Name', Icons.language),
                      const SizedBox(height: 16),
                      _buildTextField(usernameController, 'Username / Email', Icons.person),
                      const SizedBox(height: 16),
                      _buildTextField(passwordController, 'Password', Icons.lock, obscure: true),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB380),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            if (websiteController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                              await VaultStorageService.addPassword({
                                'website': websiteController.text.trim(),
                                'username': usernameController.text.trim(),
                                'password': passwordController.text.trim(),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadData();
                            }
                          },
                          child: Text('SAVE', style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A1B2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Passwords', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFB380)))
          : _passwords.isEmpty
              ? const Center(child: Text('No passwords saved yet.', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _passwords.length,
                  itemBuilder: (context, index) {
                    final item = _passwords[index];
                    return _PasswordTile(
                      item: item,
                      onDelete: () async {
                        await VaultStorageService.deletePassword(item['id']);
                        _loadData();
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFB380),
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _PasswordTile extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const _PasswordTile({required this.item, required this.onDelete});

  @override
  State<_PasswordTile> createState() => _PasswordTileState();
}

class _PasswordTileState extends State<_PasswordTile> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFB380).withOpacity(0.2),
          child: Text(
            (widget.item['website'] as String).isNotEmpty ? (widget.item['website'] as String)[0].toUpperCase() : '?',
            style: const TextStyle(color: Color(0xFFFFB380), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(widget.item['website'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((widget.item['username'] ?? '').isNotEmpty)
              Text(widget.item['username'], style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isVisible ? widget.item['password'] : '••••••••••••',
                    style: TextStyle(
                      color: _isVisible ? Colors.white : Colors.white.withOpacity(0.4),
                      letterSpacing: _isVisible ? 0 : 2,
                      fontFamily: _isVisible ? null : 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                  onPressed: () => setState(() => _isVisible = !_isVisible),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
