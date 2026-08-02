import 'dart:ui';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:app_settings/app_settings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'protection_guides_screen.dart';
import 'permission_auditor_screen.dart';
import 'package:installed_apps/installed_apps.dart';

class BomaScreen extends StatefulWidget {
  const BomaScreen({super.key});

  @override
  State<BomaScreen> createState() => _BomaScreenState();
}

class _BomaScreenState extends State<BomaScreen> with TickerProviderStateMixin {
  int _overallScore = 0;
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isCheckingDevice = true;

  // Each item has:
  //   'autoDetect': true  → value is read from the device
  //   'autoDetect': false → user self-reports
  //   'actionType'        → the type of action to perform when tapped
  final List<Map<String, dynamic>> _securityChecklist = [
    {
      'title': 'Screen Lock Enabled',
      'subtitle': 'Use PIN, fingerprint, or face unlock',
      'icon': Icons.lock,
      'completed': false,
      'category': 'Device',
      'autoDetect': true,
      'actionType': 'settings',
      'actionData': 'lockAndPassword',
    },
    {
      'title': 'Biometric Authentication',
      'subtitle': 'Fingerprint or face recognition set up',
      'icon': Icons.fingerprint,
      'completed': false,
      'category': 'Device',
      'autoDetect': true,
      'actionType': 'settings',
      'actionData': 'security',
    },
    {
      'title': 'Two-Factor Authentication',
      'subtitle': 'Enable 2FA on all important accounts',
      'icon': Icons.verified_user,
      'completed': false,
      'category': 'Account',
      'autoDetect': false,
      'actionType': 'url',
      'actionData': 'https://myaccount.google.com/security',
    },
    {
      'title': 'M-Pesa PIN Security',
      'subtitle': 'Change your M-Pesa PIN regularly',
      'icon': Icons.phone_android,
      'completed': false,
      'category': 'Banking',
      'autoDetect': false,
      'actionType': 'stk',
    },
    {
      'title': 'App Permissions Review',
      'subtitle': 'Check which apps have access to your data',
      'icon': Icons.apps,
      'completed': false,
      'category': 'Privacy',
      'autoDetect': false,
      'actionType': 'permission_manager',
    },
    {
      'title': 'Password Manager',
      'subtitle': 'Use unique passwords for each account',
      'icon': Icons.password,
      'completed': false,
      'category': 'Account',
      'autoDetect': false,
      'actionType': 'url',
      'actionData': 'https://passwords.google.com/',
    },
    {
      'title': 'Software Updates',
      'subtitle': 'Keep your OS and apps up to date',
      'icon': Icons.system_update,
      'completed': false,
      'category': 'Device',
      'autoDetect': false,
      'actionType': 'playstore',
    },
    {
      'title': 'SIM PIN Lock',
      'subtitle': 'Protect against SIM swap attacks',
      'icon': Icons.sim_card,
      'completed': false,
      'category': 'Banking',
      'autoDetect': false,
      'actionType': 'settings',
      'actionData': 'android.settings.SECURITY_SETTINGS',
    },
    {
      'title': 'Social Media Privacy',
      'subtitle': 'Review and restrict public profile info',
      'icon': Icons.people,
      'completed': false,
      'category': 'Privacy',
      'autoDetect': false,
      'actionType': 'social',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic),
    );
    _checkDeviceSecurity();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _checkDeviceSecurity() async {
    final bool isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (!isMobile) {
      setState(() {
        _isCheckingDevice = false;
        _recalculateScore();
      });
      return;
    }

    try {
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();
      final bool hasBiometrics = availableBiometrics.isNotEmpty;

      setState(() {
        for (var item in _securityChecklist) {
          if (item['title'] == 'Screen Lock Enabled') {
            item['completed'] = isDeviceSupported;
          }
          if (item['title'] == 'Biometric Authentication') {
            item['completed'] = hasBiometrics;
          }
        }
        _isCheckingDevice = false;
        _recalculateScore();
      });
    } catch (e) {
      debugPrint('Device security check failed: $e');
      setState(() {
        _isCheckingDevice = false;
        _recalculateScore();
      });
    }
  }

