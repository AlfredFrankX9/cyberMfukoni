import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chonjo_game_screen.dart';
import 'certificate_screen.dart';

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
  final ValueChanged<int>? onNavigate;

  const ChonjoLevelsScreen({
    super.key,
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

  int _totalXp = 0;
  Map<String, int> _levelScores = {};
  String? _certEarnedAt;
  String _username = '';
  String _email = '';

  // XP thresholds to unlock each level
  static const List<int> _xpThresholds = [
    0,   // Level 1
    90,  // Level 2
    190, // Level 3
    290, // Level 4
    390, // Level 5
    480, // Level 6
    580, // Level 7
    680, // Level 8
    780, // Level 9
    880, // Level 10
  ];

  // Positions calibrated to sit ON the staircase rails in the reference art.
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

    // Initialize nodes with all locked (will update after API call)
    _nodes = List.generate(10, (i) {
      return _LevelNode(
        id: i + 1,
        position: _positions[i],
        glowColor: _glowColors[i],
        status: i == 0 ? LevelStatus.current : LevelStatus.locked,
      );
    });

    _fetchProgress();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchProgress() async {
    try {
      final response = await ApiService.get('/api/chonjo/progress');
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          _totalXp = data['total_xp'] ?? 0;
          _username = data['username'] ?? '';
          _email = data['email'] ?? '';
          _certEarnedAt = data['cert_earned_at'];
          _levelScores = {};
          if (data['level_scores'] != null) {
            (data['level_scores'] as Map<String, dynamic>).forEach((k, v) {
              _levelScores[k] = v as int;
            });
          }
          _updateNodeStatuses();
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch chonjo progress: $e');
    }
  }

  void _updateNodeStatuses() {
    for (int i = 0; i < _nodes.length; i++) {
      final levelId = i + 1;
      final threshold = _xpThresholds[i];
      final hasPlayed = _levelScores.containsKey(levelId.toString());

      if (_totalXp >= threshold) {
        // Unlocked
        if (hasPlayed) {
          _nodes[i].status = LevelStatus.completed;
        } else {
          _nodes[i].status = LevelStatus.current;
        }
      } else {
        _nodes[i].status = LevelStatus.locked;
      }
    }
  }

  void _onLevelTap(_LevelNode node) async {
    if (node.status == LevelStatus.locked) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChonjoGameScreen(initialLevel: node.id),
      ),
    );
    // Refresh progress after returning from game
    _fetchProgress();
  }

  void _openCertificate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CertificateScreen(
          username: _username,
          email: _email,
          totalXp: _totalXp,
          dateEarned: _certEarnedAt ?? '',
        ),
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

          // Certificate icon (only visible once earned)
          if (_certEarnedAt != null) ...[
            GestureDetector(
              onTap: _openCertificate,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Total XP Badge
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: kCyberGreen.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kCyberGreen.withOpacity(0.15),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: kCyberGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kCyberGreen.withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_totalXp XP',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: kCyberGreen,
                        shadows: [
                          Shadow(
                            color: kCyberGreen.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

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
    final bool isCompleted = node.status == LevelStatus.completed;
    final Color glow = isLocked
        ? Colors.white.withOpacity(0.15)
        : node.glowColor;

    // XP thresholds as labels
    final String xpLabel = node.id >= 2
        ? '${_xpThresholds[node.id - 1]}XP'
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
                      color: isLocked ? glow.withOpacity(0.4) : glow,
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
                        child: ColorFiltered(
                          colorFilter: isLocked
                              ? const ColorFilter.matrix(<double>[
                                  0.4, 0, 0, 0, 0,
                                  0, 0.4, 0, 0, 0,
                                  0, 0, 0.4, 0, 0,
                                  0, 0, 0, 0.6, 0,
                                ])
                              : const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.multiply,
                                ),
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
                            border: Border.all(
                              color: isLocked ? glow.withOpacity(0.4) : glow,
                              width: 1.8,
                            ),
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
                      // Completed checkmark — top-right corner
                      if (isCompleted)
                        Positioned(
                          top: -1,
                          right: -1,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00E676),
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 14,
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
            // XP label beneath the node (shows threshold)
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
