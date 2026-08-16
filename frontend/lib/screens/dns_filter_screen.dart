import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/translations.dart';

const Color _kDeepBlack = Color(0xFF000000);
const Color _kSlateBlue = Color(0xFF222633);
const Color _kNeonGreen = Color(0xFF00FF40);
const Color _kCriticalRed = Color(0xFFFF1744);

class DnsFilterScreen extends StatefulWidget {
  const DnsFilterScreen({super.key});

  @override
  State<DnsFilterScreen> createState() => _DnsFilterScreenState();
}

class _DnsFilterScreenState extends State<DnsFilterScreen> {
  static const platform = MethodChannel('com.example.frontend/vpn');
  
  bool _isVpnRunning = false;
  int _blockedCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkVpnStatus();
    // Poll for blocked count
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isVpnRunning) _checkVpnStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVpnStatus() async {
    try {
      final bool isRunning = await platform.invokeMethod('isVpnRunning');
      final int count = await platform.invokeMethod('getBlockedCount');
      setState(() {
        _isVpnRunning = isRunning;
        _blockedCount = count;
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to get VPN status: '${e.message}'.");
    }
  }

  Future<void> _toggleVpn() async {
    try {
      if (_isVpnRunning) {
        await platform.invokeMethod('stopVpn');
      } else {
        await platform.invokeMethod('startVpn');
      }
      // Wait a moment for native side to update state
      await Future.delayed(const Duration(milliseconds: 500));
      _checkVpnStatus();
    } on PlatformException catch (e) {
      debugPrint("Failed to toggle VPN: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDeepBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr('dns_title'),
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kSlateBlue.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isVpnRunning ? _kNeonGreen.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isVpnRunning ? Icons.shield : Icons.shield_outlined,
                    size: 80,
                    color: _isVpnRunning ? _kNeonGreen : Colors.white38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isVpnRunning ? context.tr('dns_active') : context.tr('dns_disabled'),
                    style: GoogleFonts.inter(
                      color: _isVpnRunning ? _kNeonGreen : Colors.white54,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('dns_desc'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: Text(
                      context.tr('dns_enable'),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: _isVpnRunning,
                    onChanged: (val) => _toggleVpn(),
                    activeColor: _kNeonGreen,
                    tileColor: _kDeepBlack.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kSlateBlue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('dns_blocked'),
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$_blockedCount",
                          style: GoogleFonts.inter(
                            color: _kNeonGreen,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kSlateBlue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('dns_active_filters'),
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "4",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Categories
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr('dns_categories'),
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryTile(Icons.bug_report, context.tr('dns_malware'), context.tr('dns_malware_desc'), true),
            _buildCategoryTile(Icons.phishing, context.tr('dns_phishing'), context.tr('dns_phishing_desc'), true),
            _buildCategoryTile(Icons.track_changes, context.tr('dns_trackers'), context.tr('dns_trackers_desc'), true),
            _buildCategoryTile(Icons.ads_click, context.tr('dns_ads'), context.tr('dns_ads_desc'), true),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(IconData icon, String title, String subtitle, bool enabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSlateBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: _isVpnRunning ? _kNeonGreen : Colors.white38, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: _isVpnRunning ? (val) {} : null, // Mock functionality for individual toggles
            activeColor: _kNeonGreen,
          ),
        ],
      ),
    );
  }
}