  void _recalculateScore() {
    final completed =
        _securityChecklist.where((item) => item['completed'] == true).length;
    final newScore =
        ((completed / _securityChecklist.length) * 100).round();

    _scoreAnimation = Tween<double>(
      begin: _overallScore.toDouble(),
      end: newScore.toDouble(),
    ).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic),
    );
    _overallScore = newScore;
    _scoreController.forward(from: 0);
  }

  void _handleItemTap(int index) {
    final item = _securityChecklist[index];

    // Auto-detected items open settings directly if incomplete
    if (item['autoDetect'] == true) {
      if (!item['completed']) {
        _openSettings(item['actionData'] as String?);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ This setting is already enabled on your device'),
            backgroundColor: const Color(0xFF00FF40).withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    // Manual items show the action bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E212B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _buildActionBottomSheet(ctx, index),
    );
  }

  Widget _buildActionBottomSheet(BuildContext ctx, int index) {
    final item = _securityChecklist[index];
    final bool isCompleted = item['completed'] == true;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Icon(item['icon'], size: 40, color: const Color(0xFF00FF40)),
          const SizedBox(height: 12),
          Text(item['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(item['subtitle'], style: TextStyle(color: Colors.white.withOpacity(0.7)), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (item['actionType'] != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.launch, size: 18),
                label: const Text('Launch & Configure'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF40).withOpacity(0.15),
                  foregroundColor: const Color(0xFF00FF40),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: const Color(0xFF00FF40).withOpacity(0.3))
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _performAction(item);
                },
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(isCompleted ? Icons.close : Icons.check, size: 18),
              label: Text(isCompleted ? 'Mark as Incomplete' : 'Mark as Completed'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  item['completed'] = !item['completed'];
                  _recalculateScore();
                });
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _performAction(Map<String, dynamic> item) async {
    final actionType = item['actionType'];
    final actionData = item['actionData'];

    if (actionType == 'url') {
      final uri = Uri.parse(actionData);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link.')));
      }
    } else if (actionType == 'stk') {
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final bool success = await InstalledApps.startApp('com.android.stk') ?? false;
          if (!success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SIM Toolkit app not found.')));
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SIM Toolkit app not found.')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not supported on this device.')));
      }
    } else if (actionType == 'playstore') {
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final bool success = await InstalledApps.startApp('com.android.vending') ?? false;
          if (!success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Play Store app not found.')));
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Play Store app not found.')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not supported on this device.')));
      }
    } else if (actionType == 'permission_manager') {
       Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionAuditorScreen()));
    } else if (actionType == 'settings') {
       _openSettings(actionData);
    } else if (actionType == 'social') {
       _showSocialMediaPicker();
    }
  }

  void _showSocialMediaPicker() async {
    final allSocials = [
      {'name': 'WhatsApp', 'package': 'com.whatsapp', 'icon': Icons.chat},
      {'name': 'Instagram', 'package': 'com.instagram.android', 'icon': Icons.camera_alt},
      {'name': 'Facebook', 'package': 'com.facebook.katana', 'icon': Icons.facebook},
      {'name': 'X (Twitter)', 'package': 'com.twitter.android', 'icon': Icons.alternate_email},
      {'name': 'TikTok', 'package': 'com.zhiliaoapp.musically', 'icon': Icons.music_note},
    ];

    List<Map<String, dynamic>> installedSocials = [];
    if (defaultTargetPlatform == TargetPlatform.android) {
      for (var s in allSocials) {
        final bool isInstalled = await InstalledApps.isAppInstalled(s['package'] as String) ?? false;
        if (isInstalled) {
          installedSocials.add(s);
        }
      }
    }

    if (!mounted) return;

    if (installedSocials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No supported social media apps found on this device.')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E212B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select App to Configure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              ...installedSocials.map((s) => ListTile(
                leading: Icon(s['icon'] as IconData, color: Colors.white70),
                title: Text(s['name'] as String, style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (defaultTargetPlatform == TargetPlatform.android) {
                    try {
                      final bool success = await InstalledApps.startApp(s['package'] as String) ?? false;
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to launch ${s['name']}')));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to launch ${s['name']}')));
                    }
                  }
                },
              )),
              const SizedBox(height: 12),
            ],
          ),
        );
      }
    );
  }

  bool get _isWindows => defaultTargetPlatform == TargetPlatform.windows;

  void _openSettings(String? settingsType) {
    if (_isWindows) {
      _openWindowsSettings(settingsType);
      return;
    }
    // Mobile (Android / iOS)
    switch (settingsType) {
      case 'lockAndPassword':
        AppSettings.openAppSettings(type: AppSettingsType.lockAndPassword);
        break;
      case 'security':
        AppSettings.openAppSettings(type: AppSettingsType.security);
        break;
      case 'android.settings.SECURITY_SETTINGS':
        if (defaultTargetPlatform == TargetPlatform.android) {
          try {
            const intent = AndroidIntent(action: 'android.settings.SECURITY_SETTINGS');
            await intent.launch();
          } catch (e) {
            _showManualTip();
          }
        }
        break;
      case 'appSettings':
        AppSettings.openAppSettings(type: AppSettingsType.settings);
        break;
      case 'deviceInfo':
        AppSettings.openAppSettings(type: AppSettingsType.device);
        break;
      default:
        _showManualTip();
    }
  }

  void _openWindowsSettings(String? settingsType) {
    final Map<String, String> windowsSettingsMap = {
      'lockAndPassword': 'ms-settings:signinoptions',
      'security': 'ms-settings:signinoptions',
      'appSettings': 'ms-settings:appsfeatures',
      'deviceInfo': 'ms-settings:windowsupdate',
    };

    final uri = windowsSettingsMap[settingsType];
    if (uri != null) {
      launchUrl(Uri.parse(uri));
    } else {
      _showManualTip();
    }
  }

  void _showManualTip() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Enable this manually, then mark it as done here.'),
        backgroundColor: const Color(0xFFFFD600).withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF00FF40);
    if (score >= 50) return const Color(0xFFFFD600);
    return const Color(0xFFFF1744);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(
            top: 100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00FF40).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildScoreCard(),
                  const SizedBox(height: 32),
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text('SECURITY CHECKLIST', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.white70)),
                  ),
                  const SizedBox(height: 12),
                  _buildChecklist(),
                  const SizedBox(height: 32),
                  _buildProtectionGuidesTile(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00FF40).withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF00FF40).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF00FF40).withOpacity(0.2), blurRadius: 12),
            ],
          ),
          child: const Icon(Icons.security, color: Color(0xFF00FF40), size: 26),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BOMA',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                shadows: [Shadow(color: const Color(0xFF00FF40).withOpacity(0.5), blurRadius: 10)],
              ),
            ),
            Text(
              'Protection Center',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
        const Spacer(),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _isCheckingDevice = true);
              _checkDeviceSecurity();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF40).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00FF40).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isCheckingDevice
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00FF40)),
                        )
                      : const Icon(Icons.refresh, color: Color(0xFF00FF40), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _isCheckingDevice ? 'Scanning...' : 'Re-scan',
                    style: const TextStyle(
                      color: Color(0xFF00FF40),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        final currentScore = _scoreAnimation.value;
        final scoreColor = _getScoreColor(currentScore);

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: scoreColor.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(color: scoreColor.withOpacity(0.1), blurRadius: 30),
                ],
              ),
              child: Column(
                children: [
                  Text('DEVICE SAFETY SCORE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5), letterSpacing: 2)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 140, height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140, height: 140,
                          child: CircularProgressIndicator(
                            value: 1.0, strokeWidth: 10,
                            backgroundColor: Colors.transparent, color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        SizedBox(
                          width: 140, height: 140,
                          child: CircularProgressIndicator(
                            value: currentScore / 100, strokeWidth: 10,
                            strokeCap: StrokeCap.round, backgroundColor: Colors.transparent, color: scoreColor,
                          ),
                        ),
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: scoreColor.withOpacity(0.2), blurRadius: 20)],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentScore.round().toString(),
                              style: TextStyle(
                                fontSize: 42, fontWeight: FontWeight.w900,
                                color: scoreColor, shadows: [Shadow(color: scoreColor.withOpacity(0.5), blurRadius: 10)]
                              ),
                            ),
                            Text('/ 100', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    currentScore >= 80 ? 'Well Protected' : currentScore >= 50 ? 'Needs Improvement' : 'At Risk',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold,
                      color: scoreColor, shadows: [Shadow(color: scoreColor.withOpacity(0.3), blurRadius: 5)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_securityChecklist.where((i) => i['completed'] == true).length} of ${_securityChecklist.length} tasks completed',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChecklist() {
    return Column(
      children: List.generate(_securityChecklist.length, (index) {
        final item = _securityChecklist[index];
        final isCompleted = item['completed'] as bool;
        final isAutoDetect = item['autoDetect'] as bool;
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF00FF40).withOpacity(0.08) : const Color(0xFF222633),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompleted ? const Color(0xFF00FF40).withOpacity(0.3) : Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleItemTap(index),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCompleted ? const Color(0xFF00FF40).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item['icon'] as IconData, size: 22, color: isCompleted ? const Color(0xFF00FF40) : Colors.white54),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['title'] as String,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isCompleted ? Colors.white : Colors.white70,
                                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                                            decorationColor: Colors.white30,
                                          ),
                                        ),
                                      ),
                                      if (isAutoDetect)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00E5FF).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'AUTO',
                                            style: TextStyle(
                                              fontSize: 9, fontWeight: FontWeight.w800,
                                              color: const Color(0xFF00E5FF).withOpacity(0.8), letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['subtitle'] as String,
                                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                                  ),
                                  if (!isCompleted && !isAutoDetect)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Row(
                                        children: [
                                          Icon(Icons.touch_app, size: 12, color: const Color(0xFFFF9100).withOpacity(0.8)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Tap to configure',
                                              style: TextStyle(
                                                fontSize: 11, fontWeight: FontWeight.w500,
                                                color: const Color(0xFFFF9100).withOpacity(0.8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (isAutoDetect && !isCompleted)
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFF9100).withOpacity(0.15),
                                  border: Border.all(color: const Color(0xFFFF9100).withOpacity(0.5), width: 2),
                                ),
                                child: const Icon(Icons.settings, size: 16, color: Color(0xFFFF9100)),
                              )
                            else
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted ? const Color(0xFF00FF40) : Colors.transparent,
                                  border: Border.all(
                                    color: isCompleted ? const Color(0xFF00FF40) : Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: isCompleted ? [BoxShadow(color: const Color(0xFF00FF40).withOpacity(0.4), blurRadius: 8)] : [],
                                ),
                                child: isCompleted ? const Icon(Icons.check, size: 18, color: Colors.black) : null,
                              ),
                          ],
                        ),
                      ),
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

  Widget _buildProtectionGuidesTile() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProtectionGuidesScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF222633),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00FF40).withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00FF40).withOpacity(0.05), blurRadius: 20),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF40).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF00FF40).withOpacity(0.2), blurRadius: 8),
                      ],
                    ),
                    child: const Icon(Icons.menu_book_rounded, size: 26, color: Color(0xFF00FF40)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Protection Guides', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${ProtectionGuidesScreen.guides.length} guides to keep you safe', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4), size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
