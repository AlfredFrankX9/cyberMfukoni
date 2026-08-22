import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/guardian_dialog.dart';
import '../utils/translations.dart';
import '../services/auth_service.dart';

class IntelFeedScreen extends StatefulWidget {
  const IntelFeedScreen({super.key});

  @override
  State<IntelFeedScreen> createState() => _IntelFeedScreenState();
}

class _IntelFeedScreenState extends State<IntelFeedScreen> {
  List<dynamic> _scams = [];
  bool _isLoading = true;
  String _displayName = '';

  /// Assigns a stable, non-repeating fallback image to every article.
  /// The sequence is seeded daily so it changes each day.
  List<dynamic> _assignFallbacks(List<dynamic> articles) {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final dailyRng = Random(seed);
    
    // Create a list of 1 to 29 and shuffle it using the daily seed
    final indices = List.generate(29, (i) => i + 1)..shuffle(dailyRng);
    int currentIndex = 0;

    return articles.map((article) {
      final map = Map<String, dynamic>.from(article as Map);
      
      final imageId = indices[currentIndex % indices.length];
      currentIndex++;
      map['fallback_image'] = 'assets/images/intel ($imageId).webp';
      
      return map;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchIntel();
    AuthService().getDisplayName().then((name) {
      if (mounted) setState(() => _displayName = name ?? '');
    });
  }

  Future<void> _fetchIntel() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await ApiService.get('/api/intel/feed');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final scamsList = _assignFallbacks(data['data'] ?? []);

        // If backend returned actual articles, use them
        if (scamsList.isNotEmpty) {
          await prefs.setString('cached_intel_feed', json.encode(scamsList));

          setState(() {
            _scams = scamsList;
            _isLoading = false;
          });
          return;
        }
        // If backend returned empty, fall through to cache/mock below
        debugPrint('API returned 200 but empty data, falling through to cache/mock');
      }
    } catch (e) {
      debugPrint('Failed to fetch real intel, attempting to load cache: $e');
      final cachedData = prefs.getString('cached_intel_feed');
      if (cachedData != null) {
        setState(() {
          _scams = _assignFallbacks(json.decode(cachedData));
          _isLoading = false;
        });
        if (mounted) {
          GuardianDialog.show(
            context,
            title: 'Offline Mode',
            message: context.tr('intel_offline_msg') ?? 'Viewing cached intel.',
            icon: Icons.wifi_off_rounded,
            color: Colors.orange,
            primaryButtonText: 'OK',
          );
        }
        return;
      }
    }

