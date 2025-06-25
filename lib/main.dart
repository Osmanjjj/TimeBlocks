import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';
import 'models/task.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/calendar_service.dart';
import 'screens/auth_screen.dart';
import 'config/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
    );
    print('Supabase initialized successfully');
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

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Environment.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;
        
        if (session != null) {
          return const TaskHomePage();
        } else {
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
    final tasks = await SupabaseService.getTasks();
    setState(() {
      _tasks = tasks;
    });
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
            
            // Reload tasks from Supabase
            await _loadTasks();
            
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
            
            // Reload tasks from Supabase
            await _loadTasks();
            
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
      
      // Reload tasks from Supabase
      await _loadTasks();
      
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
      
      // Reload tasks from Supabase
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
            onPressed: () async {
              await SupabaseService.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
            icon: const Icon(Icons.logout),
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
          task.dueDate!.day == today.day &&
          !task.isCompleted;
    }).toList();

    // Sort tasks by time
    todayTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            '今日の予定 (${DateFormat('yyyy/MM/dd').format(today)})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90, // Start from top
                    sections: _buildPieChartSections(todayTasks, today),
                    centerSpaceRadius: 60,
                    sectionsSpace: 2,
                  ),
                ),
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
                            return ListTile(
                              dense: true,
                              leading: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getTaskColor(index),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(
                                task.title,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                '${DateFormat('HH:mm').format(task.dueDate!)} - ${task.durationMinutes}分',
                                style: const TextStyle(fontSize: 12),
                              ),
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

  List<PieChartSectionData> _buildPieChartSections(List<Task> todayTasks, DateTime today) {
    List<PieChartSectionData> sections = [];
    
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
      sections.add(
        PieChartSectionData(
          value: task.durationMinutes.toDouble(),
          color: _getTaskColor(i),
          title: task.durationMinutes > 30 ? task.title : '',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.task == null ? 'タスクを追加' : 'タスクを編集',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'タイトル',
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
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('日時'),
                      subtitle: Text(DateFormat('yyyy/MM/dd HH:mm').format(_selectedDate)),
                      onTap: _selectDateTime,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.timer),
                        const SizedBox(width: 16),
                        const Text('所要時間（分）:'),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(text: _durationMinutes.toString()),
                            onChanged: (value) {
                              _durationMinutes = int.tryParse(value) ?? 30;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('リマインダー通知'),
                      subtitle: const Text('指定した時間前に通知'),
                      value: _hasReminder,
                      onChanged: (value) {
                        setState(() {
                          _hasReminder = value;
                        });
                      },
                    ),
                    if (_hasReminder) ...[
                      const SizedBox(height: 8),
                      const Text('通知タイミング:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: _availableReminders.map((minutes) {
                          return FilterChip(
                            label: Text(_getReminderText(minutes)),
                            selected: _reminderMinutes.contains(minutes),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
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
                    ],
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('カレンダーに追加'),
                      subtitle: const Text('デバイスのカレンダーに追加'),
                      value: _addToCalendar,
                      onChanged: (value) {
                        setState(() {
                          _addToCalendar = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: _saveTask,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
