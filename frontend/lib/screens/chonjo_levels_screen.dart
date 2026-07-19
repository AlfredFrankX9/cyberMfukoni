import 'package:flutter/material.dart';
import 'chonjo_game_screen.dart';

enum LevelStatus { locked, current, completed }

class _LevelNode {
  final int id;
  final Offset position; // fractional (0-1) position over the background image
  final Color glowColor;
  LevelStatus status;

  _LevelNode({
    required this.id,
    required this.position,
    required this.glowColor,
    required this.status,
  });
}

class ChonjoLevelsScreen extends StatefulWidget {
  /// How many levels the player has unlocked so far (1 = only Level 1 open).
  /// Defaults to 10 (all unlocked) to match a fully-open level map.
  final int unlockedCount;

  final ValueChanged<int>? onNavigate;

  const ChonjoLevelsScreen({
    super.key,
    this.unlockedCount = 10,
    this.onNavigate,
  });

  @override
  State<ChonjoLevelsScreen> createState() => _ChonjoLevelsScreenState();
}

class _ChonjoLevelsScreenState extends State<ChonjoLevelsScreen>
    with TickerProviderStateMixin {
  static const Color kCyberGreen = Color(0xFF00FF66);

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  late List<_LevelNode> _nodes;

  // Positions calibrated to sit ON the staircase rails in the reference art.
  // Lower rail: 1-5 left→right; Upper rail: 6-10 left→right
  static const List<Offset> _positions = [
    // Bottom Row: 1 to 5
    Offset(0.150, 0.650),
    Offset(0.325, 0.650),
    Offset(0.500, 0.650),
    Offset(0.675, 0.650),
    Offset(0.850, 0.650),
    // Top Row: 6 to 10
    Offset(0.150, 0.350),
    Offset(0.325, 0.350),
    Offset(0.500, 0.350),
    Offset(0.675, 0.350),
    Offset(0.850, 0.350),
  ];

  static const List<Offset> _mobilePositions = [
    // Row 1 (Bottom, nodes 1-3)
    Offset(0.18, 0.70), Offset(0.50, 0.70), Offset(0.82, 0.70),
    // Row 2 (nodes 4-5)
    Offset(0.34, 0.52), Offset(0.66, 0.52),
    // Row 3 (nodes 6-8)
    Offset(0.18, 0.34), Offset(0.50, 0.34), Offset(0.82, 0.34),
    // Row 4 (Top, nodes 9-10)
    Offset(0.34, 0.16), Offset(0.66, 0.16),
  ];

  static const List<Color> _glowColors = [
    Color(0xFF2196F3), // 1 blue
    Color(0xFF4CAF50), // 2 green
    Color(0xFFFF9800), // 3 orange
    Color(0xFF9C27B0), // 4 purple
    Color(0xFFFF1744), // 5 red
    Color(0xFF00E5FF), // 6 cyan
    Color(0xFFFF9800), // 7 orange
    Color(0xFFE91E8C), // 8 pink
    Color(0xFF2196F3), // 9 blue
    Color(0xFF4CAF50), // 10 green
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _nodes = List.generate(10, (i) {
      final id = i + 1;
      LevelStatus status;
      if (id < widget.unlockedCount) {
        status = LevelStatus.completed;
      } else if (id == widget.unlockedCount) {
        status = LevelStatus.current;
      } else {
        status = LevelStatus.locked;
      }
      return _LevelNode(
        id: id,
        position: _positions[i],
        glowColor: _glowColors[i],
        status: status,
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onLevelTap(_LevelNode node) {
    if (node.status == LevelStatus.locked) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChonjoGameScreen(initialLevel: node.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Globe / world background
          Positioned.fill(
            child: Image.asset(
              'assets/images/levelbackground.webp',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.18)),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return Stack(
                        children: [
                          for (final node in _nodes) _buildNode(node, size),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 4),
                  child: Text(
                    'Tap a level to begin',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.55),
                      fontWeight: FontWeight.w500,
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo + brand text, exactly as in the reference screenshots
          Image.asset('assets/images/logo.webp', height: 140),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
          ),
          const Spacer(),
          // Close / back button — circular as in image 1
          GestureDetector(
            onTap: () {
              if (widget.onNavigate != null) {
                widget.onNavigate!(3);
              } else {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.55),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Icon(
                Icons.close,
                color: Colors.white.withOpacity(0.8),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(_LevelNode node, Size size) {
    final bool isMobile = size.width < 480;
    final pos = isMobile
        ? _mobilePositions[node.id - 1]
        : _positions[node.id - 1];
    final center = Offset(pos.dx * size.width, pos.dy * size.height);
    final double d = isMobile
        ? 64
        : 96; // bigger nodes to match reference on desktop
    final bool isLocked = node.status == LevelStatus.locked;
    final bool isCurrent = node.status == LevelStatus.current;
    final Color glow = isLocked
        ? Colors.white.withOpacity(0.15)
        : node.glowColor;

    // XP rewards per level
    final List<String> xpLabels = [
      '',
      '250XP',
      '500XP',
      '800XP',
      '1200XP',
      '1700XP',
      '2500XP',
      '3500XP',
      '5000XP',
      '',
    ];
    final String xpLabel = node.id <= 9 && node.id >= 2
        ? xpLabels[node.id - 1]
        : '';

    return Positioned(
      left: center.dx - d / 2,
      top: center.dy - d / 2,
      child: GestureDetector(
        onTap: () => _onLevelTap(node),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                final pulse = isCurrent ? _pulseAnim.value : 1.0;
                return Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(isLocked ? 0.60 : 0.30),
                    border: Border.all(
                      color: glow,
                      width: isCurrent ? 3.5 : 2.5,
                    ),
                    boxShadow: isLocked
                        ? null
                        : [
                            BoxShadow(
                              color: glow.withOpacity(
                                isCurrent ? 0.75 * pulse : 0.50,
                              ),
                              blurRadius: isCurrent ? 32 * pulse : 20,
                              spreadRadius: isCurrent ? 4 * pulse : 2,
                            ),
                          ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipOval(
                        child: Opacity(
                          opacity: isLocked ? 0.30 : 1.0,
                          child: SizedBox(
                            width: d,
                            height: d,
                            child: Image.asset(
                              'assets/images/level${node.id}.webp',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      // Number badge — top-left corner
                      Positioned(
                        top: -1,
                        left: -1,
                        child: Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.90),
                            border: Border.all(color: glow, width: 1.8),
                          ),
                          child: Text(
                            '${node.id}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Lock overlay
                      if (isLocked)
                        Container(
                          width: d,
                          height: d,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.30),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Colors.white60,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            // XP label beneath the node (matches reference screenshots)
            if (xpLabel.isNotEmpty) ...[
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  xpLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isLocked
                        ? Colors.white38
                        : Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
