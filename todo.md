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
- [x] ログイン/サインアップ画面UI実装
- [x] Firebase Authentication 連携（Email）※Google/Appleサインインは未実装
- [x] 自動ログイン（GoRouterのredirectで認証状態判定）

## Phase 2: ライフイベント機能（コア機能）
- [x] `LifeEvent` モデル定義
- [x] ライフイベント作成/編集画面UI
- [x] Firestoreへの保存・更新・削除処理
- [x] 画像アップロード（Firebase Storage連携）
- [x] マイページ：自分のタイムライン表示

## Phase 3: 可視化
- [x] fl_chart導入
- [x] 感情グラフ（折れ線グラフ）画面実装
- [x] カテゴリ別集計グラフ（円グラフ）実装
- [x] 転機（ターニングポイント）のハイライトUI

## Phase 4: 追体験・ソーシャル機能
- [x] 他ユーザーのライフライン一覧画面
- [x] 追体験モード（PageView形式）実装
- [x] いいね・共感スタンプ機能
- [x] コメント機能
- [x] フォロー機能
- [ ] 通知機能（FCM + Cloud Functions）※通知一覧UI/データ層は実装済み。プッシュ送信・自動生成にはCloud Functionsデプロイが必要

## Phase 5: 検索・発見
- [x] カテゴリ／年代／感情タグ検索UI
- [x] ホームフィード（注目のライフライン）実装

## Phase 6: 仕上げ
- [x] プロフィール編集・公開範囲設定
- [x] 設定画面（ログアウト、アカウント削除等）
- [x] Firestore Security Rules の初期実装（`firestore.rules`, `storage.rules`）
- [ ] コンテンツモデレーション方針の検討・簡易実装
- [ ] テスト（unit / widget）整備
- [ ] CI/CD（GitHub Actions）導入
- [ ] ストアリリース準備（アイコン、スクリーンショット、審査対応）

## 次にやるべきこと（直近）
1. Firebaseプロジェクトをユーザー自身がFirebase Consoleで作成
2. `flutterfire configure` を実行し、`lib/firebase_options.dart` を生成、`main.dart`をそれに合わせて更新
3. `firebase deploy --only firestore:rules,storage` でルールをデプロイ
4. 実機/エミュレータで認証・投稿・いいね・コメント・フォロー・検索・追体験の動作確認
5. Google/Appleサインイン、Cloud Functions（通知・集計）、コンテンツモデレーションの実装
