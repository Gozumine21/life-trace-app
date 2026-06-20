# SKILLS — 必要技術・スキル一覧

このプロジェクト（LifeTrace）の開発・運用に必要な技術スタックと前提知識をまとめる。

## フロントエンド
- **Flutter / Dart**：UI構築、状態管理（Riverpod）、ルーティング
- **fl_chart**：感情グラフ・カテゴリ別グラフの描画
- モバイルUI/UXの基本（PageView、ListView、フォーム入力、画像ピッカー）

## バックエンド（Firebase）
- **Firebase Authentication**：Email / Google / Apple サインイン
- **Cloud Firestore**：NoSQLデータモデリング、複合インデックス、Security Rules
- **Firebase Storage**：画像アップロード・取得、アクセス制御
- **Cloud Functions（TypeScript）**：Firestoreトリガー、通知送信、集計処理
- **Firebase Cloud Messaging**：プッシュ通知

## 開発・運用
- Git / GitHub によるバージョン管理
- `flutterfire configure` によるFirebase連携設定
- Firestore Security Rules のテスト・デプロイ
- （将来）GitHub Actions による CI/CD
- （将来）App Store / Google Play へのリリース作業

## 参考ドキュメント（本プロジェクト内）
- [docs/要件定義書.md](docs/要件定義書.md)
- [docs/基本設計書.md](docs/基本設計書.md)
- [docs/DB設計書.md](docs/DB設計書.md)
- [todo.md](todo.md)
