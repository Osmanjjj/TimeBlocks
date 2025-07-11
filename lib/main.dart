import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math' as math;
import 'models/task.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/calendar_service.dart';
import 'screens/auth_screen.dart';
import 'screens/password_update_screen.dart';
import 'screens/settings_screen.dart';
import 'config/env.dart';
import 'clock_hand_painter.dart';
// import 'completed_task_painter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    );
    print('Supabase initialized successfully');
    
    // Handle auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      print('Auth state changed: $event');
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        print('User signed in: ${session.user.email}');
      } else if (event == AuthChangeEvent.signedOut) {
        print('User signed out');
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        print('Token refreshed');
      }
    });
    
    // Handle deep links for authentication
    AppLinks().getInitialAppLink().then((value) async {
      if (value != null) {
        final link = value.toString();
        print('Initial deep link: $link');
        // Handle authentication callback
        if (link.contains('access_token') || link.contains('refresh_token')) {
          print('Processing authentication callback from deep link');
          try {
            await Supabase.instance.client.auth.getSessionFromUrl(value);
            print('Authentication successful from deep link');
          } catch (e) {
            print('Error processing authentication callback: $e');
          }
        }
      }
    });
    
    AppLinks().uriLinkStream.listen((uri) async {
      if (uri != null) {
        final link = uri.toString();
        print('Deep link: $link');
        // Handle authentication callback
        if (link.contains('access_token') || link.contains('refresh_token')) {
          print('Processing authentication callback from deep link');
          try {
            await Supabase.instance.client.auth.getSessionFromUrl(uri);
            print('Authentication successful from deep link');
          } catch (e) {
            print('Error processing authentication callback: $e');
          }
        }
      }
    });
    
  } catch (e) {
    print('Supabase initialization failed: $e');
    // Fallback: Continue without Supabase for local testing
    print('Continuing in offline mode...');
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

class TaskApp extends StatefulWidget {
  const TaskApp({super.key});

  @override
  State<TaskApp> createState() => _TaskAppState();
}

class _TaskAppState extends State<TaskApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  @override
  void initState() {
    super.initState();
    _setupDeepLinkHandling();
  }
  
  void _setupDeepLinkHandling() {
    // Handle deep links for password reset
    AppLinks().uriLinkStream.listen((uri) async {
      if (uri != null) {
        final link = uri.toString();
        print('Deep link received: $link');
        
        // Handle password reset callback
        if (link.contains('type=recovery') || link.contains('auth/login')) {
          print('Password reset callback detected');
          
          try {
            // Get session from URL
            final response = await Supabase.instance.client.auth.getSessionFromUrl(uri);
            print('Session recovered from password reset link: ${response.session?.user?.email}');
            
            // Wait a moment for the session to be fully established
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Verify session is active
            final currentUser = Supabase.instance.client.auth.currentUser;
            print('Current user after session recovery: ${currentUser?.email}');
            
            // Navigate to password update screen
            if (_navigatorKey.currentContext != null) {
              Navigator.of(_navigatorKey.currentContext!).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const PasswordUpdateScreen(),
                ),
                (route) => false,
              );
            }
          } catch (e) {
            print('Error processing password reset callback: $e');
            // If session recovery fails, still navigate to password update screen
            if (_navigatorKey.currentContext != null) {
              Navigator.of(_navigatorKey.currentContext!).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const PasswordUpdateScreen(),
                ),
                (route) => false,
              );
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Environment.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
  
  static void forceUpdate() {
    _AuthWrapperState.forceUpdate();
  }
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasShownWelcomeMessage = false;
  static _AuthWrapperState? _instance;
  
  static void forceUpdate() {
    _instance?.setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _instance = this;
    
    // Listen for authentication state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (event == AuthChangeEvent.signedIn && session != null && mounted) {
        // Show welcome message only once per session
        if (!_hasShownWelcomeMessage) {
          _hasShownWelcomeMessage = true;
          
          // Delay to ensure the UI is ready
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎉 メール認証が完了しました！',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text('✅ ${session.user.email} でログインしました'),
                      const SizedBox(height: 4),
                      const Text('🚀 TimeBlocksへようこそ！タスク管理を始めましょう！'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            }
          });
        }
      } else if (event == AuthChangeEvent.signedOut && mounted) {
        _hasShownWelcomeMessage = false;
      }
    });
  }
  
  @override
  void dispose() {
    _instance = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // First check if there's a current session
    final currentSession = SupabaseService.client.auth.currentSession;
    
    return StreamBuilder<AuthState>(
      stream: SupabaseService.authStateChanges,
      initialData: currentSession != null ? AuthState(AuthChangeEvent.initialSession, currentSession) : null,
      builder: (context, snapshot) {
        // Always check current user state directly from Supabase
        final currentUser = SupabaseService.currentUser;
        final session = snapshot.hasData ? snapshot.data!.session : null;
        
        // Debug: Print current auth state
        print('Auth state - StreamBuilder session: ${session?.user?.email}');
        print('Auth state - Direct currentUser: ${currentUser?.email}');
        
        if (snapshot.connectionState == ConnectionState.waiting && currentUser == null) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('認証状態を確認中...'),
                ],
              ),
            ),
          );
        }

        // Use direct currentUser check as primary, session as fallback
        final isAuthenticated = currentUser != null || (session != null && session.user != null);
        
        if (isAuthenticated) {
          // User is authenticated, show home page
          return const TaskHomePage();
        } else {
          // User is not authenticated, show auth screen
          return const AuthScreen();
        }
      },
    );
  }
}

