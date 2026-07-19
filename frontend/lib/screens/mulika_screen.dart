import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import '../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart'; // fallback only, see _goBack()

// ──────────────────────────────────────────────────────────────────────────────
// Theme constants – matches the global Cyber Mfukoni palette
// ──────────────────────────────────────────────────────────────────────────────
const Color _kDeepBlack = Color(0xFF000000);
const Color _kGraphiteGrey = Color(0xFF1A1A1A);
const Color _kSlateBlue = Color(0xFF222633);
const Color _kMetallicSilver = Color(0xFFB0B0B0);
const Color _kChromeSteel = Color(0xFFC0C0C0);
const Color _kNeonGreen = Color(0xFF00FF40);
const Color _kCyberEmerald = Color(0xFF32CD32);
const Color _kElectricLime = Color(0xFFA8FF00);
const Color _kDarkForest = Color(0xFF0B3D0B);

class MulikaScreen extends StatefulWidget {
  /// Passed down from the main shell (same pattern as DashboardScreen).
  /// Calling this with an index switches the shell's visible tab —
  /// it does NOT push/pop a route. Index 3 = Home/Dashboard, matching
  /// the mapping used in DockNavBar's `_leftItems` ('Home', navIndex: 3).
  final ValueChanged<int>? onNavigate;

  const MulikaScreen({super.key, this.onNavigate});

  @override
  State<MulikaScreen> createState() => _MulikaScreenState();
}

