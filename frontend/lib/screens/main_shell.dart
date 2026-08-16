import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/dock_nav_bar.dart';
import 'dashboard_screen.dart';
import 'boma_screen.dart';
import 'vault_screen.dart';
import 'mulika_screen.dart';
import 'intel_feed_screen.dart';
import 'agent_screen.dart';
import 'smart_scan_screen.dart';
import 'secure_modules_screen.dart';
import 'planner_screen.dart';
import 'secure_shredder_screen.dart';
// ChonjoLevelsScreen is no longer a shell tab — the dock pushes
// ChonjoIntroScreen → ChonjoLevelsScreen via Navigator directly.

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 3});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  static const MethodChannel _tileChannel = MethodChannel('com.example.frontend/tiles');

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _setupTileListener();
  }

  void _setupTileListener() {
    _tileChannel.setMethodCallHandler((call) async {
      if (call.method == 'onTileAction') {
        _handleTileAction(call.arguments as String?);
      }
    });
    // Check if there's a pending action from cold start
    _tileChannel.invokeMethod('getPendingTileAction').then((action) {
      if (action != null) {
        _handleTileAction(action as String);
      }
    });
  }

  void _handleTileAction(String? action) {
    if (action == null) return;
    switch (action) {
      case 'vault':
        _onDockTap(0);
        break;
      case 'scan':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SmartScanScreen()));
        break;
      case 'shred':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecureShredderScreen()));
        break;
    }
  }

  void _onDockTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Main content layer — Chonjo (index 6) is no longer here;
          // it lives on its own Navigator stack pushed by the dock.
          IndexedStack(
            index: _currentIndex,
            children: [
              const VaultScreen(), // 0: Vault
              const SecureModulesScreen(), // 1: Secure Modules (was Boma)
              MulikaScreen(onNavigate: _onDockTap), // 2: Mulika
              DashboardScreen(onNavigate: _onDockTap), // 3: Home
              const IntelFeedScreen(), // 4: Intel Feed
              const AgentScreen(), // 5: Cyber Agent
              const SizedBox.shrink(), // 6: placeholder (Chonjo uses Navigator.push)
              const BomaScreen(), // 7: Boma
              const PlannerScreen(), // 8: Planner
            ],
          ),

          // Semi-transparent dock shelf behind the menu button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.width < 480 ? 65.0 : 90.0,
            child: IgnorePointer(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                          Colors.black.withOpacity(0.72),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating dock nav bar
          DockNavBar(currentIndex: _currentIndex, onTap: _onDockTap),
        ],
      ),
    );
  }
}
