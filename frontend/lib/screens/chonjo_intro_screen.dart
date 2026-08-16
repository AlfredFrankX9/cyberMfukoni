import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/translations.dart';
import 'chonjo_levels_screen.dart';

class ChonjoIntroScreen extends StatefulWidget {
  const ChonjoIntroScreen({super.key});

  @override
  State<ChonjoIntroScreen> createState() => _ChonjoIntroScreenState();
}

class _ChonjoIntroScreenState extends State<ChonjoIntroScreen>
    with SingleTickerProviderStateMixin {
  static const Color kGreen = Color(0xFF00FF55);
  static const Color kRed = Color(0xFFFF3B30);
  static const Color kGold = Color(0xFFFFB347);
  static const Color kAmber = Color(0xFFFF7A00);

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _startGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ChonjoLevelsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double avatarR = size.width * 0.22;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0810),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/chonjoBackground.webp',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.68)),
          ),
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kAmber.withOpacity(0.22), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    _buildMascot(avatarR),
                    const SizedBox(height: 12),

                    _glassChip(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kGreen,
                              boxShadow: [
                                BoxShadow(color: kGreen, blurRadius: 6),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('', fallback: 'AGENT STATUS  ·  STANDBY'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      context.tr('', fallback: 'Kaanga Chonjo!'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        shadows: [
                          Shadow(
                            color: kAmber.withOpacity(0.35),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      context.tr('', fallback: 'Identify digital threats targeting\nthe Kenyan cyberspace.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── LEGIT (left) / SCAM (right) ───────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildSwipeCard(
                            icon: Icons.undo_rounded,
                            color: kGreen,
                            label: context.tr('', fallback: 'LEGIT'),
                            sub: context.tr('', fallback: 'Swipe Left'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSwipeCard(
                            icon: Icons.redo_rounded,
                            color: kRed,
                            label: context.tr('', fallback: 'SCAM'),
                            sub: context.tr('', fallback: 'Swipe Right'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _glassMissionCard(),

                    // ── Extra breathing room before the button ─────────
                    const SizedBox(height: 28),

                    _buildStartButton(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascot(double r) {
    final double total = r * 2 + 28;
    return SizedBox(
      width: total,
      height: total,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(total, total), painter: _HaloRingPainter()),
          ClipOval(
            child: Container(
              width: r * 2,
              height: r * 2,
              color: Colors.black,
              child: Image.asset('assets/images/icon.png', fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeCard({
    required IconData icon,
    required Color color,
    required String label,
    required String sub,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.35), width: 1.2),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.12), blurRadius: 16),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassMissionCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
            boxShadow: [
              BoxShadow(
                color: kAmber.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kAmber.withOpacity(0.12),
                  border: Border.all(color: kAmber.withOpacity(0.3)),
                ),
                child: Icon(Icons.bolt, color: kGold, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('', fallback: 'YOUR MISSION'),
                      style: const TextStyle(
                        color: kGold,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('', fallback: 'Swipe each message — flag scams before they reach citizens.'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassChip({required Widget child, Color? glow}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (glow ?? Colors.white).withOpacity(0.14),
              width: 1,
            ),
            boxShadow: glow != null
                ? [BoxShadow(color: glow.withOpacity(0.15), blurRadius: 12)]
                : [],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _startGame,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00FF55), Color(0xFF00C944)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kGreen.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            context.tr('', fallback: 'START GAME'),
            style: const TextStyle(
              color: Color(0xFF001A09),
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _HaloRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 10;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Shader sweep = const SweepGradient(
      colors: [
        Color(0xFFFFFFCC),
        Color(0xFFFFD000),
        Color(0xFFFF8800),
        Color(0xFFCC5500),
        Color(0xFF772200),
        Color(0xFFAA4400),
        Color(0xFFFF8800),
        Color(0xFFFFCC00),
        Color(0xFFFFFFCC),
      ],
      stops: [0.0, 0.07, 0.20, 0.35, 0.50, 0.65, 0.78, 0.90, 1.0],
      transform: GradientRotation(-0.52),
    ).createShader(rect);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..shader = sweep,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..shader = sweep,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..shader = sweep,
    );

    const double flareAngle = -0.52;
    final Offset flare = Offset(
      center.dx + radius * math.cos(flareAngle),
      center.dy + radius * math.sin(flareAngle),
    );

    canvas.drawCircle(
      flare,
      14,
      Paint()
        ..color = const Color(0x55FFD000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      flare,
      7,
      Paint()
        ..color = const Color(0xAAFFEE44)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      flare,
      4,
      Paint()
        ..color = const Color(0xCCFFFFAA)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(flare, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
