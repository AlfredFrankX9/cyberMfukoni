import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/vault_storage_service.dart';
import '../../utils/translations.dart';

class CreditCardsScreen extends StatefulWidget {
  const CreditCardsScreen({super.key});

  @override
  State<CreditCardsScreen> createState() => _CreditCardsScreenState();
}

class _CreditCardsScreenState extends State<CreditCardsScreen> {
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _cards = await VaultStorageService.getCards();
    setState(() => _isLoading = false);
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();

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
                          const Icon(Icons.credit_card, color: Color(0xFFFFB380)),
                          const SizedBox(width: 12),
                          Text(context.tr('vault_add_card'), style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(nameController, context.tr('vault_cardholder'), Icons.person),
                      const SizedBox(height: 16),
                      _buildTextField(numberController, context.tr('vault_card_number'), Icons.numbers, type: TextInputType.number),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(expiryController, 'MM/YY', Icons.date_range)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(cvvController, 'CVV', Icons.lock, obscure: true, type: TextInputType.number)),
                        ],
                      ),
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
                            if (numberController.text.isNotEmpty) {
                              await VaultStorageService.addCard({
                                'name': nameController.text.trim(),
                                'number': numberController.text.trim(),
                                'expiry': expiryController.text.trim(),
                                'cvv': cvvController.text.trim(),
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

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscure = false, TextInputType type = TextInputType.text}) {
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
        keyboardType: type,
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
        title: Text(context.tr('vault_credit_cards'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFB380)))
          : _cards.isEmpty
              ? Center(child: Text(context.tr('vault_no_cards'), style: const TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final item = _cards[index];
                    return _CardTile(
                      item: item,
                      onDelete: () async {
                        await VaultStorageService.deleteCard(item['id']);
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

class _CardTile extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const _CardTile({required this.item, required this.onDelete});

  @override
  State<_CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<_CardTile> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final number = widget.item['number'] as String;
    final last4 = number.length > 4 ? number.substring(number.length - 4) : number;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF8C42).withOpacity(0.8),
            const Color(0xFFB85E5A).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF8C42).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.credit_card, color: Colors.white, size: 28),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                    onPressed: () => setState(() => _isVisible = !_isVisible),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white70),
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _isVisible ? number : '•••• •••• •••• $last4',
            style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('vault_cardholder_label'), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                  const SizedBox(height: 4),
                  Text((widget.item['name'] ?? '').toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(context.tr('vault_expires_label'), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                  const SizedBox(height: 4),
                  Text(widget.item['expiry'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
          if (_isVisible && (widget.item['cvv'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('CVV: ${widget.item['cvv']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]
        ],
      ),
    );
  }
}
