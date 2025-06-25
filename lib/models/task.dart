class Task {
  final String id;
  final String? supabaseId; // Supabase database ID
  final String title;
  final String? description;
  final DateTime dueDate;
  final int durationMinutes;
  final List<int> reminderMinutes;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userId; // For Supabase user association
  String? calendarEventId; // For calendar integration

  Task({
    required this.id,
    this.supabaseId,
    required this.title,
    this.description,
    required this.dueDate,
    this.durationMinutes = 30,
    this.reminderMinutes = const [15],
    this.isCompleted = false,
    DateTime? createdAt,
    this.updatedAt,
    this.userId,
    this.calendarEventId,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create Task from Supabase data
  factory Task.fromSupabase(Map<String, dynamic> data) {
    return Task(
      id: data['id'].toString(),
      supabaseId: data['id'].toString(),
      title: data['title'] ?? '',
      description: data['description'],
      dueDate: DateTime.parse(data['due_date']),
      durationMinutes: data['duration_minutes'] ?? 30,
      reminderMinutes: data['reminder_minutes'] != null 
          ? List<int>.from(data['reminder_minutes'])
          : [15],
      isCompleted: data['is_completed'] ?? false,
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null 
          ? DateTime.parse(data['updated_at'])
          : null,
      userId: data['user_id'],
      calendarEventId: data['calendar_event_id'],
    );
  }

  // Create Task from local storage (SharedPreferences)
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      supabaseId: json['supabaseId'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      durationMinutes: json['durationMinutes'] ?? 30,
      reminderMinutes: json['reminderMinutes'] != null
          ? List<int>.from(json['reminderMinutes'])
          : [15],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
      userId: json['userId'],
      calendarEventId: json['calendarEventId'],
    );
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supabaseId': supabaseId,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'durationMinutes': durationMinutes,
      'reminderMinutes': reminderMinutes,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'userId': userId,
      'calendarEventId': calendarEventId,
    };
  }

  // Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'duration_minutes': durationMinutes,
      'reminder_minutes': reminderMinutes,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      'calendar_event_id': calendarEventId,
    };
  }

  Task copyWith({
    String? id,
    String? supabaseId,
    String? title,
    String? description,
    DateTime? dueDate,
    int? durationMinutes,
    List<int>? reminderMinutes,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? calendarEventId,
  }) {
    return Task(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      calendarEventId: calendarEventId ?? this.calendarEventId,
    );
  }

  // Computed properties
  bool get hasReminder => reminderMinutes.isNotEmpty;
  bool get addToCalendar => true; // Always add to calendar if due date is set

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Task(id: $id, title: $title, dueDate: $dueDate, isCompleted: $isCompleted)';
  }
}
