import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/translations.dart';

/// Wraps any child and monitors user activity.
///
/// • While in the foreground, if there is no touch interaction for
///   [inactivityTimeout] (default 10 min), a neon-green styled warning dialog
///   appears with a 10-second countdown. If the user doesn't dismiss it, they
///   are logged out.
///
/// • When the app goes to the background, if it stays there for longer than
///   [backgroundTimeout] (default 3 min), the user is logged out immediately
///   upon returning.
class InactivityTracker extends StatefulWidget {
  final Widget child;
  final Duration inactivityTimeout;
  final Duration backgroundTimeout;

  const InactivityTracker({
    super.key,
    required this.child,
    this.inactivityTimeout = const Duration(minutes: 10),
    this.backgroundTimeout = const Duration(minutes: 3),
  });

  @override
  State<InactivityTracker> createState() => _InactivityTrackerState();
}

class _InactivityTrackerState extends State<InactivityTracker>
    with WidgetsBindingObserver {
  Timer? _inactivityTimer;
  DateTime? _backgroundedAt;
  bool _warningShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  // ── Lifecycle observer ──────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background — record the timestamp and pause the timer
      _backgroundedAt = DateTime.now();
      _inactivityTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // App returning to foreground
      if (_backgroundedAt != null) {
        final elapsed = DateTime.now().difference(_backgroundedAt!);
        _backgroundedAt = null;
        if (elapsed >= widget.backgroundTimeout) {
          _performLogout();
          return;
        }
      }
      _resetInactivityTimer();
    }
  }

  // ── Inactivity timer ────────────────────────────────────────────────────

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(widget.inactivityTimeout, _showWarningDialog);
  }

  void _onUserInteraction() {
    if (!_warningShown) {
      _resetInactivityTimer();
    }
  }

  // ── Warning dialog with 10-second countdown ────────────────────────────

  void _showWarningDialog() {
    if (_warningShown || !mounted) return;
    _warningShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => _InactivityWarningDialog(
        onStayLoggedIn: () {
          _warningShown = false;
          Navigator.of(ctx).pop();
          _resetInactivityTimer();
        },
        onTimeout: () {
          _warningShown = false;
          Navigator.of(ctx).pop();
          _performLogout();
        },
      ),
    );
  }

  void _performLogout() {
    if (!mounted) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    auth.logout();
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _onUserInteraction,
      onPanDown: (_) => _onUserInteraction(),
      onScaleStart: (_) => _onUserInteraction(),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Self-contained dialog widget with its own countdown timer
// ─────────────────────────────────────────────────────────────────────────────

class _InactivityWarningDialog extends StatefulWidget {
  final VoidCallback onStayLoggedIn;
  final VoidCallback onTimeout;

  const _InactivityWarningDialog({
    required this.onStayLoggedIn,
    required this.onTimeout,
  });

  @override
  State<_InactivityWarningDialog> createState() =>
      _InactivityWarningDialogState();
}

class _InactivityWarningDialogState extends State<_InactivityWarningDialog> {
  static const int _countdownSeconds = 10;
  int _remaining = _countdownSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        widget.onTimeout();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color kGreen = Color(0xFF00FF40);
    const Color kCardBg = Color(0xFF1A1E2A);

    final double progress = _remaining / _countdownSeconds;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kGreen.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: kGreen.withOpacity(0.08),
              blurRadius: 40,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated countdown ring
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: progress + 0.1, end: progress),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOut,
                      builder: (context, value, _) {
                        return CircularProgressIndicator(
                          value: value.clamp(0.0, 1.0),
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _remaining <= 3
                                ? Colors.redAccent
                                : kGreen,
                          ),
                        );
                      },
                    ),
                  ),
                  Text(
                    '$_remaining',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _remaining <= 3 ? Colors.redAccent : kGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Warning icon
            Icon(
              Icons.timer_off_outlined,
              color: kGreen.withOpacity(0.7),
              size: 28,
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              context.tr('inactivity_session_timeout'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              '${context.tr('inactivity_warning_msg_1')}$_remaining${context.tr('inactivity_warning_msg_2')}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // "Stay Logged In" button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: widget.onStayLoggedIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen.withOpacity(0.15),
                  foregroundColor: kGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: kGreen.withOpacity(0.4)),
                  ),
                ),
                child: Text(
                  context.tr('inactivity_stay_logged_in'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
