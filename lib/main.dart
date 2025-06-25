import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_calendar/device_calendar.dart' as device_cal;
import 'package:add_2_calendar/add_2_calendar.dart' as add2cal;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    tz.initializeTimeZones();
    print('Timezone initialized successfully');
  } catch (e) {
    print('Timezone initialization error: $e');
  }
  
  try {
    await NotificationService.initialize();
  } catch (e) {
    print('Notification service initialization failed: $e');
  }
  
  if (!kIsWeb) {
    try {
      await CalendarService.initialize();
    } catch (e) {
      print('Calendar service initialization failed: $e');
    }
  }
  
  runApp(const TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TaskHomePage(),
    );
  }
}

class Task {
  String id;
  String title;
  String description;
  DateTime createdAt;
  DateTime? dueDate;
  bool isCompleted;
  bool hasReminder;
  List<int> reminderMinutes; // Multiple reminder times
  bool addToCalendar;
  String? calendarEventId;
  int durationMinutes; // Task duration in minutes

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.dueDate,
    this.isCompleted = false,
    this.hasReminder = false,
    this.reminderMinutes = const [30],
    this.addToCalendar = false,
    this.calendarEventId,
    this.durationMinutes = 30, // Default 30 minutes
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'hasReminder': hasReminder,
      'reminderMinutes': reminderMinutes,
      'addToCalendar': addToCalendar,
      'calendarEventId': calendarEventId,
      'durationMinutes': durationMinutes,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
      hasReminder: json['hasReminder'] ?? false,
      reminderMinutes: List<int>.from(json['reminderMinutes'] ?? [30]),
      addToCalendar: json['addToCalendar'] ?? false,
      calendarEventId: json['calendarEventId'],
      durationMinutes: json['durationMinutes'] ?? 30,
    );
  }
}

class CalendarService {
  static device_cal.DeviceCalendarPlugin? _deviceCalendarPlugin;
  static List<device_cal.Calendar>? _calendars;

  static Future<void> initialize() async {
    if (kIsWeb) return; // Skip calendar initialization on web
    
    try {
      _deviceCalendarPlugin = device_cal.DeviceCalendarPlugin();
      await requestPermissions();
      await _loadCalendars();
    } catch (e) {
      print('Calendar initialization error: $e');
    }
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb) return;
    
