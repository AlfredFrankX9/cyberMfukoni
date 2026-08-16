import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/translations.dart';

// Theme constants
const Color _kDeepBlack = Color(0xFF000000);
const Color _kSlateBlue = Color(0xFF222633);
const Color _kMetallicSilver = Color(0xFFB0B0B0);
const Color _kNeonGreen = Color(0xFF00FF40);
const Color _kCyberEmerald = Color(0xFF32CD32);
const Color _kWarningAmber = Color(0xFFFF9100);
const Color _kCriticalRed = Color(0xFFFF1744);

class PermissionAuditorScreen extends StatefulWidget {
  const PermissionAuditorScreen({super.key});

  @override
  State<PermissionAuditorScreen> createState() =>
      _PermissionAuditorScreenState();
}

class _PermissionAuditorScreenState extends State<PermissionAuditorScreen> {
  static const _platform = MethodChannel('com.example.frontend/permissions');

  bool _isLoading = true;
  List<Map<String, dynamic>> _auditedApps = [];
  int _privacyScore = 100;
  int _highRiskCount = 0;
  int _mediumRiskCount = 0;
  int _lowRiskCount = 0;

  // Sensitive permissions mapping with friendly descriptions
  static const Map<String, Map<String, String>> _sensitivePermissions = {
    'android.permission.READ_SMS': {
      'group': 'SMS',
      'desc':
          'Can read your incoming SMS messages (potentially exposing M-Pesa or bank transaction codes).',
    },
    'android.permission.RECEIVE_SMS': {
      'group': 'SMS',
      'desc': 'Can intercept transaction messages/OTPs.',
    },
    'android.permission.SEND_SMS': {
      'group': 'SMS',
      'desc': 'Can send premium-rate SMS without your knowledge.',
    },
    'android.permission.READ_CONTACTS': {
      'group': 'Contacts',
      'desc':
          'Can access your list of contacts (could be used for harassment/social engineering).',
    },
    'android.permission.WRITE_CONTACTS': {
      'group': 'Contacts',
      'desc': 'Can modify your contacts.',
    },
    'android.permission.RECORD_AUDIO': {
      'group': 'Microphone',
      'desc': 'Can record audio and listen to private conversations.',
    },
    'android.permission.CAMERA': {
      'group': 'Camera',
      'desc': 'Can take photos and videos without your explicit knowledge.',
    },
    'android.permission.ACCESS_FINE_LOCATION': {
      'group': 'Location',
      'desc': 'Can track your precise physical location.',
    },
    'android.permission.ACCESS_COARSE_LOCATION': {
      'group': 'Location',
      'desc': 'Can estimate your approximate physical location.',
    },
    'android.permission.ACCESS_BACKGROUND_LOCATION': {
      'group': 'Location',
      'desc':
          'Can track your location at all times, even when the app is closed.',
    },
    'android.permission.READ_PHONE_STATE': {
      'group': 'Phone State',
      'desc': 'Can access your phone number, IMEI, and network info.',
    },
    'android.permission.CALL_PHONE': {
      'group': 'Phone',
      'desc': 'Can initiate calls directly without user action.',
    },
    'android.permission.READ_EXTERNAL_STORAGE': {
      'group': 'Storage',
      'desc': 'Can view files, photos, and documents on your device.',
    },
    'android.permission.WRITE_EXTERNAL_STORAGE': {
      'group': 'Storage',
      'desc': 'Can write/modify files on your device.',
    },
  };

  @override
  void initState() {
    super.initState();
    _auditPermissions();
  }

