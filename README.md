# HN Reader

Hacker News の日本語リーダーアプリ（Flutter）

## 環境

- Flutter 3.29.2
- Dart 3.x
- Firebase（dev / stg / prod）

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

### 2. FlutterFire CLI で再生成

```bash
# dev
flutterfire configure \
  --project=hn-reader-dev \
  --out=lib/core/config/firebase/dev_firebase_options.dart \
  --ios-bundle-id=com.takaki.hnreader.dev \
  --android-package-name=com.takaki.hnreader.dev

# stg
flutterfire configure \
  --project=hn-reader-stg \
  --out=lib/core/config/firebase/stg_firebase_options.dart \
  --ios-bundle-id=com.takaki.hnreader.stg \
  --android-package-name=com.takaki.hnreader.stg

# prod
flutterfire configure \
  --project=hn-reader-prod \
  --out=lib/core/config/firebase/prod_firebase_options.dart \
  --ios-bundle-id=com.takaki.hnreader \
  --android-package-name=com.takaki.hnreader
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
