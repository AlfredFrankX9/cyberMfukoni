import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Represents a single cyber task in the planner.
class CyberTask {
  String id;
  String title;
  String description;
  String priority; // 'critical', 'high', 'medium', 'low'
  String category; // 'audit', 'monitoring', 'incident', 'training', 'maintenance', 'other'
  DateTime createdAt;
  DateTime dueDate;
  int reminderMinutesBefore; // Keep for backward compatibility
  List<int> reminders; // Support multiple reminders
  bool isCompleted;
  DateTime? completedAt;
  bool isMissed;

  CyberTask({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = 'medium',
    this.category = 'other',
    required this.createdAt,
    required this.dueDate,
    this.reminderMinutesBefore = 30,
    List<int>? reminders,
    this.isCompleted = false,
    this.completedAt,
    this.isMissed = false,
  }) : this.reminders = reminders ?? (reminderMinutesBefore > 0 ? [reminderMinutesBefore] : []);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'priority': priority,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'reminderMinutesBefore': reminderMinutesBefore,
    'reminders': reminders,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'isMissed': isMissed,
  };

  factory CyberTask.fromJson(Map<String, dynamic> json) => CyberTask(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    priority: json['priority'] ?? 'medium',
    category: json['category'] ?? 'other',
    createdAt: DateTime.parse(json['createdAt']),
    dueDate: DateTime.parse(json['dueDate']),
    reminderMinutesBefore: json['reminderMinutesBefore'] ?? 30,
    reminders: json['reminders'] != null ? List<int>.from(json['reminders']) : null,
    isCompleted: json['isCompleted'] ?? false,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    isMissed: json['isMissed'] ?? false,
  );
}

class PlannerService extends ChangeNotifier {
  static const String _storageKey = 'cyber_planner_tasks';
  List<CyberTask> _tasks = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  List<CyberTask> get tasks => _tasks;

  List<CyberTask> get activeTasks =>
      _tasks.where((t) => !t.isCompleted && !t.isMissed).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  List<CyberTask> get historyTasks =>
      _tasks.where((t) => t.isCompleted || t.isMissed).toList()
        ..sort((a, b) => (b.completedAt ?? b.dueDate).compareTo(a.completedAt ?? a.dueDate));

  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get missedCount => _tasks.where((t) => t.isMissed).length;
  int get totalFinished => completedCount + missedCount;

  /// Completion score: percentage of completed tasks out of all finished tasks.
  double get completionScore {
    if (totalFinished == 0) return 100.0;
    return (completedCount / totalFinished) * 100;
  }

  Future<void> init() async {
    if (_initialized) return;
    await _initNotifications();
    await _loadTasks();
    _markMissedTasks();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Request notification permission on Android 13+
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    // Request exact alarm permission on Android 12+
    await androidPlugin?.requestExactAlarmsPermission();

    // Create the notification channel explicitly
    const channel = AndroidNotificationChannel(
      'cyber_planner_reminders',
      'Planner Reminders',
      description: 'Reminders for scheduled cyber tasks',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      final List<dynamic> decoded = json.decode(jsonStr);
      _tasks = decoded.map((e) => CyberTask.fromJson(e)).toList();
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  void _markMissedTasks() {
    final now = DateTime.now();
    for (var task in _tasks) {
      if (!task.isCompleted && !task.isMissed && task.dueDate.isBefore(now)) {
        task.isMissed = true;
      }
    }
  }

  Future<void> addTask(CyberTask task) async {
    _tasks.add(task);
    await _saveTasks();
    try {
      await _scheduleReminder(task);
    } catch (e) {
      debugPrint("Failed to schedule reminder: $e");
    }
    notifyListeners();
  }

  Future<void> updateTask(CyberTask task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final oldTask = _tasks[index];
      await _cancelReminder(oldTask);
      _tasks[index] = task;
      await _saveTasks();
      if (!task.isCompleted && !task.isMissed) {
        try {
          await _scheduleReminder(task);
        } catch (e) {
          debugPrint("Failed to schedule reminder: $e");
        }
      }
      notifyListeners();
    }
  }

  Future<void> completeTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].isCompleted = true;
      _tasks[index].completedAt = DateTime.now();
      await _cancelReminder(_tasks[index]);
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks.removeAt(index);
      await _cancelReminder(task);
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> _scheduleReminder(CyberTask task) async {
    if (task.reminders.isEmpty) return;

    for (int minutes in task.reminders) {
      if (minutes <= 0) continue;

      final reminderTime = task.dueDate.subtract(Duration(minutes: minutes));
      if (reminderTime.isBefore(DateTime.now())) continue;

      final notificationId = '${task.id}_$minutes'.hashCode.abs() % 2147483647;

      final androidDetails = AndroidNotificationDetails(
        'cyber_planner_reminders',
        'Planner Reminders',
        channelDescription: 'Reminders for scheduled cyber tasks',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        timeoutAfter: 60000,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF00FF40),
        styleInformation: BigTextStyleInformation(
          task.description.isNotEmpty ? task.description : 'Due: ${_formatDateTime(task.dueDate)}',
          contentTitle: '🔒 ${task.title}',
          summaryText: _getCategoryLabel(task.category),
        ),
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            'open_guardian',
            'Open Guardian',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'dismiss',
            'Dismiss',
            cancelNotification: true,
          ),
        ],
      );

      final details = NotificationDetails(android: androidDetails);

      // Use zonedSchedule with exact time
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '🔒 Cyber Task Reminder',
        '${task.title} — due ${_formatRelativeTime(minutes)}',
        tz.TZDateTime.from(reminderTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> _cancelReminder(CyberTask task) async {
    for (int minutes in task.reminders) {
      final notificationId = '${task.id}_$minutes'.hashCode.abs() % 2147483647;
      await _notificationsPlugin.cancel(notificationId);
    }
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, $h:$m';
  }

  String _formatRelativeTime(int minutes) {
    if (minutes < 60) return 'in $minutes min';
    if (minutes < 1440) return 'in ${minutes ~/ 60}h';
    return 'in ${minutes ~/ 1440}d';
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'audit': return 'Security Audit';
      case 'monitoring': return 'Monitoring';
      case 'incident': return 'Incident Response';
      case 'training': return 'Training';
      case 'maintenance': return 'Maintenance';
      default: return 'General';
    }
  }
}
