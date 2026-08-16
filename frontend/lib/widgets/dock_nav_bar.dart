import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/chonjo_intro_screen.dart';
import '../utils/translations.dart';

/// Floating dock that starts as a single centre circle.
/// Tapping it expands 8 icon tiles — 4 slide left, 4 slide right.
///
/// Left side  (index 0–3): home · intel · mulika · boma
/// Centre:                 menu / close
/// Right side (index 4–7): chonjo · vault · agent · logout
class DockNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onLogout;

  const DockNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onLogout,
  });

  @override
  State<DockNavBar> createState() => _DockNavBarState();
}

class _DockNavBarState extends State<DockNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandController;
  bool _isOpen = false;

  double _leftPanOffset = 0.0;
  double _rightPanOffset = 0.0;

  late final List<Animation<double>> _slideAnims;
  late final List<Animation<double>> _fadeAnims;
  late final Animation<double> _glowAnim;

  static const double _gap = 5.0;
  static const double _mobileBreakpoint = 480.0;

  static const List<({String svg, String label, int navIndex})> _leftItems = [
    (svg: 'assets/icons/home.svg', label: 'nav_home', navIndex: 3),
    (svg: 'assets/icons/intel.svg', label: 'nav_intel', navIndex: 4),
    (svg: 'assets/icons/mulika.svg', label: 'nav_mulika', navIndex: 2),
    (svg: 'assets/icons/security_modules.svg', label: 'nav_secure_modules', navIndex: 1),
  ];

  static const List<({String svg, String label, int navIndex, bool isLogout})>
  _rightItems = [
    (
      svg: 'assets/icons/chonjo.svg',
      label: 'Chonjo', // This doesn't need translation according to user
      navIndex: 6,
      isLogout: false,
    ),
    (
      svg: 'assets/icons/vault.svg',
      label: 'nav_vault',
      navIndex: 0,
      isLogout: false,
    ),
    (
      svg: 'assets/icons/agent.svg',
      label: 'nav_agent',
      navIndex: 5,
      isLogout: false,
    ),
    (
      svg: 'assets/icons/logout.svg',
      label: 'settings_logout',
      navIndex: -1,
      isLogout: true,
    ),
  ];

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < _mobileBreakpoint;

  double _centreSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w < _mobileBreakpoint ? 40.0 : 72.0;
  }

  double _tileSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < _mobileBreakpoint) {
      final available = w - 32 - 40 - _gap * 10;
      return (available / 8).clamp(26.0, 34.0);
    }
    return 58.0;
  }

  @override
  void initState() {
    super.initState();

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );

    _slideAnims = List.generate(8, (i) {
      final start = (i * 0.07).clamp(0.0, 0.55);
      final end = (start + 0.50).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _expandController,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      );
    });

    _fadeAnims = List.generate(8, (i) {
      final start = (i * 0.06).clamp(0.0, 0.5);
      final end = (start + 0.38).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _expandController,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleDock() {
    if (_isOpen) {
      _expandController.reverse().then((_) {
        if (mounted)
          setState(() {
            _isOpen = false;
            _leftPanOffset = 0;
            _rightPanOffset = 0;
          });
      });
    } else {
      setState(() {
        _isOpen = true;
        _leftPanOffset = 0;
        _rightPanOffset = 0;
      });
      _expandController.forward(from: 0);
    }
  }

  void _onTileTap({required int navIndex, required bool isLogout}) {
    // Collapse dock first, then act.
    _expandController.reverse().then((_) {
      if (mounted)
        setState(() {
          _isOpen = false;
          _leftPanOffset = 0;
          _rightPanOffset = 0;
        });
    });

    if (isLogout) {
      if (widget.onLogout != null) {
        widget.onLogout!();
      } else {
        try {
          context.read<AuthService>().logout();
        } catch (_) {
          debugPrint('DockNavBar: no AuthService found in context for logout');
        }
      }
    } else if (navIndex == 6) {
      // Chonjo: push the intro/briefing screen so the full flow is
      // Dock → ChonjoIntroScreen → ChonjoLevelsScreen → ChonjoGameScreen.
      // Does NOT call widget.onTap so the shell index stays unchanged.
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ChonjoIntroScreen()));
    } else {
      widget.onTap(navIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double cs = _centreSize(context);
    final double ts = _tileSize(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedBuilder(
          animation: _expandController,
          builder: (ctx, _) => _buildDock(ctx, cs, ts),
        ),
      ),
    );
  }

  Widget _buildDock(BuildContext context, double cs, double ts) {
    final double slotW = ts + _gap;
    final double fullWidth = cs + slotW * 8 + _gap * 2;
    final bool isMobile = _isMobile(context);
    final double screenW = MediaQuery.of(context).size.width;
    final double windowWidth = isMobile
        ? (fullWidth > screenW - 32 ? screenW - 32 : fullWidth)
        : fullWidth;
    final double sideExtent = cs / 2 + 4 * ts + 5 * _gap;
    final double halfWindow = windowWidth / 2;
    final double sideMaxPan = (sideExtent - halfWindow).clamp(
      0.0,
      double.infinity,
    );

    return SizedBox(
      width: windowWidth,
      height: cs + 20,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          _buildPillBackdrop(windowWidth, cs),
          ClipRRect(
            borderRadius: BorderRadius.circular(48),
            child: SizedBox(
              width: windowWidth,
              height: cs + 4,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  _buildSideTiles(
                    isLeft: true,
                    ts: ts,
                    cs: cs,
                    halfWindow: halfWindow,
                    sideExtent: sideExtent,
                    maxPan: sideMaxPan,
                    isMobile: isMobile,
                  ),
                  _buildSideTiles(
                    isLeft: false,
                    ts: ts,
                    cs: cs,
                    halfWindow: halfWindow,
                    sideExtent: sideExtent,
                    maxPan: sideMaxPan,
                    isMobile: isMobile,
                  ),
                ],
              ),
            ),
          ),
          _buildCentreButton(cs),
        ],
      ),
    );
  }

  Widget _buildSideTiles({
    required bool isLeft,
    required double ts,
    required double cs,
    required double halfWindow,
    required double sideExtent,
    required double maxPan,
    required bool isMobile,
  }) {
    final Alignment anchor = isLeft
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final Widget tiles = SizedBox(
      width: sideExtent,
      height: cs + 20,
      child: Stack(
        alignment: anchor,
        clipBehavior: Clip.none,
        children: isLeft ? _buildLeftTiles(ts, cs) : _buildRightTiles(ts, cs),
      ),
    );

    final double panValue = isLeft ? _leftPanOffset : _rightPanOffset;

    if (maxPan > 0) {
      return Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: ClipRect(
          child: SizedBox(
            width: halfWindow,
            height: cs + 20,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: isMobile
                  ? (d) {
                      setState(() {
                        if (isLeft) {
                          _leftPanOffset = (_leftPanOffset + d.delta.dx).clamp(
                            0.0,
                            maxPan,
                          );
                        } else {
                          _rightPanOffset = (_rightPanOffset + d.delta.dx)
                              .clamp(-maxPan, 0.0);
                        }
                      });
                    }
                  : null,
              child: OverflowBox(
                minWidth: sideExtent,
                maxWidth: sideExtent,
                alignment: anchor,
                child: Transform.translate(
                  offset: Offset(panValue, 0),
                  child: tiles,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: tiles,
    );
  }

  Widget _buildPillBackdrop(double windowWidth, double cs) {
    final double maxExtra = windowWidth - cs;
    final double pillW = cs + maxExtra * _expandController.value;
    return Opacity(
      opacity: _expandController.value.clamp(0.0, 1.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(48),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: pillW,
            height: cs + 4,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A22).withOpacity(0.72),
              borderRadius: BorderRadius.circular(48),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLeftTiles(double ts, double cs) {
    return List.generate(_leftItems.length, (i) {
      final item = _leftItems[i];
      final slots = _leftItems.length - i;
      final targetX = -(cs / 2 + _gap + (slots - 1) * (ts + _gap));
      final currentX = targetX * _slideAnims[i].value;
      final isActive = widget.currentIndex == item.navIndex;
      return Positioned(
        child: Transform.translate(
          offset: Offset(currentX, 0),
          child: Opacity(
            opacity: _fadeAnims[i].value,
            child: _DockTile(
              svgPath: item.svg,
              label: context.tr(item.label),
              navIndex: item.navIndex,
              isActive: isActive,
              isLogout: false,
              ts: ts,
              onTap: () => _onTileTap(navIndex: item.navIndex, isLogout: false),
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildRightTiles(double ts, double cs) {
    return List.generate(_rightItems.length, (i) {
      final item = _rightItems[i];
      final slots = i + 1;
      final targetX = cs / 2 + _gap + (slots - 1) * (ts + _gap);
      final currentX = targetX * _slideAnims[i + 4].value;
      final isActive = widget.currentIndex == item.navIndex;
      return Positioned(
        child: Transform.translate(
          offset: Offset(currentX, 0),
          child: Opacity(
            opacity: _fadeAnims[i + 4].value,
            child: _DockTile(
              svgPath: item.svg,
              label: context.tr(item.label),
              navIndex: item.navIndex,
              isActive: isActive,
              isLogout: item.isLogout,
              ts: ts,
              onTap: () =>
                  _onTileTap(navIndex: item.navIndex, isLogout: item.isLogout),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCentreButton(double cs) {
    return GestureDetector(
      onTap: _toggleDock,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: cs,
        height: cs,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isOpen)
              Container(
                width: cs,
                height: cs,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFFF7A00,
                      ).withOpacity(0.50 * _glowAnim.value),
                      blurRadius: 28 * _glowAnim.value,
                      spreadRadius: 4 * _glowAnim.value,
                    ),
                  ],
                ),
              ),
            Container(
              width: cs,
              height: cs,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    const Color(
                      0xFFFF4500,
                    ).withOpacity(_isOpen ? _glowAnim.value : 0.55),
                    const Color(
                      0xFFFF9800,
                    ).withOpacity(_isOpen ? _glowAnim.value : 0.55),
                    const Color(
                      0xFFFFD700,
                    ).withOpacity(_isOpen ? _glowAnim.value * 0.6 : 0.3),
                    Colors.transparent,
                    const Color(
                      0xFFFF4500,
                    ).withOpacity(_isOpen ? _glowAnim.value * 0.4 : 0.3),
                  ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
            ),
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: cs - 5,
                  height: cs - 5,
                  color: const Color(0xFF252530).withOpacity(0.88),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => RotationTransition(
                        turns: child.key == const ValueKey('close')
                            ? Tween(begin: 0.25, end: 0.0).animate(anim)
                            : Tween(begin: -0.25, end: 0.0).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: _isOpen
                          ? SvgPicture.asset(
                              'assets/icons/close.svg',
                              key: const ValueKey('close'),
                              width: cs * 0.55,
                              height: cs * 0.55,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/icons/menu.svg',
                              key: const ValueKey('menu'),
                              width: cs * 0.55,
                              height: cs * 0.55,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                    ),
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

// ── Individual SVG tile with hover state ─────────────────────────────────────
class _DockTile extends StatefulWidget {
  final String svgPath;
  final String label;
  final int navIndex;
  final bool isActive;
  final bool isLogout;
  final double ts;
  final VoidCallback onTap;

  const _DockTile({
    required this.svgPath,
    required this.label,
    required this.navIndex,
    required this.isActive,
    required this.isLogout,
    required this.ts,
    required this.onTap,
  });

  @override
  State<_DockTile> createState() => _DockTileState();
}

class _DockTileState extends State<_DockTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFFFF9800);
    final Color logoutColor = const Color(0xFFFF4444);
    final Color defaultColor = Colors.white.withOpacity(0.60);
    final Color hoverColor = const Color(0xFFFFB74D);

    final Color iconColor = widget.isLogout
        ? logoutColor
        : (widget.isActive
              ? activeColor
              : (_isHovered ? hoverColor : defaultColor));

    final Color borderColor = widget.isLogout
        ? logoutColor.withOpacity(0.55)
        : (widget.isActive
              ? const Color(0xFFFF7A00).withOpacity(0.55)
              : (_isHovered
                    ? hoverColor.withOpacity(0.3)
                    : Colors.white.withOpacity(0.09)));

    final Color bgColor = widget.isActive
        ? const Color(0xFF2E3040).withOpacity(0.90)
        : (_isHovered
              ? const Color(0xFF383A4A).withOpacity(0.7)
              : const Color(0xFF2A2A38).withOpacity(0.55));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.label,
        preferBelow: false,
        verticalOffset: widget.ts / 2 + 12,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A22).withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.ts,
            height: widget.ts,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(widget.ts * 0.28),
              border: Border.all(
                color: borderColor,
                width: widget.isActive ? 1.5 : 1,
              ),
              boxShadow: widget.isActive || widget.isLogout || _isHovered
                  ? [
                      BoxShadow(
                        color: iconColor.withOpacity(
                          widget.isActive || widget.isLogout ? 0.25 : 0.4,
                        ),
                        blurRadius: _isHovered ? 20 : 14,
                        spreadRadius: _isHovered ? 2 : 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(begin: defaultColor, end: iconColor),
                duration: const Duration(milliseconds: 200),
                builder: (context, color, _) => SvgPicture.asset(
                  widget.svgPath,
                  width: widget.ts * 0.60,
                  height: widget.ts * 0.60,
                  colorFilter: ColorFilter.mode(
                    color ?? iconColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