    // Mock fallback data
    setState(() {
      _scams = _assignFallbacks([
        {
          'id': 1,
          'title': 'KRA Tax Refund Phishing Wave Hits Nairobi',
          'summary':
              'Fraudsters impersonate KRA via SMS asking for PIN to claim fake refunds.',
          'threat_level': 'CRITICAL',
          'source': 'The Standard',
          'time_ago': '2h ago',
          'image_url': '',
          'url': '',
        },
        {
          'id': 2,
          'title': 'Fake M-Pesa Reversal Calls Targeting Traders',
          'summary':
              'Scammers pose as Safaricom agents to reverse mobile money transfers.',
          'threat_level': 'HIGH',
          'source': 'Business Daily',
          'time_ago': '5h ago',
          'image_url': '',
          'url': '',
        },
        {
          'id': 3,
          'title': 'Fake M-Pesa Reversal Calls Targeting Traders',
          'summary':
              'Scammers pose as Safaricom agents to reverse mobile money transfers.',
          'threat_level': 'HIGH',
          'source': 'Business Daily',
          'time_ago': '5h ago',
          'image_url': '',
          'url': '',
        },
        {
          'id': 4,
          'title': 'New SIM-Swap Scheme Reported in Mombasa',
          'summary':
              'Police warn of SIM registration fraud used to hijack bank OTPs.',
          'threat_level': 'MEDIUM',
          'source': 'Citizen Digital',
          'time_ago': '1d ago',
          'image_url': '',
          'url': '',
        },
      ]);
      _isLoading = false;
    });
  }

  Color _getThreatColor(String level) {
    switch (level.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFFFC107);
      case 'HIGH':
        return const Color(0xFF00FF55);
      case 'MEDIUM':
        return const Color(0xFF9E9E9E);
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    
    String welcomeText = context.tr('intel_welcome');
    if (!AuthService().isOfflineMode && _displayName.isNotEmpty) {
      welcomeText = '$welcomeText $_displayName';
    }

    return isWide ? _buildWideLayout(welcomeText) : _buildMobileLayout(welcomeText);
  }

  // ── Wide / desktop layout ──────────────────────────────────────────────────
  Widget _buildWideLayout(String welcomeText) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/live_feed background.webp',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/images/logo.webp', height: 100),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF00FF55).withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FF55).withOpacity(0.3),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Text(
                          context.tr('intel_live_feed'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00FF55),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Stack(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFF2A2A2A),
                                child: Icon(
                                  Icons.notifications,
                                  color: Colors.amber,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00FF55),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 200,
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    style: const TextStyle(color: Colors.grey),
                                    decoration: InputDecoration(
                                      hintText: context.tr('intel_search'),
                                      hintStyle: const TextStyle(color: Colors.grey),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const SizedBox(width: 150),
                      _buildFilterPill(
                        context.tr('intel_filter_all'),
                        const Color(0xFF00FF55),
                        Colors.black,
                        true,
                      ),
                      const SizedBox(width: 12),
                      _buildFilterPill(
                        context.tr('intel_filter_critical'),
                        const Color(0xFF6E6E6E),
                        Colors.white,
                        false,
                      ),
                      const SizedBox(width: 12),
                      _buildFilterPill(
                        context.tr('intel_filter_high'),
                        const Color(0xFF6E6E6E),
                        Colors.white,
                        false,
                      ),
                      const SizedBox(width: 12),
                      _buildFilterPill(
                        context.tr('intel_filter_medium'),
                        const Color(0xFF6E6E6E),
                        Colors.white,
                        false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      width: 650,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: Colors.black.withOpacity(0.1),
                            padding: const EdgeInsets.all(16),
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF00FF55),
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          childAspectRatio: 1.15,
                                        ),
                                    itemCount: _scams.length,
                                    itemBuilder: (context, index) =>
                                        _buildIntelCard(_scams[index]),
                                  ),
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

  Widget _buildFilterPill(
    String text,
    Color bgColor,
    Color textColor,
    bool isSelected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildIntelCard(Map<String, dynamic> scam) {
    final Color threatColor = _getThreatColor(scam['threat_level'] ?? '');
    final Color textColor =
        (scam['threat_level'] ?? '').toUpperCase() == 'CRITICAL'
        ? Colors.black
        : Colors.white;
    final String imageUrl = scam['image_url'] ?? '';
    final String fallback = scam['fallback_image'] ?? 'assets/images/intel (1).webp';
    final String sourceUrl = scam['url'] ?? '';

    return GestureDetector(
      onTap: () async {
        if (sourceUrl.isNotEmpty) {
          final uri = Uri.parse(sourceUrl);
          if (await canLaunchUrl(uri))
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E).withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: threatColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                scam['threat_level'] ?? '',
                style: TextStyle(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.white.withOpacity(0.1)),
                      // On network error → random intel image
                      errorWidget: (_, __, ___) => Image.asset(
                        fallback,
                        height: 90,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  // No URL at all → random intel image
                  : Image.asset(
                      fallback,
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              scam['title'] ?? '',
              style: const TextStyle(
                color: Color(0xFF00FF55),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                scam['summary'] ?? '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${scam['source'] ?? ''} • ${scam['time_ago'] ?? ''}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_outward,
                  color: Colors.white.withOpacity(0.5),
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile layout ──────────────────────────────────────────────────────────
  Widget _buildMobileLayout(String welcomeText) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1217),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    welcomeText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF00FF55),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          context.tr('intel_live_feed'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('intel_live'),
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _fetchIntel,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Color(0xFF00FF55),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00FF55),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      itemCount: _scams.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (context, index) =>
                          _buildMobileCard(_scams[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> scam) {
    final double maxCardHeight = MediaQuery.of(context).size.height * 0.35;
    final String imageUrl = scam['image_url'] ?? '';
    final String fallback = scam['fallback_image'] ?? 'assets/images/intel (1).webp';
    final String sourceDomain = scam['source'] ?? 'SOURCE';
    final String sourceUrl = scam['url'] ?? '';

    return GestureDetector(
      onTap: () async {
        if (sourceUrl.isNotEmpty) {
          final uri = Uri.parse(sourceUrl);
          if (await canLaunchUrl(uri))
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxCardHeight),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00FF55).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: SizedBox(
                  height: maxCardHeight * 0.5,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image: live URL → fallback random intel image on error → random intel image when no URL
                      if (imageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.black12),
                          errorWidget: (_, __, ___) =>
                              Image.asset(fallback, fit: BoxFit.cover),
                        )
                      else
                        Image.asset(fallback, fit: BoxFit.cover),

                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                const Color(0xFF161B22).withOpacity(0.9),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // LATEST INTEL badge
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF55),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            context.tr('intel_latest'),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Source badge
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            sourceDomain.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Details
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFF00FF55),
                            size: 12,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            scam['time_ago'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF00FF55),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scam['title'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          scam['summary'] ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