class TaskHomePage extends StatefulWidget {
  const TaskHomePage({super.key});

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> with TickerProviderStateMixin {
  List<Task> _tasks = [];
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Timer? _chartUpdateTimer;
  StreamSubscription<List<Map<String, dynamic>>>? _tasksSubscription;
  static _TaskHomePageState? _instance;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _instance = this;
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
    _setupRealtimeListener();
    
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
    _instance = null;
    _stopChartUpdateTimer();
    _tasksSubscription?.cancel();
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
    final tasks = await SupabaseService.getTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  void _setupRealtimeListener() {
    _tasksSubscription = SupabaseService.listenToUserTasks().listen(
      (tasksData) {
        if (mounted) {
          final tasks = tasksData.map((data) => Task.fromSupabase(data)).toList();
          setState(() {
            _tasks = tasks;
          });
          print('Tasks updated via realtime: ${tasks.length} tasks');
        }
      },
      onError: (error) {
        print('Error in realtime listener: $error');
      },
    );
  }

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        onTaskAdded: (task) async {
          try {
            // Create task in Supabase
            await SupabaseService.createTask(
              title: task.title,
              description: task.description,
              dueDate: task.dueDate,
              durationMinutes: task.durationMinutes,
              reminderMinutes: task.reminderMinutes,
            );
            
            // Handle notifications and calendar
            await _handleTaskNotificationsAndCalendar(task);
            
            // Tasks will be updated automatically via realtime listener
            // await _loadTasks(); // Commented out as realtime handles this
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('タスクを追加しました'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('タスクの追加に失敗しました: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
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
          try {
            // Update task in Supabase
            if (task.supabaseId != null) {
              await SupabaseService.updateTask(
                taskId: task.supabaseId!,
                title: updatedTask.title,
                description: updatedTask.description,
                dueDate: updatedTask.dueDate,
                durationMinutes: updatedTask.durationMinutes,
                reminderMinutes: updatedTask.reminderMinutes,
                isCompleted: updatedTask.isCompleted,
              );
            }
            
            // Cancel old notifications
            await NotificationService.cancelTaskNotifications(task.id);
            
            // Handle notifications and calendar
            await _handleTaskNotificationsAndCalendar(updatedTask);
            
            // Tasks will be updated automatically via realtime listener
            // await _loadTasks(); // Commented out as realtime handles this
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('タスクを更新しました'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('タスクの更新に失敗しました: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
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
    try {
      // Delete from Supabase
      if (task.supabaseId != null) {
        await SupabaseService.deleteTask(task.supabaseId!);
      }
      
      // Cancel notifications
      await NotificationService.cancelTaskNotifications(task.id);
      
      // Tasks will be updated automatically via realtime listener
      // await _loadTasks(); // Commented out as realtime handles this
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('タスクを削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('タスクの削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleTaskCompletion(Task task) async {
    try {
      // Update in Supabase
      if (task.supabaseId != null) {
        await SupabaseService.updateTask(
          taskId: task.supabaseId!,
          title: task.title,
          description: task.description,
          dueDate: task.dueDate,
          durationMinutes: task.durationMinutes,
          reminderMinutes: task.reminderMinutes,
          isCompleted: !task.isCompleted,
        );
      }
      
      // Force immediate UI update
      await _loadTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(task.isCompleted ? 'タスクを未完了にしました' : 'タスクを完了しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('タスクの更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveTasks() async {
    await SupabaseService.saveTasks(_tasks);
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      return isSameDay(task.dueDate!, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TimeBlocks'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'タスク'),
            Tab(icon: Icon(Icons.calendar_today), text: 'カレンダー'),
            Tab(icon: Icon(Icons.pie_chart), text: '円グラフ'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: '設定',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskListView(),
          _buildCalendarView(),
          _buildChartView(),
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

  Widget _buildChartView() {
    final today = DateTime.now();
    final todayTasks = _tasks.where((task) {
      return task.dueDate != null &&
          task.dueDate!.year == today.year &&
          task.dueDate!.month == today.month &&
          task.dueDate!.day == today.day;
    }).toList();

    // Sort tasks by time
    todayTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    
    // Find current running task
    Task? currentTask;
    final now = DateTime.now();
    for (final task in todayTasks) {
      final taskStart = task.dueDate!;
      final taskEnd = taskStart.add(Duration(minutes: task.durationMinutes));
      if (now.isAfter(taskStart) && now.isBefore(taskEnd)) {
        currentTask = task;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            '今日の予定 (${DateFormat('yyyy/MM/dd').format(today)})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
<<<<<<< HEAD
          if (currentTask != null) ...[  
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_filled, color: Colors.blue, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${currentTask.title}中',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${DateFormat('HH:mm').format(currentTask.dueDate!)} - ${DateFormat('HH:mm').format(currentTask.dueDate!.add(Duration(minutes: currentTask.durationMinutes)))}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
=======
          // 現在のタスク状況表示
          _buildCurrentTaskStatus(todayTasks, today),
          const SizedBox(height: 16),
>>>>>>> 73ef7789c1f4f95ed1c634f4e34724399a778e13
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          return;
                        }
                        
                        final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        if (_sectionToTaskIndex.containsKey(touchedIndex)) {
                          final taskIndex = _sectionToTaskIndex[touchedIndex]!;
                          _showTaskDetails(todayTasks[taskIndex]);
                        }
                      },
                    ),
                    startDegreeOffset: -90, // Start from top
                    sections: _buildPieChartSections(todayTasks, today),
                    centerSpaceRadius: 60,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      enabled: true,
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if ((event is FlTapUpEvent || event is FlTapDownEvent) && pieTouchResponse != null) {
                          final touchedSection = pieTouchResponse.touchedSection;
                          if (touchedSection != null) {
                            _handleChartTap(touchedSection.touchedSectionIndex, todayTasks);
                          }
                        }
                      },
                    ),
                  ),
                ),
                // 時計の針を追加
                CustomPaint(
                  size: const Size(200, 200),
                  painter: ClockHandPainter(DateTime.now()),
                ),
                // 完了タスクの横線を追加
                // CustomPaint(
                //   size: const Size(200, 200),
                //   painter: CompletedTaskLinePainter(todayTasks),
                // ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(today),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      '現在時刻',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '今日の予定一覧:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: todayTasks.isEmpty
                      ? const Center(
                          child: Text(
                            '今日の予定はありません',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: todayTasks.length,
                          itemBuilder: (context, index) {
                            final task = todayTasks[index];
                            final isCompleted = task.isCompleted;
                            return ListTile(
                              dense: true,
                              leading: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isCompleted 
                                      ? _getTaskColor(index).withOpacity(0.3)
                                      : _getTaskColor(index),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  color: isCompleted ? Colors.grey : null,
                                ),
                              ),
                              subtitle: Text(
                                '${DateFormat('HH:mm').format(task.dueDate!)} - ${task.durationMinutes}分${isCompleted ? ' (完了)' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCompleted ? Colors.grey : null,
                                ),
                              ),
                              onTap: () => _showTaskDetailDialog(task),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<int, int> _sectionToTaskIndex = {};
  
  List<PieChartSectionData> _buildPieChartSections(List<Task> todayTasks, DateTime today) {
    List<PieChartSectionData> sections = [];
    _sectionToTaskIndex.clear();
    
    if (todayTasks.isEmpty) {
      // If no tasks, show full day as free time
      sections.add(
        PieChartSectionData(
          value: 24 * 60, // 24 hours in minutes
          color: Colors.grey.shade300,
          title: '空き時間',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
      return sections;
    }

    double currentMinute = 0; // Start of day in minutes
    const double totalMinutes = 24 * 60; // Total minutes in a day

    for (int i = 0; i < todayTasks.length; i++) {
      final task = todayTasks[i];
      final taskStartMinute = task.dueDate!.hour * 60.0 + task.dueDate!.minute;
      
      // Add free time before this task
      if (taskStartMinute > currentMinute) {
        sections.add(
          PieChartSectionData(
            value: taskStartMinute - currentMinute,
            color: Colors.grey.shade300,
            title: '',
            radius: 80,
          ),
        );
      }
      
      // Add the task
      _sectionToTaskIndex[sections.length] = i;  // Map section index to task index
      
      final taskColor = task.isCompleted 
          ? _getTaskColor(i).withOpacity(0.3)
          : _getCurrentRunningTask(todayTasks, today)?.id == task.id
              ? Colors.green
              : _getTaskColor(i);
      
      sections.add(
        PieChartSectionData(
          value: task.durationMinutes.toDouble(),
          color: taskColor,
          title: task.durationMinutes > 30 ? task.title : '',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          showTitle: true,
          titlePositionPercentageOffset: 0.5,
        ),
      );
      
      currentMinute = taskStartMinute + task.durationMinutes;
    }
    
    // Add remaining free time at the end of the day
    if (currentMinute < totalMinutes) {
      sections.add(
        PieChartSectionData(
          value: totalMinutes - currentMinute,
          color: Colors.grey.shade300,
          title: '',
          radius: 80,
        ),
      );
    }

    return sections;
  }

  Color _getTaskColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
  
  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty) ...[  
              Text(
                '説明:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(task.description!),
              const SizedBox(height: 16),
            ],
            Text(
              '日時:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('yyyy年MM月dd日 HH:mm').format(task.dueDate!),
            ),
            const SizedBox(height: 8),
            Text(
              '所要時間:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${task.durationMinutes}分'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editTask(task);
            },
            child: const Text('編集'),
          ),
        ],
      ),
    );
  }

  // 現在実行中のタスクを取得
  Task? _getCurrentRunningTask(List<Task> todayTasks, DateTime now) {
    final currentMinutes = now.hour * 60 + now.minute;
    
    for (final task in todayTasks) {
      if (task.isCompleted) continue;
      
      final taskStartMinutes = task.dueDate!.hour * 60 + task.dueDate!.minute;
      final taskEndMinutes = taskStartMinutes + task.durationMinutes;
      
      if (currentMinutes >= taskStartMinutes && currentMinutes < taskEndMinutes) {
        return task;
      }
    }
    return null;
  }

  // 次の予定タスクを取得
  Task? _getNextUpcomingTask(List<Task> todayTasks, DateTime now) {
    final currentMinutes = now.hour * 60 + now.minute;
    
    Task? nextTask;
    for (final task in todayTasks) {
      if (task.isCompleted) continue;
      
      final taskStartMinutes = task.dueDate!.hour * 60 + task.dueDate!.minute;
      
      if (taskStartMinutes > currentMinutes) {
        if (nextTask == null || taskStartMinutes < (nextTask.dueDate!.hour * 60 + nextTask.dueDate!.minute)) {
          nextTask = task;
        }
      }
    }
    return nextTask;
  }

  // 時間差分のフォーマット
  String _formatDuration(int minutes) {
    if (minutes < 1) return 'まもなく';
    if (minutes < 60) return '${minutes}分';
    
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (remainingMinutes == 0) {
      return '${hours}時間';
    } else {
      return '${hours}時間${remainingMinutes}分';
    }
  }

  // 現在のタスク状況を表示するウィジェット
  Widget _buildCurrentTaskStatus(List<Task> todayTasks, DateTime now) {
    final currentTask = _getCurrentRunningTask(todayTasks, now);
    final nextTask = _getNextUpcomingTask(todayTasks, now);
    
    if (currentTask != null) {
      final taskStartMinutes = currentTask.dueDate!.hour * 60 + currentTask.dueDate!.minute;
      final taskEndMinutes = taskStartMinutes + currentTask.durationMinutes;
      final currentMinutes = now.hour * 60 + now.minute;
      final remainingMinutes = taskEndMinutes - currentMinutes;
      
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_filled, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '現在実行中',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currentTask.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '開始: ${DateFormat('HH:mm').format(currentTask.dueDate!)} | '
              '終了予定: ${DateFormat('HH:mm').format(currentTask.dueDate!.add(Duration(minutes: currentTask.durationMinutes)))} | '
              '残り時間: ${_formatDuration(remainingMinutes)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    } else if (nextTask != null) {
      final nextTaskStartMinutes = nextTask.dueDate!.hour * 60 + nextTask.dueDate!.minute;
      final currentMinutes = now.hour * 60 + now.minute;
      final timeUntilNext = nextTaskStartMinutes - currentMinutes;
      
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '空き時間',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '次の予定: ${nextTask.title}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '開始まで: ${_formatDuration(timeUntilNext)} (${DateFormat('HH:mm').format(nextTask.dueDate!)}開始)',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            const Text(
              '今日の予定は全て完了しました',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }

  // チャートタップハンドラー
  void _handleChartTap(int sectionIndex, List<Task> todayTasks) {
    // セクションインデックスからタスクを特定
    int taskIndex = 0;
    int currentSectionIndex = 0;
    
    for (int i = 0; i < todayTasks.length; i++) {
      final task = todayTasks[i];
      final taskStartMinute = task.dueDate!.hour * 60.0 + task.dueDate!.minute;
      
      // 空き時間のセクションがある場合
      if (i == 0 && taskStartMinute > 0) {
        if (currentSectionIndex == sectionIndex) {
          // 空き時間がタップされた場合は何もしない
          return;
        }
        currentSectionIndex++;
      } else if (i > 0) {
        final prevTask = todayTasks[i - 1];
        final prevTaskEndMinute = prevTask.dueDate!.hour * 60.0 + prevTask.dueDate!.minute + prevTask.durationMinutes;
        if (taskStartMinute > prevTaskEndMinute) {
          if (currentSectionIndex == sectionIndex) {
            // 空き時間がタップされた場合は何もしない
            return;
          }
          currentSectionIndex++;
        }
      }
      
      // タスクのセクション
      if (currentSectionIndex == sectionIndex) {
        _showTaskDetailDialog(task);
        return;
      }
      currentSectionIndex++;
    }
  }

  // タスク詳細ダイアログ
  void _showTaskDetailDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty) ...[
              const Text('説明:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(task.description!),
              const SizedBox(height: 12),
            ],
            const Text('開始時刻:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(DateFormat('yyyy/MM/dd HH:mm').format(task.dueDate!)),
            const SizedBox(height: 8),
            const Text('所要時間:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${task.durationMinutes}分'),
            const SizedBox(height: 8),
            const Text('終了予定時刻:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(DateFormat('HH:mm').format(task.dueDate!.add(Duration(minutes: task.durationMinutes)))),
            const SizedBox(height: 8),
            const Text('完了状態:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(task.isCompleted ? '完了済み' : '未完了'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          if (!task.isCompleted)
            ElevatedButton(
              onPressed: () {
                _toggleTaskCompletion(task);
                Navigator.of(context).pop();
              },
              child: const Text('完了にする'),
            ),
        ],
      ),
    );
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
            if (task.description != null && task.description!.isNotEmpty)
              Text(task.description!),
            if (task.createdAt != null)
              Text(
                '作成日: ${DateFormat('yyyy/MM/dd HH:mm').format(task.createdAt!)}',
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
                  if (task.reminderMinutes.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.notifications, size: 12, color: Colors.blue),
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
  DateTime _selectedDate = DateTime.now();
  int _durationMinutes = 30;
  bool _hasReminder = false;
  bool _addToCalendar = false;
  List<int> _reminderMinutes = [15];
  final List<int> _availableReminders = [5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _selectedDate = widget.task!.dueDate;
      _durationMinutes = widget.task!.durationMinutes;
      _hasReminder = widget.task!.hasReminder;
      _addToCalendar = widget.task!.addToCalendar;
      _reminderMinutes = List.from(widget.task!.reminderMinutes);
    }
  }

  String _getReminderText(int minutes) {
    if (minutes == 0) return '期限時刻';
    if (minutes < 60) return '${minutes}分前';
    if (minutes < 1440) return '${(minutes / 60).round()}時間前';
    return '${(minutes / 1440).round()}日前';
  }

  void _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      } else {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            _selectedDate.hour,
            _selectedDate.minute,
          );
        });
      }
    }
  }

  void _saveTask() {
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

    final task = Task(
      id: widget.task?.id ?? SupabaseService.generateTaskId(),
      supabaseId: widget.task?.supabaseId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      dueDate: _selectedDate,
      durationMinutes: _durationMinutes,
      reminderMinutes: _hasReminder ? _reminderMinutes : [],
      isCompleted: widget.task?.isCompleted ?? false,
      createdAt: widget.task?.createdAt,
      updatedAt: DateTime.now(),
      userId: SupabaseService.currentUser?.id,
    );

    widget.onTaskAdded(task);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.task == null ? Icons.add_task : Icons.edit,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  widget.task == null ? '新しいタスクを追加' : 'タスクを編集',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'タイトル',
                          prefixIcon: Icon(Icons.title, color: Colors.blue.shade600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: '説明（任意）',
                          prefixIcon: Icon(Icons.description, color: Colors.blue.shade600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.calendar_today, color: Colors.green.shade700),
                        ),
                        title: const Text('日時', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          DateFormat('yyyy/MM/dd HH:mm').format(_selectedDate),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        onTap: _selectDateTime,
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.timer, color: Colors.orange.shade700),
                          ),
                          const SizedBox(width: 16),
                          const Text('所要時間:', style: TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                suffixText: '分',
                              ),
                              controller: TextEditingController(text: _durationMinutes.toString()),
                              onChanged: (value) {
                                _durationMinutes = int.tryParse(value) ?? 30;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'キャンセル',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade600,
                          Colors.purple.shade600,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _saveTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '保存',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
