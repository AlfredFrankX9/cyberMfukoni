import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/translations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class DarkWebScreen extends StatefulWidget {
  const DarkWebScreen({super.key});

  @override
  State<DarkWebScreen> createState() => _DarkWebScreenState();
}

class _DarkWebScreenState extends State<DarkWebScreen> {
  String _selectedType = 'Password';
  final TextEditingController _queryController = TextEditingController();
  bool _isScanning = false;
  bool _hasResults = false;
  int _pwnedCount = 0; // Number of times breached

  Future<void> _runScan() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    if (_selectedType != 'Password') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('dark_web_type_${_selectedType.toLowerCase().replaceAll(' ', '_')}')} ${context.tr('dark_web_coming_soon')}')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _hasResults = false;
      _pwnedCount = 0;
    });

    try {
      // Secure HIBP implementation: hash password with SHA-1
      final bytes = utf8.encode(query);
      final digest = sha1.convert(bytes);
      final hashStr = digest.toString().toUpperCase();

      final prefix = hashStr.substring(0, 5);
      final suffix = hashStr.substring(5);

      final url = Uri.parse('https://api.pwnedpasswords.com/range/$prefix');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final lines = response.body.split('\r\n');
        for (var line in lines) {
          if (line.startsWith(suffix)) {
            final parts = line.split(':');
            if (parts.length == 2) {
              _pwnedCount = int.parse(parts[1]);
              break;
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('dark_web_error_api')} $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _hasResults = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        // Matches VaultScreen's AppBar (title row + 60px tab bar) exactly —
        // see the same formula in vault_screen.dart's _contentTopPadding.
        // Kept in sync manually since this screen has no reference to
        // VaultScreen's State; if that AppBar's dimensions ever change,
        // update all three vault tab screens together.
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 60.0 + 16.0,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScannerInput(),
          const SizedBox(height: 24),
          if (_isScanning)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(color: Color(0xFFFF8C42)),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('dark_web_scanning'),
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          else if (_hasResults)
            _buildResults(),
        ],
      ),
    );
  }

  Widget _buildScannerInput() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8C42).withOpacity(0.05),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C42).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF8C42).withOpacity(0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.radar,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('dark_web_scanner'),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        dropdownColor: const Color(0xFF6B3A4C),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedType = newValue!;
                          });
                        },
                        items:
                            <String>[
                              'Password',
                              'Email',
                              'Phone',
                              'National ID',
                              'Passport',
                              'Username',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(context.tr('dark_web_type_${value.toLowerCase().replaceAll(' ', '_')}')),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        controller: _queryController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: '${context.tr('dark_web_enter')} ${context.tr('dark_web_type_${_selectedType.toLowerCase().replaceAll(' ', '_')}')}...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _runScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.tr('dark_web_initiate'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_pwnedCount == 0) {
      // Safe result
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user, color: Color(0xFF00FF9D)),
              const SizedBox(width: 8),
              Text(
                context.tr('dark_web_no_breaches'),
                style: GoogleFonts.inter(
                  color: const Color(0xFF00FF9D),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  context.tr('dark_web_safe_msg'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Pwned result
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5722)),
            const SizedBox(width: 8),
            Text(
              context.tr('dark_web_compromised'),
              style: GoogleFonts.inter(
                color: const Color(0xFFFF5722),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResultRow(context.tr('dark_web_source'), context.tr('dark_web_hibp')),
                  const SizedBox(height: 12),
                  _buildResultRow(context.tr('dark_web_pwned_count'), '$_pwnedCount ${context.tr('dark_web_times')}'),
                  const SizedBox(height: 12),
                  _buildResultRow(context.tr('dark_web_data_exposed'), context.tr('dark_web_hashed_passwords')),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        context.tr('dark_web_risk_score'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 1.0,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            color: const Color(0xFFFF5722),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '10/10',
                        style: TextStyle(
                          color: Color(0xFFFF5722),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.smart_toy,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('dark_web_ai_threat'),
                        style: GoogleFonts.spaceMono(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${context.tr('dark_web_breach_msg_1')} $_pwnedCount ${context.tr('dark_web_breach_msg_2')}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('dark_web_recommended'),
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        _buildActionRow(
          Icons.password,
          context.tr('dark_web_change_password'),
          context.tr('dark_web_change_password_desc'),
        ),
        const SizedBox(height: 8),
        _buildActionRow(
          Icons.security,
          context.tr('dark_web_enable_2fa'),
          context.tr('dark_web_enable_2fa_desc'),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
        ],
      ),
    );
  }
}