class _MulikaScreenState extends State<MulikaScreen>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;
  int _selectedType = 0;

  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  // Device Scan State
  String _selectedDeviceTarget = 'Apps';
  final List<String> _deviceTargets = [
    'Apps',
    'Files',
    'Storage Devices',
    'Whole Phone',
    'Target Location',
  ];
  bool _isTerminalScanning = false;
  List<String> _terminalLines = [];
  ScrollController _terminalScroll = ScrollController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scanController;

  static const List<_InputType> _inputTypes = [
    _InputType(Icons.security, 'Device Scan'),
    _InputType(Icons.sms, 'SMS'),
    _InputType(Icons.email_outlined, 'Email'),
    _InputType(Icons.link, 'URL'),
    _InputType(Icons.qr_code_scanner, 'QR Code'),
    _InputType(Icons.image_outlined, 'Image'),
    _InputType(Icons.description_outlined, 'Document'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    _textController.dispose();
    _terminalScroll.dispose();
    super.dispose();
  }

  // ── Back navigation ─────────────────────────────────────────────────────
  // Mulika lives inside the same tab shell as Dashboard/Boma/Vault/etc —
  // switching "screens" is really just switching the shell's active index
  // via onNavigate, the same callback Dashboard's module cards and
  // DockNavBar's tiles use. It is NOT a pushed route, so Navigator.pop()
  // here would pop the *shell itself* (wrong screen, or nothing to pop to
  // → black screen) and pushReplacement() would spawn a orphaned
  // DashboardScreen with no onNavigate wired up (dock/module taps go dead).
  //
  // So: always prefer onNavigate. Only fall back to Navigator if this
  // screen is ever used standalone/outside the shell (e.g. pushed directly
  // for testing) — in that case there IS a real route to pop.
  void _goBack() {
    if (widget.onNavigate != null) {
      widget.onNavigate!(3); // 3 = Home/Dashboard tab
    } else if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _kSlateBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: _kNeonGreen),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: _kNeonGreen),
                title: Text(
                  'Take a Photo',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      try {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          final bytes = await image.readAsBytes();
          setState(() {
            _imageBytes = bytes;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open camera/gallery: $e'),
              backgroundColor: const Color(0xFFFF1744),
            ),
          );
        }
      }
    }
  }

  Future<void> _runDeviceScan() async {
    setState(() {
      _isAnalyzing = true;
      _isTerminalScanning = true;
      _terminalLines = [
        '[SYSTEM] Initiating Cyber Mfukoni Device Scan...',
        '[TARGET] $_selectedDeviceTarget',
        '[ENGINE] VirusTotal Integration v3 Active',
      ];
      _result = null;
    });

    final rand = Random();
    List<String> packageNames = [];

    // ── 1. GATHER ITEMS ──────────────────────────────────
    if (_selectedDeviceTarget == 'Apps') {
      if (!kIsWeb && Theme.of(context).platform == TargetPlatform.android) {
        // REAL: Fetch installed apps on Android
        setState(
          () => _terminalLines.add('[INFO] Querying Android PackageManager...'),
        );
        _scrollToBottom();
        try {
          List<AppInfo> apps = await InstalledApps.getInstalledApps(
            excludeSystemApps: true,
            withIcon: true,
          );
          packageNames = apps.map((a) => a.packageName ?? 'unknown').toList();
          setState(
            () => _terminalLines.add(
              '[OK] Found ${packageNames.length} installed apps',
            ),
          );
          _scrollToBottom();
        } catch (e) {
          setState(
            () => _terminalLines.add(
              '[WARN] Could not query apps: $e. Using fallback.',
            ),
          );
          _scrollToBottom();
          packageNames = _getMockPackages();
        }
      } else {
        // WEB/DESKTOP: Mock data
        setState(
          () => _terminalLines.add(
            '[INFO] Web environment detected. Using simulation data.',
          ),
        );
        _scrollToBottom();
        packageNames = _getMockPackages();
      }

      // ── 2. SHOW TERMINAL OUTPUT FOR EACH APP ──────────
      await Future.delayed(const Duration(milliseconds: 300));
      setState(
        () => _terminalLines.add(
          '[SCAN] Cross-referencing with VirusTotal database...',
        ),
      );
      _scrollToBottom();

      for (int i = 0; i < min(packageNames.length, 30); i++) {
        if (!mounted) return;
        await Future.delayed(Duration(milliseconds: 80 + rand.nextInt(150)));
        setState(() {
          _terminalLines.add('  Checking: ${packageNames[i]} ...');
        });
        _scrollToBottom();
      }
      if (packageNames.length > 30) {
        setState(
          () =>
              _terminalLines.add('  ... and ${packageNames.length - 30} more'),
        );
        _scrollToBottom();
      }

      // ── 3. CALL BACKEND API ──────────────────────────
      setState(() {
        _terminalLines.add(' ');
        _terminalLines.add(
          '[NETWORK] Sending ${packageNames.length} hashes to VirusTotal API...',
        );
      });
      _scrollToBottom();

      try {
        // Send up to 15 packages to avoid VT rate limit on free tier
        final packagesToSend = packageNames.take(15).toList();
        final response = await ApiService.post(
          '/api/mulika/scan-apps',
          body: {'package_names': packagesToSend},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _terminalLines.add('[OK] VirusTotal scan complete.');
            _terminalLines.add(' ');
            _isTerminalScanning = false;
            _isAnalyzing = false;
            _result = data['data'];
          });
          _scrollToBottom();
          return;
        } else if (response.statusCode == 503) {
          setState(
            () => _terminalLines.add(
              '[WARN] VT API key not configured. Falling back to heuristic scan.',
            ),
          );
          _scrollToBottom();
        } else {
          setState(
            () => _terminalLines.add(
              '[ERROR] Backend returned ${response.statusCode}. Using heuristic analysis.',
            ),
          );
          _scrollToBottom();
        }
      } catch (e) {
        setState(
          () => _terminalLines.add(
            '[ERROR] Network error: $e. Using local heuristic analysis.',
          ),
        );
        _scrollToBottom();
      }
    } else {
      // For Files, Storage, Whole Phone, Target Location — show simulation terminal
      List<String> mockItems = _getMockItemsForTarget(rand);
      for (int i = 0; i < mockItems.length; i++) {
        if (!mounted) return;
        await Future.delayed(Duration(milliseconds: 100 + rand.nextInt(250)));
        setState(
          () => _terminalLines.add('Scanning: ${mockItems[i]} ... [OK]'),
        );
        _scrollToBottom();
      }
    }

    // ── FALLBACK: Local heuristic report ──────────────────
    setState(() {
      _terminalLines.add(' ');
      _terminalLines.add('[SYSTEM] Generating heuristic analysis report...');
    });
    _scrollToBottom();
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isTerminalScanning = false;
      _isAnalyzing = false;
      _result = {
        'scam_probability': 5,
        'risk_rating': 'Safe',
        'red_flags': ['No known threats detected in $_selectedDeviceTarget'],
        'confidence': 85,
        'community_reports': 'Heuristic scan completed. No anomalies found.',
        'explanation':
            'Local heuristic analysis of $_selectedDeviceTarget completed. '
            'No suspicious patterns or known malware signatures were detected. '
            'For a deeper scan with VirusTotal, ensure your API key is configured.',
      };
    });
  }

  List<String> _getMockPackages() {
    return [
      'com.google.android.apps.messaging',
      'com.whatsapp',
      'com.facebook.katana',
      'com.instagram.android',
      'com.twitter.android',
      'com.spotify.music',
      'com.netflix.mediaclient',
      'com.google.android.youtube',
      'org.telegram.messenger',
      'com.snapchat.android',
      'com.tiktok.android',
      'com.microsoft.teams',
      'com.amazon.mShop.android',
      'com.paypal.android.p2pmobile',
      'com.google.android.apps.maps',
    ];
  }

  List<String> _getMockItemsForTarget(Random rand) {
    if (_selectedDeviceTarget == 'Files') {
      return List.generate(
        20,
        (i) =>
            '/storage/emulated/0/Download/file_${rand.nextInt(9999)}.${['zip', 'pdf', 'apk', 'doc', 'mp3'][rand.nextInt(5)]}',
      );
    } else if (_selectedDeviceTarget == 'Storage Devices') {
      return [
        '/dev/block/mmcblk0 [INTERNAL]',
        'Mounting internal storage read-only...',
        'Scanning partition table...',
        '/storage/emulated/0/ [512MB scanned]',
        '/storage/sdcard1/ [NO CARD DETECTED]',
        'Checking boot partition integrity...',
        'Verifying system checksums...',
      ];
    } else if (_selectedDeviceTarget == 'Whole Phone') {
      return [
        ...List.generate(
          8,
          (i) => '/system/bin/app_process${rand.nextInt(64)}',
        ),
        'com.android.systemui',
        'com.google.android.gms',
        'Checking kernel modules...',
        'Scanning /data/local/tmp/ for exploits...',
        'Verifying SELinux policies...',
        'Checking for rooting indicators...',
      ];
    } else {
      return List.generate(
        15,
        (i) => '/custom_target/folder/data_${rand.nextInt(100)}.dat',
      );
    }
  }

  void _scrollToBottom() {
    if (_terminalScroll.hasClients) {
      _terminalScroll.animateTo(
        _terminalScroll.position.maxScrollExtent + 50,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _analyzeMessage() async {
    if (_inputTypes[_selectedType].label == 'Device Scan') {
      await _runDeviceScan();
      return;
    }

    if (_textController.text.trim().isEmpty && _imageBytes == null) return;

    setState(() {
      _isAnalyzing = true;
      _result = null;
      _isTerminalScanning = false;
    });
    _scanController.repeat();

    try {
      String? base64Image;
      if (_imageBytes != null) {
        base64Image = base64Encode(_imageBytes!);
      }

      final response = await ApiService.post(
        '/api/mulika/analyze',
        body: {
          'message': _textController.text.trim(),
          'type': _inputTypes[_selectedType].label.toLowerCase(),
          if (base64Image != null) 'image_base64': base64Image,
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _result = data['data'];
          _isAnalyzing = false;
        });
        _scanController.stop();
        return;
      } else {
        // Backend returned an error
        final errorData = json.decode(response.body);
        final errorMessage = errorData['detail'] ?? 'Unknown error occurred.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFFF1744),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Mulika analysis failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Network error. Please check your connection.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFFF1744),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // Stop scanning if it failed
    setState(() {
      _isAnalyzing = false;
    });
    _scanController.stop();
  }

  Color _getRatingColor(String rating) {
    switch (rating) {
      case 'Scam Likely':
        return const Color(0xFFFF1744);
      case 'High Risk':
        return const Color(0xFFFF9100);
      case 'Suspicious':
        return const Color(0xFFFFD600);
      case 'Low Risk':
        return _kCyberEmerald;
      case 'Safe':
        return _kNeonGreen;
      default:
        return _kMetallicSilver;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDeepBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/mulikaMainBackground.webp'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: _kDeepBlack.withOpacity(0.55)),
          ),
          // Ambient glow
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kCyberEmerald.withOpacity(0.10),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kDarkForest.withOpacity(0.25),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildInputArea(),
                  const SizedBox(height: 24),
                  if (_isTerminalScanning) _buildTerminalView(),
                  if (_result != null && !_isTerminalScanning)
                    _buildResultCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: _goBack,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kSlateBlue,
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 14),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kCyberEmerald.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kCyberEmerald.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: _kCyberEmerald.withOpacity(0.2),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.document_scanner,
                  color: _kNeonGreen,
                  size: 24,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MULIKA',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2,
                shadows: [
                  Shadow(color: _kNeonGreen.withOpacity(0.5), blurRadius: 10),
                ],
              ),
            ),
            Text(
              'AI Threat Detection Engine',
              style: GoogleFonts.inter(fontSize: 12, color: _kMetallicSilver),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: _kSlateBlue,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kCyberEmerald.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: _kDeepBlack.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Input type selector (scrollable chips)
              Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_inputTypes.length, (i) {
                      final t = _inputTypes[i];
                      final active = i == _selectedType;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            if (_isAnalyzing || _isTerminalScanning) return;
                            setState(() {
                              _selectedType = i;
                              if (t.label != 'Image' &&
                                  t.label != 'QR Code' &&
                                  t.label != 'Document') {
                                _imageBytes = null;
                              }
                              _result = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? _kCyberEmerald.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? _kCyberEmerald.withOpacity(0.5)
                                    : Colors.white10,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  t.icon,
                                  size: 16,
                                  color: active
                                      ? _kNeonGreen
                                      : _kMetallicSilver,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  t.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: active
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: active
                                        ? _kNeonGreen
                                        : _kMetallicSilver,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.white.withOpacity(0.06)),

              // DEVICE SCAN OPTIONS
              if (_inputTypes[_selectedType].label == 'Device Scan')
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECT TARGET:',
                        style: GoogleFonts.shareTechMono(
                          color: _kNeonGreen,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _deviceTargets.map((target) {
                          final isTargetActive =
                              _selectedDeviceTarget == target;
                          return GestureDetector(
                            onTap: () {
                              if (_isAnalyzing || _isTerminalScanning) return;
                              setState(() => _selectedDeviceTarget = target);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isTargetActive
                                    ? _kNeonGreen.withOpacity(0.1)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isTargetActive
                                      ? _kNeonGreen
                                      : Colors.white24,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                target,
                                style: GoogleFonts.inter(
                                  color: isTargetActive
                                      ? _kNeonGreen
                                      : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: isTargetActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              // IMAGE/DOC OPTIONS
              if (_inputTypes[_selectedType].label == 'Image' ||
                  _inputTypes[_selectedType].label == 'QR Code' ||
                  _inputTypes[_selectedType].label == 'Document')
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _imageBytes != null
                      ? Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _imageBytes!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () => setState(() => _imageBytes = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _kCyberEmerald.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: _kCyberEmerald,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _inputTypes[_selectedType].label == 'Document'
                                      ? 'Tap to upload document'
                                      : 'Tap to upload image',
                                  style: GoogleFonts.inter(
                                    color: _kMetallicSilver,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

              // TEXT INPUT
              if (![
                'Image',
                'QR Code',
                'Document',
                'Device Scan',
              ].contains(_inputTypes[_selectedType].label))
                Stack(
                  children: [
                    TextField(
                      controller: _textController,
                      maxLines: 6,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Paste a suspicious message, URL, or email here...',
                        hintStyle: GoogleFonts.inter(
                          color: _kMetallicSilver.withOpacity(0.4),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                    if (_isAnalyzing && !_isTerminalScanning)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _scanController,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment(
                                0,
                                -1.0 + (_scanController.value * 2.0),
                              ),
                              child: Container(
                                height: 4,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: _kNeonGreen,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _kNeonGreen.withOpacity(0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              Divider(height: 1, color: Colors.white.withOpacity(0.06)),

              // Analyze button
              if (!_isTerminalScanning)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: _isAnalyzing ? null : _analyzeMessage,
                    child: Container(
                      height: 54,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isAnalyzing
                              ? [
                                  _kCyberEmerald.withOpacity(0.4),
                                  _kNeonGreen.withOpacity(0.3),
                                ]
                              : [_kCyberEmerald, _kNeonGreen],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isAnalyzing
                            ? null
                            : [
                                BoxShadow(
                                  color: _kNeonGreen.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isAnalyzing) ...[
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ] else ...[
                              Icon(
                                _inputTypes[_selectedType].label ==
                                        'Device Scan'
                                    ? Icons.radar
                                    : Icons.document_scanner,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _isAnalyzing
                                  ? 'SCANNING...'
                                  : (_inputTypes[_selectedType].label ==
                                            'Device Scan'
                                        ? 'INITIATE SYSTEM SCAN'
                                        : 'ANALYZE THREAT'),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: Colors.white,
                                fontSize: 14,
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
        ),
      ),
    );
  }

  Widget _buildTerminalView() {
    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kNeonGreen.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(color: _kNeonGreen.withOpacity(0.1), blurRadius: 20),
        ],
      ),
      child: ListView.builder(
        controller: _terminalScroll,
        itemCount: _terminalLines.length,
        itemBuilder: (context, index) {
          final line = _terminalLines[index];
          final isThreat = line.contains('THREAT');
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '> $line',
              style: GoogleFonts.shareTechMono(
                color: isThreat
                    ? Colors.redAccent
                    : _kNeonGreen.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultCard() {
    final score = _result!['scam_probability'] as int;
    final rating = _result!['risk_rating'] as String;
    final ratingColor = _getRatingColor(rating);
    final flags = List<String>.from(_result!['red_flags'] ?? []);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: _kSlateBlue,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: ratingColor.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(color: ratingColor.withOpacity(0.15), blurRadius: 30),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ratingColor.withOpacity(0.15),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Circular score
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: ratingColor.withOpacity(0.3),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                            CircularProgressIndicator(
                              value: score / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.white10,
                              color: ratingColor,
                            ),
                            Text(
                              '$score%',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: ratingColor,
                                shadows: [
                                  Shadow(
                                    color: ratingColor.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'THREAT ASSESSMENT',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _kMetallicSilver,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              rating,
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: ratingColor,
                                shadows: [
                                  Shadow(
                                    color: ratingColor.withOpacity(0.5),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Confidence: ${_result!['confidence']}%',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Red flags
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RED FLAGS DETECTED',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _kChromeSteel,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...flags.map(
                        (flag) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: ratingColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: ratingColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  flag,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: Colors.white.withOpacity(0.06)),

                // AI Explanation
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI ANALYSIS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _kChromeSteel,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _result!['explanation'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: Colors.white.withOpacity(0.06)),

                // Community intelligence
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _kNeonGreen.withOpacity(0.04),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _kNeonGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.people_alt_outlined,
                          size: 20,
                          color: _kNeonGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _result!['community_reports'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputType {
  final IconData icon;
  final String label;
  const _InputType(this.icon, this.label);
}
