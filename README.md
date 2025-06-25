# TimeBlocks

効率的なタスク管理を実現する多機能Flutterアプリです。

## 🌟 主な機能

### ✅ タスク管理
- タスクの追加・編集・削除・完了切り替え
- タスクごとの所要時間設定（デフォルト30分）
- 作成日時と期限の管理
- データの自動保存・復元

### 📊 円グラフ可視化
- 一日のスケジュールを24時間ベースで円グラフ表示
- 現在進行中のタスク、空き時間、次のタスクまでの時間を視覚化
- リアルタイム更新（1分毎）
- 日次進捗バー表示
- プルトゥリフレッシュ対応

### 📅 カレンダー連携
- 月表示カレンダーでタスクの期限を視覚的に管理
- デバイスの標準カレンダーアプリと自動同期
- タスク作成時に自動でカレンダーイベント作成

### 🔔 通知システム
- マルチリマインダー設定（5分前〜1週間前）
- カスタマイズ可能な通知タイミング
- 堅牢なエラーハンドリングで安定動作

### 🎨 ユーザーインターフェース
- 3つのタブで効率的な管理
  1. **タスクリスト** - 全てのタスクを一覧表示
  2. **カレンダー** - 月表示で期限を視覚的に管理  
  3. **円グラフ** - 今日のスケジュールを可視化
- Material Designに基づく直感的なUI
- レスポンシブデザイン対応

## 🚀 技術スタック

- **Framework**: Flutter 3.32.4
- **Language**: Dart 3.8.1
- **主要パッケージ**:
  - `fl_chart` ^0.66.0 - 円グラフ表示
  - `table_calendar` ^3.1.2 - カレンダーUI
  - `flutter_local_notifications` ^17.2.3 - ローカル通知
  - `device_calendar` ^4.3.2 - カレンダー連携
  - `add_2_calendar` ^3.0.1 - カレンダーイベント追加
  - `permission_handler` ^11.3.1 - 権限管理
  - `timezone` ^0.9.4 - タイムゾーン対応

## 📱 対応プラットフォーム

- ✅ **Web** - 完全対応・テスト済み
- ✅ **iOS** - 設定完了（コード署名要手動設定）
- ✅ **Android** - 設定完了（SDK要インストール）
- ✅ **macOS** - 基本対応
- ✅ **Windows** - 基本対応
- ✅ **Linux** - 基本対応

## 🛠 開発・ビルド

### 前提条件
- Flutter SDK 3.32.4+
- Dart SDK 3.8.1+

### 環境設定
1. 環境テンプレートをコピーします。
   ```bash
   cp lib/config/env_template.dart lib/config/env.dart
   ```

2. `lib/config/env.dart` を編集し、Supabaseのクレデンシャルを追加します。
   ```dart
   class Environment {
     static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
     
     static const String appName = 'TimeBlocks';
     static const String bundleId = 'com.timeblocks.app';
   }
   ```

**重要**: `lib/config/env.dart` ファイルは、機密性の高いAPIキーを含むため、バージョン管理システムにコミットしないでください。

### Supabaseの設定
1. [supabase.com](https://supabase.com) で新しいプロジェクトを作成します
2. `supabase_schema.sql` のSQLスキーマをSupabaseのSQLエディターで実行します
3. プロジェクトURLとanonキーを環境ファイルにコピーします

### アプリの実行
```bash
flutter pub get
flutter run
```

## 📦 App Store準備状況

### ✅ 完了済み
- [x] アプリアイコン作成（全サイズ対応）
- [x] Bundle Identifier設定 (com.timeblocks.app)
- [x] アプリ名設定 (TimeBlocks)
- [x] 権限設定（通知・カレンダー）
- [x] 機能説明文・キーワード作成
- [x] Webビルドでの動作確認

### 🔄 手動設定が必要
- [ ] Xcodeでのコード署名設定
- [ ] App Store Connect登録
- [ ] 実機での最終テスト

詳細は `APP_STORE_RELEASE_GUIDE.md` を参照してください。

## 🐛 既知の問題と解決済みバグ

### ✅ 解決済み
- **リマインダー通知バグ**: 通知ボタン押下時の画面フリーズ問題を修正
- **エラーハンドリング**: 堅牢なtry-catch処理を全体に実装
- **UI安定性**: TextFieldエラーをTextFormFieldで解決
- **依存関係**: fl_chartバージョンを安定版に固定

### 🔧 改善点
- iOS実機ビルドにはXcodeでの手動コード署名設定が必要
- Android開発にはAndroid SDK設定が必要

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 🤝 貢献

プルリクエストやイシューの報告を歓迎します！

---

**TimeBlocks** - 毎日のタスク管理を革新的に効率化