  Future<void> _auditPermissions() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get installed apps via packages library
      final List<AppInfo> installedApps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );

      // 2. Query permissions natively via MethodChannel
      final List<dynamic>? nativeApps = await _platform
          .invokeMethod<List<dynamic>>('getInstalledAppsWithPermissions');

      if (nativeApps == null) {
        throw Exception("Failed to query permissions natively.");
      }

      // Map native permissions by package name
      final Map<String, List<String>> permissionMap = {};
      for (var app in nativeApps) {
        final Map<dynamic, dynamic> appMap = app as Map<dynamic, dynamic>;
        final String pkg = appMap['packageName'] as String;
        final List<dynamic> perms = appMap['permissions'] as List<dynamic>;
        permissionMap[pkg] = perms.map((p) => p.toString()).toList();
      }

      // 3. Match and calculate risks
      final List<Map<String, dynamic>> audited = [];
      int high = 0;
      int medium = 0;
      int low = 0;

      for (var app in installedApps) {
        final pkg = app.packageName ?? '';
        final perms = permissionMap[pkg] ?? [];

        final List<Map<String, String>> sensitiveFound = [];
        for (var perm in perms) {
          if (_sensitivePermissions.containsKey(perm)) {
            sensitiveFound.add({
              'permission': perm,
              'group': _sensitivePermissions[perm]!['group']!,
              'desc': _sensitivePermissions[perm]!['desc']!,
            });
          }
        }

        String riskRating = 'Low';
        Color riskColor = _kNeonGreen;

        // Custom risk categorization heuristic
        if (sensitiveFound.length >= 4 ||
            sensitiveFound.any(
              (p) => p['group'] == 'SMS' || p['group'] == 'Contacts',
            )) {
          riskRating = 'High';
          riskColor = _kCriticalRed;
          high++;
        } else if (sensitiveFound.isNotEmpty) {
          riskRating = 'Medium';
          riskColor = _kWarningAmber;
          medium++;
        } else {
          low++;
        }

        audited.add({
          'name': app.name ?? 'Unknown App',
          'packageName': pkg,
          'icon': app.icon,
          'permissions': perms,
          'sensitivePermissions': sensitiveFound,
          'riskRating': riskRating,
          'riskColor': riskColor,
        });
      }

      // Sort by risk: High -> Medium -> Low
      audited.sort((a, b) {
        final riskWeights = {'High': 3, 'Medium': 2, 'Low': 1};
        final weightA = riskWeights[a['riskRating']] ?? 0;
        final weightB = riskWeights[b['riskRating']] ?? 0;
        return weightB.compareTo(weightA);
      });

      // Calculate a dynamic privacy score
      int calculatedScore = 100 - (high * 8) - (medium * 3);
      if (calculatedScore < 5) calculatedScore = 5;

      setState(() {
        _auditedApps = audited;
        _highRiskCount = high;
        _mediumRiskCount = medium;
        _lowRiskCount = low;
        _privacyScore = calculatedScore;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Permission audit failed: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showAppDetails(Map<String, dynamic> app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kSlateBlue,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final List<Map<String, String>> sensitive = app['sensitivePermissions'];
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      app['icon'] != null
                          ? Image.memory(app['icon'], width: 56, height: 56)
                          : const Icon(
                              Icons.android,
                              size: 56,
                              color: Colors.white,
                            ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app['name'],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              app['packageName'],
                              style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: app['riskColor'].withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: app['riskColor'].withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          "${app['riskRating']} Risk",
                          style: GoogleFonts.inter(
                            color: app['riskColor'],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text(
                    "${context.tr('perm_sensitive_found')} (${sensitive.length})",
                    style: GoogleFonts.inter(
                      color: _kMetallicSilver,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (sensitive.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        context.tr('perm_no_sensitive'),
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    ...sensitive.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning,
                                    color: _kWarningAmber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    s['group']!,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s['desc']!,
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      InstalledApps.openSettings(app['packageName']);
                    },
                    icon: Icon(
                      app['riskRating'] == 'High'
                          ? Icons.delete_forever
                          : Icons.settings,
                    ),
                    label: Text(
                      app['riskRating'] == 'High'
                          ? context.tr('perm_uninstall')
                          : context.tr('perm_open_settings'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: app['riskRating'] == 'High'
                          ? _kCriticalRed
                          : Colors.white.withOpacity(0.08),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDeepBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('', fallback: "PRIVACY AUDITOR"),
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kNeonGreen))
          : RefreshIndicator(
              onRefresh: _auditPermissions,
              color: _kNeonGreen,
              backgroundColor: _kSlateBlue,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildScoreCard(),
                  const SizedBox(height: 24),
                  _buildRiskDistribution(),
                  const SizedBox(height: 24),
                  Text(
                    context.tr('', fallback: "AUDITED APPLICATIONS"),
                    style: GoogleFonts.inter(
                      color: _kMetallicSilver,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._auditedApps.map(
                    (app) => Card(
                      color: _kSlateBlue.withOpacity(0.6),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        onTap: () => _showAppDetails(app),
                        leading: app['icon'] != null
                            ? Image.memory(app['icon'], width: 40, height: 40)
                            : const Icon(Icons.android, color: Colors.white),
                        title: Text(
                          app['name'],
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          "${app['permissions'].length} permissions requested",
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (app['sensitivePermissions'].isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: app['riskColor'].withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.warning,
                                  color: app['riskColor'],
                                  size: 14,
                                ),
                              ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _auditPermissions,
        backgroundColor: _kNeonGreen,
        child: const Icon(Icons.refresh, color: Colors.black),
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kSlateBlue,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: _privacyScore / 100,
                    strokeWidth: 8,
                    color: _privacyScore >= 80
                        ? _kNeonGreen
                        : (_privacyScore >= 50 ? _kWarningAmber : _kCriticalRed),
                    backgroundColor: Colors.white10,
                  ),
                ),
                Text(
                  "$_privacyScore",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${context.tr('', fallback: 'PRIVACY HEALTH SCORE')}",
                  style: GoogleFonts.inter(
                    color: _kMetallicSilver,
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _privacyScore >= 80
                      ? (context.tr('', fallback: "Device is Secure"))
                      : (_privacyScore >= 50
                            ? (context.tr('', fallback: "Moderate Threats Found"))
                            : (context.tr('', fallback: "Critical Actions Needed"))),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('perm_based_on'),
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistribution() {
    return Row(
      children: [
        Expanded(
          child: _buildRiskItem(context.tr('', fallback: "Critical"), _highRiskCount, _kCriticalRed),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRiskItem(context.tr('', fallback: "Warning"), _mediumRiskCount, _kWarningAmber),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildRiskItem(context.tr('', fallback: "Secure"), _lowRiskCount, _kNeonGreen)),
      ],
    );
  }

  Widget _buildRiskItem(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _kSlateBlue.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Text(
            "$count",
            style: GoogleFonts.inter(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: _kMetallicSilver,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
