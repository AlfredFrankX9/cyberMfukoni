import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'intel_feed_screen.dart';
import 'chonjo_levels_screen.dart';
import 'mulika_screen.dart';
import 'boma_screen.dart';
import 'agent_screen.dart';
import 'chonjo_intro_screen.dart';
import 'permission_auditor_screen.dart';
import 'secure_shredder_screen.dart';
import 'smart_scan_screen.dart';
import 'dns_filter_screen.dart';
import 'secure_modules_screen.dart';
import '../utils/auth_helper.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// Plain data holder for a module tile — used both to build the grid and to
// hit-test finger position against each tile during touch-drag (see
// _handlePointerPosition). Keeping this as a single source of truth means
// the grid and the hit-test always agree on order/content.
class _ModuleDef {
  final String title;
  final String bgImage;
  final Color color;
  final VoidCallback onTap;
  const _ModuleDef({
    required this.title,
    required this.bgImage,
    required this.color,
    required this.onTap,
  });
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  int _cyberSafetyScore = 85;
  String _username = "Agent";
  String? _hoveredImage;

  // One GlobalKey per module tile so we can look up each tile's live
  // on-screen RenderBox (position/size) during a touch drag, regardless of
  // scroll offset — the key always points at the currently-built widget.
  final List<GlobalKey> _cardKeys = List.generate(5, (_) => GlobalKey());

