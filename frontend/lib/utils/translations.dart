import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

const Map<String, Map<String, String>> _translations = {
  // ── Dashboard ─────────────────────────────────────────────────────────────
  'dashboard_quick_actions': {'en': 'QUICK ACTIONS', 'sw': 'HATUA ZA HARAKA'},
  'dashboard_secure_modules': {
    'en': 'Security Modules',
    'sw': 'Vipengele vya Usalama',
  },
  'dashboard_recent_activity': {
    'en': 'RECENT ACTIVITY',
    'sw': 'SHUGHULI ZA HIVI KARIBUNI',
  },
  'dashboard_greeting': {'en': 'Welcome back,', 'sw': 'Karibu tena,'},
  'dashboard_health_good': {'en': 'Good', 'sw': 'Nzuri'},
  'dashboard_health_fair': {'en': 'Fair', 'sw': 'Wastani'},
  'dashboard_health_critical': {'en': 'Critical', 'sw': 'Hatari'},
  'dashboard_health_status': {
    'en': 'Your digital security is looking strong today.',
    'sw': 'Usalama wako wa kidijitali unaonekana imara leo.',
  },
  'dashboard_health_status_fair': {
    'en': 'You have some security issues that need attention.',
    'sw': 'Una baadhi ya matatizo ya kiusalama yanayohitaji kutatuliwa.',
  },
  'dashboard_health_status_critical': {
    'en': 'Immediate action required to secure your device.',
    'sw': 'Hatua za haraka zinahitajika kulinda kifaa chako.',
  },
  'dashboard_health_overall': {'en': 'Overall Health', 'sw': 'Afya ya Kijumla'},
  'dashboard_quick_action_scan': {'en': 'Scan Device', 'sw': 'Kagua Kifaa'},
  'dashboard_quick_action_shred': {'en': 'Secure Shred', 'sw': 'Futa Kabisa'},
  'dashboard_quick_action_filter': {
    'en': 'DNS Filter',
    'sw': 'Kichujio cha DNS',
  },
  'module_boma': {'en': 'BOMA', 'sw': 'BOMA'},
  'module_boma_desc': {'en': 'Personal Security', 'sw': 'Usalama Binafsi'},
  'module_mulika': {'en': 'MULIKA', 'sw': 'MULIKA'},
  'module_mulika_desc': {'en': 'Threat Scanner', 'sw': 'Kigunduzi Hatari'},
  'module_vault': {'en': 'VAULT', 'sw': 'SEFU'},
  'module_vault_desc': {'en': 'Secure Storage', 'sw': 'Hifadhi Salama'},
  'module_agent': {'en': 'AGENT', 'sw': 'WAKALA'},
  'module_agent_desc': {'en': 'AI Assistant', 'sw': 'Msaidizi wa AI'},

  'settings_no_changes': {
    'en': 'No changes to save.',
    'sw': 'Hakuna mabadiliko ya kuhifadhi.',
  },
  'settings_profile_updated': {
    'en': 'Profile updated successfully!',
    'sw': 'Wasifu umesasishwa kikamilifu!',
  },
  'settings_update_failed': {
    'en': 'Update failed.',
    'sw': 'Usasishaji umeshindwa.',
  },
  'settings_network_error': {
    'en': 'Network error. Please try again.',
    'sw': 'Hitilafu ya mtandao. Tafadhali jaribu tena.',
  },
  'settings_opening_app_settings': {
    'en': 'Opening app settings to manage permissions.',
    'sw': 'Inafungua mipangilio ya programu kudhibiti ruhusa.',
  },
  'settings_notifications': {'en': 'Notifications', 'sw': 'Arifa'},
  'settings_clear_permissions_title': {
    'en': 'Clear Permissions',
    'sw': 'Futa Ruhusa',
  },
  'settings_clear_permissions_body': {
    'en':
        'This will reset all permissions granted to Cyber Mfukoni. You will be prompted to grant them again when needed.',
    'sw':
        'Hii itafuta ruhusa zote ulizotoa kwa Cyber Mfukoni. Utaulizwa kuzitoa tena utakapohitajika.',
  },
  'settings_clear_all': {'en': 'Clear All', 'sw': 'Futa Zote'},
  'settings_logout': {'en': 'Log Out', 'sw': 'Ondoka'},
  'settings_cancel': {'en': 'Cancel', 'sw': 'Ghairi'},
  'settings_confirm_logout': {
    'en': 'Are you sure you want to log out?',
    'sw': 'Una uhakika unataka kuondoka?',
  },
  'auth_fill_fields': {
    'en': 'Please fill all fields',
    'sw': 'Tafadhali jaza nafasi zote',
  },
  'auth_offline_login': {
    'en': 'Logged in offline. Some features may be limited.',
    'sw': 'Umeingia bila mtandao. Baadhi ya huduma zinaweza kuwa na mipaka.',
  },
  'auth_reset_password_title': {
    'en': 'Reset Password',
    'sw': 'Weka upya Nywila',
  },
  'auth_reset_password_desc': {
    'en': 'Enter your email address to receive a password reset link.',
    'sw': 'Weka barua pepe yako ili kupata kiungo cha kuweka upya nywila.',
  },
  'auth_reset_sent': {
    'en': 'Reset link sent to email!',
    'sw': 'Kiungo cha kuweka upya nywila kimetumwa kwenye barua pepe!',
  },
  'auth_send_link': {'en': 'Send Link', 'sw': 'Tuma Kiungo'},
  'auth_continue_google': {
    'en': 'Continue with Google',
    'sw': 'Endelea na Google',
  },
  'auth_google_failed': {
    'en': 'Google Sign-In failed:',
    'sw': 'Kuingia kwa Google kumeshindwa:',
  },
  'auth_hero_1': {'en': 'Protect Yourself From', 'sw': 'Jilinde Dhidi ya'},
  'auth_hero_2': {'en': 'Cyber Threats', 'sw': 'Vitisho Vya Mtandao'},
  'auth_pill_1': {'en': 'Confidentiality', 'sw': 'Usiri'},
  'auth_pill_2': {'en': 'Integrity', 'sw': 'Uadilifu'},
  'auth_pill_3': {'en': 'Availability', 'sw': 'Upatikanaji'},
  'perm_sensitive_found': {
    'en': 'SENSITIVE PERMISSIONS FOUND',
    'sw': 'RUHUSA NYETI ZILIZOPATIKANA',
  },
  'perm_no_sensitive': {
    'en': 'No highly sensitive permissions detected in this app. Safe to use.',
    'sw':
        'Hakuna ruhusa nyeti sana zilizopatikana kwenye programu hii. Salama kutumia.',
  },
  'perm_uninstall': {
    'en': 'UNINSTALL APP (VIA SETTINGS)',
    'sw': 'ONDOA PROGRAMU (KUPITIA MIPANGILIO)',
  },
  'perm_open_settings': {
    'en': 'OPEN APP SETTINGS',
    'sw': 'FUNGUA MIPANGILIO YA PROGRAMU',
  },
  'perm_based_on': {
    'en': 'Based on requested permissions from user-installed apps.',
    'sw':
        'Kulingana na ruhusa zilizoombwa na programu zilizosakinishwa na mtumiaji.',
  },
  'dashboard_system_status': {'en': 'SYSTEM STATUS', 'sw': 'HALI YA MFUMO'},
  'dashboard_score_breakdown': {
    'en': 'SCORE BREAKDOWN',
    'sw': 'MCHANGANUO WA ALAMA',
  },
  'dashboard_device_security': {
    'en': 'Device Security',
    'sw': 'Usalama wa Kifaa',
  },
  'dashboard_vault_setup': {'en': 'Vault Setup', 'sw': 'Mpangilio wa Sefu'},
  'dashboard_chonjo_xp': {'en': 'Chonjo XP', 'sw': 'Chonjo XP'},
  'log_scan_clear': {
    'en': 'System scan clear. No threats detected.',
    'sw': 'Mfumo ni salama. Hakuna vitisho.',
  },
  'log_vpn_established': {
    'en': 'Secure VPN connection established.',
    'sw': 'Uunganisho wa VPN salama umeanzishwa.',
  },
  'log_ad_tracker_blocked': {
    'en': 'Suspicious ad-tracker blocked.',
    'sw': 'Kifuatiliaji kinachotia shaka kimezuiliwa.',
  },
  'time_just_now': {'en': 'Just now', 'sw': 'Sasa hivi'},
  'time_2h_ago': {'en': '2h ago', 'sw': 'Saa 2 zilizopita'},
  'time_5h_ago': {'en': '5h ago', 'sw': 'Saa 5 zilizopita'},
  'dns_title': {'en': 'DNS FILTER', 'sw': 'KICHUJI CHA DNS'},
  'dns_active': {'en': 'PROTECTION ACTIVE', 'sw': 'ULINZI UPO TAYARI'},
  'dns_disabled': {'en': 'PROTECTION DISABLED', 'sw': 'ULINZI UMEZIMWA'},
  'dns_desc': {
    'en':
        'Blocks malware, phishing, and tracking domains at the network level.',
    'sw':
        'Huzuia programu hasidi, wizi wa mtandao, na vifuatiliaji katika kiwango cha mtandao.',
  },
  'dns_enable': {'en': 'Enable DNS Filter', 'sw': 'Washa Kichuji cha DNS'},
  'dns_blocked': {'en': 'BLOCKED THREATS', 'sw': 'VITISHO VILIVYOZUIWA'},
  'dns_active_filters': {'en': 'ACTIVE FILTERS', 'sw': 'VICHUJI VILIVYOWASHWA'},
  'dns_categories': {'en': 'PROTECTION CATEGORIES', 'sw': 'AINA ZA ULINZI'},
  'dns_malware': {'en': 'Malware Domains', 'sw': 'Tovuti za Programu Hasidi'},
  'dns_malware_desc': {
    'en': 'Blocks known malware distribution sites',
    'sw': 'Huzuia tovuti zinazojulikana kusambaza programu hasidi',
  },
  'dns_phishing': {'en': 'Phishing', 'sw': 'Ulaghai wa Mtandaoni'},
  'dns_phishing_desc': {
    'en': 'Blocks deceptive domains that steal credentials',
    'sw': 'Huzuia tovuti za udanganyifu zinazoiba taarifa za siri',
  },
  'dns_trackers': {'en': 'Trackers', 'sw': 'Vifuatiliaji'},
  'dns_trackers_desc': {
    'en': 'Blocks cross-site tracking and analytics',
    'sw': 'Huzuia ufuatiliaji kati ya tovuti na takwimu',
  },
  'dns_ads': {'en': 'Ad Networks', 'sw': 'Mitandao ya Matangazo'},
  'dns_ads_desc': {
    'en': 'Blocks invasive ad-serving domains',
    'sw': 'Huzuia tovuti zenye matangazo yanayosumbua',
  },
  'shred_grant_access_title': {
    'en': 'Grant File Access',
    'sw': 'Toa Ruhusa ya Faili',
  },
  'shred_grant_access_desc': {
    'en':
        'Android has opened Settings. Please find "The Guardian" in the list and toggle "Allow access to manage all files" ON, then press Back to return here.',
    'sw':
        'Android imefungua Mipangilio. Tafadhali pata "The Guardian" kwenye orodha na uwashe "Ruhusu ufikiaji wa kudhibiti faili zote", kisha rudi hapa.',
  },
  'shred_granted': {'en': 'I\'ve granted it', 'sw': 'Nimetoa ruhusa'},
  'shred_warning_title': {
    'en': 'WARNING: PERMANENT DELETION',
    'sw': 'ONYO: KUFUTA KWA KUDUMU',
  },
  'shred_warning_desc': {
    'en': 'You are about to securely shred',
    'sw': 'Uko karibu kufuta kabisa faili',
  },
  'shred_warning_desc2': {
    'en':
        'file(s). This action cannot be undone. Digital forensic recovery will be impossible. Are you sure?',
    'sw':
        'Kitendo hiki hakiwezi kutenduliwa. Urejeshaji utakuwa hauwezekani. Una uhakika?',
  },
  'shred_obliterate': {'en': 'OBLITERATE', 'sw': 'FUTA KABISA'},
  'shred_in_progress': {
    'en': 'SHREDDING IN PROGRESS:',
    'sw': 'UFUTAJI UNAENDELEA:',
  },
  'shred_explorer_title': {
    'en': 'GUARDIAN FILE EXPLORER',
    'sw': 'KIGUNDUZI CHA FAILI CHA GUARDIAN',
  },
  'shred_empty_dir': {'en': 'Empty directory', 'sw': 'Saraka tupu'},
  'shred_access_denied': {
    'en': 'Access denied or empty directory.',
    'sw': 'Ufikiaji umezuiwa au saraka tupu.',
  },
  'shred_selected': {'en': 'selected', 'sw': 'zilizochaguliwa'},
  'scan_title': {'en': 'SMART SCAN', 'sw': 'UPEKUZI WA KINA'},
  'scan_in_progress': {'en': 'SCAN IN PROGRESS', 'sw': 'UPEKUZI UNAENDELEA'},
  'scan_complete': {'en': 'SCAN COMPLETE', 'sw': 'UPEKUZI UMEKAMILIKA'},
  'scan_rescan': {'en': 'RE-SCAN DEVICE', 'sw': 'PEKUA KIFAA TENA'},
  'scan_scanned_apps': {
    'en': 'SCANNED APPLICATIONS',
    'sw': 'PROGRAMU ZILIZOPEKULIWA',
  },
  'scan_gathering': {
    'en': 'Gathering installed apps...',
    'sw': 'Inakusanya programu zilizosakinishwa...',
  },
  'scan_no_apps': {
    'en': 'No user apps found to scan.',
    'sw': 'Hakuna programu za mtumiaji zilizopatikana.',
  },
  'scan_scanning': {
    'en': 'Scanning against threat database...',
    'sw': 'Inapekua dhidi ya hifadhidata ya vitisho...',
  },
  'scan_cloud_unavail': {
    'en': 'Cloud unavailable. Running local heuristic scan...',
    'sw': 'Wingu halipatikani. Inatumia upekuzi wa ndani...',
  },
  'scan_error': {'en': 'Scan error:', 'sw': 'Hitilafu ya upekuzi:'},
  'scan_unknown_app': {'en': 'Unknown App', 'sw': 'Programu Isiyojulikana'},
  'scan_status': {'en': 'STATUS:', 'sw': 'HALI:'},
  'scan_paused': {
    'en': 'Scan paused due to API rate limits.',
    'sw': 'Upekuzi umesitishwa kwa sababu ya kikomo cha API.',
  },
  'scan_no_malware': {
    'en': 'No known malware signatures detected.',
    'sw': 'Hakuna viashiria vya programu hasidi vilivyogunduliwa.',
  },
  'scan_uninstall': {'en': 'UNINSTALL APP', 'sw': 'ONDOA PROGRAMU'},
  'scan_open_settings': {'en': 'OPEN SETTINGS', 'sw': 'FUNGUA MIPANGILIO'},
  'mod_secure_modules': {'en': 'Secure Modules', 'sw': 'Vipengele vya Usalama'},
  'mod_dns_filter': {'en': 'DNS Filter', 'sw': 'Kichuji cha DNS'},
  'mod_dns_desc': {
    'en': 'Block malicious domains and trackers at the network level',
    'sw': 'Zuia tovuti hasidi na vifuatiliaji katika kiwango cha mtandao',
  },
  'mod_smart_scan': {'en': 'Smart Scan', 'sw': 'Upekuzi wa Kina'},
  'mod_scan_desc': {
    'en': 'Scan your device and files for known threats',
    'sw': 'Pekua kifaa chako na faili kutafuta vitisho vinavyojulikana',
  },
  'mod_app_perms': {'en': 'App Permissions', 'sw': 'Ruhusa za Programu'},
  'mod_perms_desc': {
    'en': 'Audit and manage sensitive permissions granted to apps',
    'sw': 'Kagua na dhibiti ruhusa nyeti ulizotoa kwa programu',
  },
  'mod_shredder': {'en': 'Secure Shredder', 'sw': 'Kifutaji Salama'},
  'mod_shredder_desc': {
    'en': 'Permanently obliterate files beyond recovery',
    'sw': 'Futa faili kabisa bila uwezekano wa kurejeshwa',
  },
  'mod_parental': {'en': 'Parental Controls', 'sw': 'Udhibiti wa Wazazi'},
  'mod_parental_desc': {
    'en': 'Block inappropriate websites and restrict app access',
    'sw': 'Zuia tovuti zisizofaa na dhibiti ufikiaji wa programu',
  },
  'parent_title': {'en': 'PARENTAL CONTROLS', 'sw': 'UDHIBITI WA WAZAZI'},
  'parent_websites': {'en': 'WEBSITES', 'sw': 'TOVUTI'},
  'parent_apps': {'en': 'APPS', 'sw': 'PROGRAMU'},
  'parent_dns_info': {
    'en':
        'Blocked domains are filtered by the DNS VPN. Enable the DNS Filter to activate blocking.',
    'sw':
        'Tovuti zilizozuiwa huchujwa na VPN ya DNS. Washa Kichuji cha DNS ili kuanza kuzuia.',
  },
  'parent_blocked_sites': {'en': 'BLOCKED SITES', 'sw': 'TOVUTI ZILIZOZUIWA'},
  'parent_no_sites': {
    'en': 'No sites blocked yet.\nAdd a domain above to get started.',
    'sw': 'Hakuna tovuti zilizozuiwa bado.\nOngeza tovuti hapo juu ili kuanza.',
  },
  'parent_app_info': {
    'en':
        'Toggle apps below to block them. When a blocked app is opened, The Guardian will display a block screen.',
    'sw':
        'Washa programu hapa chini ili kuzizuia. Programu iliyozuiwa ikifunguliwa, The Guardian itaonyesha skrini ya kuzuia.',
  },
  'parent_installed': {
    'en': 'INSTALLED APPS',
    'sw': 'PROGRAMU ZILIZOSAKINISHWA',
  },
  'parent_blocked_count': {'en': 'BLOCKED', 'sw': 'ZILIZOZUIWA'},
  'parent_no_apps': {
    'en': 'No apps found.',
    'sw': 'Hakuna programu zilizopatikana.',
  },
  'parent_eg_domain': {'en': 'e.g. example.com', 'sw': 'mf. mfano.com'},
  'parent_usage_req': {
    'en':
        'Usage Access permission is required to monitor which app is in the foreground.',
    'sw':
        'Ruhusa ya Ufikiaji wa Matumizi inahitajika ili kufuatilia ni programu gani iko mbele.',
  },
  'parent_grant_usage': {
    'en': 'GRANT USAGE ACCESS',
    'sw': 'TOA RUHUSA YA MATUMIZI',
  },
  'parent_overlay_req': {
    'en':
        'Display Over Other Apps permission is REQUIRED to block apps in the background.',
    'sw':
        'Ruhusa ya Kuonyesha Juu ya Programu Nyingine INAHITAJIKA ili kuzuia programu chini kwa chini.',
  },
  'parent_grant_overlay': {
    'en': 'GRANT DISPLAY ACCESS',
    'sw': 'TOA RUHUSA YA KUONYESHA',
  },
  'parent_grant_usage_title': {
    'en': 'Grant Usage Access',
    'sw': 'Toa Ruhusa ya Matumizi',
  },
  'parent_grant_usage_desc': {
    'en':
        'Android Settings has opened. Find "The Guardian" in the list and toggle it ON to allow app monitoring.\n\nThen press Back to return here.',
    'sw':
        'Mipangilio ya Android imefunguliwa. Pata "The Guardian" kwenye orodha na uiwashe ili kuruhusu ufuatiliaji wa programu.\n\nKisha rudi hapa.',
  },
  'parent_grant_overlay_title': {
    'en': 'Grant Display Over Other Apps',
    'sw': 'Toa Ruhusa ya Kuonyesha Juu ya Programu',
  },
  'parent_grant_overlay_desc': {
    'en':
        'Android Settings has opened. Find "The Guardian" and toggle it ON to allow drawing the block screen over restricted apps.\n\nThen press Back to return here.',
    'sw':
        'Mipangilio ya Android imefunguliwa. Pata "The Guardian" na uiwashe ili kuruhusu kuonyesha skrini ya kuzuia kwenye programu zilizozuiwa.\n\nKisha rudi hapa.',
  },
  'agent_title': {'en': 'The Guardian', 'sw': 'The Guardian'},
  'agent_quick_phishing': {
    'en': 'What is phishing?',
    'sw': 'Ulaghai wa mtandaoni ni nini?',
  },
  'agent_quick_password': {
    'en': 'Password tips',
    'sw': 'Vidokezo vya nenosiri',
  },
  'agent_quick_hacked': {'en': 'I got hacked', 'sw': 'Nimedukuliwa'},
  'agent_quick_sim': {'en': 'SIM swap help', 'sw': 'Msaada wa kubadilisha SIM'},
  'agent_input_hint': {
    'en': 'Ask anything about digital safety...',
    'sw': 'Uliza chochote kuhusu usalama wa kidijitali...',
  },
  'agent_hero_text': {
    'en': 'Your Guardian Against\nDigital Threats',
    'sw': 'Mlinzi Wako Dhidi ya\nVitisho vya Kidijitali',
  },
  'mulika_device_scan': {'en': 'Device Scan', 'sw': 'Pekua Kifaa'},
  'mulika_sms': {'en': 'SMS', 'sw': 'SMS'},
  'mulika_email': {'en': 'Email', 'sw': 'Barua pepe'},
  'mulika_url': {'en': 'URL', 'sw': 'Kiungo (URL)'},
  'mulika_qr_code': {'en': 'QR Code', 'sw': 'Msimbo wa QR'},
  'mulika_image': {'en': 'Image', 'sw': 'Picha'},
  'mulika_document': {'en': 'Document', 'sw': 'Hati'},
  'mulika_choose_gallery': {
    'en': 'Choose from Gallery',
    'sw': 'Chagua kutoka kwenye Matunzio',
  },
  'mulika_take_photo': {'en': 'Take a Photo', 'sw': 'Piga Picha'},
  'mulika_error_camera': {
    'en': 'Could not open camera/gallery:',
    'sw': 'Imeshindwa kufungua kamera/matunzio:',
  },

  'mulika_select_target': {'en': 'SELECT TARGET:', 'sw': 'CHAGUA LENGWA:'},
  'mulika_scanning': {'en': 'SCANNING...', 'sw': 'INAPEKUA...'},
  'mulika_initiate_scan': {
    'en': 'INITIATE SYSTEM SCAN',
    'sw': 'ANZISHA UPEKUZI WA MFUMO',
  },
  'mulika_analyze_threat': {'en': 'ANALYZE THREAT', 'sw': 'CHAMBUA TISHO'},
  'mulika_threat_assessment': {
    'en': 'THREAT ASSESSMENT',
    'sw': 'TATHMINI YA TISHO',
  },
  'mulika_confidence': {'en': 'Confidence', 'sw': 'Uhakika'},
  'mulika_red_flags': {
    'en': 'RED FLAGS DETECTED',
    'sw': 'VIASHIRIA VYA HATARI VILIVYOGUNDULIWA',
  },
  'mulika_ai_analysis': {'en': 'AI ANALYSIS', 'sw': 'UCHAMBUZI WA AI'},
  'mulika_paste_hint': {
    'en': 'Paste a suspicious message, URL, or email here...',
    'sw': 'Bandika ujumbe wa kutiliwa shaka, kiungo, au barua pepe hapa...',
  },
  'mulika_tap_doc': {
    'en': 'Tap to upload document',
    'sw': 'Bofya kupakia hati',
  },
  'mulika_tap_img': {'en': 'Tap to upload image', 'sw': 'Bofya kupakia picha'},
  // ── Home / Navigation ────────────────────────────────────────────────────────────
  'nav_vault': {'en': 'Vault', 'sw': 'Sefu'},
  'nav_boma': {'en': 'Boma', 'sw': 'Boma'},
  'nav_mulika': {'en': 'Mulika', 'sw': 'Mulika'},
  'nav_home': {'en': 'Home', 'sw': 'Mwanzo'},
  'nav_intel': {'en': 'Intel', 'sw': 'Taarifa'},
  'nav_agent': {'en': 'Agent', 'sw': 'Wakala'},
  'nav_secure_modules': {'en': 'Security Modules', 'sw': 'Vipengele vya Usalama'},

  // ── Settings ──────────────────────────────────────────────────────────────
  'settings_title': {'en': 'Settings', 'sw': 'Mipangilio'},
  'settings_account_mgmt': {
    'en': 'ACCOUNT MANAGEMENT',
    'sw': 'USIMAMIZI WA AKAUNTI',
  },
  'settings_username': {'en': 'Username', 'sw': 'Jina la Mtumiaji'},
  'settings_email': {'en': 'Email', 'sw': 'Barua Pepe'},
  'settings_change_password': {
    'en': 'Change Password',
    'sw': 'Badilisha Nenosiri',
  },
  'settings_current_password': {
    'en': 'Current password',
    'sw': 'Nenosiri la sasa',
  },
  'settings_new_password': {'en': 'New password', 'sw': 'Nenosiri jipya'},
  'settings_save_changes': {'en': 'Save Changes', 'sw': 'Hifadhi Mabadiliko'},
  'settings_preferences': {'en': 'PREFERENCES', 'sw': 'MAPENDELEO'},
  'settings_language': {'en': 'Language', 'sw': 'Lugha'},

  'settings_privacy_security': {
    'en': 'PRIVACY & SECURITY',
    'sw': 'FARAGHA NA USALAMA',
  },
  'settings_app_permissions': {
    'en': 'App Permissions',
    'sw': 'Ruhusa za Programu',
  },
  'settings_permissions_desc': {
    'en': 'Manage access given to the app',
    'sw': 'Dhibiti ufikiaji uliopewa programu',
  },
  'settings_clear_permissions': {
    'en': 'Clear App Permissions',
    'sw': 'Futa Ruhusa za Programu',
  },
  'settings_clear_permissions_desc': {
    'en': 'Reset granted permissions for this app',
    'sw': 'Weka upya ruhusa zilizopewa',
  },

  // ── Permissions ───────────────────────────────────────────────────────────
  'perm_camera': {'en': 'Camera', 'sw': 'Kamera'},
  'perm_microphone': {'en': 'Microphone', 'sw': 'Kipaza Sauti'},
  'perm_location': {'en': 'Location', 'sw': 'Eneo'},
  'perm_contacts': {'en': 'Contacts', 'sw': 'Majina'},
  'perm_storage': {'en': 'Storage / Photos', 'sw': 'Hifadhi / Picha'},
  'perm_notification': {'en': 'Notifications', 'sw': 'Arifa'},
  'perm_revoke_warning': {
    'en': 'To revoke permissions, you must do so from your device settings.',
    'sw':
        'Ili kufuta ruhusa, lazima ufanye hivyo kupitia mipangilio ya kifaa chako.',
  },

  // ── Boma ──────────────────────────────────────────────────────────────────
  'boma_title': {'en': 'Boma Security', 'sw': 'Usalama wa Boma'},
  'boma_score': {'en': 'Security Score', 'sw': 'Alama ya Usalama'},
  'boma_protection_guides': {
    'en': 'Protection Guides',
    'sw': 'Miongozo ya Ulinzi',
  },

  // ── Mulika ────────────────────────────────────────────────────────────────
  'mulika_title': {'en': 'Mulika Scanner', 'sw': 'Kigunduzi cha Mulika'},
  'mulika_analyze_msg': {
    'en': 'Analyze Message/Link',
    'sw': 'Changanua Ujumbe/Kiungo',
  },
  'mulika_scan_device': {
    'en': 'Scan Device Apps',
    'sw': 'Kagua Programu za Kifaa',
  },
  'mulika_scan_files': {'en': 'Scan Files', 'sw': 'Kagua Faili'},
  'mulika_placeholder': {
    'en': 'Paste suspicious SMS or Link here...',
    'sw': 'Bandika SMS au Kiungo kinachotiliwa shaka hapa...',
  },
  'mulika_analyze_btn': {'en': 'Analyze', 'sw': 'Changanua'},

  // ── Agent ─────────────────────────────────────────────────────────────────
  'agent_status': {'en': 'Online & Ready', 'sw': 'Yupo Tayari'},
  'agent_hero': {
    'en': 'Your Guardian Against\nDigital Threats',
    'sw': 'Mlinzi Wako Dhidi\nya Vitisho vya Kidijitali',
  },
  'agent_copy': {'en': 'Copy', 'sw': 'Nakili'},
  'agent_retry': {'en': 'Retry', 'sw': 'Jaribu Tena'},

  // ── Vault ─────────────────────────────────────────────────────────────────
  'vault_title': {'en': 'Secure Vault', 'sw': 'Sefu Salama'},

  // ── General / Auth ────────────────────────────────────────────────────────
  'auth_login': {'en': 'Login', 'sw': 'Ingia'},
  'auth_signup': {'en': 'Sign Up', 'sw': 'Jisajili'},
  'auth_email': {'en': 'Email', 'sw': 'Barua Pepe'},
  'auth_password': {'en': 'Password', 'sw': 'Nenosiri'},
  'copied_to_clipboard': {
    'en': 'Copied to clipboard',
    'sw': 'Imenakiliwa kwenye ubao wako',
  },
  'online_status': {'en': 'Online & Ready', 'sw': 'Yupo Tayari'},
  'chat_cleared': {
    'en': 'Chat cleared. How can I help you?',
    'sw': 'Gumzo limefutwa. Nikusaidieje?',
  },
  'clear_chat': {'en': 'Clear Chat', 'sw': 'Futa Gumzo'},
  'copy': {'en': 'Copy', 'sw': 'Nakili'},
  'retry': {'en': 'Retry', 'sw': 'Jaribu Tena'},

  'vault_auth_desc': {
    'en': 'Authenticate to access your secure vault',
    'sw': 'Thibitisha ili kufikia sefu yako salama',
  },
  'vault_authenticate': {'en': 'Authenticate', 'sw': 'Thibitisha'},
  'vault_cards': {'en': 'Cards', 'sw': 'Kadi'},
  'vault_encrypted_storage': {
    'en': 'Encrypted Storage',
    'sw': 'Hifadhi Iliyosimbwa',
  },
  'vault_encryption': {'en': 'AES-256 Encryption', 'sw': 'Usimbaji AES-256'},
  'vault_files_count': {'en': 'Files', 'sw': 'Faili'},
  'vault_health': {'en': 'Vault Health', 'sw': 'Afya ya Sefu'},
  'vault_last_backup': {'en': 'Last Backup', 'sw': 'Hifadhi ya Mwisho'},
  'vault_locked': {'en': 'Vault Locked', 'sw': 'Sefu Imefungwa'},
  'vault_notes_count': {'en': 'Notes', 'sw': 'Vidokezo'},
  'vault_recovery': {'en': 'Recovery', 'sw': 'Urejeshaji'},
  'vault_saved': {'en': 'Saved successfully', 'sw': 'Imehifadhiwa'},
  'vault_services_count': {'en': 'Services', 'sw': 'Huduma'},
  // ── Newly Added Keys ──────────────────────────────────────────────────────
  'boma_security_checklist': {
    'en': 'SECURITY CHECKLIST',
    'sw': 'ORODHA YA USALAMA',
  },
  'vault_defense': {'en': 'DEFENSE', 'sw': 'ULINZI'},
  'vault_dark_web': {'en': 'DARK WEB', 'sw': 'MTANDAO GIZA'},
  'vault_secure': {'en': 'SECURE', 'sw': 'SALAMA'},
  'auth_login_title': {'en': 'Welcome Back', 'sw': 'Karibu Tena'},
  'auth_signup_title': {'en': 'Create Account', 'sw': 'Fungua Akaunti'},
  'auth_login_desc': {
    'en': 'Log in to continue protecting your digital life',
    'sw': 'Ingia ili uendelee kulinda maisha yako ya kidijitali',
  },
  'auth_signup_desc': {
    'en': 'Sign up to unlock advanced digital protection',
    'sw': 'Jisajili ili upate ulinzi wa hali ya juu wa kidijitali',
  },
  'auth_username': {'en': 'USERNAME', 'sw': 'JINA LA MTUMIAJI'},
  'auth_username_email': {
    'en': 'USERNAME OR EMAIL ADDRESS',
    'sw': 'JINA LA MTUMIAJI AU BARUA PEPE',
  },

  'auth_forgot_password': {
    'en': 'Forgot password?',
    'sw': 'Umesahau nenosiri?',
  },
  'auth_login_btn': {'en': 'Log In', 'sw': 'Ingia'},
  'auth_signup_btn': {'en': 'Sign Up', 'sw': 'Jisajili'},
  'auth_dont_have_account': {
    'en': "Don't have an account?  ",
    'sw': "Hauna akaunti?  ",
  },
  'auth_already_have_account': {
    'en': "Already have an account?  ",
    'sw': "Tayari una akaunti?  ",
  },

  // ── Vault – Active Defense ─────────────────────────────────────────────────
  'vault_active_defense': {'en': 'ACTIVE DEFENSE', 'sw': 'ULINZI AMILIFU'},
  'vault_active_defense_desc': {
    'en': 'Verify suspicious numbers or report threats to alert other agents.',
    'sw':
        'Thibitisha nambari zenye mashaka au ripoti vitisho ili kuonya mawakala wengine.',
  },
  'vault_check': {'en': 'CHECK', 'sw': 'KAGUA'},
  'vault_verify_number': {'en': 'Verify Number', 'sw': 'Thibitisha Nambari'},
  'vault_report': {'en': 'REPORT', 'sw': 'RIPOTI'},
  'vault_flag_threat': {'en': 'Flag Threat', 'sw': 'Onya Tishio'},
  'vault_check_number': {'en': 'Check Number', 'sw': 'Kagua Nambari'},
  'vault_check_number_desc': {
    'en': 'Enter a phone number to check if it has been reported for scams.',
    'sw': 'Ingiza nambari ya simu ili kuona ikiwa imeripotiwa kwa ulaghai.',
  },
  'vault_safe': {'en': 'SAFE', 'sw': 'SALAMA'},
  'vault_safe_desc': {
    'en': 'This number has not been reported.',
    'sw': 'Nambari hii haijaripotiwa.',
  },
  'vault_danger': {'en': '⚠ DANGER', 'sw': '⚠ HATARI'},
  'vault_scam_type': {'en': 'Scam Type', 'sw': 'Aina ya Ulaghai'},
  'vault_reports': {'en': 'Reports', 'sw': 'Ripoti'},
  'vault_last_reported': {'en': 'Last Reported', 'sw': 'Ripoti ya Mwisho'},
  'vault_report_number': {'en': 'Report Number', 'sw': 'Ripoti Nambari'},
  'vault_report_number_desc': {
    'en': 'Report a fraudulent number to protect others.',
    'sw': 'Ripoti nambari ya ulaghai ili kulinda wengine.',
  },
  'vault_report_submitted': {'en': 'Report Submitted', 'sw': 'Ripoti Imetumwa'},
  'vault_report_thankyou': {
    'en':
        'Thank you for helping protect the community. This number has been flagged in the database.',
    'sw':
        'Asante kwa kusaidia kulinda jamii. Nambari hii imeandikwa kwenye hifadhidata.',
  },
  'vault_close': {'en': 'CLOSE', 'sw': 'FUNGA'},
  'vault_phone_number': {'en': 'Phone Number', 'sw': 'Nambari ya Simu'},
  'vault_category': {'en': 'Category', 'sw': 'Kategoria'},
  'vault_details': {'en': 'Details (optional)', 'sw': 'Maelezo (si lazima)'},
  'vault_submit': {'en': 'SUBMIT REPORT', 'sw': 'TUMA RIPOTI'},
  'vault_fortress_analyzer': {
    'en': 'FORTRESS ANALYZER',
    'sw': 'KICHAMBUZI CHA NGOME',
  },
  'vault_fortress_desc': {
    'en': 'Enter a password to assess its strength in real-time.',
    'sw': 'Ingiza nenosiri ili kutathmini nguvu zake kwa wakati halisi.',
  },
  'vault_enter_password': {
    'en': 'Enter a password to test...',
    'sw': 'Ingiza nenosiri la kujaribu...',
  },
  'vault_system_status': {'en': 'System Status:', 'sw': 'Hali ya Mfumo:'},

  // ── Vault Sub-Screens ─────────────────────────────────────────────────────
  'vault_passwords': {'en': 'Passwords', 'sw': 'Nywila'},
  'vault_add_password': {'en': 'Add Password', 'sw': 'Ongeza Nywila'},
  'vault_website_app': {
    'en': 'Website / App Name',
    'sw': 'Tovuti / Jina la Programu',
  },
  'vault_username_email': {
    'en': 'Username / Email',
    'sw': 'Jina la Mtumiaji / Barua Pepe',
  },
  'vault_password': {'en': 'Password', 'sw': 'Nenosiri'},
  'vault_save': {'en': 'SAVE', 'sw': 'HIFADHI'},
  'vault_no_passwords': {
    'en': 'No passwords saved yet.',
    'sw': 'Hakuna nywila zilizohifadhiwa bado.',
  },
  'vault_notes': {'en': 'Secure Notes', 'sw': 'Maelezo Salama'},
  'vault_no_notes': {
    'en': 'No secure notes saved yet.',
    'sw': 'Hakuna maelezo salama yaliyohifadhiwa bado.',
  },
  'vault_note_title': {'en': 'Title', 'sw': 'Kichwa'},
  'vault_note_hint': {
    'en': 'Start typing your secure note here...',
    'sw': 'Anza kuandika maelezo yako salama hapa...',
  },
  'vault_credit_cards': {'en': 'Credit Cards', 'sw': 'Kadi za Mkopo'},
  'vault_add_card': {'en': 'Add Card', 'sw': 'Ongeza Kadi'},
  'vault_cardholder': {
    'en': 'Cardholder Name',
    'sw': 'Jina la Mmiliki wa Kadi',
  },
  'vault_card_number': {'en': 'Card Number', 'sw': 'Nambari ya Kadi'},
  'vault_no_cards': {
    'en': 'No credit cards saved yet.',
    'sw': 'Hakuna kadi za mkopo zilizohifadhiwa bado.',
  },
  'vault_cardholder_label': {'en': 'CARDHOLDER', 'sw': 'MMILIKI'},
  'vault_expires_label': {'en': 'EXPIRES', 'sw': 'INAISHA'},
  'vault_files': {'en': 'Hidden Files', 'sw': 'Faili Zilizofichwa'},
  'vault_no_files': {
    'en': 'No files hidden yet. Tap + to import.',
    'sw': 'Hakuna faili zilizofichwa bado. Bonyeza + kuongeza.',
  },
  'vault_importing': {
    'en': 'Importing and Encrypting...',
    'sw': 'Inaingiza na Kusimba...',
  },
  'vault_restore': {
    'en': 'Restore to Downloads folder',
    'sw': 'Rejesha kwenye folda ya Upakuaji',
  },
  'vault_delete_permanent': {
    'en': 'Delete Permanently from Vault',
    'sw': 'Futa Kabisa kutoka Sefu',
  },
  'vault_file_restored': {
    'en': 'File restored to Downloads folder',
    'sw': 'Faili imerejeshwa kwenye folda ya Upakuaji',
  },
  'vault_file_deleted': {
    'en': 'File deleted permanently',
    'sw': 'Faili imefutwa kabisa',
  },
  'vault_photos': {'en': 'Private Photos', 'sw': 'Picha Binafsi'},
  'vault_no_photos': {
    'en': 'No photos hidden yet. Tap + to import.',
    'sw': 'Hakuna picha zilizofichwa bado. Bonyeza + kuongeza.',
  },
  'vault_photo_restored': {
    'en': 'Photo restored to Downloads',
    'sw': 'Picha imerejeshwa kwenye Upakuaji',
  },
  'vault_photo_deleted': {
    'en': 'Photo deleted permanently',
    'sw': 'Picha imefutwa kabisa',
  },
  'vault_recovery_codes': {
    'en': 'Recovery Codes',
    'sw': 'Misimbo ya Kurejesha',
  },
  'vault_add_code': {'en': 'Add Code', 'sw': 'Ongeza Msimbo'},
  'vault_app_website': {
    'en': 'App / Website Name',
    'sw': 'Jina la Programu / Tovuti',
  },
  'vault_recovery_code': {'en': 'Recovery Code', 'sw': 'Msimbo wa Kurejesha'},
  'vault_no_codes': {
    'en': 'No recovery codes saved yet.',
    'sw': 'Hakuna misimbo ya kurejesha iliyohifadhiwa bado.',
  },
  'vault_code_copied': {
    'en': 'Code copied to clipboard!',
    'sw': 'Msimbo umenakiliwa!',
  },
  'vault_error_pick_file': {
    'en': 'Error picking file:',
    'sw': 'Hitilafu ya kuchagua faili:',
  },
  'vault_error_pick_photo': {
    'en': 'Error picking photo:',
    'sw': 'Hitilafu ya kuchagua picha:',
  },

  // ── Boma Extras ────────────────────────────────────────────────────────────
  'boma_screen_lock': {
    'en': 'Screen Lock Enabled',
    'sw': 'Kufunga Skrini Kumewashwa',
  },
  'boma_screen_lock_desc': {
    'en': 'Use PIN, fingerprint, or face unlock',
    'sw': 'Tumia PIN, alama ya kidole, au uso',
  },
  'boma_biometric': {
    'en': 'Biometric Authentication',
    'sw': 'Uthibitishaji wa Kibiometria',
  },
  'boma_biometric_desc': {
    'en': 'Fingerprint or face recognition set up',
    'sw': 'Uwekaji wa alama ya kidole au uso',
  },
  'boma_2fa': {
    'en': 'Two-Factor Authentication',
    'sw': 'Uthibitishaji wa Hatua Mbili (2FA)',
  },
  'boma_2fa_desc': {
    'en': 'Enable 2FA on all important accounts',
    'sw': 'Washa 2FA kwenye akaunti muhimu',
  },
  'boma_mpesa_pin': {
    'en': 'M-Pesa PIN Security',
    'sw': 'Usalama wa PIN ya M-Pesa',
  },
  'boma_mpesa_pin_desc': {
    'en': 'Change your M-Pesa PIN regularly',
    'sw': 'Badilisha PIN yako ya M-Pesa mara kwa mara',
  },
  'boma_permissions': {
    'en': 'App Permissions Review',
    'sw': 'Mapitio ya Ruhusa za Programu',
  },
  'boma_permissions_desc': {
    'en': 'Check which apps have access to your data',
    'sw': 'Kagua programu zenye ufikiaji wa data yako',
  },
  'boma_password_manager': {
    'en': 'Password Manager',
    'sw': 'Kidhibiti cha Nywila',
  },
  'boma_password_manager_desc': {
    'en': 'Use unique passwords for each account',
    'sw': 'Tumia nywila tofauti kwa kila akaunti',
  },
  'boma_updates': {'en': 'Software Updates', 'sw': 'Masasisho ya Programu'},
  'boma_updates_desc': {
    'en': 'Keep your OS and apps up to date',
    'sw': 'Weka programu zako katika toleo jipya',
  },
  'boma_sim_pin': {'en': 'SIM PIN Lock', 'sw': 'Kufunga PIN ya SIM'},
  'boma_sim_pin_desc': {
    'en': 'Protect against SIM swap attacks',
    'sw': 'Jilinde dhidi ya ubadilishaji wa SIM',
  },
  'boma_social': {
    'en': 'Social Media Privacy',
    'sw': 'Faragha ya Mitandao ya Kijamii',
  },
  'boma_social_desc': {
    'en': 'Review and restrict public profile info',
    'sw': 'Kagua na dhibiti maelezo yako ya umma',
  },
  'boma_already_enabled': {
    'en': '✅ This setting is already enabled on your device',
    'sw': '✅ Mpangilio huu tayari umewashwa',
  },
  'boma_launch_configure': {
    'en': 'Launch & Configure',
    'sw': 'Fungua na Usanidi',
  },
  'boma_mark_incomplete': {
    'en': 'Mark as Incomplete',
    'sw': 'Tia alama Kuwa Haijakamilika',
  },
  'boma_mark_complete': {
    'en': 'Mark as Completed',
    'sw': 'Tia alama Imekamilika',
  },
  'boma_select_app': {
    'en': 'Select App to Configure',
    'sw': 'Chagua Programu ya Kusanidi',
  },
  'boma_manual_tip': {
    'en': 'Enable this manually, then mark it as done here.',
    'sw': 'Washa hii mwenyewe, kisha weka alama hapa.',
  },
  'boma_scanning': {'en': 'Scanning...', 'sw': 'Inakagua...'},
  'boma_rescan': {'en': 'Re-scan', 'sw': 'Kagua Tena'},
  'boma_safety_score': {
    'en': 'DEVICE SAFETY SCORE',
    'sw': 'ALAMA YA USALAMA WA KIFAA',
  },
  'boma_well_protected': {'en': 'Well Protected', 'sw': 'Umelindwa Vizuri'},
  'boma_needs_improvement': {
    'en': 'Needs Improvement',
    'sw': 'Inahitaji Kuboreshwa',
  },
  'boma_at_risk': {'en': 'At Risk', 'sw': 'Hatarini'},
  'boma_tasks_of': {'en': 'of', 'sw': 'kati ya'},
  'boma_tasks_completed': {'en': 'tasks completed', 'sw': 'kazi zimekamilika'},
  'boma_auto': {'en': 'AUTO', 'sw': 'KIOTOMATIKI'},

  // ── Intel Extras ──────────────────────────────────────────────────────────
  'intel_offline_msg': {
    'en': 'Offline Mode: Showing cached intel feed.',
    'sw': 'Hali ya Nje ya Mtandao: Inaonyesha taarifa za akiba.',
  },
  'intel_live_feed': {
    'en': 'Live Intel Feed',
    'sw': 'Taarifa za Moja kwa Moja',
  },
  'intel_search': {'en': 'Search threats...', 'sw': 'Tafuta vitisho...'},
  'intel_filter_all': {'en': 'All', 'sw': 'Zote'},
  'intel_filter_critical': {'en': 'Critical', 'sw': 'Kritikali'},
  'intel_filter_high': {'en': 'High', 'sw': 'Juu'},
  'intel_filter_medium': {'en': 'Medium', 'sw': 'Wastani'},
  'intel_welcome': {
    'en': 'Welcome, Agent Franklin',
    'sw': 'Karibu, Wakala Franklin',
  },
  'intel_live': {'en': 'LIVE', 'sw': 'MOJA KWA MOJA'},
  'intel_latest': {'en': 'LATEST INTEL', 'sw': 'TAARIFA MPYA'},
  'boma_link_failed': {
    'en': 'Could not open link.',
    'sw': 'Haikuweza kufungua kiungo.',
  },
  'boma_no_sim_toolkit': {
    'en': 'SIM Toolkit app not found.',
    'sw': 'Programu ya SIM Toolkit haijapatikana.',
  },
  'boma_not_supported': {
    'en': 'Not supported on this device.',
    'sw': 'Haikubaliwi kwenye kifaa hiki.',
  },
  'boma_no_playstore': {
    'en': 'Play Store app not found.',
    'sw': 'Programu ya Play Store haijapatikana.',
  },
  'boma_no_social_apps': {
    'en': 'No supported social media apps found on this device.',
    'sw':
        'Hakuna programu za mitandao ya kijamii zinazoungwa mkono zilizopatikana kwenye kifaa hiki.',
  },
  'boma_launch_failed': {'en': 'Failed to launch', 'sw': 'Imeshindwa kufungua'},
  // ── Protection Guides ──────────────────────────────────────────────────────
  'guide_title': {'en': 'Protection Guides', 'sw': 'Miongozo ya Ulinzi'},
  'guide_step': {'en': 'STEP', 'sw': 'HATUA'},
  'guide_next': {'en': 'NEXT STEP', 'sw': 'HATUA INAYOFUATA'},
  'guide_finish': {'en': 'FINISH', 'sw': 'KAMILISHA'},
  'guide_back': {'en': 'BACK', 'sw': 'RUDI'},
  'guide_sim_swap': {'en': 'SIM Swap Protection', 'sw': 'Ulinzi wa SIM Swap'},
  'guide_sim_desc': {
    'en': 'Learn how to protect yourself from SIM swap fraud',
    'sw': 'Jifunze jinsi ya kujilinda dhidi ya ulaghai wa SIM swap',
  },
  'guide_social': {
    'en': 'Social Media Safety',
    'sw': 'Usalama wa Mitandao ya Kijamii',
  },
  'guide_social_desc': {
    'en': 'Secure your social media accounts against hackers',
    'sw': 'Linda akaunti zako za mitandao ya kijamii dhidi ya wadukuzi',
  },
  'guide_banking': {'en': 'Banking Security', 'sw': 'Usalama wa Kibenki'},
  'guide_banking_desc': {
    'en': 'Best practices for mobile & online banking',
    'sw': 'Mbinu bora za benki kupitia simu na mtandao',
  },
  'guide_identity': {
    'en': 'Identity Theft Guard',
    'sw': 'Ulinzi wa Wizi wa Utambulisho',
  },
  'guide_identity_desc': {
    'en': 'Steps to prevent and respond to identity theft',
    'sw': 'Hatua za kuzuia na kukabiliana na wizi wa utambulisho',
  },
  'guide_password': {'en': 'Password Health', 'sw': 'Afya ya Nywila'},
  'guide_password_desc': {
    'en': 'Check and improve your password strength',
    'sw': 'Kagua na boresha nguvu ya nywila yako',
  },
  'guide_wifi': {'en': 'Wi-Fi Security', 'sw': 'Usalama wa Wi-Fi'},
  'guide_wifi_desc': {
    'en': 'Stay safe on public and home networks',
    'sw': 'Baki salama kwenye mitandao ya umma na nyumbani',
  },
  'guide_sim_1_title': {'en': 'Recognize the Signs', 'sw': 'Tambua Dalili'},
  'guide_sim_1_desc': {
    'en':
        'If your phone suddenly loses network signal for an extended period, you may be a SIM swap victim. Act immediately — every second counts.',
    'sw':
        'Ikiwa simu yako inapoteza mtandao ghafla kwa muda mrefu, unaweza kuwa mwathiriwa wa SIM swap. Chukua hatua mara moja.',
  },
  'guide_sim_2_title': {
    'en': 'Contact Your Carrier',
    'sw': 'Wasiliana na Mtoa Huduma Wako',
  },
  'guide_sim_2_desc': {
    'en':
        'Call Safaricom (100), Airtel (100), or your carrier from another phone to report the suspicious SIM swap and request an immediate block.',
    'sw':
        'Piga simu Safaricom (100), Airtel (100), au mtoa huduma wako kutoka simu nyingine ili kuripoti na kuomba kufungiwa mara moja.',
  },
  'guide_sim_2_action': {'en': 'CALL SAFARICOM', 'sw': 'PIGA SIMU SAFARICOM'},
  'guide_sim_3_title': {'en': 'Lock Your Accounts', 'sw': 'Funga Akaunti Zako'},
  'guide_sim_3_desc': {
    'en':
        'Call your bank immediately to freeze online and mobile banking. Your SIM is the key to M-Pesa and SMS-based authentication.',
    'sw':
        'Piga simu benki yako mara moja ili kufunga huduma za kibenki mtandaoni. SIM yako ni ufunguo wa M-Pesa na uthibitishaji wa SMS.',
  },
  'guide_sim_4_title': {'en': 'Report to Police', 'sw': 'Ripoti kwa Polisi'},
  'guide_sim_4_desc': {
    'en':
        'File a report at the nearest police station or through the eCitizen portal. You\'ll need the OB number for insurance or bank claims.',
    'sw':
        'Toa ripoti katika kituo cha polisi kilicho karibu au kupitia mtandao wa eCitizen. Utahitaji nambari ya OB kwa madai ya bima au benki.',
  },
  'guide_sim_5_title': {
    'en': 'Monitor Your Accounts',
    'sw': 'Kagua Akaunti Zako',
  },
  'guide_sim_5_desc': {
    'en':
        'For the next 30 days, watch all your bank statements and M-Pesa history for unauthorized transactions. Report anything suspicious immediately.',
    'sw':
        'Kwa siku 30 zijazo, kagua taarifa zako zote za benki na historia ya M-Pesa kwa miamala isiyoidhinishwa. Ripoti chochote kinachotia shaka mara moja.',
  },
  'guide_soc_1_title': {
    'en': 'Enable Two-Factor Authentication',
    'sw': 'Washa Uthibitishaji wa Hatua Mbili',
  },
  'guide_soc_1_desc': {
    'en':
        'Add 2FA to all your social media accounts. Use an authenticator app like Google Authenticator instead of SMS for stronger security.',
    'sw':
        'Ongeza 2FA kwenye akaunti zako zote za mitandao ya kijamii. Tumia programu ya uthibitishaji kama Google Authenticator badala ya SMS kwa usalama zaidi.',
  },
  'guide_soc_2_title': {
    'en': 'Review Privacy Settings',
    'sw': 'Kagua Mipangilio ya Faragha',
  },
  'guide_soc_2_desc': {
    'en':
        'Limit who can see your posts, friends list, and personal information. Set your profile to private and restrict friend requests to friends-of-friends.',
    'sw':
        'Punguza wanaoweza kuona machapisho yako, orodha ya marafiki, na maelezo ya kibinafsi. Weka wasifu wako kuwa wa faragha.',
  },
  'guide_soc_3_title': {
    'en': 'Beware of Phishing Links',
    'sw': 'Jihadhari na Viungo vya Hadaa',
  },
  'guide_soc_3_desc': {
    'en':
        'Don\'t click suspicious links in DMs or comments, even from friends. Hackers often hijack accounts and send malicious links to contacts.',
    'sw':
        'Usibonyeze viungo vinavyotia shaka kwenye jumbe (DMs) au maoni, hata kutoka kwa marafiki. Wadukuzi hutumia akaunti zilizodukuliwa kutuma viungo hatari.',
  },
  'guide_soc_4_title': {
    'en': 'Use Strong Passwords',
    'sw': 'Tumia Nywila Imara',
  },
  'guide_soc_4_desc': {
    'en':
        'Use a unique, complex password for each social media account. Never reuse your email or banking password for social media.',
    'sw':
        'Tumia nywila ya kipekee na ngumu kwa kila akaunti ya mtandao wa kijamii. Usitumie nywila ya barua pepe au benki yako kwa mitandao ya kijamii.',
  },
  'guide_soc_5_title': {
    'en': 'Audit Connected Apps',
    'sw': 'Kagua Programu Zilizounganishwa',
  },
  'guide_soc_5_desc': {
    'en':
        'Remove third-party apps and website logins you no longer use. These forgotten connections can become backdoors for attackers.',
    'sw':
        'Ondoa programu za watu wengine na tovuti ambazo hutumii tena. Miunganisho hii iliyosahaulika inaweza kuwa milango ya wadukuzi.',
  },
  'guide_bnk_1_title': {
    'en': 'Never Share PINs or OTPs',
    'sw': 'Usishiriki PIN au OTP Kamwe',
  },
  'guide_bnk_1_desc': {
    'en':
        'Your M-Pesa PIN, ATM PIN, and one-time passwords should never be shared with anyone — not even someone claiming to be from your bank or Safaricom.',
    'sw':
        'PIN yako ya M-Pesa, ATM, na nywila za mara moja (OTPs) hazipaswi kushirikiwa na mtu yeyote - hata mtu anayedai kuwa anatoka benki yako au Safaricom.',
  },
  'guide_bnk_2_title': {
    'en': 'Verify Before Transacting',
    'sw': 'Thibitisha Kabla ya Kufanya Muamala',
  },
  'guide_bnk_2_desc': {
    'en':
        'Always confirm the recipient\'s name before completing M-Pesa or bank transfers. A wrong transaction is very difficult to reverse.',
    'sw':
        'Daima thibitisha jina la mpokeaji kabla ya kukamilisha muamala wa M-Pesa au benki. Muamala mbaya ni vigumu sana kuurejesha.',
  },
  'guide_bnk_3_title': {
    'en': 'Use Official Apps Only',
    'sw': 'Tumia Programu Rasmi Tu',
  },
  'guide_bnk_3_desc': {
    'en':
        'Download banking apps only from Google Play Store or Apple App Store. Fake banking apps are a common tool for stealing credentials.',
    'sw':
        'Pakua programu za benki pekee kutoka Google Play Store au Apple App Store. Programu bandia za benki ni zana ya kawaida ya kuiba utambulisho.',
  },
  'guide_bnk_4_title': {
    'en': 'Enable Transaction Alerts',
    'sw': 'Washa Arifa za Miamala',
  },
  'guide_bnk_4_desc': {
    'en':
        'Set up SMS and email notifications for all account activity. Instant alerts help you catch unauthorized transactions immediately.',
    'sw':
        'Weka arifa za SMS na barua pepe kwa shughuli zote za akaunti. Arifa za hapo hapo zinakusaidia kukamata miamala isiyoidhinishwa mara moja.',
  },
  'guide_bnk_5_title': {
    'en': 'Report Fraud Immediately',
    'sw': 'Ripoti Ulaghai Mara Moja',
  },
  'guide_bnk_5_desc': {
    'en':
        'If you notice unauthorized activity, call your bank\'s fraud line and Safaricom\'s M-Pesa support (234) without delay.',
    'sw':
        'Ukiona shughuli isiyoidhinishwa, piga simu nambari ya udanganyifu ya benki yako na usaidizi wa M-Pesa wa Safaricom (234) bila kuchelewa.',
  },
  'guide_bnk_5_action': {
    'en': 'CALL M-PESA SUPPORT',
    'sw': 'PIGA SIMU USAIDIZI WA M-PESA',
  },
  'guide_id_1_title': {
    'en': 'Guard Your ID Documents',
    'sw': 'Linda Hati Zako za Vitambulisho',
  },
  'guide_id_1_desc': {
    'en':
        'Never share photos of your National ID, passport, or KRA PIN on social media or with unverified websites. Criminals use these to open accounts in your name.',
    'sw':
        'Kamwe usishiriki picha za Kitambulisho chako cha Taifa, pasipoti, au KRA PIN kwenye mitandao ya kijamii au tovuti zisizothibitishwa. Wahalifu huzitumia kufungua akaunti kwa jina lako.',
  },
  'guide_id_2_title': {
    'en': 'Shred Sensitive Documents',
    'sw': 'Chana Hati Nyeti',
  },
  'guide_id_2_desc': {
    'en':
        'Destroy old bank statements, utility bills, and any documents containing personal information. Dumpster diving is a real threat.',
    'sw':
        'Haribu taarifa za zamani za benki, bili za huduma, na hati zozote zenye habari za kibinafsi. Kuchakura kwenye majalala ni tishio halisi.',
  },
  'guide_id_3_title': {
    'en': 'Monitor Your Credit',
    'sw': 'Fuatilia Rekodi Yako ya Mikopo',
  },
  'guide_id_3_desc': {
    'en':
        'Check your CRB (Credit Reference Bureau) report regularly for unauthorized loans or accounts opened in your name. You can check via Metropol or TransUnion.',
    'sw':
        'Angalia ripoti yako ya CRB (Credit Reference Bureau) mara kwa mara kwa mikopo isiyoidhinishwa au akaunti zilizofunguliwa kwa jina lako. Unaweza kuangalia kupitia Metropol au TransUnion.',
  },
  'guide_id_4_title': {
    'en': 'Be Cautious Online',
    'sw': 'Kuwa Mwangalifu Mtandaoni',
  },
  'guide_id_4_desc': {
    'en':
        'Avoid entering personal details on unfamiliar or unsecured websites. Look for the padlock icon (HTTPS) before submitting any information.',
    'sw':
        'Epuka kuingiza maelezo ya kibinafsi kwenye tovuti zisizojulikana au zisizo salama. Tafuta ikoni ya kufuli (HTTPS) kabla ya kuwasilisha taarifa yoyote.',
  },
  'guide_id_5_title': {
    'en': 'Act Fast If Compromised',
    'sw': 'Chukua Hatua Haraka Ikiwa Umedukuliwa',
  },
  'guide_id_5_desc': {
    'en':
        'Report identity theft to the DCI Cybercrime Unit immediately. File an official complaint and notify your bank and mobile provider.',
    'sw':
        'Ripoti wizi wa utambulisho kwa Kitengo cha Uhalifu wa Mtandao cha DCI mara moja. Toa malalamiko rasmi na ujulishe benki yako na mtoa huduma wako wa simu.',
  },
  'guide_id_5_action': {
    'en': 'CALL DCI CYBERCRIME',
    'sw': 'PIGA SIMU DCI MTANDAO',
  },
  'guide_pwd_1_title': {
    'en': 'Use Long, Unique Passwords',
    'sw': 'Tumia Nywila Ndefu na za Kipekee',
  },
  'guide_pwd_1_desc': {
    'en':
        'Each account should have a password of at least 12 characters mixing uppercase, lowercase, numbers, and symbols. Length beats complexity.',
    'sw':
        'Kila akaunti inapaswa kuwa na nywila ya angalau herufi 12 inayochanganya herufi kubwa, ndogo, nambari, na alama. Urefu unashinda ugumu.',
  },
  'guide_pwd_2_title': {
    'en': 'Use a Password Manager',
    'sw': 'Tumia Kidhibiti Nywila',
  },
  'guide_pwd_2_desc': {
    'en':
        'Apps like Bitwarden or Google Password Manager store all your passwords securely so you only need to remember one master password.',
    'sw':
        'Programu kama Bitwarden au Google Password Manager huhifadhi nywila zako zote kwa usalama ili uhitaji kukumbuka nywila kuu moja tu.',
  },
  'guide_pwd_3_title': {
    'en': 'Never Reuse Passwords',
    'sw': 'Kamwe Usitumie Nywila Zilizotumika',
  },
  'guide_pwd_3_desc': {
    'en':
        'If one service is breached, reused passwords expose all your other accounts. Each account must have its own unique password.',
    'sw':
        'Ikiwa huduma moja itadukuliwa, nywila zinazotumiwa tena zinaweka akaunti zako zote hatarini. Kila akaunti lazima iwe na nywila yake ya kipekee.',
  },
  'guide_pwd_4_title': {
    'en': 'Change Compromised Passwords',
    'sw': 'Badilisha Nywila Zilizodukuliwa',
  },
  'guide_pwd_4_desc': {
    'en':
        'If a service reports a data breach, change your password there immediately. Check haveibeenpwned.com to see if your email has been exposed.',
    'sw':
        'Ikiwa huduma itaripoti ukiukaji wa data, badilisha nywila yako hapo mara moja. Angalia haveibeenpwned.com ili uone ikiwa barua pepe yako imefichuliwa.',
  },
  'guide_pwd_5_title': {
    'en': 'Try Passphrases',
    'sw': 'Jaribu Vifungu vya Nywila',
  },
  'guide_pwd_5_desc': {
    'en':
        'Combine random words like "Sunset-Mango-River-42" for passwords that are both strong and easy to remember. Avoid common phrases or song lyrics.',
    'sw':
        'Changanya maneno kwa mpangilio bila mpangilio kama "Machweo-Embe-Mto-42" kwa nywila ambazo ni thabiti na rahisi kukumbuka. Epuka vifungu vya kawaida au mashairi ya nyimbo.',
  },
  'guide_wifi_1_title': {
    'en': 'Avoid Public Wi-Fi for Banking',
    'sw': 'Epuka Wi-Fi za Umma kwa Huduma za Kibenki',
  },
  'guide_wifi_1_desc': {
    'en':
        'Never access banking, M-Pesa, or other sensitive accounts on public Wi-Fi at restaurants, malls, or airports. Use mobile data instead.',
    'sw':
        'Kamwe usifikie benki, M-Pesa, au akaunti nyingine nyeti kwenye Wi-Fi za umma katika mikahawa, maduka makubwa, au viwanja vya ndege. Tumia data ya simu badala yake.',
  },
  'guide_wifi_2_title': {'en': 'Use a VPN', 'sw': 'Tumia VPN'},
  'guide_wifi_2_desc': {
    'en':
        'A Virtual Private Network encrypts all your data on public networks, making it invisible to hackers on the same Wi-Fi.',
    'sw':
        'Mtandao wa Kibinafsi (VPN) husimba data yako yote kwenye mitandao ya umma, na kuifanya ionekane kwa wadukuzi kwenye Wi-Fi hiyo.',
  },
  'guide_wifi_3_title': {
    'en': 'Secure Your Home Wi-Fi',
    'sw': 'Linda Wi-Fi Yako ya Nyumbani',
  },
  'guide_wifi_3_desc': {
    'en':
        'Change the default router password and Wi-Fi name. Use WPA3 or WPA2 encryption — never leave your network open or use WEP.',
    'sw':
        'Badilisha nywila chaguomsingi ya ruta na jina la Wi-Fi. Tumia usimbaji fiche wa WPA3 au WPA2 - usiwahi kuacha mtandao wako wazi au kutumia WEP.',
  },
  'guide_wifi_4_title': {
    'en': 'Forget Old Networks',
    'sw': 'Sahau Mitandao ya Zamani',
  },
  'guide_wifi_4_desc': {
    'en':
        'Remove saved Wi-Fi networks you no longer use from your device. Your phone could auto-connect to a malicious network with the same name.',
    'sw':
        'Ondoa mitandao ya Wi-Fi iliyohifadhiwa ambayo hutumii tena kutoka kwenye kifaa chako. Simu yako inaweza kuunganishwa kiotomatiki kwenye mtandao mbaya wenye jina sawa.',
  },
  'guide_wifi_5_title': {
    'en': 'Watch for Fake Hotspots',
    'sw': 'Jihadhari na Mitandao Bandia',
  },
  'guide_wifi_5_desc': {
    'en':
        'Hackers create fake Wi-Fi networks that mimic coffee shops, hotels, or airports. Always confirm the exact network name with staff before connecting.',
    'sw':
        'Wadukuzi hutengeneza mitandao bandia ya Wi-Fi inayoiga mikahawa, hoteli, au viwanja vya ndege. Daima thibitisha jina kamili la mtandao na wafanyakazi kabla ya kuunganishwa.',
  },
  'cert_title': {'en': 'Your Certificate', 'sw': 'Cheti Chako'},
  'cert_saved_success': {
    'en': 'Certificate saved successfully!',
    'sw': 'Cheti kimehifadhiwa kikamilifu!',
  },
  'cert_save_failed': {
    'en': 'Failed to save certificate:',
    'sw': 'Imeshindwa kuhifadhi cheti:',
  },
  'cert_saving': {'en': 'Saving...', 'sw': 'Inahifadhi...'},
  'cert_download': {'en': 'Download Certificate', 'sw': 'Pakua Cheti'},
  // ── Dark Web Scanner ──────────────────────────────────────────────────────
  'dark_web_coming_soon': {
    'en': 'scanning coming soon!',
    'sw': 'upekuzi unakuja hivi karibuni!',
  },
  'dark_web_error_api': {
    'en': 'Error connecting to HIBP API:',
    'sw': 'Hitilafu kuunganisha na API ya HIBP:',
  },
  'dark_web_scanning': {
    'en': 'Scanning Dark Web Databases...',
    'sw': 'Inapekua Hifadhidata za Mtandao Giza...',
  },
  'dark_web_scanner': {
    'en': 'Dark Web Scanner',
    'sw': 'Kigunduzi cha Mtandao Giza',
  },
  'dark_web_enter': {'en': 'Enter', 'sw': 'Ingiza'},
  'dark_web_initiate': {'en': 'INITIATE SCAN', 'sw': 'ANZISHA UPEKUZI'},
  'dark_web_no_breaches': {
    'en': 'NO BREACHES FOUND',
    'sw': 'HAKUNA UVUNJAJI ULIOONEKANA',
  },
  'dark_web_safe_msg': {
    'en':
        'Good news! This password was not found in any known data breaches. It is safe to use.',
    'sw':
        'Habari njema! Nenosiri hili halikupatikana katika uvunjaji wowote wa data unaojulikana. Ni salama kutumia.',
  },
  'dark_web_compromised': {
    'en': 'COMPROMISED PASSWORD',
    'sw': 'NENOSIRI LILILOVUJISHWA',
  },
  'dark_web_source': {'en': 'Source', 'sw': 'Chanzo'},
  'dark_web_hibp': {
    'en': 'Have I Been Pwned API',
    'sw': 'API ya Have I Been Pwned',
  },
  'dark_web_pwned_count': {'en': 'Pwned Count', 'sw': 'Idadi ya Uvujaji'},
  'dark_web_times': {'en': 'times', 'sw': 'mara'},
  'dark_web_data_exposed': {'en': 'Data Exposed', 'sw': 'Data Iliyofichuliwa'},
  'dark_web_hashed_passwords': {
    'en': 'Hashed Passwords',
    'sw': 'Nywila Zilizofichwa',
  },
  'dark_web_risk_score': {'en': 'Risk Score:', 'sw': 'Alama ya Hatari:'},
  'dark_web_ai_threat': {
    'en': 'AI THREAT ANALYSIS',
    'sw': 'UCHAMBUZI WA TISHO WA AI',
  },
  'dark_web_breach_msg_1': {
    'en': 'This password has been seen',
    'sw': 'Nenosiri hili limeonekana',
  },
  'dark_web_breach_msg_2': {
    'en':
        'times in data breaches. This means it is no longer secure. Hackers use lists of breached passwords (credential stuffing) to break into accounts.',
    'sw':
        'mara katika uvunjaji wa data. Hii inamaanisha si salama tena. Wadukuzi hutumia orodha za nywila zilizovunjwa (kujaza sifa) kuingia kwenye akaunti.',
  },
  'dark_web_recommended': {
    'en': 'RECOMMENDED ACTIONS',
    'sw': 'HATUA ZINAZOPENDEKEZWA',
  },
  'dark_web_change_password': {
    'en': 'Change Password',
    'sw': 'Badilisha Nenosiri',
  },
  'dark_web_change_password_desc': {
    'en': 'Update your password for this service immediately.',
    'sw': 'Sasisha nenosiri lako kwa huduma hii mara moja.',
  },
  'dark_web_enable_2fa': {'en': 'Enable 2FA', 'sw': 'Washa 2FA'},
  'dark_web_enable_2fa_desc': {
    'en': 'Add an extra layer of security to your account.',
    'sw': 'Ongeza safu ya ziada ya usalama kwenye akaunti yako.',
  },
  'dark_web_type_password': {'en': 'Password', 'sw': 'Nenosiri'},
  'dark_web_type_email': {'en': 'Email', 'sw': 'Barua pepe'},
  'dark_web_type_phone': {'en': 'Phone', 'sw': 'Simu'},
  'dark_web_type_national_id': {'en': 'National ID', 'sw': 'Kitambulisho'},
  'dark_web_type_passport': {'en': 'Passport', 'sw': 'Pasipoti'},
  'dark_web_type_username': {'en': 'Username', 'sw': 'Jina la mtumiaji'},
  'inactivity_session_timeout': {
    'en': 'Session Timeout',
    'sw': 'Muda wa Kikao Kuisha',
  },
  'inactivity_warning_msg_1': {
    'en': 'You have been inactive. You will be logged out in ',
    'sw': 'Umekuwa kimya. Utaondolewa katika ',
  },
  'inactivity_warning_msg_2': {'en': ' seconds.', 'sw': ' sekunde.'},
  'inactivity_stay_logged_in': {'en': 'Stay Logged In', 'sw': 'Baki Umeingia'},
  'placeholder_coming_soon': {
    'en': 'Coming soon...',
    'sw': 'Inakuja hivi karibuni...',
  },
  'vault_auth_failed': {
    'en': 'Authentication Failed or Cancelled',
    'sw': 'Uthibitishaji Umeshindikana au Umeghairiwa',
  },
  'vault_bio_error': {
    'en': 'Biometrics error:',
    'sw': 'Hitilafu ya kibayometriki:',
  },
  'vault_bio_unlock_demo': {
    'en': 'Unlocking for demo.',
    'sw': 'Inafungua kwa maonyesho.',
  },
  'chonjo_agent_status': {
    'en': 'AGENT STATUS  ·  STANDBY',
    'sw': 'HALI YA WAKALA  ·  INASUBIRI',
  },
  'chonjo_title': {'en': 'Kaanga Chonjo!', 'sw': 'Kaanga Chonjo!'},
  'chonjo_subtitle': {
    'en': 'Identify digital threats targeting\nthe Kenyan cyberspace.',
    'sw': 'Tambua vitisho vya kidijitali vinavyolenga\nmtandao wa Kenya.',
  },
  'chonjo_legit': {'en': 'LEGIT', 'sw': 'HALALI'},
  'chonjo_swipe_left': {'en': 'Swipe Left', 'sw': 'Telezesha Kushoto'},
  'chonjo_scam': {'en': 'SCAM', 'sw': 'UTAPELI'},
  'chonjo_swipe_right': {'en': 'Swipe Right', 'sw': 'Telezesha Kulia'},
  'chonjo_mission': {'en': 'YOUR MISSION', 'sw': 'DHIMA YAKO'},
  'chonjo_mission_desc': {
    'en': 'Swipe each message — flag scams before they reach citizens.',
    'sw': 'Telezesha kila ujumbe — onyesha utapeli kabla haujawafikia raia.',
  },
  'chonjo_start': {'en': 'START GAME', 'sw': 'ANZA MCHEZO'},
  'chonjo_tap_level': {
    'en': 'Tap a level to begin',
    'sw': 'Gusa kiwango ili kuanza',
  },
  'chonjo_download_cert': {'en': 'Download Certificate', 'sw': 'Pakua Cheti'},
  'chonjo_loading': {'en': 'Loading scenarios...', 'sw': 'Inapakia matukio...'},
  'chonjo_level': {'en': 'Level', 'sw': 'Kiwango'},
  'chonjo_review': {'en': 'Review', 'sw': 'Pitia'},
  'chonjo_finish_level': {'en': 'Finish Level', 'sw': 'Maliza Kiwango'},

  // Cyber Planner
  'planner_title': {'en': 'CYBER PLANNER', 'sw': 'MPANGAJI WA MTANDAO'},
  'planner_completion_rate': {
    'en': 'Completion Rate',
    'sw': 'Kiwango cha Kukamilisha',
  },
  'planner_active': {'en': 'Active Tasks', 'sw': 'Kazi Zinazoendelea'},
  'planner_history': {'en': 'History', 'sw': 'Historia'},
  'planner_no_tasks': {
    'en': 'No Active Tasks',
    'sw': 'Hakuna Kazi Zinazoendelea',
  },
  'planner_no_tasks_desc': {
    'en': 'Tap + to add your first cyber task',
    'sw': 'Bofya + kuongeza kazi yako ya kwanza',
  },
  'planner_no_history': {'en': 'No History Yet', 'sw': 'Hakuna Historia Bado'},
  'planner_no_history_desc': {
    'en': 'Completed and missed tasks appear here',
    'sw': 'Kazi zilizokamilika na zilizokosekana zinaonekana hapa',
  },
  'planner_add_task': {'en': 'New Cyber Task', 'sw': 'Kazi Mpya ya Mtandao'},
  'planner_task_title': {'en': 'Task Title', 'sw': 'Kichwa cha Kazi'},
  'planner_task_desc': {
    'en': 'Description (optional)',
    'sw': 'Maelezo (sio lazima)',
  },
  'planner_save_task': {'en': 'Save Task', 'sw': 'Hifadhi Kazi'},
};

extension TranslationContext on BuildContext {
  /// Translates a key based on the current locale. If the key is not found,
  /// it returns the key itself as a fallback.
  String tr(String key, {String? fallback}) {
    try {
      final localeProvider = Provider.of<LocaleProvider>(this, listen: true);
      final lang = localeProvider.locale;

      if (_translations.containsKey(key)) {
        final val = _translations[key]?[lang];
        if (val != null && val.isNotEmpty) return val;

        final enVal = _translations[key]?['en'];
        if (enVal != null && enVal.isNotEmpty) return enVal;
      }
      return fallback ?? key;
    } catch (_) {
      // If used outside Provider scope somehow, return default English
      final enVal = _translations[key]?['en'];
      if (enVal != null && enVal.isNotEmpty) return enVal;
      return fallback ?? key;
    }
  }
}
