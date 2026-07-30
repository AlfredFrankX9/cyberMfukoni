import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'vault/dark_web_screen.dart';
import 'vault/secure_vault_screen.dart';
import '../services/active_defense_service.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Fortress Analyzer State
  final TextEditingController _passwordController = TextEditingController();
  int _entropyLevel = 0;
  String _statusMessage = 'System Idle.';
  String _terminalBody = 'Brute forcer Deployed, Waiting for Input';

  // Dynamic color helper based on score (0-4)
  Color _getEntropyColor() {
    switch (_entropyLevel) {
      case 0:
        return Colors.grey;
      case 1:
        return const Color(0xFFEF5350); // Red
      case 2:
        return const Color(0xFFFF9800); // Amber
      case 3:
        return const Color(0xFFFF9800); // Amber
      case 4:
        return const Color(0xFF00FF9D); // Neon Green
      default:
        return Colors.grey;
    }
  }

  // ── Real AppBar height, computed instead of guessed ────────────────────
  // With extendBodyBehindAppBar: true, the body starts at y=0 and slides
  // underneath the AppBar, so any scrollable content needs top padding that
  // exactly matches: status bar + toolbar (title row) + the 60px tab-bar
  // `bottom` widget. A hardcoded number (e.g. 120) drifts from device to
  // device as the status bar height changes, which is why content was
  // peeking out from behind the tab bar on some screens.
  double _contentTopPadding(BuildContext context) {
    const double breathingRoom = 16.0; // small gap so content isn't flush
    return MediaQuery.of(context).padding.top + breathingRoom;
  }

  void _analyzePassword(String val) {
    if (val.isEmpty) {
      setState(() {
        _entropyLevel = 0;
        _statusMessage = 'System Idle.';
        _terminalBody = 'Brute forcer Deployed, Waiting for Input';
      });
      return;
    }

    int score = 0;
    if (val.length >= 8) score++;
    if (val.contains(RegExp(r'[A-Z]'))) score++;
    if (val.contains(RegExp(r'[0-9]'))) score++;
    if (val.contains(RegExp(r'[!@#\$%\^\&\*\(\)_\+\-=\[\]\{\};:"\\|,.<>/?]')))
      score++;

    setState(() {
      _entropyLevel = score;
      _statusMessage = 'Calculating...';

      if (score <= 1) {
        _terminalBody =
            '> ANALYZING ENTROPY...\n> WEAK DEFENSES DETECTED\n> VULNERABILITY HIGH';
        _statusMessage = 'Compromised';
      } else if (score == 2 || score == 3) {
        _terminalBody =
            '> ANALYZING ENTROPY...\n> MODERATE DEFENSES\n> PROCEED WITH CAUTION';
        _statusMessage = 'Stable';
      } else {
        _terminalBody =
            '> ANALYZING ENTROPY...\n> MAXIMUM DEFENSES DETECTED\n> IMPENETRABLE';
        _statusMessage = 'Secure';
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        title: Text(
          'VAULT',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: const Color(0xFFFF8C42).withOpacity(0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8C42).withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF8C42).withOpacity(0.4),
                        const Color(0xFFFF8C42).withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFF8C42).withOpacity(0.5),
                    ),
                  ),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  tabs: const [
                    Tab(text: 'DEFENSE'),
                    Tab(text: 'DARK WEB'),
                    Tab(text: 'SECURE'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Sunset Sky Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2A1B2E), // Deep dusk purple
                  Color(0xFF6B3A4C), // Sunset pink
                  Color(0xFFB85E5A), // Warm coral
                  Color(0xFFFF8C42), // Bright peach
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Additional soft orb for lighting
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: -100,
            right: -100,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          TabBarView(
            controller: _tabController,
            children: [
              _buildActiveDefenseTab(),
              const DarkWebScreen(),
              const SecureVaultScreen(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDefenseTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: _contentTopPadding(context),
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE DEFENSE',
            style: GoogleFonts.inter(
              color: const Color(0xFFFF8C42),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verify suspicious numbers or report threats to alert other agents.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'CHECK',
                  subtitle: 'Verify Number',
                  icon: Icons.public,
                  baseColor: const Color(0xFFFFB380),
                  imagePath: 'assets/images/check.webp',
                  onTap: () => _showCheckPopup(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'REPORT',
                  subtitle: 'Flag Threat',
                  icon: Icons.campaign_rounded,
                  baseColor: const Color(0xFFFF8C42),
                  imagePath: 'assets/images/report.webp',
                  onTap: () => _showReportPopup(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFortressAnalyzerSection(),
        ],
      ),
    );
  }

  // ─── CHECK POPUP ───────────────────────────────────────
  void _showCheckPopup() {
    final checkController = TextEditingController();
    bool isLoading = false;
    Map<String, dynamic>? result;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setPopupState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 40,
              ),
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
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8C42).withOpacity(0.1),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB380).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search,
                                color: Color(0xFFFFB380),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Check Number',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white38,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter a phone number to check if it has been reported for scams.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Input
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: TextField(
                            controller: checkController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              icon: Icon(
                                Icons.phone,
                                color: Colors.white.withOpacity(0.4),
                                size: 20,
                              ),
                              hintText: 'e.g. 0712345678',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final phone = checkController.text.trim();
                                    if (phone.isEmpty) return;
                                    setPopupState(() {
                                      isLoading = true;
                                      result = null;
                                    });
                                    final res =
                                        await ActiveDefenseService.checkNumber(
                                          phone,
                                        );
                                    setPopupState(() {
                                      isLoading = false;
                                      result = res;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB380),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'CHECK',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),

                        // Result
                        if (result != null) ...[
                          const SizedBox(height: 20),
                          _buildCheckResult(result!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCheckResult(Map<String, dynamic> result) {
    if (result['status'] == 'error') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result['message'] ?? 'Unknown error',
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final data = result['data'] as Map<String, dynamic>;
    final isSafe = data['is_safe'] as bool;

    if (isSafe) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF00FF9D).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00FF9D).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_user, color: Color(0xFF00FF9D), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SAFE',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00FF9D),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This number has not been reported.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF5350),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  '⚠ DANGER',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFEF5350),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildResultDetail('Scam Type', data['scam_category'] ?? 'Unknown'),
            const SizedBox(height: 6),
            _buildResultDetail(
              'Reports',
              '${data['report_count'] ?? 0} time(s)',
            ),
            if (data['last_reported'] != null) ...[
              const SizedBox(height: 6),
              _buildResultDetail('Last Reported', data['last_reported']),
            ],
          ],
        ),
      );
    }
  }

  Widget _buildResultDetail(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
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

  // ─── REPORT POPUP ──────────────────────────────────────
  void _showReportPopup() {
    final reportController = TextEditingController();
    final detailsController = TextEditingController();
    String selectedCategory = 'M-Pesa Fraud';
    bool isLoading = false;
    bool isSubmitted = false;

    final categories = [
      'M-Pesa Fraud',
      'SMS Phishing',
      'Impersonation',
      'Fake Promotions',
      'Bank Fraud',
      'Romance Scam',
      'Investment Scam',
      'Other',
    ];

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setPopupState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 40,
              ),
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
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8C42).withOpacity(0.1),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF8C42,
                                  ).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.campaign_rounded,
                                  color: Color(0xFFFF8C42),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Report Number',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Report a fraudulent number to protect others.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (isSubmitted) ...[
                            // Success state
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00FF9D).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFF00FF9D,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF00FF9D),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Report Submitted',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF00FF9D),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Thank you for helping protect the community. This number has been flagged in the database.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.1,
                                  ),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'CLOSE',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // Phone Input
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: TextField(
                                controller: reportController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  icon: Icon(
                                    Icons.phone,
                                    color: Colors.white.withOpacity(0.4),
                                    size: 20,
                                  ),
                                  hintText: 'Phone number',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Category Selector
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Scam Category',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: categories.map((cat) {
                                final isSelected = cat == selectedCategory;
                                return GestureDetector(
                                  onTap: () => setPopupState(
                                    () => selectedCategory = cat,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(
                                              0xFFFF8C42,
                                            ).withOpacity(0.3)
                                          : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFFF8C42)
                                            : Colors.white.withOpacity(0.15),
                                      ),
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFFFF8C42)
                                            : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // Details Input
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: TextField(
                                controller: detailsController,
                                maxLines: 3,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Additional details (optional)...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        final phone = reportController.text
                                            .trim();
                                        if (phone.isEmpty) return;
                                        setPopupState(() => isLoading = true);
                                        await ActiveDefenseService.reportNumber(
                                          phoneNumber: phone,
                                          scamCategory: selectedCategory,
                                          details: detailsController.text
                                              .trim(),
                                        );
                                        setPopupState(() {
                                          isLoading = false;
                                          isSubmitted = true;
                                        });
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8C42),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'REPORT',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFortressAnalyzerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.shield_outlined, color: Color(0xFFFF8C42), size: 48),
        const SizedBox(height: 12),
        Text(
          'Fortress Analyzer',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Test your password strength against brute-force attacks.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: TextField(
            controller: _passwordController,
            onChanged: _analyzePassword,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              icon: const Icon(
                Icons.vpn_key_rounded,
                color: Color(0xFFFF8C42),
                size: 20,
              ),
              hintText: 'Enter password to test...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildTerminalConsole(),
      ],
    );
  }

  Widget _buildTerminalConsole() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8C42).withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.terminal, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Brute Forcer',
                    style: GoogleFonts.spaceMono(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getEntropyColor(),
                      shape: BoxShape.circle,
                      boxShadow: _entropyLevel > 0
                          ? [
                              BoxShadow(
                                color: _getEntropyColor().withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 12),

              // Terminal Body
              SizedBox(
                height: 100,
                child: Text(
                  _terminalBody,
                  style: GoogleFonts.spaceMono(
                    color: _getEntropyColor().withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Footer
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STATUS',
                            style: GoogleFonts.spaceMono(
                              color: Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _statusMessage,
                            style: GoogleFonts.spaceMono(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'LEVEL',
                          style: GoogleFonts.spaceMono(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_entropyLevel/4',
                          style: GoogleFonts.spaceMono(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color baseColor,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    baseColor.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: baseColor.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
