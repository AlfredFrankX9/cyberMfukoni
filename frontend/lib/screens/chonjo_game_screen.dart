import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../utils/translations.dart';

class ChonjoGameScreen extends StatefulWidget {
  final int initialLevel;

  const ChonjoGameScreen({super.key, this.initialLevel = 1});

  @override
  State<ChonjoGameScreen> createState() => _ChonjoGameScreenState();
}

class _ChonjoGameScreenState extends State<ChonjoGameScreen>
    with TickerProviderStateMixin {
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _selectedLevel = 1;
  bool _isLoading = true;
  bool _gameFinished = false;

  final List<Map<String, dynamic>> _userAnswers = [];

  late AnimationController _cardEntryController;
  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;

  late AnimationController _scorePopController;
  late Animation<double> _scorePop;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialLevel;
    _cardEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _cardEntryController, curve: Curves.easeOutBack),
    );
    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardEntryController, curve: Curves.easeOut),
    );

    _scorePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scorePop = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _scorePopController, curve: Curves.elasticOut),
    );

    _fetchQuestions();
  }

  @override
  void dispose() {
    _cardEntryController.dispose();
    _scorePopController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Back to level map — pops with the earned XP so ChonjoLevelsScreen can
  // update unlock state. Returns null (no XP) if the player quits mid-game.
  // ---------------------------------------------------------------------------
  void _backToMap() {
    Navigator.of(context).maybePop(_gameFinished ? _score : null);
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _gameFinished = false;
      _currentIndex = 0;
      _score = 0;
      _userAnswers.clear();
    });

    try {
      final response = await ApiService.get(
        '/api/chonjo/daily-quiz?level=$_selectedLevel',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _questions = data['data'];
          _isLoading = false;
        });
        _cardEntryController.forward(from: 0);
        return;
      }
    } catch (e) {
      debugPrint('Backend unreachable, using fallback mock data: $e');
    }

    // Fallback Mock Data
    setState(() {
      final baseMocks = [
        {
          "id": 1,
          "type": "SMS",
          "sender": "MPESA",
          "message":
              "Dear customer, your account will be suspended. Click here to verify: http://mpesa-verify.com",
          "is_scam": true,
          "explanation":
              "Safaricom never sends links via SMS to verify accounts.",
        },
        {
          "id": 2,
          "type": "SMS",
          "sender": "MPESA",
          "message":
              "Confirmed. Ksh 2,500.00 sent to JOHN DOE 07XX.. New Balance: Ksh 4,500. Transaction Cost: Ksh 0.00.",
          "is_scam": false,
          "explanation": "This matches standard receipt formatting.",
        },
        {
          "id": 3,
          "type": "EMAIL",
          "sender": "security@paypaI.com",
          "message":
              "Subject: Account Locked\n\nYour account has been restricted. Click here to verify your identity.",
          "is_scam": true,
          "explanation":
              "Sender uses capital 'I' instead of 'l'. Generic greeting and urgency are red flags.",
        },
        {
          "id": 4,
          "type": "SMS",
          "sender": "0712345678",
          "message":
              "Hi mum, I lost my phone. Please send Ksh 1000 to this new number urgently.",
          "is_scam": true,
          "explanation":
              "A classic 'Hi Mum' social engineering scam. Always verify by calling.",
        },
        {
          "id": 5,
          "type": "EMAIL",
          "sender": "billing@netflix.com",
          "message":
              "Subject: Payment Receipt\n\nYour monthly subscription of \$15.99 has been processed.",
          "is_scam": false,
          "explanation": "Standard billing receipt from legitimate domain.",
        },
      ];
      _questions = List.from(baseMocks);
      _questions.shuffle();
      _isLoading = false;
    });
    _cardEntryController.forward(from: 0);
  }

  void _handleSwipe(bool userSaysScam) {
    if (_currentIndex >= _questions.length) return;

    final currentQ = _questions[_currentIndex];
    final isCorrect = userSaysScam == currentQ['is_scam'];

    if (isCorrect) {
      _score += 10;
      _scorePopController.forward(from: 0);
    }

    _userAnswers.add({
      'question': currentQ,
      'user_said_scam': userSaysScam,
      'is_correct': isCorrect,
    });

    setState(() {
      _currentIndex++;
      if (_currentIndex >= _questions.length) {
        _gameFinished = true;
        _submitScore();
        // The popup is now triggered manually via the 'Finish Level' button on the results view.
      } else {
        _cardEntryController.forward(from: 0);
      }
    });
  }

  void _showCompletionDialog() {
    final percentage = _questions.isNotEmpty
        ? (_score / (_questions.length * 10) * 100).round()
        : 0;
    final bool isLastLevel = _selectedLevel >= 10;

    final Color gradeColor;
    final String gradeLabel;
    final String gradeEmoji;
    if (percentage >= 80) {
      gradeColor = const Color.fromARGB(255, 0, 255, 13);
      gradeLabel = 'Excellent!';
      gradeEmoji = '🏆';
    } else if (percentage >= 50) {
      gradeColor = const Color(0xFFFFD600);
      gradeLabel = 'Good Effort';
      gradeEmoji = '⭐';
    } else {
      gradeColor = const Color.fromARGB(255, 255, 0, 0);
      gradeLabel = 'Keep Practicing';
      gradeEmoji = '💪';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF111318).withOpacity(0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: gradeColor.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradeColor.withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji badge
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gradeColor.withOpacity(0.12),
                      border: Border.all(
                        color: gradeColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        gradeEmoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grade label
                  Text(
                    gradeLabel,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: gradeColor,
                      shadows: [
                        Shadow(
                          color: gradeColor.withOpacity(0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Level completed subtitle
                  Text(
                    'Level $_selectedLevel Complete',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.45),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Score row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statChip('$percentage%', 'Accuracy', gradeColor),
                        Container(
                          width: 1,
                          height: 32,
                          color: Colors.white.withOpacity(0.08),
                        ),
                        _statChip(
                          '$_score XP',
                          'Earned',
                          const Color(0xFF00FFCC),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: Colors.white.withOpacity(0.08),
                        ),
                        _statChip(
                          '${_userAnswers.where((a) => a['is_correct'] == true).length}/${_questions.length}',
                          'Correct',
                          Colors.white70,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    children: [
                      // Quit → back to level map
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _backToMap();
                          },
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Quit',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Next Level → advance and reload
                      Expanded(
                        child: GestureDetector(
                          onTap: isLastLevel
                              ? null
                              : () {
                                  Navigator.of(ctx).pop();
                                  setState(() {
                                    _selectedLevel++;
                                  });
                                  _fetchQuestions();
                                },
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: isLastLevel
                                  ? null
                                  : const LinearGradient(
                                      colors: [
                                        Color.fromARGB(255, 9, 255, 0),
                                        Color.fromARGB(255, 0, 255, 98),
                                      ],
                                    ),
                              color: isLastLevel
                                  ? Colors.white.withOpacity(0.04)
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isLastLevel
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color.fromARGB(
                                          255,
                                          51,
                                          255,
                                          0,
                                        ).withOpacity(0.28),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: isLastLevel
                                  ? const Text(
                                      'All Levels Done! 🎉',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Next Level',
                                          style: TextStyle(
                                            color: Color(0xFF0A0A0A),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 13,
                                          color: Color(0xFF0A0A0A),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10),
        ),
      ],
    );
  }

  Future<void> _submitScore() async {
    try {
      await ApiService.post('/api/chonjo/submit-score?score=$_score&level=$_selectedLevel');
    } catch (e) {
      debugPrint('Failed to submit score: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(255, 0, 255, 13).withOpacity(0.1),
              ),
              child: const CircularProgressIndicator(
                color: Color.fromARGB(255, 0, 255, 55),
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('', fallback: 'Loading scenarios...'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (_gameFinished) {
      return _buildResultsView();
    }

    final currentQ = _questions[_currentIndex];
    final sender = currentQ['sender'] ?? 'Unknown';
    final type = currentQ['type'] ?? 'SMS';
    final message = currentQ['message'] ?? '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            // ── Header: back-to-map ← | level label | XP score ─────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // ← back to level map (mid-game: no XP awarded)
                    GestureDetector(
                      onTap: _backToMap,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Static level label — no dropdown
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.psychology,
                                color: Color(0xFFAA00FF),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${context.tr('', fallback: 'Level')} $_selectedLevel',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Animated XP score
                AnimatedBuilder(
                  animation: _scorePopController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scorePop.value,
                      child: child,
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color.fromARGB(
                              255,
                              0,
                              255,
                              0,
                            ).withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 72, 255, 0),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(
                                      255,
                                      0,
                                      255,
                                      55,
                                    ).withOpacity(0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'XP: $_score',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color.fromARGB(255, 81, 255, 0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar with counter
            Row(
              children: [
                Text(
                  '${_currentIndex + 1}/${_questions.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _questions.length,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      color: const Color.fromARGB(255, 30, 255, 0),
                      minHeight: 4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Swipeable scenario card
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _cardEntryController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _cardOpacity.value,
                        child: Transform.scale(
                          scale: _cardScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Dismissible(
                          key: ValueKey(
                            currentQ['id'].toString() +
                                _currentIndex.toString(),
                          ),
                          onDismissed: (direction) {
                            if (direction == DismissDirection.startToEnd) {
                              _handleSwipe(false); // LEGIT
                            } else {
                              _handleSwipe(true); // SCAM
                            }
                          },
                          background: _buildSwipeBackground(
                            const Color(0xFF00FF40),
                            Icons.verified_user,
                            'LEGIT',
                            Alignment.centerLeft,
                          ),
                          secondaryBackground: _buildSwipeBackground(
                            const Color(0xFFFF1744),
                            Icons.warning_amber,
                            'SCAM',
                            Alignment.centerRight,
                          ),
                          child: type == 'EMAIL'
                              ? _buildRealisticEmailCard(sender, message)
                              : _buildRealisticSmsCard(
                                  sender,
                                  message,
                                  isWhatsApp: type == 'WHATSAPP',
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Swipe hint
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_back,
                  size: 14,
                  color: Colors.greenAccent.withOpacity(0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  context.tr('', fallback: 'LEGIT'),
                  style: TextStyle(
                    color: Colors.greenAccent.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 1,
                  height: 12,
                  color: Colors.white.withOpacity(0.1),
                ),
                const SizedBox(width: 16),
                Text(
                  context.tr('', fallback: 'SCAM'),
                  style: TextStyle(
                    color: Colors.redAccent.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: Colors.redAccent.withOpacity(0.4),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRealisticSmsCard(
    String sender,
    String message, {
    bool isWhatsApp = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF40).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(-15, 0),
          ),
          BoxShadow(
            color: const Color(0xFFFF1744).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(15, 0),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
          if (isWhatsApp)
            BoxShadow(
              color: const Color.fromARGB(255, 13, 212, 39).withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isWhatsApp
                      ? const Color.fromARGB(255, 22, 219, 72).withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  child: Icon(
                    isWhatsApp ? Icons.chat : Icons.person,
                    color: isWhatsApp
                        ? const Color.fromARGB(255, 29, 228, 55)
                        : Colors.white70,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sender,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        isWhatsApp ? 'WhatsApp • online' : 'Mobile • 2 min ago',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_vert, color: Colors.white.withOpacity(0.3)),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.05)),
          Expanded(
            child: Container(
              color: const Color(0xFF121212),
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isWhatsApp
                      ? const Color(0xFF1B3A2D)
                      : const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '10:42 AM',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.add, color: Colors.white.withOpacity(0.3)),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Type a message',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.mic, color: Colors.white.withOpacity(0.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealisticEmailCard(String sender, String message) {
    final lines = message.split('\n');
    String subject = "No Subject";
    String body = message;
    if (lines.first.toLowerCase().startsWith('subject:')) {
      subject = lines.first.substring(8).trim();
      body = lines.skip(1).join('\n').trim();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF40).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(-15, 0),
          ),
          BoxShadow(
            color: const Color(0xFFFF1744).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(15, 0),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.white54, size: 20),
                const Spacer(),
                Icon(
                  Icons.archive_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 20,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.delete_outline,
                  color: Colors.white.withOpacity(0.4),
                  size: 20,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.mark_email_unread_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 20,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.more_vert,
                  color: Colors.white.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const Icon(Icons.star_border, color: Colors.white30, size: 20),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blueAccent.withOpacity(0.3),
                  child: Text(
                    sender.isNotEmpty ? sender[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sender,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '10:42 AM',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'to me',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEmailActionBtn(Icons.reply, 'Reply'),
                _buildEmailActionBtn(Icons.reply_all, 'Reply all'),
                _buildEmailActionBtn(Icons.forward, 'Forward'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailActionBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white54),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeBackground(
    Color color,
    IconData icon,
    String label,
    Alignment alignment,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(alignment == Alignment.centerLeft ? 0.2 : 0.0),
            color.withOpacity(alignment == Alignment.centerRight ? 0.2 : 0.0),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    final percentage = _questions.isNotEmpty
        ? (_score / (_questions.length * 10) * 100).round()
        : 0;
    final Color gradeColor;
    final String gradeLabel;
    if (percentage >= 80) {
      gradeColor = const Color.fromARGB(255, 0, 255, 13);
      gradeLabel = 'Excellent!';
    } else if (percentage >= 50) {
      gradeColor = const Color(0xFFFFD600);
      gradeLabel = 'Good Effort';
    } else {
      gradeColor = const Color.fromARGB(255, 255, 0, 0);
      gradeLabel = 'Keep Practicing';
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // Glass score card
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: gradeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: gradeColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        gradeLabel,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: gradeColor,
                          shadows: [
                            Shadow(
                              color: gradeColor.withOpacity(0.5),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: gradeColor,
                        ),
                      ),
                      Text(
                        '$_score / ${_questions.length * 10} XP',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('', fallback: 'Review'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _userAnswers.length,
                itemBuilder: (context, index) {
                  final ans = _userAnswers[index];
                  final isCorrect = ans['is_correct'];
                  final currentQ = ans['question'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            (isCorrect
                                    ? const Color.fromARGB(255, 10, 255, 2)
                                    : const Color.fromARGB(255, 255, 0, 0))
                                .withOpacity(0.15),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect
                                    ? const Color.fromARGB(255, 83, 255, 3)
                                    : const Color.fromARGB(255, 255, 0, 51),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isCorrect ? 'Correct!' : 'Wrong!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isCorrect
                                        ? const Color.fromARGB(255, 9, 255, 0)
                                        : const Color.fromARGB(255, 255, 0, 51),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (currentQ['is_scam']
                                              ? const Color(0xFFFF1744)
                                              : const Color(0xFF00E676))
                                          .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  currentQ['is_scam'] ? 'SCAM' : 'LEGIT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: currentQ['is_scam']
                                        ? const Color(0xFFFF1744)
                                        : const Color(0xFF00E676),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${currentQ['type']} from ${currentQ['sender']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.35),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentQ['explanation'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.55),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _showCompletionDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 255, 98),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 10,
                shadowColor: const Color.fromARGB(255, 0, 255, 98).withOpacity(0.5),
              ),
              child: Text(
                context.tr('', fallback: 'Finish Level'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
