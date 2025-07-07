import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../config/env.dart';
import 'password_reset_screen.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        // Sign up
        final response = await SupabaseService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim().isNotEmpty 
              ? _displayNameController.text.trim() 
              : null,
        );

        // サインアップは常に成功として扱う（メール確認が必要なため）
        // Supabaseはメール確認が必要な場合でもユーザーオブジェクトを返す
        if (mounted) {
          // Create user profile if display name is provided
          if (_displayNameController.text.trim().isNotEmpty && response.user != null) {
            try {
              await SupabaseService.upsertUserProfile(
                displayName: _displayNameController.text.trim(),
              );
            } catch (profileError) {
              // プロフィール作成エラーは無視（後で設定可能）
              print('Profile creation error: $profileError');
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎉 アカウント作成が完了しました！',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text('📧 ${_emailController.text.trim()} に確認メールを送信しました'),
                  const SizedBox(height: 4),
                  const Text('✅ メール内のリンクをクリックしてアカウントを有効化してください'),
                  const SizedBox(height: 4),
                  const Text('⚠️ 迷惑メールフォルダもご確認ください'),
                  const SizedBox(height: 8),
                  const Text(
                    '💡 確認後、このアプリでログインできるようになります',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 10),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          
          // Clear form after successful signup
          _emailController.clear();
          _passwordController.clear();
          _displayNameController.clear();
          setState(() => _isSignUp = false); // Switch to login mode
        }
      } else {
        // Sign in
        final response = await SupabaseService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.user != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🚀 TimeBlocksにログインしました！\nタスク管理を始めましょう！'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );
            
            // Wait for SnackBar to show, then force navigation
            await Future.delayed(const Duration(milliseconds: 800));
            
            // Force AuthWrapper to update
            AuthWrapper.forceUpdate();
            
            // Force navigation to home screen
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const TaskHomePage()),
                (route) => false,
              );
            }
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.message)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 予期しないエラーが発生しました\n$e\n\nしばらく時間をおいてから再度お試しください'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return '🔐 ログイン情報が正しくありません\n\n• メールアドレスとパスワードをご確認ください\n• アカウントが有効化されているかご確認ください\n• パスワードを忘れた場合は「パスワードを忘れた場合」をクリック';
    } else if (error.contains('Email not confirmed')) {
      return '📧 メールアドレスの確認が完了していません\n\n• 登録時に送信された確認メールをチェックしてください\n• メール内のリンクをクリックしてアカウントを有効化してください\n• 迷惑メールフォルダもご確認ください';
    } else if (error.contains('User already registered') || error.contains('already been registered')) {
      return '✅ このメールアドレスは既に登録済みです\n\n• アカウント作成は完了しています\n• 「ログイン」に切り替えてサインインしてください\n• パスワードを忘れた場合は「パスワードを忘れた場合」をクリック\n• メール確認がまだの場合は、確認メールをチェックしてください';
    } else if (error.contains('Password should be at least 6 characters')) {
      return '🔒 パスワードは6文字以上で設定してください\n\n• 英数字を組み合わせることをお勧めします\n• セキュリティのため、推測されにくいパスワードを使用してください';
    } else if (error.contains('Unable to validate email address') || error.contains('Invalid email')) {
      return '📧 メールアドレスの形式が正しくありません\n\n• 正しいメールアドレス形式で入力してください\n• 例: user@example.com';
    } else if (error.contains('Signup is disabled')) {
      return '🚫 現在、新規アカウント作成を一時停止しています\n\n• しばらく時間をおいてから再度お試しください\n• 既存のアカウントをお持ちの場合はログインしてください';
    } else if (error.contains('Too many requests') || error.contains('rate limit')) {
      return '⏰ リクエストが多すぎます\n\n• しばらく時間をおいてから再度お試しください\n• 数分後に再度アクセスしてください';
    } else if (error.contains('Network error') || error.contains('Failed to fetch')) {
      return '🌐 ネットワークエラーが発生しました\n\n• インターネット接続をご確認ください\n• Wi-Fiまたはモバイルデータ通信の状態をチェック\n• しばらく時間をおいてから再度お試しください';
    } else {
      return '❌ 認証エラーが発生しました\n\n• エラー詳細: $error\n• ネットワーク接続をご確認ください\n• 問題が続く場合は、しばらく時間をおいてから再度お試しください';
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📧 パスワードリセット用のメールアドレスを入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await SupabaseService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📧 パスワードリセットメールを送信しました',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('✉️ $email にリセット用のリンクを送信しました'),
                const SizedBox(height: 4),
                const Text('🔗 メール内のリンクをクリックして新しいパスワードを設定してください'),
                const SizedBox(height: 4),
                const Text('⚠️ 迷惑メールフォルダもご確認ください'),
                const SizedBox(height: 4),
                const Text('⏰ リンクの有効期限は24時間です'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ パスワードリセットメールの送信に失敗しました\n$e\n\nメールアドレスをご確認の上、再度お試しください'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App logo and title
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.task_alt,
                            size: 40,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          Environment.appName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignUp ? 'アカウントを作成' : 'ログイン',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 32),

                        // Display name field (only for sign up)
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _displayNameController,
                            decoration: InputDecoration(
                              labelText: '表示名（任意）',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'メールアドレス',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'メールアドレスを入力してください';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return '有効なメールアドレスを入力してください';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'パスワード',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'パスワードを入力してください';
                            }
                            if (value.length < 6) {
                              return 'パスワードは6文字以上で入力してください';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleAuth(),
                        ),
                        const SizedBox(height: 24),

                        // Auth button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    _isSignUp ? 'アカウント作成' : 'ログイン',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Forgot password (only for sign in)
                        if (!_isSignUp) ...[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PasswordResetScreen(),
                                ),
                              );
                            },
                            child: const Text('パスワードを忘れた場合'),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Switch between sign in and sign up
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_isSignUp ? 'すでにアカウントをお持ちですか？' : 'アカウントをお持ちでない場合'),
                            TextButton(
                              onPressed: () => setState(() => _isSignUp = !_isSignUp),
                              child: Text(_isSignUp ? 'ログイン' : 'アカウント作成'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
