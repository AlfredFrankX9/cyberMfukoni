import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CertificateScreen extends StatefulWidget {
  final String username;
  final String email;
  final int totalXp;
  final String dateEarned;

  const CertificateScreen({
    super.key,
    required this.username,
    required this.email,
    required this.totalXp,
    required this.dateEarned,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final GlobalKey _certKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _downloadCertificate() async {
    setState(() => _isSaving = true);
    try {
      // Capture the widget as an image
      final boundary = _certKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to Downloads/Pictures directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/CyberMfukoni_Certificate_${widget.username}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00E676),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Certificate saved to: $filePath',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to save certificate: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Your Certificate',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Certificate card
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RepaintBoundary(
                  key: _certKey,
                  child: _buildCertificate(),
                ),
              ),
            ),
          ),
          // Download button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _downloadCertificate,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 22),
                label: Text(
                  _isSaving ? 'Saving...' : 'Download Certificate',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFFFFD700).withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificate() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.25),
            blurRadius: 30,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Certificate background image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/cert_bg.png',
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if cert_bg.png is not yet placed
                return _buildFallbackCertBackground();
              },
            ),
          ),
          // Overlay text on the certificate
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // "THE GUARDIAN" branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.webp',
                        height: 60,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // "CERTIFICATE" heading
                  Text(
                    'CERTIFICATE',
                    style: GoogleFonts.cinzel(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8B4513),
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    'OF ACHIEVEMENT',
                    style: GoogleFonts.cinzel(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8B4513).withOpacity(0.7),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'THE FOLLOWING AWARD IS GIVEN TO',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // User's name in Old English style
                  Text(
                    widget.username,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.unifrakturMaguntia(
                      fontSize: 32,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    widget.email,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'In recognition of successfully completing the Chonjo Quiz\nin the Guardian Cybersecurity Training.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Bottom row: XP and Date
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${widget.totalXp} XP',
                              style: GoogleFonts.cinzel(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 1,
                              color: Colors.grey[400],
                              margin: const EdgeInsets.only(top: 4),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              widget.dateEarned,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                            Container(
                              width: 80,
                              height: 1,
                              color: Colors.grey[400],
                              margin: const EdgeInsets.only(top: 4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fallback certificate background if cert_bg.png is not placed yet.
  Widget _buildFallbackCertBackground() {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFDF5),
            Color(0xFFFFF8E7),
            Color(0xFFFFFDF5),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFDAA520),
          width: 3,
        ),
      ),
      child: CustomPaint(
        painter: _CertBorderPainter(),
      ),
    );
  }
}

class _CertBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDAA520).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Inner border
    final rect = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);

    // Corner decorations
    final cornerPaint = Paint()
      ..color = const Color(0xFFDAA520).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    const cornerSize = 20.0;
    // Top-left
    canvas.drawCircle(Offset(cornerSize, cornerSize), 4, cornerPaint);
    // Top-right
    canvas.drawCircle(Offset(size.width - cornerSize, cornerSize), 4, cornerPaint);
    // Bottom-left
    canvas.drawCircle(Offset(cornerSize, size.height - cornerSize), 4, cornerPaint);
    // Bottom-right
    canvas.drawCircle(
        Offset(size.width - cornerSize, size.height - cornerSize), 4, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
