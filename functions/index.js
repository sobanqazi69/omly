const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { RtcTokenBuilder, RtcRole } = require("agora-access-token");

admin.initializeApp();

exports.checkUserActivity = functions.pubsub.schedule('every 1 minutes').onRun(async (context) => {
  const now = admin.firestore.Timestamp.now();
  const fiveMinutesAgo = now.toMillis() - (1 * 60 * 1000);
  const roomsRef = admin.firestore().collection('rooms');

  try {
    const roomsSnapshot = await roomsRef.get();
    const promises = [];

    roomsSnapshot.forEach(roomDoc => {
      const roomId = roomDoc.id;
      const usersRef = roomsRef.doc(roomId).collection('joinedUsers');

      const promise = usersRef.get().then(usersSnapshot => {
        usersSnapshot.forEach(async userDoc => {
          const userId = userDoc.id;
          const userTimestamp = userDoc.data().timestamp;

          if (userTimestamp && userTimestamp.toMillis() < fiveMinutesAgo) {
            console.log(`Removing user ${userId} from room ${roomId}`);
            await usersRef.doc(userId).delete();
            await roomsRef.doc(roomId).update({
              participants: admin.firestore.FieldValue.arrayRemove(userId)
            });
            console.log(`User ${userId} removed from participants list of room ${roomId}`);
          }
        });
      });

      promises.push(promise);
    });

    await Promise.all(promises);
    console.log('Completed user activity check');
  } catch (error) {
    console.error('Error checking user activity:', error);
  }
});

const APP_ID = "018815000ecb48bebce36fc9ee84830d";
const APP_CERTIFICATE = "728609c83fda41b8813aa759807b6a80";
exports.generateAgoraToken = functions.https.onCall((data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const channelName = data.channelName;
  const uid = data.uid;
  const role = RtcRole.PUBLISHER;

  const expirationTimeInSeconds = 3600; // Token expires in 1 hour
  const currentTimeInSeconds = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimeInSeconds + expirationTimeInSeconds;

  const token = RtcTokenBuilder.buildTokenWithUid(APP_ID, APP_CERTIFICATE, channelName, uid, role, privilegeExpiredTs);
  console.log(`token for ${channelName} is ${token}`);

  return { token };
});