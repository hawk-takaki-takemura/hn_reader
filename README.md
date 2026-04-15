# Yomi

Hacker News の日本語リーダーアプリ（Flutter）

対応プラットフォームは iOS / Android / Web のみです。

## 環境

- Flutter 3.29.2
- Dart 3.x
- Firebase（dev / stg / prod）
- アプリ識別子のベースは **`com.takaki.yomi`**（iOS の Bundle ID・Android の `applicationId` / Gradle `namespace` を揃えています。dev / stg は `.dev` / `.stg` サフィックス）

## セットアップ

#### Firebase設定

```bash
cp firebase.json.example firebase.json
```

### 1. Firebase設定ファイルの配置

以下のファイルは Git 管理外のため、手動で配置が必要です。

#### Android

```bash
cp android/app/google-services.json.example \
   android/app/google-services.json
```

Firebase Console から実際の値を取得して上書きしてください。

#### iOS

```bash
cp ios/Runner/GoogleService-Info.plist.example \
   ios/Runner/GoogleService-Info.plist
```

Firebase Console から実際の値を取得して上書きしてください。

加えて、flavor ごとに以下のファイルを配置してください。

- `ios/Runner/GoogleService-Info-dev.plist` (`com.takaki.yomi.dev`)
- `ios/Runner/GoogleService-Info-stg.plist` (`com.takaki.yomi.stg`)
- `ios/Runner/GoogleService-Info-prod.plist` (`com.takaki.yomi`)

ビルド時に flavor 名に応じた plist が `GoogleService-Info.plist` としてコピーされます。

### 2. FlutterFire CLI で再生成

```bash
# dev
flutterfire configure \
  --project=yomi-dev \
  --out=lib/core/config/firebase/dev_firebase_options.dart \
  --ios-bundle-id=com.takaki.yomi.dev \
  --android-package-name=com.takaki.yomi.dev

# stg
flutterfire configure \
  --project=yomi-stg \
  --out=lib/core/config/firebase/stg_firebase_options.dart \
  --ios-bundle-id=com.takaki.yomi.stg \
  --android-package-name=com.takaki.yomi.stg

# prod
flutterfire configure \
  --project=yomi-prod \
  --out=lib/core/config/firebase/prod_firebase_options.dart \
  --ios-bundle-id=com.takaki.yomi \
  --android-package-name=com.takaki.yomi
```

### 3. パッケージインストール

```bash
flutter pub get
```

### 4. 起動

```bash
# dev
make run-dev

# stg
make run-stg

# prod
make run-prod
```

## ブランチ戦略

```
main        本番リリース済みコード
stg         ステージング検証
dev         開発統合ブランチ
feature/*   機能開発
fix/*       バグ修正
```

## 翻訳バックエンド運用（短縮版）

翻訳はクライアント直叩きではなく、`yomi-backend/functions` の Callable
`translateStories` を経由します。

- Secret は Flutter 側に持たせず、Functions 側の `ANTHROPIC_API_KEY` を使用
- App Check を有効化した状態で動かす
- Remote Config で切り替える
  - `translation_backend=remote` で Functions 経由
  - `translation_backend=local` で翻訳スキップ（原文表示）

本番切替・ロールバック手順は
`/Users/takaki/Projects/yomi-backend/functions/RUNBOOK.md` を参照してください。

## バックログ（リリース前に実施）

- App Check の最終確認（stg/prod、debug token の整理）
- Functions ランタイム / `firebase-functions` の更新（非互換に注意）

詳細は `RUNBOOK.md` の Backlog セクションを参照してください。
