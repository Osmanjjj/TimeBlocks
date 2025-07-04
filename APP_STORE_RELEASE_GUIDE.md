# App Store リリースガイド - TimeBlocks

## 📱 アプリ情報
- **アプリ名**: TimeBlocks
- **バンドルID**: com.osmanjjj.timeblocks
- **バージョン**: 1.0.0
- **ビルド番号**: 1

## 🚀 App Store リリース手順

### 1. Apple Developer アカウント準備
- [ ] Apple Developer Program登録 ($99/年)
- [ ] 開発者証明書の確認
- [ ] App Store Connect アクセス確認

### 2. アプリ情報設定
- [ ] **バンドルID変更**: `com.example.simpletaskmanager` → `com.yourcompany.simpletaskmanager`
- [ ] **チーム設定**: Xcodeでサインイン設定
- [ ] **プロビジョニングプロファイル**: 自動管理を有効化

### 3. アプリアイコン準備
必要なサイズ（すべて正方形、角丸なし）:
- [ ] 1024x1024 (App Store用)
- [ ] 180x180 (iPhone @3x)
- [ ] 120x120 (iPhone @2x)
- [ ] 167x167 (iPad Pro @2x)
- [ ] 152x152 (iPad @2x)
- [ ] 76x76 (iPad @1x)

### 4. スクリーンショット準備
- [ ] iPhone 6.7" (iPhone 15 Pro Max等): 1290x2796
- [ ] iPhone 6.5" (iPhone 14 Plus等): 1242x2688
- [ ] iPhone 5.5" (iPhone 8 Plus等): 1242x2208
- [ ] iPad Pro 12.9" (第6世代): 2048x2732

### 5. Xcode でのビルド設定

#### 5.1 プロジェクト設定
```bash
# Xcodeでプロジェクトを開く
open ios/Runner.xcworkspace
```

#### 5.2 必要な設定変更
1. **General タブ**:
   - Bundle Identifier を変更
   - Team を選択
   - Deployment Target を iOS 13.0 に設定

2. **Signing & Capabilities タブ**:
   - Automatically manage signing を有効化
   - Team を選択

3. **Build Settings タブ**:
   - Code Signing Identity を確認

### 6. Archive とアップロード

#### 6.1 Release ビルド作成
```bash
# Flutter でリリースビルド
flutter build ios --release

# または Xcode で Archive
# Product → Archive
```

#### 6.2 App Store Connect アップロード
```bash
# Xcode Organizer でアップロード
# Window → Organizer → Archives → Distribute App
```

### 7. App Store Connect 設定

#### 7.1 アプリ情報入力
- [ ] アプリ名: "TimeBlocks"
- [ ] サブタイトル: "シンプルなタスク管理"
- [ ] カテゴリ: "生産性"
- [ ] 年齢制限: "4+"

#### 7.2 説明文例
```
効率的なタスク管理を実現する多機能アプリです。

【主な機能】
✓ タスクの追加・編集・削除・完了切り替え
✓ 円グラフによる一日のスケジュール可視化
✓ カレンダー表示とタスクの期限管理
✓ マルチリマインダー通知システム
✓ デバイスカレンダーとの自動連携
✓ タスクごとの所要時間設定
✓ リアルタイム進捗表示

【特徴】
• 直感的で美しいMaterial Designインターフェース
• 円グラフで一日のスケジュールを視覚的に把握
• 複数のリマインダー設定（5分前〜1週間前）
• スマホの標準カレンダーアプリと自動同期
• 現在の予定と次の予定までの時間を表示
• プルトゥリフレッシュでリアルタイム更新
• オフラインでも完全動作
• データの自動保存・復元

【3つのタブで効率管理】
1. タスクリスト - 全てのタスクを一覧表示
2. カレンダー - 月表示で期限を視覚的に管理
3. 円グラフ - 今日のスケジュールを24時間ベースで可視化

毎日のタスク管理を革新的に効率化しましょう！
```

#### 7.3 キーワード例
```
タスク管理,TODO,生産性,メモ,リスト,仕事,効率,シンプル,軽量,カレンダー,通知,リマインダー,スケジュール,円グラフ,可視化,時間管理
```

### 8. 審査提出前チェックリスト
- [x] アプリが正常に動作する（Webビルドで確認済み）
- [x] アプリアイコンを全サイズで作成済み
- [x] Bundle Identifier設定済み (com.simpletaskmanager.app)
- [x] アプリ名設定済み (TimeBlocks)
- [x] Info.plist設定済み（通知・カレンダー権限）
- [x] 機能説明文・キーワード更新済み
- [ ] Xcodeでコード署名設定（手動設定が必要）
- [ ] App Store Connect登録
- [ ] クラッシュしない（実機テスト要）
- [ ] App Store Review Guidelines に準拠
- [ ] プライバシーポリシー（必要に応じて）
- [ ] サポートURL設定

### 9. 次のステップ（手動作業が必要）

#### 9.1 Xcodeでの最終設定
1. `ios/Runner.xcworkspace` をXcodeで開く
2. Runner > Signing & Capabilities で以下を設定：
   - Team: 開発者アカウントを選択
   - Bundle Identifier: com.simpletaskmanager.app
   - Automatically manage signing: チェック
3. Deployment Target: 13.0以上に設定
4. Archive用のRelease buildを作成

#### 9.2 App Store Connect準備
1. [App Store Connect](https://appstoreconnect.apple.com) にログイン
2. 新しいアプリを作成
3. アプリ情報を入力：
   - 名前: TimeBlocks
   - Bundle ID: com.simpletaskmanager.app
   - SKU: 任意の識別子
4. アプリの説明・キーワード・スクリーンショットを追加

#### 9.3 ビルド・アップロード
```bash
# Xcodeでアーカイブ作成後、App Store Connectにアップロード
# または以下のコマンドでリリースビルド作成
./flutter/bin/flutter build ios --release
```

### 9. 審査・リリース
- [ ] 審査提出
- [ ] 審査結果待ち（通常1-7日）
- [ ] 承認後リリース

## 🛠 開発環境情報
- **Flutter**: 3.32.4
- **Dart**: 3.8.1
- **iOS Deployment Target**: 13.0
- **Xcode**: 15.2 (推奨: 最新版)

## 📝 注意事項
1. バンドルIDは一意である必要があります
2. Apple Developer アカウントが必要です
3. 初回リリースには審査に時間がかかる場合があります
4. アプリアイコンとスクリーンショットは必須です

## 🔗 参考リンク
- [App Store Connect](https://appstoreconnect.apple.com/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
