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
- [ ] テスト（unit / widget）整備 ※v1.1.0でチュートリアル・記録フォーム・共通部品のテストを追加
- [ ] CI/CD（GitHub Actions）導入
- [ ] ストアリリース準備（アイコン、スクリーンショット、審査対応）

## Phase 7: 使いやすさ改善（v1.1.0）
- [x] 初回チュートリアル（使い方ガイド）と再表示導線
- [x] 「記録する」ボタンの常時表示・はじめての方へカード
- [x] 記録フォームのステップ化（年月ピッカー、絵文字チップ、説明文、破棄確認）
- [x] 未読バッジ、分かりやすいエラー・空状態、ダークモード
- [ ] 実機での操作確認（特に年月ピッカーと戻る操作の確認ダイアログ）

## Phase 8: 活用マニュアルの反映（v1.2.0）
- [x] 他人のページ・追体験・感情グラフで、非公開／フォロワー限定の記録を表示しないよう修正
- [x] アカウント削除時に、ライフイベント・フォロー・お知らせ・プロフィールも削除（パスワードで本人確認）
- [x] 応答記録（「この記録に応えて記録する」、元記録への表示、お知らせ）
- [x] 本文の「5つの問い」テンプレート挿入、公開前の個人情報チェック、全体公開チェックリスト
- [x] 新規記録・新規アカウントの公開範囲を「非公開」から開始（プロフィールの既定値を反映）
- [x] 検索：目的別の入口、ジャンル×気持ち×年代の組み合わせ
- [x] 追体験モード：「転機だけ」、年齢表示、応答記録への導線
- [x] 感情グラフ：「谷からの回復」
- [x] 誕生月・12月のふり返りカード
- [x] リアクション3種を詳細画面でも選択可能に、コメントに投稿者名
- [x] いいね・コメント・フォロー・応答記録のお知らせをクライアントから作成
- [x] Security Rules 修正（フォロワー数更新、experienceLogs の読み取り、投稿者によるコメント削除、プロフィール削除）
- [x] lifeEvents・コメント・リアクションの読み取りをルール側でも公開範囲に応じて制限
- [x] プッシュ通知のアプリ側（設定・トークン登録・iOS権限）と Cloud Functions（functions/）
- [x] 1.2.0 (8) を App Store Connect にアップロード
- [ ] `firebase deploy --only firestore:rules` で本番にルールを反映（審査提出の前に）
- [ ] App Store Connect で審査に提出（docs/release/v1.2.0_審査提出.md）
- [ ] プッシュ通知の本番化：Blaze プラン、APNs キーの登録、`firebase deploy --only functions`
- [ ] 実機での確認（応答記録、アカウント削除、年代検索、プッシュ通知）

## 次にやるべきこと（直近）
1. Firebaseプロジェクトをユーザー自身がFirebase Consoleで作成
2. `flutterfire configure` を実行し、`lib/firebase_options.dart` を生成、`main.dart`をそれに合わせて更新
3. `firebase deploy --only firestore:rules,storage` でルールをデプロイ
4. 実機/エミュレータで認証・投稿・いいね・コメント・フォロー・検索・追体験の動作確認
5. Google/Appleサインイン、Cloud Functions（通知・集計）、コンテンツモデレーションの実装
