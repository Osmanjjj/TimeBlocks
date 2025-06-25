import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../config/env.dart';

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

        if (response.user != null) {
          // Create user profile
          if (_displayNameController.text.trim().isNotEmpty) {
            await SupabaseService.upsertUserProfile(
              displayName: _displayNameController.text.trim(),
            );
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 TimeBlocksへようこそ！\n📧 確認メールをお送りしました。メールボックスをチェックして、アカウントを有効化してください。'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        // Sign in
        await SupabaseService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚀 TimeBlocksにログインしました！\nタスク管理を始めましょう！'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.message)),
            backgroundColor: Colors.red,
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
      return '🔐 メールアドレスまたはパスワードが正しくありません\n入力内容をもう一度ご確認ください';
    } else if (error.contains('Email not confirmed')) {
      return '📧 メールアドレスの確認が完了していません\n受信したメールのリンクをクリックしてください';
    } else if (error.contains('User already registered')) {
      return '👤 このメールアドレスは既に登録されています\nログインをお試しください';
    } else if (error.contains('Password should be at least 6 characters')) {
      return '🔒 パスワードは6文字以上で入力してください\nより安全なパスワードをお勧めします';
    } else if (error.contains('Email rate limit exceeded')) {
      return '⏰ メール送信の制限に達しました\n少し時間をおいてから再度お試しください';
    } else if (error.contains('Invalid email')) {
      return '📧 有効なメールアドレスを入力してください\n例: user@example.com';
    }
    return '❌ エラーが発生しました: $error\nしばらく時間をおいてから再度お試しください';
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📧 メールアドレスを入力してください\nパスワードリセット用のメールをお送りします'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      await SupabaseService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📧 パスワードリセットメールをお送りしました！\nメールボックスをチェックして、新しいパスワードを設定してください。'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
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
                            onPressed: _resetPassword,
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