    try {
      await Permission.calendarFullAccess.request();
    } catch (e) {
      print('Calendar permission error: $e');
    }
  }

  static Future<void> _loadCalendars() async {
    if (kIsWeb || _deviceCalendarPlugin == null) return;
    
    try {
      final permissionsGranted = await _deviceCalendarPlugin!.hasPermissions();
      if (permissionsGranted.isSuccess && (permissionsGranted.data ?? false)) {
        final calendarsResult = await _deviceCalendarPlugin!.retrieveCalendars();
        if (calendarsResult.isSuccess) {
          _calendars = calendarsResult.data;
        }
      }
    } catch (e) {
      print('Error loading calendars: $e');
    }
  }

  static Future<String?> addEventToCalendar(Task task) async {
    if (kIsWeb || task.dueDate == null || _deviceCalendarPlugin == null || _calendars == null) {
      return null;
    }

    try {
      // Use the first writable calendar
      final writableCalendar = _calendars!.firstWhere(
        (cal) => !(cal.isReadOnly ?? true),
        orElse: () => _calendars!.first,
      );

      final event = device_cal.Event(
        writableCalendar.id,
        title: task.title,
        description: task.description,
        start: tz.TZDateTime.from(task.dueDate!, tz.local),
        end: tz.TZDateTime.from(task.dueDate!.add(Duration(minutes: task.durationMinutes)), tz.local),
        allDay: false,
      );

      final createEventResult = await _deviceCalendarPlugin!.createOrUpdateEvent(event);
      if (createEventResult?.isSuccess == true) {
        return createEventResult!.data;
      }
    } catch (e) {
      print('Error adding event to calendar: $e');
    }
    return null;
  }

  static Future<void> removeEventFromCalendar(String calendarId, String eventId) async {
    if (kIsWeb || _deviceCalendarPlugin == null) return;
    
    try {
      await _deviceCalendarPlugin!.deleteEvent(calendarId, eventId);
    } catch (e) {
      print('Error removing event from calendar: $e');
    }
  }

  static Future<void> addToSystemCalendar(Task task) async {
    if (kIsWeb || task.dueDate == null) return;

    try {
      final event = add2cal.Event(
        title: task.title,
        description: task.description,
        location: '',
        startDate: task.dueDate!,
        endDate: task.dueDate!.add(Duration(minutes: task.durationMinutes)),
        allDay: false,
      );

      await add2cal.Add2Calendar.addEvent2Cal(event);
    } catch (e) {
      print('Error adding to system calendar: $e');
    }
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) return; // Skip notification initialization on web
    
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(settings);
      print('Notification service initialized successfully');
      
      await requestPermissions();
    } catch (e) {
      print('Notification initialization error: $e');
      // Don't rethrow the error to prevent app crash
    }
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb) return;
    
    try {
      await Permission.notification.request();
    } catch (e) {
      print('Notification permission error: $e');
    }
  }

  static Future<void> scheduleMultipleNotifications({
    required String taskId,
    required String title,
    required String body,
    required DateTime dueDate,
    required List<int> reminderMinutes,
  }) async {
    if (kIsWeb) return; // Skip notifications on web
    
    try {
      await cancelTaskNotifications(taskId);

      int successCount = 0;
      int errorCount = 0;

      for (int i = 0; i < reminderMinutes.length; i++) {
        try {
          final reminderTime = dueDate.subtract(Duration(minutes: reminderMinutes[i]));
          
          if (reminderTime.isAfter(DateTime.now())) {
            final notificationId = '${taskId}_$i'.hashCode;
            
            String reminderText;
            if (reminderMinutes[i] == 0) {
              reminderText = '期限になりました';
            } else if (reminderMinutes[i] < 60) {
              reminderText = '期限まで${reminderMinutes[i]}分です';
            } else if (reminderMinutes[i] < 1440) {
              reminderText = '期限まで${(reminderMinutes[i] / 60).round()}時間です';
            } else {
              reminderText = '期限まで${(reminderMinutes[i] / 1440).round()}日です';
            }

            await _notifications.zonedSchedule(
              notificationId,
              'タスクリマインダー',
              '「$title」$reminderText',
              tz.TZDateTime.from(reminderTime, tz.local),
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'task_reminders',
                  'Task Reminders',
                  channelDescription: 'Notifications for task reminders',
                  importance: Importance.high,
                  priority: Priority.high,
                  showWhen: true,
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.time,
            );
            successCount++;
          }
        } catch (e) {
          print('Error scheduling individual notification for ${reminderMinutes[i]} minutes: $e');
          errorCount++;
        }
      }

      if (successCount == 0 && errorCount > 0) {
        throw Exception('すべての通知の設定に失敗しました');
      }
    } catch (e) {
      print('Error in scheduleMultipleNotifications: $e');
      rethrow;
    }
  }

  static Future<void> cancelTaskNotifications(String taskId) async {
    if (kIsWeb) return;
    
    try {
      for (int i = 0; i < 10; i++) {
        final notificationId = '${taskId}_$i'.hashCode;
        await _notifications.cancel(notificationId);
      }
    } catch (e) {
      print('Error canceling notifications: $e');
    }
  }
}

class TaskHomePage extends StatefulWidget {
  const TaskHomePage({super.key});

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> with TickerProviderStateMixin {
  List<Task> _tasks = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late TabController _tabController;
  Timer? _chartUpdateTimer; // Timer for chart updates

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
    
    // Start timer for chart updates when on chart tab
    _tabController.addListener(() {
      if (_tabController.index == 2) { // Chart tab
        _startChartUpdateTimer();
      } else {
        _stopChartUpdateTimer();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stopChartUpdateTimer();
    super.dispose();
  }

  void _startChartUpdateTimer() {
    _stopChartUpdateTimer();
    _chartUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted && _tabController.index == 2) {
        setState(() {
          // Update chart view
        });
      }
    });
  }

