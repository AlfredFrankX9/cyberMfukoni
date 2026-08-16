import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../services/vault_storage_service.dart';
import '../../utils/translations.dart';

class RecoveryCodesScreen extends StatefulWidget {
  const RecoveryCodesScreen({super.key});

  @override
  State<RecoveryCodesScreen> createState() => _RecoveryCodesScreenState();
}

class _RecoveryCodesScreenState extends State<RecoveryCodesScreen> {
  List<Map<String, dynamic>> _codes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _codes = await VaultStorageService.getRecoveryCodes();
    setState(() => _isLoading = false);
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

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
                          const Icon(Icons.vpn_key, color: Color(0xFFFFB380)),
                          const SizedBox(width: 12),
                          Text(context.tr('vault_add_code'), style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(nameController, context.tr('vault_app_website'), Icons.apps),
                      const SizedBox(height: 16),
                      _buildTextField(codeController, context.tr('vault_recovery_code'), Icons.numbers),
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
                            if (nameController.text.isNotEmpty && codeController.text.isNotEmpty) {
                              await VaultStorageService.addRecoveryCode({
                                'name': nameController.text.trim(),
                                'code': codeController.text.trim(),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadData();
                            }
                          },
                          child: Text(context.tr('vault_save'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
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

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: TextField(
        controller: controller,
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
        title: Text(context.tr('vault_recovery_codes'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFB380)))
          : _codes.isEmpty
               ? Center(child: Text(context.tr('vault_no_codes'), style: const TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _codes.length,
                  itemBuilder: (context, index) {
                    final item = _codes[index];
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
                          child: const Icon(Icons.vpn_key, color: Color(0xFFFFB380), size: 20),
                        ),
                        title: Text(item['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          item['code'] ?? '',
                          style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 13, letterSpacing: 1.5),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: item['code']));
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('vault_code_copied'))));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () async {
                                await VaultStorageService.deleteRecoveryCode(item['id']);
                                _loadData();
                              },
                            ),
                          ],
                        ),
                      ),
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
