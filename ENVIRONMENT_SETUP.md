# Environment Setup Guide

## 🔐 Security Configuration for TimeBlocks

This guide explains how to set up environment variables to protect sensitive information like Supabase API keys.

## 📋 Setup Steps

### 1. Copy Environment Template

```bash
cp lib/config/env_template.dart lib/config/env.dart
```

### 2. Configure Your Supabase Credentials

Edit `lib/config/env.dart` and replace the placeholder values:

```dart
class Environment {
  static const String supabaseUrl = 'https://your-project-ref.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  
  static const String appName = 'TimeBlocks';
  static const String bundleId = 'com.timeblocks.app';
}
```

### 3. Verify .gitignore Protection

Ensure these files are in your `.gitignore`:

```
# Environment variables and secrets
.env
.env.local
.env.development
.env.production
lib/config/env.dart
```

## 🔑 Getting Supabase Credentials

1. Go to [supabase.com](https://supabase.com)
2. Create a new project or select existing one
3. Go to Settings → API
4. Copy:
   - **Project URL** (supabaseUrl)
   - **Anon public key** (supabaseAnonKey)

## ⚠️ Security Notes

- **NEVER** commit `lib/config/env.dart` to version control
- The template file `env_template.dart` is safe to commit
- API keys should only be stored in the actual environment file
- Use different Supabase projects for development and production

## 🚀 For Team Development

When sharing the project:

1. Share the repository (without env.dart)
2. Each developer creates their own `lib/config/env.dart`
3. Use the same Supabase project or create separate dev instances
4. Follow this setup guide

## 📱 Production Deployment

For production builds:

1. Use production Supabase project credentials
2. Ensure environment file is properly configured
3. Verify .gitignore is working correctly
4. Test authentication and data sync

## 🔍 Troubleshooting

**Error: "Environment not found"**
- Ensure `lib/config/env.dart` exists
- Check that the file contains valid Dart syntax

**Error: "Supabase initialization failed"**
- Verify your Supabase URL and anon key
- Check internet connection
- Ensure Supabase project is active

**Error: "Authentication failed"**
- Check Supabase project settings
- Verify RLS policies are configured
- Ensure user registration is enabled
