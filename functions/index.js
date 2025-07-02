const functions = require('firebase-functions/v2');
const admin = require('firebase-admin');
const { RtcTokenBuilder, RtcRole } = require("agora-access-token");

admin.initializeApp();

exports.checkUserActivity = functions.scheduler.onSchedule('every 1 minutes', async (event) => {
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
        const userDeletionPromises = [];

        usersSnapshot.forEach(userDoc => {
          const userId = userDoc.id;
          const userTimestamp = userDoc.data().timestamp;

          if (userTimestamp && userTimestamp.toMillis() < fiveMinutesAgo) {
            console.log(`Removing user ${userId} from room ${roomId}`);

            const deleteUserPromise = usersRef.doc(userId).delete()
              .then(() => roomsRef.doc(roomId).update({
                participants: admin.firestore.FieldValue.arrayRemove(userId)
              }))
              .then(() => {
                console.log(`User ${userId} removed from participants list of room ${roomId}`);
                return usersRef.get();
              })
              .then(updatedUsersSnapshot => {
                if (updatedUsersSnapshot.empty) {
                  console.log(`Deleting room ${roomId} as no more users are present`);
                  return roomsRef.doc(roomId).delete();
                }
              });

            userDeletionPromises.push(deleteUserPromise);
          }
        });

        return Promise.all(userDeletionPromises);
      });

      promises.push(promise);
    });

    await Promise.all(promises);
    console.log('Completed user activity check');
  } catch (error) {
    console.error('Error checking user activity:', error);
  }
});

const APP_ID = "36876abda2bf48e2a2ed324ebac196c4";
const APP_CERTIFICATE = "d592795125d04b369a8e69547f047be6";

exports.generateAgoraToken = functions.https.onCall(async (data, context) => {
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