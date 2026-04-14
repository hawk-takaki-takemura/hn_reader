# HN Reader — プロダクト設計メモ（実装前整理）

この文書は、実装に入る前の**内容の共有・合意形成用**です。README のセットアップ手順と重複する部分は省略し、プロダクト像・アーキテクチャ・運用コスト・フェーズを一枚にまとめます。

**現状のコードベース**: Flutter 3.x、`firebase_core` / `flutter_riverpod` / `go_router` のみ（本書の「計画スタック」とは差がある）。

---

## 1. プロダクト概要

- **題材**: [Hacker News](https://news.ycombinator.com/)（英語中心のテック記事・議論）
- **ゴール**: モバイルアプリ化し、**日本語で読みやすく**する（UI 日本語化＋翻訳・要約など）
- **日本語化の核**: AI（Claude 等）を翻訳・要約・文脈説明に利用
- **UX の参考**: 2chまとめビュアー系の「縦スクロールでサクサク読む」体験（例: [まとめサイトビュアー MT2](https://apps.apple.com/jp/app/%E3%81%BE%E3%81%A8%E3%82%81%E3%82%B5%E3%82%A4%E3%83%88%E3%83%93%E3%83%A5%E3%83%BC%E3%82%A2-mt2/id406613151)）

### 1.1 MT2 由来の機能を HN に当てはめたイメージ

| 方向性 | HN アプリでのイメージ |
|--------|------------------------|
| 記事一覧を縦スクロール | トップ / 新着などのフィード |
| スコア順・新着 | `topstories` / `newstories` 等とソート切替 |
| タップで本文展開 | 記事詳細（URL 先 or テキスト post） |
| タップで日本語要約 | AI 要約パネル（プレミアム想定） |
| コメントをスレッド表示 | HN コメント木（折りたたみ） |
| オートスクロール | 将来検討 |
| 履歴・ブックマーク | ローカル DB ＋必要なら Firestore と同期 |
| フォント / テキストスケール | アクセシビリティ設定 |

---

## 2. 機能の二段構え（「簡単」vs「差別化」）

### 2.1 比較的シンプルにできること

- タイトル翻訳（HN API で取得 → 翻訳 API）
- UI の日本語化（文言リソース）
- コメントの翻訳（タップで展開・オンデマンド）

### 2.2 AI で差別化しやすいこと

- タイトル翻訳に加え **3 行要約**
- 英語記事を **「日本語で読む」ビュー**（抽出テキスト or 要約ストリーム等、実装方針は要決定）
- **「この記事、なぜ HN で話題？」** の一言説明
- **リンク先本文の翻訳**（長文・コスト・著作権・利用規約の確認が必要）

---

## 3. データフロー（論理アーキテクチャ）

```
HN API（無料・認証不要）
  → タイトル / スコア / コメント数 / ID など取得

翻訳・要約 API（Claude 等）
  → 日本語タイトル・要約・各種 AI 生成物

Flutter アプリ
  → 表示用にキャッシュ（端末内＋可能なら共有キャッシュ）

Firebase スイート
  → Firestore / FCM / Auth / Remote Config / Analytics
```

**キャッシュ設計**を先に固めると、AI コストと体感速度の両方に効く。同一記事は**共有キャッシュ**（後述の Firestore）で再利用する想定。

---

## 4. アプリ内アーキテクチャ（拡張しやすさ優先）

### 4.1 レイヤ構成

| レイヤ | 役割 |
|--------|------|
| **Presentation** | `screens/` / `widgets/` / `providers/`（Riverpod） |
| **Domain** | `usecases/` / `repositories/`（インターフェース） |
| **Data** | `remote/`（HN API, 翻訳・要約 API） / `local/`（Hive 等） |

依存の向き: **Presentation → Domain ← Data**。新機能は `features/<name>/` に同じ型のフォルダを足していく。

### 4.2 想定ディレクトリ（抜粋）

```
lib/
├── core/           # 定数・テーマ・ロガー・共通エラー等
├── features/
│   ├── feed/
│   ├── translation/
│   ├── comments/
│   ├── auth/
│   ├── subscription/
│   ├── ads/
│   └── notifications/
└── main.dart
```

各 feature は `data/` · `domain/` · `presentation/` の三層に分ける方針。

---

## 5. 技術スタック（計画）

README 記載の **Flutter / Firebase 多環境（dev・stg・prod）** は維持。追加予定の主なパッケージ例:

- **状態管理**: `flutter_riverpod` + `riverpod_annotation`（生成）
- **Firebase**: Core, Firestore, Auth, Messaging, Analytics, Remote Config
- **課金**: `purchases_flutter`（RevenueCat）
- **広告**: `google_mobile_ads`（AdMob）
- **HTTP**: `dio` + `retrofit`（型安全クライアント）
- **ローカル**: `hive_flutter`（高速キャッシュ・オフライン寄与）
- **UI 補助**: `flutter_html`, `cached_network_image`, `shimmer`, `go_router`

`build_runner` + `riverpod_generator` + `retrofit_generator` を dev に置く想定。

---

## 6. マネタイズ

- **AdMob**: 無料ユーザー向けバナー等
- **有料プラン**: 広告非表示＋機能アンロック（要約・コメント翻訳などをプレミアムに寄せる案）
- **RevenueCat**: iOS / Android の課金を一 SDK で扱い、審査・レシート周りの変更に追徑しやすくする

ドメイン例（概念）:

- `SubscriptionTier`: `free` / `premium`
- `showAds` = 非プレミアム、`canUseSummary` 等はプレミアム限定フラグ

---

## 7. Firebase（Firestore）スキーマ案

| コレクション | 用途 |
|--------------|------|
| `translations/{story_id}` | 共有翻訳キャッシュ（`title_ja`, `summary_ja`, `cached_at` 等） |
| `users/{uid}` | 設定・ブックマーク・読了履歴・（必要なら）課金ティアのミラー |
| `notifications/{id}` | 配信管理用メタデータ（タイトル、`story_id`、`sent_at` 等） |

**共有キャッシュ**により、誰かが一度翻訳すれば他ユーザーが再利用でき、API コストを抑えられる。

---

## 8. 運用コストの目安（ユーザー 1,000 人想定・概算）

| 項目 | 内容 | 月額目安 |
|------|------|-----------|
| Claude API | トップ N 記事 × 日数、キャッシュ前提 | 約 $3〜10 |
| Firebase | HN は読み取り中心なら従量の大部分は小さめ（要監視） | 〜$0 近辺もあり得る |
| ストア | Apple 年 $99、Google 一回 $25 | 月換算で数ドル |

**合計イメージ**: 月 **約 $10〜20 程度**（トラフィックと AI 呼び出し設計で変動）。

---

## 9. CI/CD（将来）

- `main` への push → GitHub Actions（テスト・ビルド）
- Fastlane で TestFlight / Play 配信
- 事前準備: `.github/workflows/deploy.yml` の枠、`ios/android` の Fastlane

---

## 10. フェーズ案

| Phase | 内容 |
|-------|------|
| **1 — MVP** | HN フィード、タイトル翻訳、AdMob、Analytics |
| **2 — マネタイズ** | Auth、RevenueCat、AI 要約（プレミアム）、コメント翻訳（プレミアム） |
| **3 — 拡張** | FCM、Remote Config、Fastlane 本番連携、A/B 等 |

実装の入り方の候補: **フィード画面**（`feed_screen` + `story_card`）から着手すると、一覧・ナビ・状態管理の型が先に決まりやすい。

---

## 11. 疑問・決めておきたいこと（意見含む）

1. **HN API の呼び出し経路**  
   クライアント直叩きが最もシンプル。Firebase「経由」にするなら **Cloud Functions / 別 BFF** でプロキシ・ログ・将来のレート制御がしやすい。コストと運用のトレードオフ。

2. **Claude（等）API キーの置き場所**  
   **クライアントに埋め込まない**のが原則。Callable Functions や自前 BFF 経由で、課金ユーザーだけ拡張クォータ、などが現実的。

3. **Firestore の `translations` 書き込み権限**  
   共有キャッシュを「誰が書けるか」: **サーバのみ書き込み**にすると不正・スパム投稿を抑えやすい。クライアント直書きはセキュリティルール設計が難しい。

4. **ブックマーク・履歴**  
   Hive ローカル一本で MVP、ログイン後に Firestore と同期、の二段階が実装負荷と価値のバランスが取りやすい。

5. **README の「Web 対応」**  
   AdMob / IAP / 一部 Firebase の挙動は Web と相性が異なる。Web を **同一コードで本気サポート**するか、モバイル優先にするかは早めに線引きした方がよい。

6. **リンク先本文の翻訳**  
   相手サイトの利用規約・robots・著作権に加え、**取得手段**（アプリ内 WebView だけにするか、抽出するか）で法務・技術リスクが変わる。Phase 2 以降で詳細設計推奨。

7. **`subscription_tier` を Firestore に持つ場合**  
   真実のソースは RevenueCat 側に寄せ、Firestore は表示用キャッシュとして扱うと不整合が減る。

---

## 12. 次のアクション（実装に入るとき）

1. `pubspec.yaml` に Phase 1 必要分から段階的に依存関係を追加  
2. `lib/features/feed/` を核に、Domain の `Story` エンティティと Repository インターフェースを先に定義  
3. HN API の datasource → Repository 実装 → Riverpod で画面接続  
4. 翻訳は「ローカルキャッシュ → Firestore 共有 → API」の**レイヤ順**をインターフェースで差し替え可能にしておくと拡張しやすい  

---

*最終更新: 設計メモ初版（リポジトリ内用）*
