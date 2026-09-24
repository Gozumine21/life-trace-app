import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

initializeApp();

/** お知らせの種類ごとの文面（アプリの「お知らせ」画面と合わせる）。 */
const messages: Record<string, string> = {
  like: "さんがあなたのライフイベントに気持ちを送りました",
  comment: "さんがあなたのライフイベントにコメントしました",
  follow: "さんがあなたをフォローしました",
  newEvent: "さんが新しいライフイベントを投稿しました",
  response: "さんがあなたの記録に応えて、自分の経験を記録しました",
};

/**
 * アプリが users/{uid}/notifications にお知らせを作ったら、
 * その人の端末（users/{uid}/fcmTokens）にプッシュ通知を送る。
 */
export const sendPushOnNotification = onDocumentCreated(
  { document: "users/{uid}/notifications/{notificationId}", region: "asia-northeast1" },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const uid = event.params.uid;
    const db = getFirestore();

    const tokensSnap = await db.collection(`users/${uid}/fcmTokens`).get();
    const tokens = tokensSnap.docs.map((d) => d.id);
    if (tokens.length === 0) return;

    const from = await db.doc(`users/${data.fromUserId}`).get();
    const fromName = (from.get("displayName") as string | undefined) || "ユーザー";
    const body = `${fromName}${messages[data.type as string] ?? "さんからお知らせがあります"}`;

    const unread = await db
      .collection(`users/${uid}/notifications`)
      .where("isRead", "==", false)
      .count()
      .get();

    const result = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: "LifeTrace", body },
      data: {
        type: String(data.type ?? ""),
        targetEventId: String(data.targetEventId ?? ""),
        fromUserId: String(data.fromUserId ?? ""),
      },
      apns: { payload: { aps: { badge: unread.data().count, sound: "default" } } },
    });

    // 使われなくなったトークンは消しておく。
    const stale = result.responses
      .map((r, i) => (r.error?.code === "messaging/registration-token-not-registered" ||
        r.error?.code === "messaging/invalid-registration-token" ? tokens[i] : null))
      .filter((t): t is string => t !== null);
    await Promise.all(stale.map((t) => db.doc(`users/${uid}/fcmTokens/${t}`).delete()));
    logger.info("push sent", { uid, success: result.successCount, removed: stale.length });
  },
);
