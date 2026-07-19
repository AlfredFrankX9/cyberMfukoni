import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  static const Color kGreen = Color(0xFF00FF55);
  static const Color kFieldFill = Color(0xFF1A1A1A);
  static const Color kCardColor = Color(0xFF262626);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();

    if (_isLogin) {
      if (email.isEmpty || password.isEmpty) {
        _snack('Please fill all fields');
        return;
      }
    } else {
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        _snack('Please fill all fields');
        return;
      }
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);

    // FIX: pass trimmed values so trailing whitespace never causes a
    // credential mismatch that silently falls back to offline mode.
    final String? error = _isLogin
        ? await auth.login(email, password)
        : await auth.register(username, email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      // Successful online login — AuthService navigates away.
      return;
    }

    if (error == 'offline_success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged in offline. Some features may be limited.'),
          backgroundColor: Color(0xFF00FFCC),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade800),
      );
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
    });
  }

  void _showForgotPasswordDialog() {
    final resetController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reset Password',
                style: TextStyle(
                  color: kGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email address to receive a password reset link.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              _buildField(controller: resetController, hint: 'you@example.com'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reset link sent to email!'),
                          backgroundColor: kGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Send Link',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    final double formWidth = isDesktop
        ? (size.width * 0.21).clamp(300.0, 340.0)
        : (size.width * 0.85).clamp(280.0, 360.0);

    return Scaffold(
      // FIX 1: extend behind any system UI so the bg image truly fills the screen.
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit
            .expand, // FIX 1: force the Stack to fill the Scaffold body.
        children: [
          // ── Background — always full screen ──────────────────────────────
          Image.asset(
            isDesktop
                ? 'assets/images/login background.webp'
                : 'assets/images/login_background_mobile.webp',
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
          ),
          // Dark overlay
          Container(color: Colors.black.withOpacity(0.18)),

          if (isDesktop) ...[
            // Top-left logo
            Positioned(top: 20, left: 16, child: _buildLogo(isDesktop: true)),
            // Form — vertically centred, anchored left
            Align(
              alignment: const Alignment(-0.8, -0.08),
              child: _buildForm(formWidth, isDesktop: true),
            ),
            // Bottom headline + pills
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _buildHeroText(isDesktop: true),
            ),
          ] else ...[
            // FIX 1: Positioned.fill so the content layer also fills the screen,
            // then SafeArea keeps content inside notch/status-bar bounds.
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: ConstrainedBox(
                    // Ensure the column fills at least the visible viewport so
                    // the background is never exposed by a short-content page.
                    constraints: BoxConstraints(
                      minHeight:
                          size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: _buildLogo(isDesktop: false),
                            ),
                            const SizedBox(height: 4),
                            _buildForm(formWidth, isDesktop: false),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _buildHeroText(isDesktop: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogo({required bool isDesktop}) =>
      Image.asset('assets/images/logo.webp', height: isDesktop ? 120 : 120);

  Widget _buildForm(double formWidth, {required bool isDesktop}) {
    return SizedBox(
      width: formWidth,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 18 : 14,
          vertical: isDesktop ? 18 : 14,
        ),
        decoration: BoxDecoration(
          color: kCardColor.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                key: ValueKey<bool>(_isLogin),
                style: TextStyle(
                  fontSize: isDesktop ? 19 : 17,
                  fontWeight: FontWeight.bold,
                  color: kGreen,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isLogin
                    ? 'Log in to continue protecting your digital life'
                    : 'Sign up to unlock advanced digital protection',
                key: ValueKey<bool>(_isLogin),
                style: TextStyle(
                  fontSize: isDesktop ? 11 : 9,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 10),

            // Username field (register only)
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_isLogin
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('USERNAME', isDesktop),
                        SizedBox(height: isDesktop ? 5 : 2),
                        _buildField(
                          controller: _usernameController,
                          hint: 'cyberninja99',
                        ),
                        SizedBox(height: isDesktop ? 12 : 8),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            _buildLabel(
              _isLogin ? 'USERNAME OR EMAIL ADDRESS' : 'EMAIL ADDRESS',
              isDesktop,
            ),
            SizedBox(height: isDesktop ? 5 : 2),
            _buildField(controller: _emailController, hint: 'you@example.com'),
            SizedBox(height: isDesktop ? 12 : 8),

            _buildLabel('PASSWORD', isDesktop),
            SizedBox(height: isDesktop ? 5 : 2),
            _buildField(
              controller: _passwordController,
              hint: '••••••••',
              obscure: true,
            ),
            SizedBox(height: isDesktop ? 5 : 2),

            // Forgot password (login only)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: _isLogin
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _showForgotPasswordDialog,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: kGreen,
                              fontSize: isDesktop ? 11 : 10,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(height: isDesktop ? 12 : 8),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: isDesktop ? 42 : 38,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2.2,
                        ),
                      )
                    : Text(
                        _isLogin ? 'Log In' : 'Sign Up',
                        style: TextStyle(
                          fontSize: isDesktop ? 13.5 : 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            SizedBox(height: isDesktop ? 13 : 8),

            // OR divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: isDesktop ? 10 : 9,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
              ],
            ),
            SizedBox(height: isDesktop ? 13 : 8),

            // Google button
            Container(
              width: double.infinity,
              height: isDesktop ? 40 : 36,
              padding: const EdgeInsets.all(1.3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: const LinearGradient(
                  colors: [
                    Colors.redAccent,
                    Colors.orangeAccent,
                    Colors.yellowAccent,
                    Colors.greenAccent,
                    Colors.blueAccent,
                    Colors.purpleAccent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Material(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(9.7),
                child: InkWell(
                  borderRadius: BorderRadius.circular(9.7),
                  onTap: () async {
                    setState(() => _isLoading = true);
                    final auth = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    final error = await auth.googleLogin(
                      'google_user',
                      'user@gmail.com',
                    );
                    if (!mounted) return;
                    setState(() => _isLoading = false);
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: Colors.red.shade800,
                        ),
                      );
                    }
                  },
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: isDesktop ? 12 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 10),

            // Toggle login / register
            Center(
              child: GestureDetector(
                onTap: _toggleMode,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLogin
                            ? "Don't have an account?  "
                            : "Already have an account?  ",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: isDesktop ? 11 : 10,
                        ),
                      ),
                      Text(
                        _isLogin ? 'Sign Up' : 'Log In',
                        style: TextStyle(
                          color: kGreen,
                          fontSize: isDesktop ? 11 : 10,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroText({required bool isDesktop}) {
    return Column(
      children: [
        Text(
          'Protect Yourself From',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 32 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.55),
          ),
        ),
        Text(
          'Cyber Threats',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 44 : 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: isDesktop ? 16 : 8,
          runSpacing: 12,
          children: [
            _buildPill('Confidentiality', Colors.redAccent, isDesktop),
            _buildPill('Integrity', kGreen, isDesktop),
            _buildPill('Availability', Colors.purpleAccent, isDesktop),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text, bool isDesktop) => Text(
    text,
    style: TextStyle(
      fontSize: isDesktop ? 9 : 8,
      color: Colors.white.withOpacity(0.6),
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
  }) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 12.5),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
          filled: true,
          fillColor: kFieldFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String text, Color glowColor, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : 16,
        vertical: isDesktop ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: glowColor, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.55),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isDesktop ? 14 : 9,
        ),
      ),
    );
  }
}
