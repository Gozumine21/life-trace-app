# TODO — LifeTrace 実装タスク一覧

## Phase 0: 環境構築
- [x] Flutter SDK インストール（Homebrew）
- [x] プロジェクトフォルダ作成・git init
- [x] ドキュメント作成（要件定義書／基本設計書／DB設計書）
- [x] Flutterプロジェクトの初期セットアップ（flutter create）
- [ ] Firebaseプロジェクトの作成（Firebase Console、要ユーザー作業）
- [ ] FlutterFire CLI で各プラットフォームにFirebase連携（`flutterfire configure`）
- [ ] Firestore Security Rules の初期設定・デプロイ

## Phase 1: 認証
- [ ] ログイン/サインアップ画面UI実装
- [ ] Firebase Authentication 連携（Email, Google, Apple）
- [ ] 自動ログイン（スプラッシュ画面での認証状態判定）

## Phase 2: ライフイベント機能（コア機能）
- [ ] `LifeEvent` モデル定義
- [ ] ライフイベント作成/編集画面UI
- [ ] Firestoreへの保存・更新・削除処理
- [ ] 画像アップロード（Firebase Storage連携）
- [ ] マイページ：自分のタイムライン表示

## Phase 3: 可視化
- [ ] fl_chart導入
- [ ] 感情グラフ（折れ線グラフ）画面実装
- [ ] カテゴリ別集計グラフ（円グラフ）実装
- [ ] 転機（ターニングポイント）のハイライトUI

## Phase 4: 追体験・ソーシャル機能
- [ ] 他ユーザーのライフライン一覧画面
- [ ] 追体験モード（PageView形式）実装
- [ ] いいね・共感スタンプ機能
- [ ] コメント機能
- [ ] フォロー機能
- [ ] 通知機能（FCM + Cloud Functions）

## Phase 5: 検索・発見
- [ ] カテゴリ／年代／感情タグ検索UI
- [ ] ホームフィード（注目のライフライン）実装

## Phase 6: 仕上げ
- [ ] プロフィール編集・公開範囲設定
- [ ] 設定画面（ログアウト、アカウント削除等）
- [ ] Firestore Security Rules の本番強化・テスト
- [ ] コンテンツモデレーション方針の検討・簡易実装
- [ ] テスト（unit / widget）整備
- [ ] CI/CD（GitHub Actions）導入
- [ ] ストアリリース準備（アイコン、スクリーンショット、審査対応）

## 次にやるべきこと（直近）
1. Firebaseプロジェクトをユーザー自身がFirebase Consoleで作成
2. `flutterfire configure` を実行し、iOS/Android向け設定ファイルを生成
3. Phase 1（認証）から実装開始
