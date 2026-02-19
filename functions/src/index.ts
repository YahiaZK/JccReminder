import {onSchedule} from "firebase-functions/v2/scheduler";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {setGlobalOptions} from "firebase-functions/v2";

setGlobalOptions({region: "europe-west3"});

initializeApp();

const db = getFirestore();

// Helper function remains the same
const calculateNextMaintenanceDate = (
  lastMaintenanceDate: Date,
  hoursLimit: number,
): Date => {
  const averageDailyUsageHours = (6.5 * 6) / 7;
  if (averageDailyUsageHours <= 0) {
    return lastMaintenanceDate;
  }
  const daysUntilNext = Math.ceil(hoursLimit / averageDailyUsageHours);
  // Use a new date object to avoid mutation
  const nextDate = new Date(lastMaintenanceDate.valueOf());
  nextDate.setDate(nextDate.getDate() + daysUntilNext);
  return nextDate;
};


// MODIFIED: The scheduled function now iterates through all users.
export const checkMaintenanceDueDates = onSchedule(
  // 1. Change the schedule to run at 7:00 every day.
  "every day 07:00",
  async () => {
    logger.info("--- Starting daily maintenance check ---");

    // 2. We are no longer checking for "tomorrow", but for "today".
    const today = new Date();

    // 3. Compare date components directly. This is robust against timezones.
    const todayYear = today.getFullYear();
    const todayMonth = today.getMonth(); // 0-11
    const todayDate = today.getDate();

    logger.info("Target Date (Today):"+
    ` Y=${todayYear}, M=${todayMonth}, D=${todayDate}`);

    const usersSnapshot = await db.collection("users").get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const fcmTokens = userDoc.data().fcmTokens as string[] | undefined;
      if (!fcmTokens || fcmTokens.length === 0) {
        logger.info(`Skipping user ${userId}, no FCM tokens found.`);
        continue;
      }

      logger.info(`Checking maintenance for user: ${userId}`);
      const equipmentSnapshot =
       await db.collection("users").doc(userId).collection("equipment").get();
      const notificationsToSend: string[] = [];

      for (const equipDoc of equipmentSnapshot.docs) {
        const equipment = equipDoc.data();
        const maintSnapshot =
         await equipDoc.ref.collection("maintenance").get();

        for (const maintDoc of maintSnapshot.docs) {
          const maintenance = maintDoc.data();
          // The timestamp from Firestore is always in UTC.
          const lastDateFromDB = (maintenance.last_date as Timestamp).toDate();

          // 4. The calculation for the due date remains the same.
          const nextDueDate = calculateNextMaintenanceDate(
            lastDateFromDB,
            maintenance.hours_limit,
          );

          const isDueToday =
            nextDueDate.getFullYear() === todayYear &&
            nextDueDate.getMonth() === todayMonth &&
            nextDueDate.getDate() === todayDate;

          if (isDueToday) {
            // 6. Update the message to say "is due today".
            const messageBody =
              `Maintenance for "${maintenance.type}" on ` +
              `"${equipment.name}" is due tomorrow.`;
            notificationsToSend.push(messageBody);
            logger.info("SUCCESS: Found due maintenance for" +
            ` ${userId}: ${messageBody}`);
          }
        }
      }

      if (notificationsToSend.length > 0) {
        const messageBody = notificationsToSend.join("\n");
        await sendNotificationToUser(userId, fcmTokens, messageBody);
      }
    }
    logger.info("--- Finished daily maintenance check ---");
  },
);

/**
 * Sends a multicast notification to a specific user using their FCM tokens.
 * @param {string} userId The ID of the user to send the notification to.
 * @param {string[]} tokens The array of FCM device tokens for the user.
 * @param {string} messageBody The body content of the notification message.
 */
async function sendNotificationToUser(
  userId: string,
  tokens: string[],
  messageBody: string,
) {
  if (!tokens || tokens.length === 0) {
    logger.warn(`No tokens found for user ${userId}. Cannot send message.`);
    return;
  }

  const message = {
    notification: {
      title: "Upcoming Maintenance Reminder",
      body: messageBody,
    },
  };

  try {
    logger.info(`Sending message to user: ${userId}`);
    const response = await getMessaging().sendEachForMulticast({
      tokens: tokens,
      notification: message.notification,
    });
    logger.info(
      `Successfully processed messages for user ${userId}.`,
      `${response.successCount} messages were sent successfully.`,
      `${response.failureCount} messages failed.`
    );
    // Optional: Clean up invalid tokens here if needed
  } catch (error) {
    logger.error(`Error sending message to user ${userId}:`, error);
  }
}

// MODIFIED: Test notification now sends only to the calling user.
export const sendTestNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to send a test notification.",
    );
  }
  const uid = request.auth.uid;
  logger.info(`Test notification requested by user: ${uid}`);

  // Fetch the user's document to get their FCM tokens
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) {
    throw new HttpsError("not-found", "User profile not found.");
  }

  const fcmTokens = userDoc.data()?.fcmTokens;
  if (!fcmTokens || fcmTokens.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "No notification tokens found for your account.",
      " Please ensure notifications are enabled.",
    );
  }

  const messageBody = "This is a test notification from the app settings!";

  const message = {
    notification: {
      title: "Test Notification",
      body: messageBody,
    },
  };

  try {
    await getMessaging().sendEachForMulticast({
      tokens: fcmTokens,
      notification: message.notification,
    });
    return {success: true, message: "Test notification sent successfully."};
  } catch (error) {
    logger.error("Error sending test notification:", error);
    throw new HttpsError(
      "internal",
      "An error occurred while trying to send the notification.",
    );
  }
});