  void _stopChartUpdateTimer() {
    _chartUpdateTimer?.cancel();
    _chartUpdateTimer = null;
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];
    
    setState(() {
      _tasks = tasksJson.map((taskJson) => Task.fromJson(json.decode(taskJson))).toList();
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = _tasks.map((task) => json.encode(task.toJson())).toList();
    await prefs.setStringList('tasks', tasksJson);
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      return isSameDay(task.dueDate!, day);
    }).toList();
  }

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        onTaskAdded: (task) async {
          setState(() {
            _tasks.add(task);
          });
          await _saveTasks();
          await _handleTaskNotificationsAndCalendar(task);
        },
      ),
    );
  }

  void _editTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        task: task,
        onTaskAdded: (updatedTask) async {
          setState(() {
            final index = _tasks.indexWhere((t) => t.id == task.id);
            if (index != -1) {
              _tasks[index] = updatedTask;
            }
          });
          await _saveTasks();
          
          // Cancel old notifications and calendar events
          await NotificationService.cancelTaskNotifications(task.id);
          if (task.calendarEventId != null) {
            // Remove old calendar event if needed
          }
          
          await _handleTaskNotificationsAndCalendar(updatedTask);
        },
      ),
    );
  }

  Future<void> _handleTaskNotificationsAndCalendar(Task task) async {
    if (!mounted) return;
    
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('設定を保存中...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Handle notifications
      if (task.hasReminder && task.dueDate != null) {
        try {
          await NotificationService.scheduleMultipleNotifications(
            taskId: task.id,
            title: task.title,
            body: task.description,
            dueDate: task.dueDate!,
            reminderMinutes: task.reminderMinutes,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('リマインダー通知を設定しました'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          print('Notification error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('通知設定に失敗しました: ${e.toString()}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      // Handle calendar integration (skip on web)
      if (!kIsWeb && task.addToCalendar && task.dueDate != null) {
        try {
          await CalendarService.addToSystemCalendar(task);
          
          // Also try to add to device calendar
          final eventId = await CalendarService.addEventToCalendar(task);
          if (eventId != null) {
            task.calendarEventId = eventId;
            await _saveTasks();
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('カレンダーに追加しました'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          print('Calendar error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('カレンダーへの追加に失敗しました: ${e.toString()}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('General error in _handleTaskNotificationsAndCalendar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('設定の保存中にエラーが発生しました: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _deleteTask(Task task) async {
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
    
    // Cancel notifications
    await NotificationService.cancelTaskNotifications(task.id);
    
    // Remove from calendar if added
    if (task.calendarEventId != null) {
      // Remove calendar event
    }
    
    await _saveTasks();
  }

  void _toggleTaskCompletion(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Task Manager'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'タスク'),
            Tab(icon: Icon(Icons.calendar_today), text: 'カレンダー'),
            Tab(icon: Icon(Icons.pie_chart), text: '円グラフ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskListView(),
          _buildCalendarView(),
          _buildPieChartView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        tooltip: 'タスクを追加',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskListView() {
    final incompleteTasks = _tasks.where((task) => !task.isCompleted).toList();
    final completedTasks = _tasks.where((task) => task.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (incompleteTasks.isNotEmpty) ...[
          const Text(
            '未完了のタスク',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...incompleteTasks.map((task) => _buildTaskCard(task)),
          const SizedBox(height: 16),
        ],
        if (completedTasks.isNotEmpty) ...[
          const Text(
            '完了済みのタスク',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...completedTasks.map((task) => _buildTaskCard(task)),
        ],
        if (_tasks.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'タスクがありません\n右下の + ボタンでタスクを追加しましょう',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        TableCalendar<Task>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          eventLoader: _getTasksForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            markersMaxCount: 3,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: ListView(
            children: _getTasksForDay(_selectedDay)
                .map((task) => _buildTaskCard(task))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartView() {
    final now = DateTime.now();
    final todayTasks = _getTasksForDay(now).where((task) => task.dueDate != null).toList();
    
    // Sort tasks by due time
    todayTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          // Refresh the chart
        });
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentStatusCard(now, todayTasks),
            const SizedBox(height: 20),
            _buildDailyProgressBar(now, todayTasks),
            const SizedBox(height: 20),
            _buildDailySchedulePieChart(todayTasks),
            const SizedBox(height: 20),
            _buildTodayTasksList(todayTasks),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard(DateTime now, List<Task> todayTasks) {
    Task? currentTask;
    Task? nextTask;
    
    for (int i = 0; i < todayTasks.length; i++) {
      final task = todayTasks[i];
      if (task.dueDate!.isAfter(now)) {
        nextTask = task;
        if (i > 0) {
          currentTask = todayTasks[i - 1];
        }
        break;
      }
    }
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '現在の状況',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (currentTask != null) ...[
              Text(
                '現在の予定:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                currentTask.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
            ],
            if (nextTask != null) ...[
              Text(
                '次の予定:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                nextTask.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('HH:mm').format(nextTask.dueDate!)} (あと${_getMinutesUntil(now, nextTask.dueDate!)}分)',
                style: TextStyle(fontSize: 14, color: Colors.orange[700]),
              ),
            ] else ...[
              Text(
                '今日はこれ以上の予定はありません',
                style: TextStyle(fontSize: 16, color: Colors.green[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyProgressBar(DateTime now, List<Task> todayTasks) {
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentTotalMinutes = currentHour * 60 + currentMinute;
    final dayTotalMinutes = 24 * 60;
    final progress = currentTotalMinutes / dayTotalMinutes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '一日の進捗',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(1)}% 経過 (${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySchedulePieChart(List<Task> todayTasks) {
    if (todayTasks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                '今日の予定はありません',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final sections = _createPieChartSections(todayTasks);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '今日のスケジュール (24時間)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildPieChartLegend(todayTasks),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _createPieChartSections(List<Task> todayTasks) {
    final sections = <PieChartSectionData>[];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    
    // Calculate free time and task time
    double totalTaskMinutes = 0;
    for (int i = 0; i < todayTasks.length; i++) {
      // Assume each task takes 30 minutes
      totalTaskMinutes += todayTasks[i].durationMinutes;
      
      sections.add(
        PieChartSectionData(
          value: todayTasks[i].durationMinutes.toDouble(), // 30 minutes per task
          color: colors[i % colors.length],
          title: '${todayTasks[i].title.length > 8 ? todayTasks[i].title.substring(0, 8) + '...' : todayTasks[i].title}',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    // Add free time
    final freeTime = 1440 - totalTaskMinutes; // 1440 minutes in a day
    if (freeTime > 0) {
      sections.add(
        PieChartSectionData(
          value: freeTime.toDouble(),
          color: Colors.grey[300]!,
          title: '空き時間',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      );
    }
    
    return sections;
  }

  Widget _buildPieChartLegend(List<Task> todayTasks) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    
    return Column(
      children: [
        ...todayTasks.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${task.title} (${DateFormat('HH:mm').format(task.dueDate!)})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '空き時間',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayTasksList(List<Task> todayTasks) {
    if (todayTasks.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今日の予定一覧',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...todayTasks.map((task) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(
                    task.isCompleted ? Icons.check_circle : Icons.schedule,
                    color: task.isCompleted ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(task.dueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  int _getMinutesUntil(DateTime from, DateTime to) {
    return to.difference(from).inMinutes;
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => _toggleTaskCompletion(task),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(task.description),
            Text(
              '作成日: ${DateFormat('yyyy/MM/dd HH:mm').format(task.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (task.dueDate != null)
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 12,
                    color: task.dueDate!.isBefore(DateTime.now()) && !task.isCompleted
                        ? Colors.red
                        : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '期限: ${DateFormat('yyyy/MM/dd HH:mm').format(task.dueDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: task.dueDate!.isBefore(DateTime.now()) && !task.isCompleted
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                  if (task.hasReminder) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.notifications, size: 12, color: Colors.blue),
                  ],
                  if (task.addToCalendar) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.event, size: 12, color: Colors.green),
                  ],
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editTask(task);
                break;
              case 'delete':
                _deleteTask(task);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('編集'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 8),
                  Text('削除'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskDialog extends StatefulWidget {
  final Task? task;
  final Function(Task) onTaskAdded;

  const TaskDialog({
    super.key,
    this.task,
    required this.onTaskAdded,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  bool _hasReminder = false;
  bool _addToCalendar = false;
  List<int> _reminderMinutes = [30];
  int _durationMinutes = 30;

  final List<int> _availableReminders = [
    0,     // 期限時刻
    5,     // 5分前
    15,    // 15分前
    30,    // 30分前
    60,    // 1時間前
    120,   // 2時間前
    1440,  // 1日前
    2880,  // 2日前
    10080, // 1週間前
  ];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDueDate = widget.task!.dueDate;
      _selectedDueTime = widget.task!.dueDate != null
          ? TimeOfDay.fromDateTime(widget.task!.dueDate!)
          : null;
      _hasReminder = widget.task!.hasReminder;
      _addToCalendar = widget.task!.addToCalendar;
      _reminderMinutes = List.from(widget.task!.reminderMinutes);
      _durationMinutes = widget.task!.durationMinutes;
    }
  }

  String _getReminderText(int minutes) {
    if (minutes == 0) return '期限時刻';
    if (minutes < 60) return '${minutes}分前';
    if (minutes < 1440) return '${(minutes / 60).round()}時間前';
    return '${(minutes / 1440).round()}日前';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'タスクを追加' : 'タスクを編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タスク名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明（任意）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDueDate = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_selectedDueDate == null
                        ? '期限日を選択'
                        : DateFormat('yyyy/MM/dd').format(_selectedDueDate!)),
                  ),
                ),
                if (_selectedDueDate != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDueDate = null;
                        _selectedDueTime = null;
                        _hasReminder = false;
                        _addToCalendar = false;
                      });
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
            if (_selectedDueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedDueTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _selectedDueTime = time;
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedDueTime == null
                          ? '時刻を選択'
                          : _selectedDueTime!.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: '所要時間（分）',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: _durationMinutes.toString(),
                      onChanged: (value) {
                        setState(() {
                          _durationMinutes = int.tryParse(value) ?? 30;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('リマインダー通知'),
                subtitle: const Text('指定した時間前に通知'),
                value: _hasReminder,
                onChanged: (value) {
                  setState(() {
                    _hasReminder = value ?? false;
                  });
                },
              ),
              if (_hasReminder) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('通知タイミング:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView(
                    children: _availableReminders.map((minutes) {
                      return CheckboxListTile(
                        dense: true,
                        title: Text(_getReminderText(minutes)),
                        value: _reminderMinutes.contains(minutes),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              if (!_reminderMinutes.contains(minutes)) {
                                _reminderMinutes.add(minutes);
                                _reminderMinutes.sort();
                              }
                            } else {
                              _reminderMinutes.remove(minutes);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('カレンダーに追加'),
                subtitle: const Text('デバイスのカレンダーアプリに追加'),
                value: _addToCalendar,
                onChanged: (value) {
                  setState(() {
                    _addToCalendar = value ?? false;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('タスク名を入力してください')),
              );
              return;
            }

            if (_hasReminder && _reminderMinutes.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('リマインダーを有効にする場合は、通知タイミングを選択してください')),
              );
              return;
            }

            DateTime? finalDueDate;
            if (_selectedDueDate != null) {
              final time = _selectedDueTime ?? const TimeOfDay(hour: 23, minute: 59);
              finalDueDate = DateTime(
                _selectedDueDate!.year,
                _selectedDueDate!.month,
                _selectedDueDate!.day,
                time.hour,
                time.minute,
              );
            }

            final task = Task(
              id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              createdAt: widget.task?.createdAt ?? DateTime.now(),
              dueDate: finalDueDate,
              isCompleted: widget.task?.isCompleted ?? false,
              hasReminder: _hasReminder,
              reminderMinutes: _reminderMinutes,
              addToCalendar: _addToCalendar,
              calendarEventId: widget.task?.calendarEventId,
              durationMinutes: _durationMinutes,
            );

            widget.onTaskAdded(task);
            Navigator.of(context).pop();
          },
          child: Text(widget.task == null ? '追加' : '更新'),
        ),
      ],
    );
  }
}
