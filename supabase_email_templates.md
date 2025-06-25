# Supabase メールテンプレート設定ガイド

## 📧 認証メールのカスタマイズ

TimeBlocksアプリでより分かりやすい認証メールを送信するため、Supabaseのメールテンプレートをカスタマイズします。

## 🔧 設定手順

### 1. Supabase Dashboard にアクセス
1. [Supabase Dashboard](https://supabase.com/dashboard) にログイン
2. TimeBlocksプロジェクトを選択
3. 左サイドバーから「Authentication」→「Email Templates」を選択

### 2. Confirm Signup テンプレートの設定

**件名 (Subject):**
```
TimeBlocks - アカウント確認のお願い 🎯
```

**本文 (Body HTML):**
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>TimeBlocks - アカウント確認</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            text-align: center;
            padding: 30px 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .logo {
            font-size: 32px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        .content {
            padding: 0 20px;
        }
        .button {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 15px 30px;
            text-decoration: none;
            border-radius: 8px;
            font-weight: bold;
            margin: 20px 0;
            text-align: center;
        }
        .button:hover {
            background: #5a67d8;
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            font-size: 14px;
            color: #666;
            text-align: center;
        }
        .highlight {
            background: #f7fafc;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">⏰ TimeBlocks</div>
        <p>時間を効率的に管理するタスクアプリ</p>
    </div>
    
    <div class="content">
        <h2>🎉 TimeBlocksへようこそ！</h2>
        
        <p>TimeBlocksアカウントの作成ありがとうございます。</p>
        
        <div class="highlight">
            <h3>📝 次のステップ</h3>
            <p>アカウントを有効化するため、下のボタンをクリックしてメールアドレスを確認してください。</p>
        </div>
        
        <div style="text-align: center;">
            <a href="{{ .ConfirmationURL }}" class="button">
                ✅ メールアドレスを確認する
            </a>
        </div>
        
        <div class="highlight">
            <h3>🚀 TimeBlocksでできること</h3>
            <ul>
                <li>📋 タスクの作成・管理</li>
                <li>📅 カレンダー連携</li>
                <li>📊 1日の予定を円グラフで可視化</li>
                <li>⏰ リマインダー通知</li>
                <li>🎯 効率的な時間管理</li>
            </ul>
        </div>
        
        <p><strong>注意:</strong> このリンクは24時間で期限切れになります。</p>
        
        <p>もしボタンが機能しない場合は、以下のURLをブラウザにコピー&ペーストしてください：</p>
        <p style="word-break: break-all; background: #f8f9fa; padding: 10px; border-radius: 4px; font-family: monospace;">
            {{ .ConfirmationURL }}
        </p>
    </div>
    
    <div class="footer">
        <p>このメールに心当たりがない場合は、無視してください。</p>
        <p>© 2025 TimeBlocks - あなたの時間を最大化するアプリ</p>
    </div>
</body>
</html>
```

### 3. Magic Link テンプレートの設定

**件名 (Subject):**
```
TimeBlocks - ログインリンク 🔐
```

**本文 (Body HTML):**
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>TimeBlocks - ログイン</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            text-align: center;
            padding: 30px 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .logo {
            font-size: 32px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        .content {
            padding: 0 20px;
        }
        .button {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 15px 30px;
            text-decoration: none;
            border-radius: 8px;
            font-weight: bold;
            margin: 20px 0;
            text-align: center;
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            font-size: 14px;
            color: #666;
            text-align: center;
        }
        .highlight {
            background: #f7fafc;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">⏰ TimeBlocks</div>
        <p>時間を効率的に管理するタスクアプリ</p>
    </div>
    
    <div class="content">
        <h2>🔐 TimeBlocksにログイン</h2>
        
        <p>TimeBlocksへのログインリクエストを受け付けました。</p>
        
        <div class="highlight">
            <h3>🚀 ワンクリックログイン</h3>
            <p>パスワード不要で安全にログインできます。下のボタンをクリックしてください。</p>
        </div>
        
        <div style="text-align: center;">
            <a href="{{ .ConfirmationURL }}" class="button">
                🚀 TimeBlocksにログイン
            </a>
        </div>
        
        <p><strong>セキュリティ情報:</strong></p>
        <ul>
            <li>このリンクは1時間で期限切れになります</li>
            <li>一度使用すると無効になります</li>
            <li>あなた専用の安全なリンクです</li>
        </ul>
        
        <p>もしボタンが機能しない場合は、以下のURLをブラウザにコピー&ペーストしてください：</p>
        <p style="word-break: break-all; background: #f8f9fa; padding: 10px; border-radius: 4px; font-family: monospace;">
            {{ .ConfirmationURL }}
        </p>
    </div>
    
    <div class="footer">
        <p>このログイン試行に心当たりがない場合は、このメールを無視してください。</p>
        <p>© 2025 TimeBlocks - あなたの時間を最大化するアプリ</p>
    </div>
</body>
</html>
```

### 4. Password Reset テンプレートの設定

**件名 (Subject):**
```
TimeBlocks - パスワードリセット 🔑
```

**本文 (Body HTML):**
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>TimeBlocks - パスワードリセット</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            text-align: center;
            padding: 30px 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .logo {
            font-size: 32px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        .content {
            padding: 0 20px;
        }
        .button {
            display: inline-block;
            background: #e53e3e;
            color: white;
            padding: 15px 30px;
            text-decoration: none;
            border-radius: 8px;
            font-weight: bold;
            margin: 20px 0;
            text-align: center;
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            font-size: 14px;
            color: #666;
            text-align: center;
        }
        .highlight {
            background: #fed7d7;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #e53e3e;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">⏰ TimeBlocks</div>
        <p>時間を効率的に管理するタスクアプリ</p>
    </div>
    
    <div class="content">
        <h2>🔑 パスワードリセットのご依頼</h2>
        
        <p>TimeBlocksアカウントのパスワードリセットリクエストを受け付けました。</p>
        
        <div class="highlight">
            <h3>⚠️ セキュリティ確認</h3>
            <p>パスワードを変更するには、下のボタンをクリックして新しいパスワードを設定してください。</p>
        </div>
        
        <div style="text-align: center;">
            <a href="{{ .ConfirmationURL }}" class="button">
                🔑 新しいパスワードを設定
            </a>
        </div>
        
        <p><strong>重要な注意事項:</strong></p>
        <ul>
            <li>このリンクは1時間で期限切れになります</li>
            <li>一度使用すると無効になります</li>
            <li>強力なパスワードを設定することをお勧めします</li>
        </ul>
        
        <p>もしボタンが機能しない場合は、以下のURLをブラウザにコピー&ペーストしてください：</p>
        <p style="word-break: break-all; background: #f8f9fa; padding: 10px; border-radius: 4px; font-family: monospace;">
            {{ .ConfirmationURL }}
        </p>
    </div>
    
    <div class="footer">
        <p><strong>このリクエストに心当たりがない場合は、このメールを無視してください。</strong></p>
        <p>アカウントのセキュリティに不安がある場合は、すぐにパスワードを変更することをお勧めします。</p>
        <p>© 2025 TimeBlocks - あなたの時間を最大化するアプリ</p>
    </div>
</body>
</html>
```

## 🎨 改良点

### ✅ **視覚的改善**
- TimeBlocksブランドカラーの使用
- 分かりやすいアイコンとレイアウト
- レスポンシブデザイン

### ✅ **内容の改善**
- 日本語での分かりやすい説明
- アプリの機能紹介
- セキュリティ情報の明記
- 期限切れ時間の明示

### ✅ **ユーザビリティ向上**
- 大きなボタンでアクション明確化
- URLのコピー&ペースト対応
- 不正アクセス時の対処法説明

## 📝 設定後の確認

1. Supabase Dashboardで各テンプレートを保存
2. テストユーザーでサインアップを試行
3. メールの見た目と内容を確認
4. 各リンクが正常に動作することを確認

これで、TimeBlocksアプリの認証メールがより分かりやすく、プロフェッショナルな見た目になります！
