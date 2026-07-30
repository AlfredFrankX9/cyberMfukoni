import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme constants
const Color _kDeepBlack = Color(0xFF000000);
const Color _kSlateBlue = Color(0xFF222633);
const Color _kMetallicSilver = Color(0xFFB0B0B0);
const Color _kNeonGreen = Color(0xFF00FF40);
const Color _kWarningAmber = Color(0xFFFF9100);
const Color _kCriticalRed = Color(0xFFFF1744);
const Color _kCyberPurple = Color(0xFF9C27B0);

class ParentalControlsScreen extends StatefulWidget {
  const ParentalControlsScreen({super.key});

  @override
  State<ParentalControlsScreen> createState() => _ParentalControlsScreenState();
}

class _ParentalControlsScreenState extends State<ParentalControlsScreen>
    with SingleTickerProviderStateMixin {
  static const _vpnChannel = MethodChannel('com.example.frontend/vpn');
  static const _parentalChannel = MethodChannel('com.example.frontend/parental');

  late TabController _tabController;

  // Website blocking
  List<String> _blockedDomains = [];
  final TextEditingController _domainController = TextEditingController();

  // App blocking
  List<Map<String, dynamic>> _installedApps = [];
  Set<String> _blockedAppPackages = {};
  bool _loadingApps = true;
  bool _hasUsagePermission = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadBlockedDomains();
    await _loadBlockedApps();
    await _checkUsagePermission();
    await _loadInstalledApps();
  }

  Future<void> _loadBlockedDomains() async {
    try {
      final result = await _vpnChannel.invokeMethod('getBlockedDomains');
      if (result != null) {
        setState(() {
          _blockedDomains = List<String>.from(result);
        });
      }
    } catch (e) {
      // Load from prefs as fallback
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _blockedDomains = prefs.getStringList('blocked_domains') ?? [];
      });
    }
  }

  Future<void> _loadBlockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _blockedAppPackages = (prefs.getStringList('blocked_apps') ?? []).toSet();
    });
    // Sync to native
    if (_blockedAppPackages.isNotEmpty) {
      try {
        await _parentalChannel.invokeMethod(
            'updateBlockedApps', {'packages': _blockedAppPackages.toList()});
      } catch (_) {}
    }
  }

  Future<void> _checkUsagePermission() async {
    try {
      final result = await _parentalChannel.invokeMethod('hasUsagePermission');
      setState(() {
        _hasUsagePermission = result == true;
      });
    } catch (_) {}
  }

  Future<void> _loadInstalledApps() async {
    try {
      final result = await _parentalChannel.invokeMethod('getInstalledApps');
      if (result != null) {
        setState(() {
          _installedApps = (result as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _loadingApps = false;
        });
      }
    } catch (e) {
      setState(() => _loadingApps = false);
    }
  }

  Future<void> _addDomain(String domain) async {
    if (domain.isEmpty) return;
    final cleaned = domain.trim().toLowerCase().replaceAll(RegExp(r'^https?://'), '').replaceAll('/', '');
    if (cleaned.isEmpty || _blockedDomains.contains(cleaned)) return;

    setState(() => _blockedDomains.add(cleaned));
    _domainController.clear();

    try {
      await _vpnChannel.invokeMethod('addBlockedDomain', {'domain': cleaned});
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_domains', _blockedDomains);
  }

  Future<void> _removeDomain(String domain) async {
    setState(() => _blockedDomains.remove(domain));

    try {
      await _vpnChannel.invokeMethod('removeBlockedDomain', {'domain': domain});
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_domains', _blockedDomains);
  }

  Future<void> _toggleAppBlock(String packageName, bool block) async {
    setState(() {
      if (block) {
        _blockedAppPackages.add(packageName);
      } else {
        _blockedAppPackages.remove(packageName);
      }
    });

    // Save to prefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_apps', _blockedAppPackages.toList());

    // Sync to native
    try {
      await _parentalChannel.invokeMethod(
          'updateBlockedApps', {'packages': _blockedAppPackages.toList()});
    } catch (_) {}
  }

  Future<void> _requestUsagePermission() async {
    try {
      await _parentalChannel.invokeMethod('requestUsagePermission');

      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _kSlateBlue,
            title: Text(
              "Grant Usage Access",
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Android Settings has opened. Find "The Guardian" in the list and toggle it ON to allow app monitoring.\n\nThen press Back to return here.',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: _kNeonGreen),
                child: Text("I've granted it",
                    style: GoogleFonts.inter(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }

      await _checkUsagePermission();
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _domainController.dispose();
    super.dispose();
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
          "PARENTAL CONTROLS",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _kCyberPurple,
          labelColor: _kCyberPurple,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.language), text: "WEBSITES"),
            Tab(icon: Icon(Icons.apps), text: "APPS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWebsitesTab(),
          _buildAppsTab(),
        ],
      ),
    );
  }

  // ─────────────────────────── WEBSITES TAB ───────────────────────────
  Widget _buildWebsitesTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCyberPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kCyberPurple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield, color: _kCyberPurple, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Blocked domains are filtered by the DNS VPN. Enable the DNS Filter to activate blocking.",
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Add domain input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _domainController,
                  style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "e.g. example.com",
                    hintStyle: GoogleFonts.shareTechMono(color: Colors.white30),
                    filled: true,
                    fillColor: _kSlateBlue,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: const Icon(Icons.block, color: _kCriticalRed, size: 20),
                  ),
                  onSubmitted: _addDomain,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _addDomain(_domainController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kCyberPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Blocked domains list
          Text(
            "BLOCKED SITES (${_blockedDomains.length})",
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _blockedDomains.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white24, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          "No sites blocked yet.\nAdd a domain above to get started.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _blockedDomains.length,
                    itemBuilder: (context, index) {
                      final domain = _blockedDomains[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _kSlateBlue.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kCriticalRed.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.block, color: _kCriticalRed, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                domain,
                                style: GoogleFonts.shareTechMono(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: _kCriticalRed, size: 20),
                              onPressed: () => _removeDomain(domain),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── APPS TAB ───────────────────────────
  Widget _buildAppsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Usage permission banner
          if (!_hasUsagePermission)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kWarningAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kWarningAmber.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber, color: _kWarningAmber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Usage Access permission is required to monitor which app is in the foreground.",
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _requestUsagePermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kWarningAmber,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text("GRANT USAGE ACCESS",
                          style: GoogleFonts.inter(
                              color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCyberPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kCyberPurple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: _kCyberPurple, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Toggle apps below to block them. When a blocked app is opened, The Guardian will display a block screen.",
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Blocked count
          Text(
            "INSTALLED APPS — ${_blockedAppPackages.length} BLOCKED",
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          // App list
          Expanded(
            child: _loadingApps
                ? const Center(
                    child: CircularProgressIndicator(color: _kNeonGreen))
                : _installedApps.isEmpty
                    ? Center(
                        child: Text("No apps found.",
                            style: GoogleFonts.inter(color: Colors.white38)),
                      )
                    : ListView.builder(
                        itemCount: _installedApps.length,
                        itemBuilder: (context, index) {
                          final app = _installedApps[index];
                          final name = app['appName'] as String? ?? 'Unknown';
                          final pkg = app['packageName'] as String? ?? '';
                          final isBlocked = _blockedAppPackages.contains(pkg);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isBlocked
                                  ? _kCriticalRed.withOpacity(0.08)
                                  : _kSlateBlue.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: isBlocked
                                  ? Border.all(
                                      color: _kCriticalRed.withOpacity(0.3))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isBlocked
                                        ? _kCriticalRed.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: (app['iconBase64'] != null && (app['iconBase64'] as String).isNotEmpty)
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.memory(
                                            base64Decode(app['iconBase64'] as String),
                                            fit: BoxFit.cover,
                                            width: 36,
                                            height: 36,
                                          ),
                                        )
                                      : Icon(
                                          isBlocked ? Icons.lock : Icons.android,
                                          color: isBlocked ? _kCriticalRed : _kNeonGreen,
                                          size: 20,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        pkg,
                                        style: GoogleFonts.shareTechMono(
                                          color: Colors.white38,
                                          fontSize: 10,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isBlocked,
                                  activeColor: _kCriticalRed,
                                  inactiveThumbColor: Colors.white30,
                                  inactiveTrackColor: Colors.white10,
                                  onChanged: (val) =>
                                      _toggleAppBlock(pkg, val),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
