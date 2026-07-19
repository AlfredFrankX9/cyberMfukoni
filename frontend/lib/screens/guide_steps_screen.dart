import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// A single step inside a protection guide.
class GuideStep {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;   // e.g. "OPEN SETTINGS"
  final String? actionUrl;     // e.g. "tel:100"

  const GuideStep({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.actionUrl,
  });
}

/// Full-screen step-by-step guide walkthrough.
class GuideStepsScreen extends StatefulWidget {
  final String guideTitle;
  final Color accentColor;
  final List<GuideStep> steps;

  const GuideStepsScreen({
    super.key,
    required this.guideTitle,
    required this.accentColor,
    required this.steps,
  });

  @override
  State<GuideStepsScreen> createState() => _GuideStepsScreenState();
}

class _GuideStepsScreenState extends State<GuideStepsScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep++);
        _fadeController.forward();
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep--);
        _fadeController.forward();
      });
    }
  }

  void _finish() {
    Navigator.pop(context);
  }

  Future<void> _launchAction(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final progress = (_currentStep + 1) / widget.steps.length;
    final isLast = _currentStep == widget.steps.length - 1;
    final isFirst = _currentStep == 0;
    final accent = widget.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header: Close + Title ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.guideTitle,
                    style: GoogleFonts.spaceMono(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ── Progress Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    height: 4,
                    width: MediaQuery.of(context).size.width * progress * 0.9,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Step Content ──
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Circular Icon
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accent, width: 3),
                          color: accent.withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(step.icon, size: 60, color: accent),
                      ),

                      const SizedBox(height: 32),

                      // Step Counter
                      Text(
                        'S T E P   ${_currentStep + 1}',
                        style: GoogleFonts.spaceMono(
                          color: accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Description
                      Text(
                        step.description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom Buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  // Action button (if present)
                  if (step.actionLabel != null) ...[
                    GestureDetector(
                      onTap: step.actionUrl != null
                          ? () => _launchAction(step.actionUrl!)
                          : null,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.open_in_new, color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              step.actionLabel!,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Navigation row
                  _AnimatedHoverNavigation(
                    isFirst: isFirst,
                    isLast: isLast,
                    onPrev: _prevStep,
                    onNext: _nextStep,
                    onFinish: _finish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Pre-built guide data for each Protection Guide topic
// ═══════════════════════════════════════════════════════

final Map<String, List<GuideStep>> allGuideSteps = {
  'SIM Swap Protection': [
    const GuideStep(
      icon: Icons.signal_cellular_off,
      title: 'Recognize the Signs',
      description:
          'If your phone suddenly loses network signal for an extended period, '
          'you may be a SIM swap victim. Act immediately — every second counts.',
    ),
    const GuideStep(
      icon: Icons.phone_in_talk,
      title: 'Contact Your Carrier',
      description:
          'Call Safaricom (100), Airtel (100), or your carrier from another phone '
          'to report the suspicious SIM swap and request an immediate block.',
      actionLabel: 'CALL SAFARICOM',
      actionUrl: 'tel:100',
    ),
    const GuideStep(
      icon: Icons.account_balance,
      title: 'Lock Your Accounts',
      description:
          'Call your bank immediately to freeze online and mobile banking. '
          'Your SIM is the key to M-Pesa and SMS-based authentication.',
    ),
    const GuideStep(
      icon: Icons.local_police,
      title: 'Report to Police',
      description:
          'File a report at the nearest police station or through the eCitizen portal. '
          'You\'ll need the OB number for insurance or bank claims.',
    ),
    const GuideStep(
      icon: Icons.visibility,
      title: 'Monitor Your Accounts',
      description:
          'For the next 30 days, watch all your bank statements and M-Pesa history '
          'for unauthorized transactions. Report anything suspicious immediately.',
    ),
  ],

  'Social Media Safety': [
    const GuideStep(
      icon: Icons.verified_user,
      title: 'Enable Two-Factor Authentication',
      description:
          'Add 2FA to all your social media accounts. Use an authenticator app '
          'like Google Authenticator instead of SMS for stronger security.',
    ),
    const GuideStep(
      icon: Icons.privacy_tip,
      title: 'Review Privacy Settings',
      description:
          'Limit who can see your posts, friends list, and personal information. '
          'Set your profile to private and restrict friend requests to friends-of-friends.',
    ),
    const GuideStep(
      icon: Icons.link_off,
      title: 'Beware of Phishing Links',
      description:
          'Don\'t click suspicious links in DMs or comments, even from friends. '
          'Hackers often hijack accounts and send malicious links to contacts.',
    ),
    const GuideStep(
      icon: Icons.key,
      title: 'Use Strong Passwords',
      description:
          'Use a unique, complex password for each social media account. '
          'Never reuse your email or banking password for social media.',
    ),
    const GuideStep(
      icon: Icons.app_settings_alt,
      title: 'Audit Connected Apps',
      description:
          'Remove third-party apps and website logins you no longer use. '
          'These forgotten connections can become backdoors for attackers.',
    ),
  ],

  'Banking Security': [
    const GuideStep(
      icon: Icons.lock,
      title: 'Never Share PINs or OTPs',
      description:
          'Your M-Pesa PIN, ATM PIN, and one-time passwords should never be shared '
          'with anyone — not even someone claiming to be from your bank or Safaricom.',
    ),
    const GuideStep(
      icon: Icons.person_search,
      title: 'Verify Before Transacting',
      description:
          'Always confirm the recipient\'s name before completing M-Pesa or bank '
          'transfers. A wrong transaction is very difficult to reverse.',
    ),
    const GuideStep(
      icon: Icons.download,
      title: 'Use Official Apps Only',
      description:
          'Download banking apps only from Google Play Store or Apple App Store. '
          'Fake banking apps are a common tool for stealing credentials.',
    ),
    const GuideStep(
      icon: Icons.notifications_active,
      title: 'Enable Transaction Alerts',
      description:
          'Set up SMS and email notifications for all account activity. '
          'Instant alerts help you catch unauthorized transactions immediately.',
    ),
    const GuideStep(
      icon: Icons.report_problem,
      title: 'Report Fraud Immediately',
      description:
          'If you notice unauthorized activity, call your bank\'s fraud line and '
          'Safaricom\'s M-Pesa support (234) without delay.',
      actionLabel: 'CALL M-PESA SUPPORT',
      actionUrl: 'tel:234',
    ),
  ],

  'Identity Theft Guard': [
    const GuideStep(
      icon: Icons.badge,
      title: 'Guard Your ID Documents',
      description:
          'Never share photos of your National ID, passport, or KRA PIN on social media '
          'or with unverified websites. Criminals use these to open accounts in your name.',
    ),
    const GuideStep(
      icon: Icons.delete_sweep,
      title: 'Shred Sensitive Documents',
      description:
          'Destroy old bank statements, utility bills, and any documents containing '
          'personal information. Dumpster diving is a real threat.',
    ),
    const GuideStep(
      icon: Icons.credit_score,
      title: 'Monitor Your Credit',
      description:
          'Check your CRB (Credit Reference Bureau) report regularly for unauthorized '
          'loans or accounts opened in your name. You can check via Metropol or TransUnion.',
    ),
    const GuideStep(
      icon: Icons.security,
      title: 'Be Cautious Online',
      description:
          'Avoid entering personal details on unfamiliar or unsecured websites. '
          'Look for the padlock icon (HTTPS) before submitting any information.',
    ),
    const GuideStep(
      icon: Icons.emergency,
      title: 'Act Fast If Compromised',
      description:
          'Report identity theft to the DCI Cybercrime Unit immediately. '
          'File an official complaint and notify your bank and mobile provider.',
      actionLabel: 'CALL DCI CYBERCRIME',
      actionUrl: 'tel:0800723253',
    ),
  ],

  'Password Health': [
    const GuideStep(
      icon: Icons.text_fields,
      title: 'Use Long, Unique Passwords',
      description:
          'Each account should have a password of at least 12 characters mixing '
          'uppercase, lowercase, numbers, and symbols. Length beats complexity.',
    ),
    const GuideStep(
      icon: Icons.manage_accounts,
      title: 'Use a Password Manager',
      description:
          'Apps like Bitwarden or Google Password Manager store all your passwords '
          'securely so you only need to remember one master password.',
    ),
    const GuideStep(
      icon: Icons.block,
      title: 'Never Reuse Passwords',
      description:
          'If one service is breached, reused passwords expose all your other accounts. '
          'Each account must have its own unique password.',
    ),
    const GuideStep(
      icon: Icons.sync_problem,
      title: 'Change Compromised Passwords',
      description:
          'If a service reports a data breach, change your password there immediately. '
          'Check haveibeenpwned.com to see if your email has been exposed.',
    ),
    const GuideStep(
      icon: Icons.abc,
      title: 'Try Passphrases',
      description:
          'Combine random words like "Sunset-Mango-River-42" for passwords that are '
          'both strong and easy to remember. Avoid common phrases or song lyrics.',
    ),
  ],

  'Wi-Fi Security': [
    const GuideStep(
      icon: Icons.wifi_off,
      title: 'Avoid Public Wi-Fi for Banking',
      description:
          'Never access banking, M-Pesa, or other sensitive accounts on public '
          'Wi-Fi at restaurants, malls, or airports. Use mobile data instead.',
    ),
    const GuideStep(
      icon: Icons.vpn_lock,
      title: 'Use a VPN',
      description:
          'A Virtual Private Network encrypts all your data on public networks, '
          'making it invisible to hackers on the same Wi-Fi.',
    ),
    const GuideStep(
      icon: Icons.router,
      title: 'Secure Your Home Wi-Fi',
      description:
          'Change the default router password and Wi-Fi name. Use WPA3 or WPA2 '
          'encryption — never leave your network open or use WEP.',
    ),
    const GuideStep(
      icon: Icons.delete_forever,
      title: 'Forget Old Networks',
      description:
          'Remove saved Wi-Fi networks you no longer use from your device. '
          'Your phone could auto-connect to a malicious network with the same name.',
    ),
    const GuideStep(
      icon: Icons.warning_amber,
      title: 'Watch for Fake Hotspots',
      description:
          'Hackers create fake Wi-Fi networks that mimic coffee shops, hotels, or '
          'airports. Always confirm the exact network name with staff before connecting.',
    ),
  ],
};

class _AnimatedHoverNavigation extends StatefulWidget {
  final bool isFirst;
  final bool isLast;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  const _AnimatedHoverNavigation({
    required this.isFirst,
    required this.isLast,
    required this.onPrev,
    required this.onNext,
    required this.onFinish,
  });

  @override
  State<_AnimatedHoverNavigation> createState() => _AnimatedHoverNavigationState();
}

class _AnimatedHoverNavigationState extends State<_AnimatedHoverNavigation> {
  // 0 = left (back), 1 = right (next/finish)
  // Default to 1 (next/finish) as it is the primary action
  int _hoverIndex = 1; 

  @override
  Widget build(BuildContext context) {
    // Colors based on the provided screenshot
    final outerBorderColor = Colors.white.withOpacity(0.4);
    final outerBgColor = Colors.white.withOpacity(0.05);
    final activeGradient = const LinearGradient(
      colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    final activeBorderColor = const Color(0xFFFFD54F);
    final activeGlowColor = const Color(0xFFFF9800).withOpacity(0.6);

    final textStyle = GoogleFonts.inter(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );

    // If it's the first step, there's only one button.
    if (widget.isFirst && !widget.isLast) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 600
                ? MediaQuery.of(context).size.width * 0.5
                : double.infinity,
          ),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoverIndex = 1),
            onExit: (_) => setState(() => _hoverIndex = 1), // always 1
            child: GestureDetector(
              onTap: widget.onNext,
              child: Container(
                height: 58,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: outerBgColor, 
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: outerBorderColor, width: 1.5),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: activeGradient,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: activeBorderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: activeGlowColor,
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text('NEXT STEP', style: textStyle),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (widget.isFirst && widget.isLast) {
      // Single step guide
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 600
                ? MediaQuery.of(context).size.width * 0.5
                : double.infinity,
          ),
          child: GestureDetector(
            onTap: widget.onFinish,
            child: Container(
              height: 58,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: outerBgColor, 
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: outerBorderColor, width: 1.5),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: activeGradient,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: activeBorderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: activeGlowColor,
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text('FINISH', style: textStyle),
              ),
            ),
          ),
        ),
      );
    }

    // For 2 buttons:
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width > 600
              ? MediaQuery.of(context).size.width * 0.5
              : double.infinity,
        ),
        child: Container(
          height: 58,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: outerBgColor, 
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: outerBorderColor, width: 1.5),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 2;
              return Stack(
                children: [
                  // Animated background pill
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: _hoverIndex == 0 ? 0 : tabWidth,
                    width: tabWidth,
                    height: constraints.maxHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: activeGradient,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: activeBorderColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: activeGlowColor,
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Buttons
                  Row(
                    children: [
                      // BACK
                      Expanded(
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hoverIndex = 0),
                          onExit: (_) => setState(() => _hoverIndex = 1),
                          child: GestureDetector(
                            onTap: widget.onPrev,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              alignment: Alignment.center,
                              child: Text('BACK', style: textStyle),
                            ),
                          ),
                        ),
                      ),
                      // NEXT
                      Expanded(
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hoverIndex = 1),
                          onExit: (_) => setState(() => _hoverIndex = 1),
                          child: GestureDetector(
                            onTap: widget.isLast ? widget.onFinish : widget.onNext,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(widget.isLast ? 'FINISH' : 'NEXT STEP', style: textStyle),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
