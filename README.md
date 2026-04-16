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

Xcode ビルドでは `FLAVOR` が `Runner-prod` のように **Gradle flavor 名**になることがあります。Run Script 側で `dev` / `stg` / `prod` に正規化してから `GoogleService-Info-*.plist` を選ぶため、誤った plist へのフォールバックを避けられます。

### App Check（Android・debug トークン）

`kDebugMode` では `AndroidProvider.debug`、リリース相当では `Play Integrity` を使います（実装: `lib/core/firebase/app_check_bootstrap.dart`）。

開発端末ごとに **App Check のデバッグトークン**を Firebase Console に登録します（継続運用で **stg / prod 両方**に登録する想定）。

1. 対象プロジェクトで Android アプリを App Check に登録済みであること（`yomi-stg` / `yomi-prod`）。
2. 該当 flavor で **debug** ビルドを起動する（例: `make run-stg` / `make run-prod`）。
3. Logcat でデバッグ用シークレット（UUID）を控える。例: `DebugAppCheckProvider` の行に `Enter this debug secret into the allow list ...: <uuid>` と出る。別バージョンでは `AppCheck debug token:` の文言になることもある。
4. Firebase Console → **App Check** → Android アプリ → **デバッグトークンを管理** → トークンを追加（メモ欄に端末名・担当者・登録日を書く）。
5. 退職・端末売却・漏えいが疑われる場合はトークンを削除して再発行する。

### iOS（Runner-prod とシミュレータ）

- **Bundle ID**: `Debug-Runner-prod` は本番と同じ `com.takaki.yomi` です（`flutter run --flavor Runner-prod` でのデバッグ実行時も prod の Firebase 設定と整合します）。
- **Xcode**: `ios/Runner.xcworkspace` を開き、スキーム **`Runner-prod`** を選び、メニュー **Product → Destination** で使うシミュレータ（例: **iPhone 16**）を選択してください。共有 `.xcscheme` だけでは端末世代の固定が保証されないため、チームでは同じ機種名に揃える運用を推奨します。
- **CLI**: 既定シミュレータ名で prod を起動する場合は `make run-prod-sim`（別名にする場合は `make run-prod-sim IOS_SIM='iPhone 16 Pro'`）。

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

### Git / デプロイ運用（dev → stg）

**Flutter（本リポジトリ）** と **Cloud Functions（別リポジトリ `yomi-backend`）** で同じ考え方に揃えます。

1. **日常実装**  
   `dev` に小さなコミット・PRで積む（長期ブランチは `feature/*` → `dev` へマージでも可）。
2. **ステージングへ載せるタイミング**  
   まとまった単位で `dev` → `stg` にマージ（PR 推奨）。  
   - アプリ: `stg` をチェックアウトし、Firebase **`yomi-stg`** 向けにビルド・検証（例: `make run-stg` は iOS スキーム名。Android は `--flavor stg`）。  
   - バックエンド: `yomi-backend` の `stg` をデプロイ対象にし、`firebase deploy --only functions --project yomi-stg` など（手順は `yomi-backend/functions/README.md`）。
3. **本番**  
   `stg` で問題なければ、リリース単位で `stg` → `main` にマージし、prod 用ビルド・`yomi-prod` へのデプロイを行う。

`stg` / `main` は「検証済み・リリース用」のライン、`dev` は常時開発のライン、という整理です。

### ブランチの初期作成（初回のみ）

リモートに `dev` / `stg` がまだない場合の例（`main` が既にある前提）。

```bash
# 本リポジトリ（yomi）
git checkout main && git pull
git checkout -b dev && git push -u origin dev
git checkout -b stg && git push -u origin stg
```

`yomi-backend` でも同様に `main` から `dev` と `stg` を切って `git push -u` する。

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

- App Check: 上記「App Check（Android・debug トークン）」に従い stg/prod のトークンを棚卸しする
- Functions: ランタイム・依存は `yomi-backend/functions` で管理（`RUNBOOK.md` / `package.json` を参照）

詳細は `/Users/takaki/Projects/yomi-backend/functions/RUNBOOK.md` を参照してください。
