import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/task.dart';

class SupabaseService {
  static const String _url = 'https://cszdcnpfteimwinmjnqu.supabase.co';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNzemRjbnBmdGVpbXdpbm1qbnF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4MzA5NzgsImV4cCI6MjA2NjQwNjk3OH0.-qgJ8ZN97exWJsyF53y9ht1da_CvCfiEUI52MOloXzY';
  
  static SupabaseClient get client => Supabase.instance.client;
  
  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }
  
  /// Get current user
  static User? get currentUser {
    try {
      return client.auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
  
  /// Check if user is authenticated
  static bool get isAuthenticated {
    try {
      return currentUser != null;
    } catch (e) {
      print('Error checking authentication: $e');
      return false;
    }
  }
  
  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
      emailRedirectTo: 'timeblocks://auth/callback',
    );
    return response;
  }
  
  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }
  
  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  /// Reset password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'timeblocks://auth/callback',
    );
  }
  
  /// Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isAuthenticated) return null;
    
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('user_id', currentUser!.id)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  /// Create or update user profile
  static Future<void> upsertUserProfile({
    required String displayName,
    String? avatarUrl,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final profile = {
      'user_id': currentUser!.id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await client.from('user_profiles').upsert(profile);
  }
  
  /// Get tasks for current user
  static Future<List<Map<String, dynamic>>> getUserTasks() async {
    if (!isAuthenticated) return [];
    
    try {
      final response = await client
          .from('tasks')
          .select()
          .eq('user_id', currentUser!.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }
  
  /// Get tasks for current user (alias for getUserTasks)
  static Future<List<Task>> getTasks() async {
    final tasksData = await getUserTasks();
    return tasksData.map((data) => Task.fromSupabase(data)).toList();
  }
  
  /// Create a new task
  static Future<Map<String, dynamic>?> createTask({
    required String title,
    String? description,
    required DateTime dueDate,
    required int durationMinutes,
    required List<int> reminderMinutes,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final taskData = {
      'user_id': currentUser!.id,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'duration_minutes': durationMinutes,
      'reminder_minutes': reminderMinutes,
      'is_completed': false,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    try {
      final response = await client
          .from('tasks')
          .insert(taskData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating task: $e');
      rethrow;
    }
  }
  
  /// Update a task
  static Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    DateTime? dueDate,
    int? durationMinutes,
    List<int>? reminderMinutes,
    bool? isCompleted,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (title != null) updateData['title'] = title;
    if (description != null) updateData['description'] = description;
    if (dueDate != null) updateData['due_date'] = dueDate.toIso8601String();
    if (durationMinutes != null) updateData['duration_minutes'] = durationMinutes;
    if (reminderMinutes != null) updateData['reminder_minutes'] = reminderMinutes;
    if (isCompleted != null) updateData['is_completed'] = isCompleted;
    
    try {
      await client
          .from('tasks')
          .update(updateData)
          .eq('id', taskId)
          .eq('user_id', currentUser!.id);
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }
  
  /// Delete a task
  static Future<void> deleteTask(String taskId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      await client
          .from('tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_id', currentUser!.id);
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }
  
  /// Save tasks (not used with Supabase - tasks are saved individually)
  static Future<void> saveTasks(List<Task> tasks) async {
    // This method is kept for compatibility but not used
    // Tasks are saved individually using createTask, updateTask, deleteTask
    print('saveTasks called - tasks are saved individually in Supabase');
  }
  
  /// Generate a unique task ID for local use
  static String generateTaskId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final bytes = utf8.encode('$timestamp$random');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
  
  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  /// Listen to task changes for current user
  static Stream<List<Map<String, dynamic>>> listenToUserTasks() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }
    
    return client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
  }
}
