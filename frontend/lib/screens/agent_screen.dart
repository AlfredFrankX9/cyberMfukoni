import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/guardian_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/translations.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  late AnimationController _agentGlowController;
  late Animation<double> _agentGlowAnimation;

  static const Color kCyberGreen = Color(0xFF00FF66);
  static const Color kSteelGrey = Color(0xFF2E2E2E);
  static const Color kBg = Color(0xFF05070A);

  @override
  void initState() {
    super.initState();
    _agentGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _agentGlowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _agentGlowController, curve: Curves.easeInOut),
    );

    // Welcome message
    _messages.add({
      'role': 'agent',
      'content':
          'Hi! Welcome to **Cyber Mfukoni**. I\'m **The Guardian** — how can I help you today?',
      'timestamp': DateTime.now(),
    });
    _messages.add({
      'role': 'agent',
      'content':
          'I can answer cybersecurity questions, explain scams and threats, guide you on safe practices, '
          'and help with incident response. What would you like to know?',
      'timestamp': DateTime.now(),
      'action': {'label': '🔍  Scan a suspicious message', 'route': 'mulika'},
    });
  }

  @override
  void dispose() {
    _agentGlowController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    GuardianDialog.show(
      context,
      title: 'Success',
      message: context.tr('copied_to_clipboard') ?? 'Copied to clipboard',
      icon: Icons.check_circle_outline,
      color: Colors.green,
      primaryButtonText: 'OK',
    );
  }

  Future<void> _retryMessage(int index) async {
    // Find the relevant user query to retry
    String queryToRetry = '';
    if (_messages[index]['role'] == 'user') {
      queryToRetry = _messages[index]['content'] as String;
    } else {
      // Look back for the preceding user message
      for (int i = index - 1; i >= 0; i--) {
        if (_messages[i]['role'] == 'user') {
          queryToRetry = _messages[i]['content'] as String;
          break;
        }
      }
    }
    if (queryToRetry.isNotEmpty) {
      _sendMessage(queryToRetry);
    }
  }

  Future<void> _sendMessage([String? quick]) async {
    final text = (quick ?? _messageController.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'timestamp': DateTime.now(),
      });
      _messageController.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await ApiService.post(
        '/api/agent/chat',
        body: {'message': text},
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.add({
            'role': 'agent',
            'content': data['data']['response'],
            'timestamp': DateTime.now(),
          });
          _isTyping = false;
        });
        _scrollToBottom();
        return;
      }
    } catch (e) {
      debugPrint('Agent chat failed: $e');
    }

    // Fallback mock response
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _messages.add({
        'role': 'agent',
        'content': _getMockResponse(text),
        'timestamp': DateTime.now(),
      });
      _isTyping = false;
    });
    _scrollToBottom();
  }

  String _getMockResponse(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('phishing') || lower.contains('scam')) {
      return '**Phishing & Scam Protection Tips:**\n\n'
          '1. **Never click suspicious links** in SMS or email\n'
          '2. **Verify the sender** — check email addresses carefully for typos\n'
          '3. **Don\'t share personal info** via text or phone calls\n'
          '4. **Use official apps** — always download from Play Store or App Store\n'
          '5. **Report scams** to your carrier and the CA\n\n'
          'Would you like me to analyze a specific message? Try the **Mulika** tab!';
    }

    if (lower.contains('password')) {
      return '**Password Security Best Practices:**\n\n'
          '🔑 Use at least **12 characters** with uppercase, lowercase, numbers, and symbols\n'
          '🔄 **Never reuse passwords** across different accounts\n'
          '📱 Use a **password manager** like Bitwarden or 1Password\n'
          '🔐 Enable **2FA** (Two-Factor Authentication) everywhere\n'
          '⚠️ **Never share** your passwords with anyone\n\n'
          'Your M-Pesa PIN should also be changed every 3 months.';
    }

    if (lower.contains('hack') || lower.contains('hacked')) {
      return '**If You\'ve Been Hacked — Immediate Steps:**\n\n'
          '1. 🔒 **Change your password** immediately on the affected account\n'
          '2. 📱 **Enable 2FA** if not already active\n'
          '3. 📧 **Check for unauthorized activity** (emails sent, posts made)\n'
          '4. 🔍 **Review connected apps** and revoke suspicious ones\n'
          '5. 📞 **Contact the platform** support team\n'
          '6. 🚔 **Report to authorities** if financial loss occurred\n\n'
          'For step-by-step recovery, check the **Daktari** module (coming soon).';
    }

    if (lower.contains('sim swap') || lower.contains('sim')) {
      return '**SIM Swap Protection:**\n\n'
          'SIM swap fraud is when criminals convince your carrier to transfer your number to their SIM.\n\n'
          '**How to protect yourself:**\n'
          '• Set a **SIM PIN** on your phone\n'
          '• Register a **SIM lock** with your carrier (Safaricom: *100#)\n'
          '• **Never share** your ID details with strangers\n'
          '• Use **app-based 2FA** instead of SMS-based\n'
          '• **Monitor** your phone signal — sudden loss could indicate a swap\n\n'
          '🚨 If you suspect a SIM swap, call your carrier **immediately**.';
    }

    return '**Great question!** Here\'s what I\'d recommend:\n\n'
        'Cybersecurity is all about staying vigilant. Here are general tips:\n\n'
        '• Keep your devices and apps **updated**\n'
        '• Use **strong, unique passwords** for each account\n'
        '• Enable **two-factor authentication**\n'
        '• Be **cautious with links** from unknown sources\n'
        '• Regularly **back up** your important data\n\n'
        'Feel free to ask me about specific topics like phishing, password security, SIM swap protection, or what to do if you\'ve been hacked!';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 900;

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // Background photo
          Positioned.fill(
            child: Image.asset(
              'assets/images/agent_background.webp',
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay so the chat card and text stay legible over the photo
          Positioned.fill(child: Container(color: kBg.withOpacity(0.55))),

          // Ambient background glow (left side only, behind the chat card)
          Positioned(
            top: -120,
            left: -80,
            child: _glowOrb(360, kCyberGreen.withOpacity(0.14)),
          ),

          SafeArea(
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _buildChatCard(),
                        ),
                      ),
                      Expanded(child: _buildHeroPanel()),
                    ],
                  )
                : _buildChatCard(isFullScreen: true),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // -------------------- Decorative right-side hero panel (wide layouts) --------------------
  Widget _buildHeroPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 40, 40, 120),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Text(
          context.tr('agent_hero_text'),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 12),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- The floating glass chat card --------------------
  Widget _buildChatCard({bool isFullScreen = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isFullScreen ? 0 : 28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101317).withOpacity(0.9),
            borderRadius: BorderRadius.circular(isFullScreen ? 0 : 28),
            border: isFullScreen
                ? null
                : Border.all(color: Colors.white.withOpacity(0.06)),
            boxShadow: isFullScreen
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                  ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[index], index);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 48,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 8, right: 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildQuickAction(context.tr('agent_quick_phishing')),
                              _buildQuickAction(context.tr('agent_quick_password')),
                              _buildQuickAction(context.tr('agent_quick_hacked')),
                              _buildQuickAction(context.tr('agent_quick_sim')),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildInputArea(),
              SizedBox(height: isFullScreen ? 96 : 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _agentGlowAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kCyberGreen, Color(0xFF00B8D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: kCyberGreen.withOpacity(
                        0.4 * _agentGlowAnimation.value,
                      ),
                      blurRadius: 15 * _agentGlowAnimation.value,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.black87,
                  size: 22,
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('agent_title'),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: kCyberGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kCyberGreen.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('online_status'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Colors.white.withOpacity(0.4),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'agent',
                  'content': context.tr('chat_cleared'),
                  'timestamp': DateTime.now(),
                });
              });
            },
            tooltip: context.tr('clear_chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _sendMessage(text),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: kCyberGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kCyberGreen.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: kCyberGreen.withOpacity(0.95),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 80),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: kSteelGrey.withOpacity(0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: kCyberGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: kCyberGreen.withOpacity(0.5), blurRadius: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, int index) {
    final isAgent = message['role'] == 'agent';
    final action = message['action'] as Map<String, dynamic>?;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + 0.1 * value,
          alignment: isAgent ? Alignment.bottomLeft : Alignment.bottomRight,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Align(
        alignment: isAgent ? Alignment.centerLeft : Alignment.centerRight,
        child: Column(
          crossAxisAlignment: isAgent
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Container(
              margin: EdgeInsets.only(
                bottom: action == null ? 12 : 8,
                left: isAgent ? 0 : 40,
                right: isAgent ? 40 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: isAgent ? kSteelGrey.withOpacity(0.7) : null,
                gradient: isAgent
                    ? null
                    : const LinearGradient(
                        colors: [kCyberGreen, Color(0xFF00CC88)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isAgent ? 4 : 20),
                  bottomRight: Radius.circular(isAgent ? 20 : 4),
                ),
                border: isAgent
                    ? Border.all(color: Colors.white.withOpacity(0.06))
                    : null,
              ),
              child: _buildRichText(message['content'] as String, isAgent),
            ),
            // Action bar: Copy for user, Copy & Retry for agent
            Padding(
              padding: EdgeInsets.only(
                bottom: action == null ? 8 : 4,
                left: isAgent ? 4 : 0,
                right: isAgent ? 0 : 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _copyToClipboard(message['content'] as String),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 13,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('copy').toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isAgent) ...[
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _retryMessage(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 13,
                              color: Colors.white.withOpacity(0.4),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.tr('retry').toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (action != null)
              Container(
                margin: EdgeInsets.only(
                  bottom: 14,
                  left: isAgent ? 0 : 40,
                  right: isAgent ? 40 : 0,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: kCyberGreen,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: kCyberGreen.withOpacity(0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Text(
                        action['label'] as String,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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

  Widget _buildRichText(String text, bool isAgent) {
    // Simple markdown-like bold rendering
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: i % 2 == 1 ? FontWeight.bold : FontWeight.normal,
            color: i % 2 == 1
                ? (isAgent ? kCyberGreen : Colors.black)
                : (isAgent
                      ? Colors.white.withOpacity(0.88)
                      : Colors.black.withOpacity(0.88)),
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
      );
    }
    return Text.rich(
      TextSpan(children: spans),
      style: const TextStyle(fontSize: 13.5, height: 1.5),
    );
  }

  Widget _buildInputArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(fontSize: 13.5, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: context.tr('agent_input_hint'),
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 13.5,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kCyberGreen, Color(0xFF00B8D4)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_upward,
                    color: Colors.black87,
                    size: 18,
                  ),
                  onPressed: () => _sendMessage(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
