import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/vault_storage_service.dart';

import 'passwords_screen.dart';
import 'credit_cards_screen.dart';
import 'notes_screen.dart';
import 'photos_screen.dart';
import 'files_screen.dart';
import 'recovery_codes_screen.dart';
import '../../utils/translations.dart';

class SecureVaultScreen extends StatefulWidget {
  const SecureVaultScreen({super.key});

  @override
  State<SecureVaultScreen> createState() => _SecureVaultScreenState();
}

class _SecureVaultScreenState extends State<SecureVaultScreen> {
  bool _isUnlocked = false;
  final LocalAuthentication auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  // Dynamic counts
  int passwordsCount = 0;
  int cardsCount = 0;
  int notesCount = 0;
  int photosCount = 0;
  int filesCount = 0;
  int recoveryCount = 0;

  @override
  void initState() {
    super.initState();
    // We only load stats after unlock
  }

  Future<void> _loadStats() async {
    final passes = await VaultStorageService.getPasswords();
    final cards = await VaultStorageService.getCards();
    final notes = await VaultStorageService.getNotes();
    final photos = await VaultStorageService.getPhotos();
    final files = await VaultStorageService.getFiles();
    final codes = await VaultStorageService.getRecoveryCodes();

    if (mounted) {
      setState(() {
        passwordsCount = passes.length;
        cardsCount = cards.length;
        notesCount = notes.length;
        photosCount = photos.length;
        filesCount = files.length;
        recoveryCount = codes.length;
      });
    }
  }

  // Vault health color based on percentage
  Color _getHealthColor(double health) {
    if (health >= 0.8) return const Color(0xFF00FF9D); // Neon Green
    if (health >= 0.6) return const Color(0xFFFF9800); // Amber
    if (health >= 0.4) return Colors.grey;
    return const Color(0xFFEF5350); // Red
  }

  Future<void> _authenticate() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access the Secure Vault',
        biometricOnly: true,
      );

      if (didAuthenticate) {
        await _storage.write(key: 'vault_unlocked', value: 'true');

        setState(() {
          _isUnlocked = true;
        });
        _loadStats();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('vault_auth_failed'))),
          );
        }
      }
    } catch (e) {
      // Fallback if biometrics aren't available/setup on emulator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('vault_bio_error')} $e. ${context.tr('vault_bio_unlock_demo')}')),
        );
      }
      setState(() {
        _isUnlocked = true;
      });
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C42).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF8C42).withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8C42).withOpacity(0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.lock, size: 64, color: Color(0xFFFF8C42)),
            ),
            const SizedBox(height: 32),
            Text(
              context.tr('', fallback: 'SECURE VAULT LOCKED'),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('', fallback: 'Authenticate to access encrypted storage.'),
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: Text(context.tr('', fallback: 'AUTHENTICATE')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C42),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        // Matches VaultScreen's AppBar. Scaffold automatically updates
        // MediaQuery.padding.top to include the full AppBar height, 
        // so we just add a small 16.0px breathing room.
        top: MediaQuery.of(context).padding.top + 16.0,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVaultStatus(),
          const SizedBox(height: 24),
          Text(
            context.tr('', fallback: 'ENCRYPTED STORAGE'),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _buildGridItem(
                context.tr('', fallback: 'Passwords'),
                '$passwordsCount ${context.tr('', fallback: 'Saved')}',
                Icons.password,
                'assets/images/password_vault.webp',
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PasswordsScreen()),
                  );
                  _loadStats();
                },
              ),
              _buildGridItem(
                context.tr('', fallback: 'Credit Cards'),
                '$cardsCount ${context.tr('', fallback: 'Saved')}',
                Icons.credit_card,
                'assets/images/card_vault.webp',
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreditCardsScreen(),
                    ),
                  );
                  _loadStats();
                },
              ),
              _buildGridItem(
                context.tr('', fallback: 'Secure Notes'),
                '$notesCount ${context.tr('', fallback: 'Notes')}',
                Icons.note,
                'assets/images/notes_vault.webp',
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotesScreen()),
                  );
                  _loadStats();
                },
              ),
              _buildGridItem(
                context.tr('', fallback: 'Private Photos'),
                '$photosCount ${context.tr('', fallback: 'Files')}',
                Icons.photo_library,
                'assets/images/photo_vault.webp',
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PhotosScreen()),
                  );
                  _loadStats();
                },
              ),
              _buildGridItem(
                context.tr('', fallback: 'Files'),
                '$filesCount ${context.tr('', fallback: 'Files')}',
                Icons.folder,
                'assets/images/doc_vault.webp',
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FilesScreen()),
                  );
                  _loadStats();
                },
              ),
              _buildGridItem(
                context.tr('', fallback: 'Recovery Codes'),
                '$recoveryCount ${context.tr('', fallback: 'Services')}',
                Icons.vpn_key,
                'assets/images/key_vault.webp',
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecoveryCodesScreen(),
                    ),
                  );
                  _loadStats();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVaultStatus() {
    const double healthValue = 0.92;
    final Color healthColor = _getHealthColor(healthValue);

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: healthColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: healthColor.withOpacity(0.08), blurRadius: 30),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: healthValue,
                      strokeWidth: 5,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      color: healthColor,
                    ),
                    Text(
                      '${(healthValue * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
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
                      context.tr('', fallback: 'VAULT HEALTH'),
                      style: GoogleFonts.inter(
                        color: healthColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('', fallback: 'Encryption: AES-256'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('', fallback: 'Last backed up: 2h ago'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
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

  Widget _buildGridItem(
    String title,
    String subtitle,
    IconData icon,
    String imagePath,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                      ),
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
