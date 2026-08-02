import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

/// Utility to gate access to sensitive screens behind device authentication
/// (fingerprint, face, PIN, pattern, etc.).
class AuthHelper {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Returns `true` when the user passes device authentication, or when the
  /// platform doesn't support it (e.g. desktop/web — we let them through).
  static Future<bool> authenticate(BuildContext context) async {
    final bool isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (!isMobile) return true; // Skip on desktop/web

    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        // No lock screen configured — let them through with a warning.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No device security set up. Please enable a lock screen.'),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return true;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access this secure feature',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern/password fallback
        ),
      );

      if (!didAuthenticate && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Authentication failed or cancelled.'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      return didAuthenticate;
    } catch (e) {
      debugPrint('AuthHelper error: $e');
      return false;
    }
  }
}
