# Supabase統合セットアップガイド

このガイドでは、Simple Task ManagerアプリにSupabaseを統合する手順を説明します。

## 前提条件

1. [Supabase](https://supabase.com/)アカウントの作成
2. 新しいSupabaseプロジェクトの作成

## セットアップ手順

### 1. Supabaseプロジェクトの設定

1. Supabaseダッシュボードにログイン
2. 新しいプロジェクトを作成
3. プロジェクトURL（Project URL）とAnon Key（匿名キー）をメモ

### 2. データベーススキーマの作成

1. Supabaseダッシュボードの「SQL Editor」を開く
2. `supabase_schema.sql`ファイルの内容をコピー&ペースト
3. 「Run」ボタンをクリックしてスキーマを作成

### 3. 認証設定

1. Supabaseダッシュボードの「Authentication」→「Settings」を開く
2. 「Site URL」を設定（開発時は`http://localhost:3000`など）
3. 必要に応じて「Email templates」をカスタマイズ

### 4. アプリケーション設定

`lib/services/supabase_service.dart`ファイルで以下の値を更新：

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

現在の設定値：
- Project URL: `https://cszdcnpfteimwinmjnqu.supabase.co`
- Anon Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## 機能概要

### 認証機能
- ✅ メール/パスワードでのユーザー登録
- ✅ ログイン/ログアウト
- ✅ パスワードリセット
- ✅ ユーザープロファイル管理

### タスク管理機能
- ✅ ユーザー別タスク管理
- ✅ タスクのCRUD操作（作成・読取・更新・削除）
- ✅ リアルタイム同期
- ✅ タスクの完了状態管理

### データベーステーブル

#### `profiles`テーブル
- `id`: ユーザーID（auth.usersテーブルの外部キー）
- `display_name`: 表示名
- `email`: メールアドレス
- `created_at`: 作成日時
- `updated_at`: 更新日時

#### `tasks`テーブル
- `id`: タスクID（UUID）
- `user_id`: ユーザーID（外部キー）
- `title`: タスクタイトル
- `description`: タスク説明（任意）
- `due_date`: 期限日時
- `duration_minutes`: 所要時間（分）
- `reminder_minutes`: リマインダー設定（分の配列）
- `is_completed`: 完了フラグ
- `created_at`: 作成日時
- `updated_at`: 更新日時

## セキュリティ

### Row Level Security (RLS)
- 全テーブルでRLSが有効
- ユーザーは自分のデータのみアクセス可能
- 適切なポリシーが設定済み

### 認証
- JWTトークンベースの認証
- セッション管理はSupabaseが自動処理
- パスワードハッシュ化は自動

## トラブルシューティング

### よくある問題

1. **認証エラー**
   - Project URLとAnon Keyが正しいか確認
   - ネットワーク接続を確認

2. **データベースエラー**
   - RLSポリシーが正しく設定されているか確認
   - テーブルが正しく作成されているか確認

3. **リアルタイム同期の問題**
   - Supabaseプロジェクトでリアルタイム機能が有効か確認

### デバッグ

アプリのコンソールログを確認：
```
flutter run
```

Supabaseのログを確認：
- Supabaseダッシュボードの「Logs」セクション

## 開発者向け情報

### 依存関係
- `supabase_flutter: ^2.5.6`
- `crypto: ^3.0.3`

### 主要クラス
- `SupabaseService`: Supabase操作の中心クラス
- `AuthScreen`: 認証画面
- `Task`: タスクデータモデル
- `AuthWrapper`: 認証状態管理

### API使用例

```dart
// ユーザー登録
await SupabaseService.signUp(
  email: 'user@example.com',
  password: 'password123',
  displayName: 'ユーザー名',
);

// タスク作成
await SupabaseService.createTask(
  title: 'サンプルタスク',
  description: 'タスクの説明',
  dueDate: DateTime.now().add(Duration(days: 1)),
  durationMinutes: 60,
  reminderMinutes: [30, 60],
);

// タスク取得
final tasks = await SupabaseService.getUserTasks();
```

## 本番環境への展開

1. Supabaseプロジェクトの本番環境設定
2. 適切なSite URLの設定
3. メールテンプレートのカスタマイズ
4. セキュリティ設定の確認

---

**注意**: このアプリはSupabaseの無料プランで動作しますが、ユーザー数やデータ量に応じて有料プランへのアップグレードが必要になる場合があります。