  List<_ModuleDef> get _moduleDefs => [
    _ModuleDef(
      title: 'Threat Intel',
      bgImage: 'assets/images/ThreatIntelBackround.webp',
      color: const Color(0xFF00FF40),
      onTap: () => _navigateTo(4),
    ),
    _ModuleDef(
      title: 'Mulika AI',
      bgImage: 'assets/images/mulikaBacground.webp',
      color: const Color(0xFF32CD32),
      onTap: () => _navigateTo(2),
    ),
    _ModuleDef(
      title: 'Chonjo',
      bgImage: 'assets/images/chonjoBackground.webp',
      color: const Color(0xFFA8FF00),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ChonjoIntroScreen())),
    ),
    _ModuleDef(
      title: 'Secure Vault',
      bgImage: 'assets/images/vaultbackground.webp',
      color: const Color(0xFF00FF40),
      onTap: () => _navigateTo(0),
    ),
    _ModuleDef(
      title: 'Secure',
      bgImage: 'assets/images/secure.webp',
      color: const Color(0xFF00FF40),
      onTap: () async {
        final ok = await AuthHelper.authenticate(context);
        if (ok && mounted) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecureModulesScreen()));
        }
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await ApiService.get('/api/auth/me');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _username = data['username'] ?? "Agent";
          final score = (data['total_score'] as num?)?.toInt() ?? 0;
          _cyberSafetyScore = 40 + (score / 100).clamp(0, 60).toInt();
        });
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateTo(int index) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
    }
  }

  // ── Touch-drag "hover" ──────────────────────────────────────────────────
  // Mirrors what MouseRegion gives desktop for free: as a finger moves
  // across the grid (including while the ScrollView is being dragged),
  // whichever card is currently under it becomes the background image.
  // Lifting the finger reverts to the default background, matching
  // MouseRegion's onExit behavior.
  void _handlePointerPosition(Offset globalPosition) {
    String? matchedImage;
    final defs = _moduleDefs;
    for (int i = 0; i < _cardKeys.length && i < defs.length; i++) {
      final ctx = _cardKeys[i].currentContext;
      if (ctx == null) continue;
      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) continue;
      final topLeft = renderBox.localToGlobal(Offset.zero);
      final rect = topLeft & renderBox.size;
      if (rect.contains(globalPosition)) {
        matchedImage = defs[i].bgImage;
        break;
      }
    }
    if (matchedImage != _hoveredImage) {
      setState(() => _hoveredImage = matchedImage);
    }
  }

  void _clearPointerHover() {
    if (_hoveredImage != null) {
      setState(() => _hoveredImage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          // Dynamic background cross-fade
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: SizedBox.expand(
                key: ValueKey(_hoveredImage ?? 'default'),
                child: Image.asset(
                  _hoveredImage ?? 'assets/images/dashboardbackground.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFF0A0C10)),
                ),
              ),
            ),
          ),
          // Dark overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.70)),
          ),

          // Scrollable main content — clipped so it can NEVER scroll behind the dock
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // Stops 90px above the bottom — the dock shelf height
            bottom: 90,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Listener(
                      // translucent so this never blocks scroll/tap gestures
                      // underneath it — it only observes raw pointer events.
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (e) => _handlePointerPosition(e.position),
                      onPointerMove: (e) => _handlePointerPosition(e.position),
                      onPointerUp: (_) => _clearPointerHover(),
                      onPointerCancel: (_) => _clearPointerHover(),
                      child: ShaderMask(
                        // Fade the last 80px of the scroll area to transparent
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: const [
                              Colors.white,
                              Colors.white,
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.78, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: isWide ? size.width * 0.08 : 20.0,
                            right: isWide ? size.width * 0.08 : 20.0,
                            top: 20,
                            bottom: 80,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHealthCard(),
                              const SizedBox(height: 30),
                              Text(
                                'QUICK ACTIONS',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  color: const Color(0xFFC0C0C0),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildQuickActions(),
                              const SizedBox(height: 30),
                              Text(
                                'SECURITY MODULES',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  color: const Color(0xFFC0C0C0),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildModulesGrid(isWide, size),
                              const SizedBox(height: 40),
                              Text(
                                'RECENT ACTIVITY',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  color: const Color(0xFFC0C0C0),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildActivityLog(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A1A),
                  border: Border.all(
                    color: const Color(0xFF32CD32).withOpacity(0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF32CD32).withOpacity(0.2),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.security,
                  color: Color(0xFF00FF40),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: const Color(0xFFB0B0B0),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFB0B0B0)),
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
    );
  }

  // ─── Cyber safety card ────────────────────────────────────────────────────
  Widget _buildHealthCard() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glow = 0.6 + 0.4 * _pulseController.value;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF222633),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF32CD32).withOpacity(0.3 * glow),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF32CD32).withOpacity(0.15 * glow),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.shield_moon,
                    color: Color(0xFF00FF40),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SYSTEM STATUS',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00FF40),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Cyber Safety Score',
                style: GoogleFonts.inter(
                  color: const Color(0xFFC0C0C0),
                  fontSize: 14,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$_cyberSafetyScore',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF32CD32).withOpacity(0.8),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '/100',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB0B0B0),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF32CD32).withOpacity(0.5),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF32CD32,
                          ).withOpacity(0.2 * glow),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.verified_user,
                        color: Color(0xFF00FF40),
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _cyberSafetyScore / 100,
                backgroundColor: Colors.black,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFA8FF00),
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 16),
              Text(
                'SCORE BREAKDOWN',
                style: GoogleFonts.inter(
                  color: const Color(0xFFB0B0B0),
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildScoreBreakdownItem(
                Icons.lock,
                'Device Security',
                '30/30',
                const Color(0xFF00FF40),
              ),
              const SizedBox(height: 6),
              _buildScoreBreakdownItem(
                Icons.vpn_key,
                'Vault Setup',
                '10/20',
                const Color(0xFFFFC107),
              ),
              const SizedBox(height: 6),
              _buildScoreBreakdownItem(
                Icons.school,
                'Chonjo XP',
                '${(_cyberSafetyScore > 40) ? (_cyberSafetyScore - 40) : 0}/50',
                const Color(0xFF00FF40),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoreBreakdownItem(
    IconData icon,
    String label,
    String value,
    Color statusColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14, color: statusColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ─── Modules grid ─────────────────────────────────────────────────────────
  Widget _buildModulesGrid(bool isWide, Size size) {
    double itemWidth;
    double itemHeight;
    if (isWide) {
      final availableWidth =
          size.width * 0.84; // matches 0.08 padding each side
      itemWidth = (availableWidth - 48) / 3; // 2 gaps of 24px
      itemHeight = itemWidth * 0.85;
    } else {
      itemWidth = size.width - 40;
      itemHeight = itemWidth * 0.75;
    }

    final defs = _moduleDefs;
    final cards = List.generate(defs.length, (i) {
      final def = defs[i];
      return _buildModuleCard(
        key: _cardKeys[i],
        title: def.title,
        bgImage: def.bgImage,
        color: def.color,
        onTap: def.onTap,
      );
    });

    return Wrap(
      clipBehavior: Clip.none,
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 24,
      children: cards
          .map(
            (card) =>
                SizedBox(width: itemWidth, height: itemHeight, child: card),
          )
          .toList(),
    );
  }

  Widget _buildModuleCard({
    Key? key,
    required String title,
    required String bgImage,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _ModuleCardWidget(
      key: key,
      title: title,
      bgImage: bgImage,
      color: color,
      onTap: onTap,
      onHover: (isHovering) {
        if (isHovering) {
          setState(() => _hoveredImage = bgImage);
        } else {
          if (_hoveredImage == bgImage) {
            setState(() => _hoveredImage = null);
          }
        }
      },
    );
  }

  // ─── Quick Actions (infinite marquee) ───────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QuickActionData(
        icon: Icons.radar,
        label: 'SMART SCAN',
        color: const Color(0xFF00FF40),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SmartScanScreen()),
        ),
      ),
      _QuickActionData(
        icon: Icons.shield,
        label: 'APP PERMISSIONS',
        color: const Color(0xFF00FF40),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PermissionAuditorScreen()),
        ),
      ),
      _QuickActionData(
        icon: Icons.delete_forever,
        label: 'SECURE SHRED',
        color: const Color(0xFF32CD32),
        onTap: () async {
          final ok = await AuthHelper.authenticate(context);
          if (ok && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SecureShredderScreen()),
            );
          }
        },
      ),
      _QuickActionData(
        icon: Icons.vpn_lock,
        label: 'DNS FILTER',
        color: const Color(0xFF00FF40),
        onTap: () async {
          final ok = await AuthHelper.authenticate(context);
          if (ok && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DnsFilterScreen()),
            );
          }
        },
      ),
    ];

    return SizedBox(
      height: 50,
      child: _InfiniteMarquee(actions: actions),
    );
  }

  // ─── Activity Log ─────────────────────────────────────────────────────────
  Widget _buildActivityLog() {
    final List<Map<String, dynamic>> mockLogs = [
      {'icon': Icons.check_circle, 'color': const Color(0xFF00FF40), 'text': 'System scan clear. No threats detected.', 'time': 'Just now'},
      {'icon': Icons.vpn_lock, 'color': const Color(0xFF32CD32), 'text': 'Secure VPN connection established.', 'time': '2h ago'},
      {'icon': Icons.warning_amber, 'color': const Color(0xFFFFC107), 'text': 'Suspicious ad-tracker blocked.', 'time': '5h ago'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: mockLogs.map((log) {
          final isLast = mockLogs.last == log;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: log['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(log['icon'], color: log['color'], size: 20),
                ),
                title: Text(
                  log['text'],
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Text(
                  log['time'],
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.05),
                  indent: 70,
                  endIndent: 24,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ModuleCardWidget extends StatefulWidget {
  final String title;
  final String bgImage;
  final Color color;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _ModuleCardWidget({
    super.key,
    required this.title,
    required this.bgImage,
    required this.color,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_ModuleCardWidget> createState() => _ModuleCardWidgetState();
}

class _ModuleCardWidgetState extends State<_ModuleCardWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.onHover(true);
      },
      onExit: (_) {
        setState(() => _hovered = false);
        widget.onHover(false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          transform: Matrix4.translationValues(0, _hovered ? -12 : 0, 0),
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: const Color(0xFF222633).withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.95),
                      blurRadius: 30,
                      spreadRadius: -6,
                      offset: const Offset(0, 35),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      widget.bgImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: const Color(0xFF1A1A1A)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: widget.color,
                    width: _hovered ? 2.0 : 1.5,
                  ),
                  boxShadow: _hovered
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.35),
                            blurRadius: 14,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: widget.color.withOpacity(0.10),
                            blurRadius: 10,
                          ),
                        ],
                ),
                child: Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _InfiniteMarquee extends StatefulWidget {
  final List<_QuickActionData> actions;
  const _InfiniteMarquee({required this.actions});

  @override
  State<_InfiniteMarquee> createState() => _InfiniteMarqueeState();
}

class _InfiniteMarqueeState extends State<_InfiniteMarquee> {
  late final ScrollController _scrollController;
  bool _isPaused = false;
  Timer? _resumeTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    if (_isPaused || !_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final minScroll = _scrollController.position.minScrollExtent;
    
    final currentPosition = _scrollController.offset;
    final remainingDistance = maxScroll - currentPosition;
    
    if (remainingDistance <= 0) {
      _scrollController.jumpTo(minScroll);
      _startScrolling();
      return;
    }
    
    final durationMs = (remainingDistance / 40) * 1000;
    
    _scrollController.animateTo(
      maxScroll,
      duration: Duration(milliseconds: durationMs.toInt()),
      curve: Curves.linear,
    ).then((_) {
      if (mounted) {
        _scrollController.jumpTo(minScroll);
        _startScrolling();
      }
    });
  }

  void _pauseScrolling() {
    if (_isPaused) return;
    setState(() {
      _isPaused = true;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.offset);
    }
    _resetResumeTimer();
  }

  void _resetResumeTimer() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isPaused) {
        setState(() {
          _isPaused = false;
        });
        _startScrolling();
      }
    });
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];
    
    // Repeat items to allow smooth continuous scrolling
    for (int loop = 0; loop < 8; loop++) {
      for (int i = 0; i < widget.actions.length; i++) {
        final action = widget.actions[i];
        items.add(
          GestureDetector(
            onTap: () {
              // Execute immediately on tap
              action.onTap();
              // Briefly pause to prevent accidental subsequent clicks if moving
              _pauseScrolling();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF222633),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: action.color.withOpacity(0.3),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: action.color.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action.icon, color: action.color, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    action.label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        items.add(const SizedBox(width: 12));
      }
    }

    return GestureDetector(
      onTapDown: (_) {
        _pauseScrolling();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            _resumeTimer?.cancel();
          } else if (notification is ScrollEndNotification) {
            _resetResumeTimer();
          }
          return false;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: _isPaused
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: Row(
            children: items,
          ),
        ),
      ),
    );
  }
}
