import * as admin from "firebase-admin";
import { onDocumentUpdated, onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { setGlobalOptions } from "firebase-functions/v2";
import * as logger from "firebase-functions/logger";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

setGlobalOptions({ maxInstances: 10, region: "us-central1" });

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: Send FCM notification to a user
// ─────────────────────────────────────────────────────────────────────────────
async function sendNotificationToUser(
  uid: string,
  title: string,
  body: string,
  type: string,
  data: Record<string, string> = {}
): Promise<void> {
  try {
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) return;

    const userData = userDoc.data();
    const fcmToken: string | undefined = userData?.fcmToken;
    const fcmTokens: string[] = userData?.fcmTokens ?? [];

    if (!fcmToken && fcmTokens.length === 0) {
      logger.info(`No FCM token for user ${uid}`);
      return;
    }

    const tokens = fcmToken
      ? Array.from(new Set([fcmToken, ...fcmTokens]))
      : fcmTokens;

    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: { title, body },
      data: { type, ...data },
      android: {
        notification: {
          channelId: "aimr_notifications",
          priority: "high",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: { sound: "default", badge: 1 },
        },
      },
    };

    const response = await messaging.sendEachForMulticast(message);
    logger.info(`Sent to ${response.successCount}/${tokens.length} tokens for user ${uid}`);

    // Save notification to Firestore so it appears in the notifications screen
    await db
      .collection("users")
      .doc(uid)
      .collection("notifications")
      .add({
        title,
        message: body,
        type,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        data,
      });

    // Clean up invalid tokens
    const invalidTokens: string[] = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const errCode = resp.error?.code;
        if (
          errCode === "messaging/invalid-registration-token" ||
          errCode === "messaging/registration-token-not-registered"
        ) {
          invalidTokens.push(tokens[idx]);
        }
      }
    });

    if (invalidTokens.length > 0) {
      await db.collection("users").doc(uid).update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      });
    }
  } catch (error) {
    logger.error(`Failed to send notification to user ${uid}:`, error);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRIGGER 1: Credits usage notifications
// Fires when imagesUsedToday or credits field changes on a user document
// ─────────────────────────────────────────────────────────────────────────────
export const onCreditsChanged = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    const uid = event.params.userId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;

    const totalCredits: number = after.totalCredits ?? 4; // default free trial = 4
    const creditsUsed: number = after.imagesUsedToday ?? 0;
    const prevUsed: number = before.imagesUsedToday ?? 0;

    // Only fire if credits actually changed
    if (creditsUsed === prevUsed) return;

    const usagePercent = Math.round((creditsUsed / totalCredits) * 100);
    const prevPercent = Math.round((prevUsed / totalCredits) * 100);

    // 50% threshold
    if (prevPercent < 50 && usagePercent >= 50) {
      await sendNotificationToUser(
        uid,
        "⚡ 50% Credits Used",
        "You've used half your daily credits. Use them wisely!",
        "warning",
        { creditsUsed: String(creditsUsed), totalCredits: String(totalCredits) }
      );
    }
    // 75% threshold
    else if (prevPercent < 75 && usagePercent >= 75) {
      await sendNotificationToUser(
        uid,
        "⚠️ 75% Credits Used",
        "Only 25% of your credits remain today. Generate wisely!",
        "warning",
        { creditsUsed: String(creditsUsed), totalCredits: String(totalCredits) }
      );
    }
    // 90% threshold
    else if (prevPercent < 90 && usagePercent >= 90) {
      await sendNotificationToUser(
        uid,
        "🔴 Almost Out of Credits!",
        "You've used 90% of your credits. Upgrade your plan for more.",
        "error",
        { creditsUsed: String(creditsUsed), totalCredits: String(totalCredits) }
      );
    }
    // 100% — credits exhausted
    else if (prevPercent < 100 && usagePercent >= 100) {
      await sendNotificationToUser(
        uid,
        "❌ Credits Exhausted",
        "You've used all your credits for today. Upgrade to continue generating.",
        "error",
        { creditsUsed: String(creditsUsed), totalCredits: String(totalCredits) }
      );
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// TRIGGER 2: Image generated successfully — notify user
// ─────────────────────────────────────────────────────────────────────────────
export const onImageGenerated = onDocumentCreated(
  "users/{userId}/generatedImages/{imageId}",
  async (event) => {
    const uid = event.params.userId;
    const data = event.data?.data();
    if (!data) return;

    const outfit = data.outfit ?? "your style";
    const location = data.location ?? "a location";

    await sendNotificationToUser(
      uid,
      "✨ Image Generated!",
      `Your ${outfit} shoot at ${location} is ready. View it in your library.`,
      "image",
      { imageId: event.params.imageId }
    );
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// TRIGGER 3: New user welcome notification
// ─────────────────────────────────────────────────────────────────────────────
export const onUserCreated = onDocumentCreated(
  "users/{userId}",
  async (event) => {
    const uid = event.params.userId;
    const data = event.data?.data();
    if (!data) return;

    const name = data.displayName ?? "there";

    // Wait 5 seconds for FCM token to be saved
    await new Promise((resolve) => setTimeout(resolve, 5000));

    await sendNotificationToUser(
      uid,
      `Welcome to AIMR Twin Studio™, ${name}! 🎉`,
      "Your AI digital twin is ready. Start generating stunning images now.",
      "success",
      {}
    );
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// TRIGGER 4: Subscription expiry warning (runs daily at 9 AM UTC)
// ─────────────────────────────────────────────────────────────────────────────
export const dailySubscriptionCheck = onSchedule(
  "0 9 * * *",
  async () => {
    const now = admin.firestore.Timestamp.now();
    const threeDaysFromNow = new Date();
    threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);

    const snapshot = await db
      .collection("users")
      .where("subscription", "!=", "free")
      .where("planExpiry", "<=", admin.firestore.Timestamp.fromDate(threeDaysFromNow))
      .where("planExpiry", ">", now)
      .get();

    const promises = snapshot.docs.map((doc) =>
      sendNotificationToUser(
        doc.id,
        "⏰ Subscription Expiring Soon",
        "Your plan expires in 3 days. Renew now to keep generating.",
        "warning",
        {}
      )
    );

    await Promise.all(promises);
    logger.info(`Sent expiry warnings to ${snapshot.size} users`);
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// TRIGGER 5: Daily credit reset notification (runs at midnight UTC)
// ─────────────────────────────────────────────────────────────────────────────
export const dailyCreditReset = onSchedule(
  "0 0 * * *",
  async () => {
    // Reset imagesUsedToday for all users
    const snapshot = await db
      .collection("users")
      .where("imagesUsedToday", ">", 0)
      .get();

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        imagesUsedToday: 0,
        usageDate: new Date().toISOString().split("T")[0],
      });
    });
    await batch.commit();

    logger.info(`Reset credits for ${snapshot.size} users`);
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// CALLABLE: Send broadcast notification to ALL users (admin use)
// Call from Firebase Console or admin panel
// ─────────────────────────────────────────────────────────────────────────────
export const sendBroadcastNotification = onDocumentCreated(
  "broadcasts/{broadcastId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const { title, body, type = "info" } = data;
    if (!title || !body) return;

    // Get all users with FCM tokens
    const snapshot = await db
      .collection("users")
      .where("fcmToken", "!=", null)
      .get();

    logger.info(`Broadcasting to ${snapshot.size} users: ${title}`);

    const promises = snapshot.docs.map((doc) =>
      sendNotificationToUser(doc.id, title, body, type, {
        broadcastId: event.params.broadcastId,
      })
    );

    await Promise.all(promises);

    // Mark broadcast as sent
    await event.data?.ref.update({
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      sentTo: snapshot.size,
    });
  }
);
