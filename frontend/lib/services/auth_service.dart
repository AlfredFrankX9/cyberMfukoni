import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // FIX: shared GoogleSignIn instance so login and logout act on the same
  // cached session.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: '477196656875-0gedcmtv04hcngvakcs2r89o9cmiop07.apps.googleusercontent.com',
    serverClientId: '477196656875-0gedcmtv04hcngvakcs2r89o9cmiop07.apps.googleusercontent.com',
  );

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    _isAuthenticated = token != null;
    notifyListeners();
    syncOfflineData();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------
  Future<String?> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/api/auth/login'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'username': username, 'password': password},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // ── Online success ────────────────────────────────────────────────
        final data = _decodeJson(response.body);
        final token = data['access_token'] as String?;
        if (token == null) return 'Unexpected response from server.';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        // Cache hashed credentials so a genuine offline session works later.
        await prefs.setString(
          'offline_user_$username',
          _hashPassword(password),
        );

        _isAuthenticated = true;
        notifyListeners();
        return null; // null = success
      } else {
        // ── Server returned an error status (4xx / 5xx) ───────────────────
        // Do NOT fall back to offline — the server is reachable and has
        // rejected the credentials.  Show the real error to the user.
        final String detail =
            _extractDetail(response.body) ??
            'Login failed (${response.statusCode}).';
        return detail;
      }
    } on SocketException {
      // No internet — safe to try cached credentials.
      return _attemptOfflineLogin(username, password);
    } on TimeoutException {
      // Server unreachable — safe to try cached credentials.
      return _attemptOfflineLogin(username, password);
    } catch (e) {
      // Any other error (SSL, malformed response, etc.) — do NOT silently
      // fall back to offline; surface the real problem to the user.
      debugPrint('Login unexpected error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  /// Only called when we are genuinely offline (SocketException / Timeout).
  Future<String?> _attemptOfflineLogin(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString('offline_user_$username');

    if (storedHash != null && storedHash == _hashPassword(password)) {
      await prefs.setString('jwt_token', 'offline_token_$username');
      _isAuthenticated = true;
      notifyListeners();
      return 'offline_success';
    }

    return 'Cannot reach the server and no offline session was found. '
        'Please check your connection.';
  }

  // ---------------------------------------------------------------------------
  // REGISTER
  // ---------------------------------------------------------------------------
  Future<String?> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await ApiService.post(
        '/api/auth/register',
        body: {'username': username, 'email': email, 'password': password},
      ).timeout(const Duration(seconds: 30));

      debugPrint('Register response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = _decodeJson(response.body);
        final token = data['access_token'] as String?;
        if (token == null) return 'Unexpected response from server.';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString(
          'offline_user_$username',
          _hashPassword(password),
        );

        _isAuthenticated = true;
        notifyListeners();
        return null;
      } else {
        // Server rejected the registration — show the real error.
        final String detail =
            _extractDetail(response.body) ??
            'Registration failed (${response.statusCode}).';
        return detail;
      }
    } on SocketException {
      return _attemptOfflineRegister(username, email, password);
    } on TimeoutException {
      return _attemptOfflineRegister(username, email, password);
    } catch (e) {
      debugPrint('Register unexpected error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> _attemptOfflineRegister(
    String username,
    String email,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('offline_user_$username', _hashPassword(password));

    final List<String> pendingSyncs =
        prefs.getStringList('pending_sync_accounts') ?? [];
    pendingSyncs.add(
      json.encode({'username': username, 'email': email, 'password': password}),
    );
    await prefs.setStringList('pending_sync_accounts', pendingSyncs);

    await prefs.setString('jwt_token', 'offline_token_$username');
    _isAuthenticated = true;
    notifyListeners();
    return 'offline_success';
  }

  // ---------------------------------------------------------------------------
  // SYNC
  // ---------------------------------------------------------------------------
  Future<void> syncOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSyncs = prefs.getStringList('pending_sync_accounts') ?? [];
    if (pendingSyncs.isEmpty) return;

    debugPrint('Attempting to sync ${pendingSyncs.length} offline accounts…');

    final List<String> remainingSyncs = [];

    for (final accountStr in pendingSyncs) {
      try {
        final account = json.decode(accountStr) as Map<String, dynamic>;
        final response = await ApiService.post(
          '/api/auth/register',
          body: {
            'username': account['username'],
            'email': account['email'],
            'password': account['password'],
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 400) {
          debugPrint('Synced account: ${account['username']}');
        } else {
          remainingSyncs.add(accountStr);
        }
      } catch (_) {
        remainingSyncs.add(accountStr);
      }
    }

    await prefs.setStringList('pending_sync_accounts', remainingSyncs);
  }

  // ---------------------------------------------------------------------------
  // GOOGLE LOGIN
  // ---------------------------------------------------------------------------
  Future<String?> googleLogin(String username, String email) async {
    try {
      final response = await ApiService.post(
        '/api/auth/google',
        body: {'username': username, 'email': email},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _decodeJson(response.body);
        final token = data['access_token'] as String?;
        if (token == null) return 'Unexpected response from server.';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        _isAuthenticated = true;
        notifyListeners();
        return null;
      } else {
        return _extractDetail(response.body) ??
            'Google login failed (${response.statusCode}).';
      }
    } on SocketException {
      return 'No internet connection.';
    } on TimeoutException {
      return 'Server unreachable. Please try again.';
    } catch (e) {
      debugPrint('Google login error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // FIX: expose the shared GoogleSignIn instance so AuthScreen doesn't create
  // its own separate instance with its own (possibly stale) cached session.
  /// Clears any cached Google session so the next `signIn()` call is
  /// guaranteed to show the account picker instead of silently
  /// re-authenticating as the previous account.
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google signOut error: $e');
    }
  }

  GoogleSignIn get googleSignIn => _googleSignIn;

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');

    // FIX: logout() previously only cleared the app's own JWT and left the
    // Google SDK's cached account in place. That meant tapping "Continue
    // with Google" again — even after logging out — silently reused the
    // last Google account instead of showing the account picker. Clearing
    // the cached Google session here makes "log out" actually log the user
    // out everywhere.
    await signOutGoogle();

    _isAuthenticated = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Safely decode a JSON response body; returns empty map on failure.
  Map<String, dynamic> _decodeJson(String body) {
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Extract the `detail` field from an error response body, if present.
  String? _extractDetail(String body) {
    try {
      final data = json.decode(body) as Map<String, dynamic>;
      return data['detail']?.toString();
    } catch (_) {
      return null;
    }
  }
}
