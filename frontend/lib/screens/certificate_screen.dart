import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_saver/file_saver.dart';
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

      final image = await boundary.toImage(pixelRatio: 2.0); // 2.0 is enough for a 1000x700 canvas (results in 2000x1400 image)
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Use file_saver to support Web, Desktop, and Mobile seamlessly
      final fileName = 'CyberMfukoni_Certificate_${widget.username.replaceAll(' ', '_')}';
      final filePath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: pngBytes,
        ext: 'png',
        mimeType: MimeType.png,
      );

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
                    'Certificate saved successfully!\n$filePath',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 12),
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
          // Certificate card wrapped in FittedBox to maintain aspect ratio and fit on screen
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.15),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: RepaintBoundary(
                      key: _certKey,
                      child: _buildCertificate(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Download button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
    // We use a fixed 1000x700 resolution. 
    // The FittedBox above will scale this down to fit the phone screen visually, 
    // but the RepaintBoundary will capture the full 1000x700 high-res image.
    return Container(
      width: 1000,
      height: 700,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF5),
      ),
      child: Stack(
        children: [
          // Certificate background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/cert_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if cert_bg.png is not yet placed
                return _buildFallbackCertBackground();
              },
            ),
          ),
          // Overlay text on the certificate
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // "THE GUARDIAN" branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.webp',
                        height: 80,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // "CERTIFICATE" heading
                  Text(
                    'CERTIFICATE',
                    style: GoogleFonts.cinzel(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF8B4513),
                      letterSpacing: 10,
                    ),
                  ),
                  Text(
                    'OF ACHIEVEMENT',
                    style: GoogleFonts.cinzel(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B4513).withOpacity(0.75),
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'THE FOLLOWING AWARD IS GIVEN TO',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // User's name in Old English style
                  Text(
                    widget.username,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.unifrakturMaguntia(
                      fontSize: 72,
                      color: const Color(0xFF1A1A2E),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Email
                  Text(
                    widget.email,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Description
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 120),
                    child: Text(
                      'In recognition of successfully completing the Chonjo Quiz\nin the Guardian Cybersecurity Training.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.grey[800],
                        height: 1.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Bottom row: XP and Date
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40, left: 100, right: 100),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${widget.totalXp} XP',
                              style: GoogleFonts.cinzel(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                            Container(
                              width: 140,
                              height: 2,
                              color: Colors.grey[500],
                              margin: const EdgeInsets.only(top: 8),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              widget.dateEarned,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                            Container(
                              width: 180,
                              height: 2,
                              color: Colors.grey[500],
                              margin: const EdgeInsets.only(top: 8),
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
      decoration: BoxDecoration(
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
          width: 5,
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
      ..color = const Color(0xFFDAA520).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Inner border
    final rect = Rect.fromLTWH(20, 20, size.width - 40, size.height - 40);
    canvas.drawRect(rect, paint);

    // Corner decorations
    final cornerPaint = Paint()
      ..color = const Color(0xFFDAA520).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    const cornerSize = 30.0;
    // Top-left
    canvas.drawCircle(const Offset(cornerSize, cornerSize), 6, cornerPaint);
    // Top-right
    canvas.drawCircle(Offset(size.width - cornerSize, cornerSize), 6, cornerPaint);
    // Bottom-left
    canvas.drawCircle(Offset(cornerSize, size.height - cornerSize), 6, cornerPaint);
    // Bottom-right
    canvas.drawCircle(
        Offset(size.width - cornerSize, size.height - cornerSize), 6, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
