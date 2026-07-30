import 'dart:ui';
import 'package:flutter/material.dart';

import 'dns_filter_screen.dart';
import 'smart_scan_screen.dart';
import 'permission_auditor_screen.dart';
import 'secure_shredder_screen.dart';
import 'parental_controls_screen.dart';

class SecureModulesScreen extends StatelessWidget {
  const SecureModulesScreen({super.key});

  static final List<Map<String, dynamic>> modules = [
    {
      'title': 'DNS Filter',
      'description': 'Block malicious domains and trackers at the network level',
      'icon': Icons.security,
      'color': const Color(0xFF00FF40),
      'image': 'assets/images/dns.webp',
      'screen': const DnsFilterScreen(),
    },
    {
      'title': 'Smart Scan',
      'description': 'Scan your device and files for known threats',
      'icon': Icons.radar,
      'color': const Color(0xFF00E5FF),
      'image': 'assets/images/smart_scan.webp',
      'screen': const SmartScanScreen(),
    },
    {
      'title': 'App Permissions',
      'description': 'Audit and manage sensitive permissions granted to apps',
      'icon': Icons.privacy_tip,
      'color': const Color(0xFFFF9100),
      'image': 'assets/images/app_permission.webp',
      'screen': const PermissionAuditorScreen(),
    },
    {
      'title': 'Secure Shredder',
      'description': 'Permanently obliterate files beyond recovery',
      'icon': Icons.delete_forever,
      'color': const Color(0xFFFF1744),
      'image': 'assets/images/shredder.webp',
      'screen': const SecureShredderScreen(),
    },
    {
      'title': 'Parental Controls',
      'description': 'Block inappropriate websites and restrict app access',
      'icon': Icons.family_restroom,
      'color': const Color(0xFF9C27B0),
      'image': 'assets/images/secure.webp',
      'screen': const ParentalControlsScreen(),
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
        title: const Text(
          'Secure Modules',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: _buildModulesGrid(context),
        ),
      ),
    );
  }

  Widget _buildModulesGrid(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final bool isWide = screenW > 800;

    if (!isWide) {
      // Mobile layout
      final double paddingTotal = 32.0; // 16 * 2 horizontal padding
      final double spacing = 16.0;
      final double cardW = (screenW - paddingTotal - spacing) / 2;
      final double cardH = cardW / 0.9;

      return Wrap(
        alignment: WrapAlignment.center,
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(modules.length, (index) {
          final module = modules[index];
          final color = module['color'] as Color;
          final image = module['image'] as String?;
          
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 100)),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: cardW,
              height: cardH,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => module['screen'] as Widget,
                        ),
                      );
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
                            child: Icon(module['icon'] as IconData, size: 20, color: color),
                          ),
                          const Spacer(),
                          Text(
                            module['title'] as String,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            module['description'] as String,
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
        }),
      );
    }

    // Desktop layout
    final double cardSize = (screenW / 4).clamp(150.0, 400.0);

    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(modules.length, (index) {
          final module = modules[index];
          final color = module['color'] as Color;
          final image = module['image'] as String?;
          
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => module['screen'] as Widget,
                        ),
                      );
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
                              child: Icon(module['icon'] as IconData, size: 54, color: color),
                            ),
                            const Spacer(),
                            Text(
                              module['title'] as String,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              module['description'] as String,
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
