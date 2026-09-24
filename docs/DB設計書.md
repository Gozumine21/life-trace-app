# DB設計書 — LifeTrace（Cloud Firestore）

Cloud FirestoreはNoSQLドキュメント指向DBのため、本書では「コレクション／ドキュメント構造」として設計を記述する。

## 1. コレクション一覧

| コレクション名 | 概要 |
|---|---|
| users | ユーザープロフィール情報 |
| lifeEvents | ライフイベント（人生体験の各記録） |
| comments | ライフイベントへのコメント |
| reactions | いいね・共感スタンプ |
| follows | フォロー関係 |
| notifications | 通知履歴 |
| experienceLogs | 追体験モードの閲覧履歴 |

## 2. 各コレクションの構造

### 2.1 users

パス: `/users/{userId}`

| フィールド名 | 型 | 説明 |
|---|---|---|
| uid | string | Firebase Auth の UID（ドキュメントIDと同一） |
| displayName | string | 表示名 |
| iconUrl | string \| null | アイコン画像URL（Storage） |
| bio | string | 自己紹介文 |
| birthYearMonth | string \| null | 生年月（例: "1990-04"）。年齢軸での可視化に使用 |
| defaultVisibility | string | デフォルト公開範囲（"public" \| "followers" \| "private"） |
| followerCount | number | フォロワー数（集計値） |
| followingCount | number | フォロー数（集計値） |
| createdAt | timestamp | 登録日時 |
| updatedAt | timestamp | 更新日時 |

### 2.2 lifeEvents

パス: `/lifeEvents/{eventId}`

| フィールド名 | 型 | 説明 |
|---|---|---|
| eventId | string | ドキュメントID |
| authorId | string | 投稿者の users.uid |
| title | string | イベントタイトル |
| body | string | 本文 |
| occurredYearMonth | string | 発生年月（例: "2015-09"） |
| category | string | カテゴリ（学業/仕事/家族/恋愛/健康/挑戦/挫折/達成/転居/その他） |
| emotionTag | string | 感情タグ（例: "嬉しい","辛い","不安","誇り" 等） |
| emotionScore | number | 感情スコア（-5 〜 +5）。グラフ描画に使用 |
| isTurningPoint | boolean | 人生の転機としてハイライトするか |
| imageUrls | array\<string\> | 添付画像URL一覧（Storage） |
| visibility | string | 公開範囲（"public" \| "followers" \| "private"） |
| likeCount | number | いいね数（集計値） |
| commentCount | number | コメント数（集計値） |
| respondsToEventId | string \| null | 応答記録の元になったライフイベントのID（v1.2.0〜。応答記録でなければフィールドなし） |
| createdAt | timestamp | 作成日時 |
| updatedAt | timestamp | 更新日時 |

インデックス方針:
- `authorId` + `occurredYearMonth`（昇順）の複合インデックス → 個人のタイムライン取得に使用
- `visibility` + `createdAt`（降順）の複合インデックス → ホームフィード取得に使用
- `category`, `emotionTag` の単一フィールドインデックス → 検索機能に使用
- `respondsToEventId` の単一フィールドインデックス（自動作成）→ 応答記録の一覧に使用
- ジャンルと気持ちの組み合わせ・年代での検索は、1条件で問い合わせたうえでクライアント側で絞り込む（追加の複合インデックスは不要）

### 2.3 comments

パス: `/lifeEvents/{eventId}/comments/{commentId}`（サブコレクション）

| フィールド名 | 型 | 説明 |
|---|---|---|
| commentId | string | ドキュメントID |
| authorId | string | コメント投稿者の uid |
| body | string | コメント本文 |
| createdAt | timestamp | 投稿日時 |

### 2.4 reactions

パス: `/lifeEvents/{eventId}/reactions/{userId}`（サブコレクション、ドキュメントID=ユーザーID で重複防止）

| フィールド名 | 型 | 説明 |
|---|---|---|
| userId | string | 反応したユーザーのuid |
| type | string | 反応の種類（"like" \| "empathy" \| "moved" 等） |
| createdAt | timestamp | 反応日時 |

### 2.5 follows

パス: `/follows/{followId}`（followId = `{followerId}_{followeeId}`）

| フィールド名 | 型 | 説明 |
|---|---|---|
| followerId | string | フォローする側のuid |
| followeeId | string | フォローされる側のuid |
| createdAt | timestamp | フォロー日時 |

### 2.6 notifications

パス: `/users/{userId}/notifications/{notificationId}`（サブコレクション）

| フィールド名 | 型 | 説明 |
|---|---|---|
| notificationId | string | ドキュメントID |
| type | string | 通知種別（"like" \| "comment" \| "follow" \| "newEvent" \| "response"）。v1.2.0からクライアントが相手のサブコレクションに作成する |
| fromUserId | string | 通知元ユーザーのuid |
| targetEventId | string \| null | 対象のライフイベントID（該当する場合） |
| isRead | boolean | 既読フラグ |
| createdAt | timestamp | 通知発生日時 |

### 2.7 experienceLogs

パス: `/experienceLogs/{logId}`

| フィールド名 | 型 | 説明 |
|---|---|---|
| viewerId | string | 追体験を行ったユーザーのuid |
| targetUserId | string | 追体験対象（ライフラインの主）のuid |
| lastViewedEventId | string | 最後に閲覧したライフイベントID |
| viewedEventIds | array\<string\> | 閲覧済みイベントID一覧 |
| createdAt | timestamp | 初回閲覧日時 |
| updatedAt | timestamp | 最終閲覧日時 |

## 3. ER概念図（NoSQL関係概念）

```
users (1) ──< lifeEvents (N)            : authorId で関連
lifeEvents (1) ──< comments (N)         : サブコレクション
lifeEvents (1) ──< reactions (N)        : サブコレクション
users (1) ──< follows (N) >── users (1) : follower/followee
users (1) ──< notifications (N)         : サブコレクション
users (1) ──< experienceLogs (N) >── users (1) : viewer/target
```

## 4. Firestore Security Rules 方針

- `lifeEvents`：`visibility == "public"` は誰でも読み取り可、`"followers"` は followsコレクションで関係確認、`"private"` は `authorId == request.auth.uid` のみ
- 書き込みは常に `authorId == request.auth.uid`（自分のデータのみ作成・更新・削除可）
- `users`：読み取りは認証済み全ユーザー可、書き込みは本人のみ
- 集計値（likeCount, commentCount, followerCount等）はクライアントから直接更新せず、Cloud Functions経由でのみ更新する
