import 'dart:ui';
import 'package:flutter/material.dart';
import 'guide_steps_screen.dart';
import '../utils/translations.dart';

class ProtectionGuidesScreen extends StatelessWidget {
  const ProtectionGuidesScreen({super.key});

  static List<Map<String, dynamic>> _getGuides(BuildContext context) => [
    {
      'title': context.tr('', fallback: 'SIM Swap Protection'),
      'titleKey': 'guide_sim_swap',
      'description': context.tr('', fallback: 'Learn how to protect yourself from SIM swap fraud'),
      'icon': Icons.sim_card_alert,
      'color': const Color(0xFFFF9100),
      'image': 'assets/images/simSwap.webp',
    },
    {
      'title': context.tr('', fallback: 'Social Media Safety'),
      'titleKey': 'guide_social',
      'description': context.tr('', fallback: 'Secure your social media accounts against hackers'),
      'icon': Icons.share,
      'color': const Color(0xFF00E5FF),
      'image': 'assets/images/socialMedia.webp',
    },
    {
      'title': context.tr('', fallback: 'Banking Security'),
      'titleKey': 'guide_banking',
      'description': context.tr('', fallback: 'Best practices for mobile & online banking'),
      'icon': Icons.account_balance,
      'color': const Color(0xFF00FF40),
      'image': 'assets/images/banking.webp',
    },
    {
      'title': context.tr('', fallback: 'Identity Theft Guard'),
      'titleKey': 'guide_identity',
      'description': context.tr('', fallback: 'Steps to prevent and respond to identity theft'),
      'icon': Icons.badge,
      'color': const Color(0xFFAA00FF),
      'image': 'assets/images/identityGuard.webp',
    },
    {
      'title': context.tr('', fallback: 'Password Health'),
      'titleKey': 'guide_password',
      'description': context.tr('', fallback: 'Check and improve your password strength'),
      'icon': Icons.key,
      'color': const Color(0xFFFFD600),
      'image': 'assets/images/password.webp',
    },
    {
      'title': context.tr('', fallback: 'Wi-Fi Security'),
      'titleKey': 'guide_wifi',
      'description': context.tr('', fallback: 'Stay safe on public and home networks'),
      'icon': Icons.wifi_lock,
      'color': const Color(0xFFFF1744),
      'image': 'assets/images/wifi.webp',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('guide_title'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: _buildGuidesGrid(context),
        ),
      ),
    );
  }

  Widget _buildGuidesGrid(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final bool isWide = screenW > 800;

    if (!isWide) {
      // Mobile layout
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemCount: _getGuides(context).length,
        itemBuilder: (context, index) {
          final guide = _getGuides(context)[index];
          final color = guide['color'] as Color;
          final image = guide['image'] as String?;
          
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 600 + (index * 100)),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.05), blurRadius: 20),
                ],
                image: image != null ? DecorationImage(
                  image: AssetImage(image),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final steps = allGuideSteps[guide['titleKey']];
                      if (steps != null && steps.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GuideStepsScreen(
                              guideTitle: context.tr(guide['titleKey'] as String),
                              accentColor: color,
                              steps: steps,
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF0A0A0A).withOpacity(0.95),
                            const Color(0xFF0A0A0A).withOpacity(0.5),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)],
                            ),
                            child: Icon(guide['icon'] as IconData, size: 20, color: color),
                          ),
                          const Spacer(),
                          Text(
                            guide['title'] as String,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            guide['description'] as String,
                            style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6), height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    // Desktop layout
    final double cardSize = (screenW / 4).clamp(150.0, 400.0);

    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(_getGuides(context).length, (index) {
          final guide = _getGuides(context)[index];
          final color = guide['color'] as Color;
          final image = guide['image'] as String?;
          
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 600 + (index * 100)),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: cardSize,
              height: cardSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.1), blurRadius: 20),
                ],
                image: image != null ? DecorationImage(
                  image: AssetImage(image),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final steps = allGuideSteps[guide['titleKey']];
                      if (steps != null && steps.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GuideStepsScreen(
                              guideTitle: context.tr(guide['titleKey'] as String),
                              accentColor: color,
                              steps: steps,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0xFF1A1A22).withOpacity(0.95), // Translucent grey
                            const Color(0xFF1A1A22).withOpacity(0.7),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.55,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)],
                              ),
                              child: Icon(guide['icon'] as IconData, size: 54, color: color),
                            ),
                            const Spacer(),
                            Text(
                              guide['title'] as String,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              guide['description'] as String,
                              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), height: 1.3),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
