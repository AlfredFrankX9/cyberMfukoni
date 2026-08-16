import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/translations.dart';

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
                        '${context.tr('guide_step')}   ${_currentStep + 1}',
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
                        context.tr(step.title),
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
                        context.tr(step.description),
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
                              context.tr(step.actionLabel!),
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
  'guide_sim_swap': [
    const GuideStep(
      icon: Icons.signal_cellular_off,
      title: 'guide_sim_1_title',
      description: 'guide_sim_1_desc',
    ),
    const GuideStep(
      icon: Icons.phone_in_talk,
      title: 'guide_sim_2_title',
      description: 'guide_sim_2_desc',
      actionLabel: 'guide_sim_2_action',
      actionUrl: 'tel:100',
    ),
    const GuideStep(
      icon: Icons.account_balance,
      title: 'guide_sim_3_title',
      description: 'guide_sim_3_desc',
    ),
    const GuideStep(
      icon: Icons.local_police,
      title: 'guide_sim_4_title',
      description: 'guide_sim_4_desc',
    ),
    const GuideStep(
      icon: Icons.visibility,
      title: 'guide_sim_5_title',
      description: 'guide_sim_5_desc',
    ),
  ],

  'guide_social': [
    const GuideStep(
      icon: Icons.verified_user,
      title: 'guide_soc_1_title',
      description: 'guide_soc_1_desc',
    ),
    const GuideStep(
      icon: Icons.privacy_tip,
      title: 'guide_soc_2_title',
      description: 'guide_soc_2_desc',
    ),
    const GuideStep(
      icon: Icons.link_off,
      title: 'guide_soc_3_title',
      description: 'guide_soc_3_desc',
    ),
    const GuideStep(
      icon: Icons.key,
      title: 'guide_soc_4_title',
      description: 'guide_soc_4_desc',
    ),
    const GuideStep(
      icon: Icons.app_settings_alt,
      title: 'guide_soc_5_title',
      description: 'guide_soc_5_desc',
    ),
  ],

  'guide_banking': [
    const GuideStep(
      icon: Icons.lock,
      title: 'guide_bnk_1_title',
      description: 'guide_bnk_1_desc',
    ),
    const GuideStep(
      icon: Icons.person_search,
      title: 'guide_bnk_2_title',
      description: 'guide_bnk_2_desc',
    ),
    const GuideStep(
      icon: Icons.download,
      title: 'guide_bnk_3_title',
      description: 'guide_bnk_3_desc',
    ),
    const GuideStep(
      icon: Icons.notifications_active,
      title: 'guide_bnk_4_title',
      description: 'guide_bnk_4_desc',
    ),
    const GuideStep(
      icon: Icons.report_problem,
      title: 'guide_bnk_5_title',
      description: 'guide_bnk_5_desc',
      actionLabel: 'guide_bnk_5_action',
      actionUrl: 'tel:234',
    ),
  ],

  'guide_identity': [
    const GuideStep(
      icon: Icons.badge,
      title: 'guide_id_1_title',
      description: 'guide_id_1_desc',
    ),
    const GuideStep(
      icon: Icons.delete_sweep,
      title: 'guide_id_2_title',
      description: 'guide_id_2_desc',
    ),
    const GuideStep(
      icon: Icons.credit_score,
      title: 'guide_id_3_title',
      description: 'guide_id_3_desc',
    ),
    const GuideStep(
      icon: Icons.security,
      title: 'guide_id_4_title',
      description: 'guide_id_4_desc',
    ),
    const GuideStep(
      icon: Icons.emergency,
      title: 'guide_id_5_title',
      description: 'guide_id_5_desc',
      actionLabel: 'guide_id_5_action',
      actionUrl: 'tel:0800723253',
    ),
  ],

  'guide_password': [
    const GuideStep(
      icon: Icons.text_fields,
      title: 'guide_pwd_1_title',
      description: 'guide_pwd_1_desc',
    ),
    const GuideStep(
      icon: Icons.manage_accounts,
      title: 'guide_pwd_2_title',
      description: 'guide_pwd_2_desc',
    ),
    const GuideStep(
      icon: Icons.block,
      title: 'guide_pwd_3_title',
      description: 'guide_pwd_3_desc',
    ),
    const GuideStep(
      icon: Icons.sync_problem,
      title: 'guide_pwd_4_title',
      description: 'guide_pwd_4_desc',
    ),
    const GuideStep(
      icon: Icons.abc,
      title: 'guide_pwd_5_title',
      description: 'guide_pwd_5_desc',
    ),
  ],

  'guide_wifi': [
    const GuideStep(
      icon: Icons.wifi_off,
      title: 'guide_wifi_1_title',
      description: 'guide_wifi_1_desc',
    ),
    const GuideStep(
      icon: Icons.vpn_lock,
      title: 'guide_wifi_2_title',
      description: 'guide_wifi_2_desc',
    ),
    const GuideStep(
      icon: Icons.router,
      title: 'guide_wifi_3_title',
      description: 'guide_wifi_3_desc',
    ),
    const GuideStep(
      icon: Icons.delete_forever,
      title: 'guide_wifi_4_title',
      description: 'guide_wifi_4_desc',
    ),
    const GuideStep(
      icon: Icons.warning_amber,
      title: 'guide_wifi_5_title',
      description: 'guide_wifi_5_desc',
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
                  child: Text(context.tr('', fallback: 'NEXT STEP'), style: textStyle),
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
                child: Text(context.tr('', fallback: 'FINISH'), style: textStyle),
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
                              child: Text(context.tr('', fallback: 'BACK'), style: textStyle),
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
                              child: Text(widget.isLast ? (context.tr('', fallback: 'FINISH')) : (context.tr('', fallback: 'NEXT STEP')), style: textStyle),
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
