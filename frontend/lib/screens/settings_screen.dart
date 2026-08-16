import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/translations.dart';
import '../providers/locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  // ── Theme constants ──────────────────────────────────────────────────────
  static const Color kGreen = Color(0xFF00FF40);
  static const Color kBg = Color(0xFF0A0C10);
  static const Color kCard = Color(0xFF151922);
  static const Color kFieldFill = Color(0xFF1A1E28);

  // ── Account fields ────────────────────────────────────────────────────
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _isSaving = false;
  bool _isLoadingProfile = true;

  // ── Settings state ────────────────────────────────────────────────────
  String _language = 'English';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfile();
    _loadLocalSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiService.get('/api/auth/me');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _usernameController.text = data['username'] ?? '';
            _emailController.text = data['email'] ?? '';
            _isLoadingProfile = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      });
      _checkPermissions();
    }
  }

  // ── Permissions State ──────────────────────────────────────────────────
  Map<Permission, bool> _permissionStatuses = {
    Permission.storage: false,
    Permission.notification: false,
    Permission.manageExternalStorage: false,
    Permission.systemAlertWindow: false,
  };

  Future<void> _checkPermissions() async {
    final Map<Permission, bool> statuses = {};
    for (var perm in _permissionStatuses.keys) {
      statuses[perm] = await perm.isGranted;
    }
    if (mounted) {
      setState(() {
        _permissionStatuses = statuses;
      });
    }
  }

  Future<void> _togglePermission(Permission perm, bool currentValue) async {
    // Special permissions that must be granted through system settings
    final specialPerms = [Permission.manageExternalStorage, Permission.systemAlertWindow];
    if (specialPerms.contains(perm) || currentValue) {
      if (currentValue) {
        _showSnack(context.tr('perm_revoke_warning'), isError: true);
      }
      await openAppSettings();
      // Re-check after returning from settings
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkPermissions();
    } else {
      // Request it normally
      final status = await perm.request();
      if (mounted) {
        setState(() {
          _permissionStatuses[perm] = status.isGranted;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final Map<String, dynamic> body = {};
    if (_usernameController.text.trim().isNotEmpty) {
      body['username'] = _usernameController.text.trim();
    }
    if (_emailController.text.trim().isNotEmpty) {
      body['email'] = _emailController.text.trim();
    }
    if (_newPasswordController.text.isNotEmpty) {
      body['current_password'] = _currentPasswordController.text;
      body['new_password'] = _newPasswordController.text;
    }

    if (body.isEmpty) {
      _showSnack(context.tr('settings_no_changes', fallback: 'No changes detected'), isError: false);
      setState(() => _isSaving = false);
      return;
    }

    try {
      final response = await ApiService.put('/api/auth/update-profile', body: body);
      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSnack(context.tr('settings_profile_updated', fallback: 'Profile updated'), isError: false);
        _currentPasswordController.clear();
        _newPasswordController.clear();
      } else {
        final data = json.decode(response.body);
        _showSnack(data['detail'] ?? context.tr('settings_update_failed', fallback: 'Failed to update'), isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(context.tr('settings_network_error', fallback: 'Network error'), isError: true);
    }

    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _setLanguage(String lang) async {
    final code = lang == 'Kiswahili' ? 'sw' : 'en';
    await context.read<LocaleProvider>().setLocale(code);
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    if (mounted) setState(() => _notificationsEnabled = value);
  }

  Future<void> _clearPermissions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildConfirmDialog(
        title: context.tr('settings_clear_permissions_title', fallback: 'Revoke All Permissions'),
        body: context.tr('settings_clear_permissions_body', fallback: 'This will open system settings where you can manually revoke access.'),
        confirmLabel: context.tr('settings_clear_all', fallback: 'Open Settings'),
      ),
    );
    if (confirmed == true) {
      await openAppSettings();
      if (!mounted) return;
      _showSnack(context.tr('settings_opening_app_settings', fallback: 'Opening Settings'), isError: false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : kGreen.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.6),
                  radius: 1.4,
                  colors: [
                    kGreen.withOpacity(0.06),
                    kBg,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: _isLoadingProfile
                      ? const Center(
                          child: CircularProgressIndicator(color: kGreen),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionLabel(context.tr('settings_account_mgmt')),
                              const SizedBox(height: 12),
                              _buildAccountCard(),
                              const SizedBox(height: 28),
                              _buildSectionLabel(context.tr('settings_preferences')),
                              const SizedBox(height: 12),
                              _buildPreferencesCard(),
                              const SizedBox(height: 28),
                              _buildSectionLabel(context.tr('settings_privacy_security')),
                              const SizedBox(height: 12),
                              _buildPrivacyCard(),
                              const SizedBox(height: 28),
                              _buildLogoutButton(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Icon(Icons.settings, color: kGreen.withOpacity(0.8), size: 22),
          const SizedBox(width: 10),
          Text(
            context.tr('settings_title'),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
        color: kGreen.withOpacity(0.7),
      ),
    );
  }

  // ── Account Card ──────────────────────────────────────────────────────────
  Widget _buildAccountCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(context.tr('settings_username')),
          const SizedBox(height: 6),
          _textField(controller: _usernameController, hint: ''),
          const SizedBox(height: 16),
          _fieldLabel(context.tr('settings_email')),
          const SizedBox(height: 6),
          _textField(controller: _emailController, hint: ''),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          _fieldLabel(context.tr('settings_change_password')),
          const SizedBox(height: 6),
          _textField(
            controller: _currentPasswordController,
            hint: context.tr('settings_current_password'),
            obscure: _obscureCurrent,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                color: kGreen, size: 18,
              ),
              onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
          ),
          const SizedBox(height: 10),
          _textField(
            controller: _newPasswordController,
            hint: context.tr('settings_new_password'),
            obscure: _obscureNew,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew ? Icons.visibility_off : Icons.visibility,
                color: kGreen, size: 18,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen.withOpacity(0.15),
                foregroundColor: kGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: kGreen.withOpacity(0.3)),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: kGreen, strokeWidth: 2),
                    )
                  : Text(
                      context.tr('settings_save_changes'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Preferences Card ──────────────────────────────────────────────────────
  Widget _buildPreferencesCard() {
    final currentLang = context.watch<LocaleProvider>().locale == 'sw' ? 'Kiswahili' : 'English';
    return _glassCard(
      child: Column(
        children: [
          // Language selector
          _settingsRow(
            icon: Icons.language,
            title: context.tr('settings_language'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kFieldFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentLang,
                  isDense: true,
                  dropdownColor: const Color(0xFF1C2030),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  icon: Icon(Icons.expand_more, color: kGreen.withValues(alpha: 0.6), size: 18),
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Kiswahili', child: Text('Kiswahili')),
                  ],
                  onChanged: (val) {
                    if (val != null) _setLanguage(val);
                  },
                ),
              ),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.04), height: 24),
          // Notifications toggle
          _settingsRow(
            icon: Icons.notifications_active_outlined,
            title: context.tr('settings_notifications'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeColor: kGreen,
              activeTrackColor: kGreen.withOpacity(0.3),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('settings_app_permissions', fallback: 'App Permissions'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(context.tr('settings_permissions_desc', fallback: 'Manage access given to the app'), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          const SizedBox(height: 12),
          _buildPermissionToggle(Permission.storage, context.tr('perm_storage', fallback: 'Storage / Photos'), Icons.folder_outlined),
          _buildPermissionToggle(Permission.notification, context.tr('perm_notification', fallback: 'Notifications'), Icons.notifications_none),
          _buildPermissionToggle(Permission.manageExternalStorage, context.tr('perm_manage_storage', fallback: 'All File Access'), Icons.sd_storage_outlined),
          _buildPermissionToggle(Permission.systemAlertWindow, context.tr('perm_system_alert', fallback: 'Display over other apps'), Icons.picture_in_picture_alt_outlined),
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 32),
          _settingsRow(
            icon: Icons.shield_outlined,
            title: context.tr('settings_clear_permissions'),
            subtitle: context.tr('settings_clear_permissions_desc'),
            trailing: const IconButton(
              icon: Icon(Icons.chevron_right, color: Colors.white38),
              onPressed: null,
            ),
            onTap: _clearPermissions,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionToggle(Permission perm, String label, IconData icon) {
    final bool isGranted = _permissionStatuses[perm] ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Switch(
            value: isGranted,
            onChanged: (val) => _togglePermission(perm, isGranted),
            activeColor: kGreen,
            activeTrackColor: kGreen.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  // ── Logout Button ─────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => _buildConfirmDialog(
              title: context.tr('settings_logout'),
              body: context.tr('settings_confirm_logout'),
              confirmLabel: context.tr('settings_logout'),
              isDestructive: true,
            ),
          );
          if (confirmed == true && mounted) {
            await Provider.of<AuthService>(context, listen: false).logout();
            if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        icon: const Icon(Icons.logout, size: 18),
        label: Text(context.tr('settings_logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ── Reusable components ───────────────────────────────────────────────────
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCard.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.5),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
          filled: true,
          fillColor: kFieldFill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide.none,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kGreen, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildConfirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kCard.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDestructive ? Colors.redAccent : kGreen,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        context.tr('settings_cancel'),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructive ? Colors.redAccent : kGreen,
                        foregroundColor: isDestructive ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
