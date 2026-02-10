const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Helper: get FCM token and send notification
async function sendPush(token, title, body, data = {}) {
  if (!token) return;
  try {
    await messaging.send({
      token,
      notification: { title, body },
      data: { ...Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])) },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  } catch (e) {
    console.warn('Push send failed:', e.message);
  }
}

// On match created → notify both users
exports.onMatchCreate = functions.firestore
  .document('matches/{matchId}')
  .onCreate(async (snap, context) => {
    const { userA, userB } = snap.data();
    const [userADoc, userBDoc] = await Promise.all([
      db.collection('users').doc(userA).get(),
      db.collection('users').doc(userB).get(),
    ]);
    const nameA = userADoc.exists ? (userADoc.data().name || 'Someone') : 'Someone';
    const nameB = userBDoc.exists ? (userBDoc.data().name || 'Someone') : 'Someone';
    const tokenA = userADoc.exists ? userADoc.data().fcmToken : null;
    const tokenB = userBDoc.exists ? userBDoc.data().fcmToken : null;

    await Promise.all([
      sendPush(tokenA, "It's a match! 💕", `${nameB} liked you too!`, { type: 'match', matchId: snap.id }),
      sendPush(tokenB, "It's a match! 💕", `${nameA} liked you too!`, { type: 'match', matchId: snap.id }),
    ]);
  });

// On message sent → notify the other user in chat
exports.onMessageCreate = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const chatId = context.params.chatId;
    const { senderId, text } = snap.data();
    const chatDoc = await db.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) return;
    const users = chatDoc.data().users || [];
    const recipientId = users.find((u) => u !== senderId);
    if (!recipientId) return;

    const senderDoc = await db.collection('users').doc(senderId).get();
    const senderName = senderDoc.exists ? (senderDoc.data().name || 'Someone') : 'Someone';
    const recipientDoc = await db.collection('users').doc(recipientId).get();
    const token = recipientDoc.exists ? recipientDoc.data().fcmToken : null;

    await sendPush(
      token,
      senderName,
      text.length > 80 ? text.substring(0, 77) + '...' : text,
      { type: 'message', chatId }
    );
  });

// On like created → notify the liked user
exports.onLikeCreate = functions.firestore
  .document('likes/{likeId}')
  .onCreate(async (snap, context) => {
    const { fromUserId, toUserId } = snap.data();
    const [fromDoc, toDoc] = await Promise.all([
      db.collection('users').doc(fromUserId).get(),
      db.collection('users').doc(toUserId).get(),
    ]);
    const fromName = fromDoc.exists ? (fromDoc.data().name || 'Someone') : 'Someone';
    const token = toDoc.exists ? toDoc.data().fcmToken : null;

    await sendPush(
      token,
      'New like 💗',
      `${fromName} likes you!`,
      { type: 'like', userId: fromUserId }
    );
  });
