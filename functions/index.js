const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Agora: generate RTC token for video call. Set AGORA_APP_ID and AGORA_APP_CERTIFICATE in Firebase config.
exports.getAgoraToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }
  const channelId = data?.channelId;
  const uid = data?.uid != null ? Number(data.uid) : null;
  if (!channelId || typeof channelId !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'channelId required');
  }
  const appId = process.env.AGORA_APP_ID || functions.config().agora?.app_id;
  const appCert = process.env.AGORA_APP_CERTIFICATE || functions.config().agora?.app_certificate;
  if (!appId || !appCert) {
    throw new functions.https.HttpsError('failed-precondition', 'Agora not configured. Set AGORA_APP_ID and AGORA_APP_CERTIFICATE.');
  }
  const effectiveUid = uid != null && !Number.isNaN(uid) ? uid : hashCode(context.auth.uid);
  const expirationSeconds = 24 * 60 * 60; // 24 hours
  const privilegeExpiredTs = Math.floor(Date.now() / 1000) + expirationSeconds;
  const token = RtcTokenBuilder.buildTokenWithUid(appId, appCert, channelId, effectiveUid, RtcRole.PUBLISHER, privilegeExpiredTs);
  return { token, uid: effectiveUid };
});

function hashCode(str) {
  let h = 0;
  for (let i = 0; i < str.length; i++) {
    h = ((h << 5) - h) + str.charCodeAt(i);
    h |= 0;
  }
  return Math.abs(h) % 2147483647;
}

// Face verification: compare selfie with user's profile photos via Azure Face API.
// Set FACE_API_ENDPOINT (e.g. https://xxx.cognitiveservices.azure.com) and FACE_API_KEY in Firebase config or env.
exports.verifyFaceWithPhotos = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }
  const userId = data?.userId;
  const selfieDownloadUrl = data?.selfieDownloadUrl;
  if (!userId || userId !== context.auth.uid) {
    throw new functions.https.HttpsError('permission-denied', 'userId must be current user');
  }
  if (!selfieDownloadUrl || typeof selfieDownloadUrl !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'selfieDownloadUrl required');
  }

  const userDoc = await db.collection('users').doc(userId).get();
  if (!userDoc.exists) {
    return { match: false, error: 'User not found' };
  }
  const photoUrls = userDoc.data().photoUrls || [];
  if (photoUrls.length === 0) {
    return { match: false, error: 'Add at least one profile photo first' };
  }

  const endpoint = process.env.FACE_API_ENDPOINT || functions.config().face?.endpoint;
  const key = process.env.FACE_API_KEY || functions.config().face?.key;
  if (!endpoint || !key) {
    return { match: false, error: 'Face comparison not configured (FACE_API_ENDPOINT, FACE_API_KEY)' };
  }

  const baseUrl = endpoint.replace(/\/$/, '');
  const authHeader = { 'Ocp-Apim-Subscription-Key': key, 'Content-Type': 'application/json' };

  async function detectFace(imageUrl) {
    const res = await fetch(`${baseUrl}/face/v1.0/detect?returnFaceId=true&recognitionModel=recognition_03`, {
      method: 'POST',
      headers: authHeader,
      body: JSON.stringify({ url: imageUrl }),
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Detect failed: ${res.status} ${text}`);
    }
    const faces = await res.json();
    if (!faces || faces.length === 0) return null;
    return faces[0].faceId;
  }

  async function verifyFaces(faceId1, faceId2) {
    const res = await fetch(`${baseUrl}/face/v1.0/verify`, {
      method: 'POST',
      headers: authHeader,
      body: JSON.stringify({ faceId1, faceId2 }),
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Verify failed: ${res.status} ${text}`);
    }
    const out = await res.json();
    return out.isIdentical === true && (out.confidence || 0) >= 0.5;
  }

  try {
    const selfieFaceId = await detectFace(selfieDownloadUrl);
    if (!selfieFaceId) {
      return { match: false, error: 'No face found in selfie' };
    }
    for (const photoUrl of photoUrls) {
      const photoFaceId = await detectFace(photoUrl);
      if (!photoFaceId) continue;
      const identical = await verifyFaces(selfieFaceId, photoFaceId);
      if (identical) {
        return { match: true };
      }
    }
    return { match: false, error: 'Selfie does not match your profile photos' };
  } catch (e) {
    console.warn('verifyFaceWithPhotos error:', e);
    return { match: false, error: e.message || 'Face comparison failed' };
  }
});

// ---------- FaceTec 3D:2D Profile Pic (no Azure, no selfie) ----------
// Session proxy: receives requestBlob from device, forwards to FaceTec with externalDatabaseRefID for enrollment.
// Call as: POST /processFaceTecSession?userId=XXX with body { requestBlob }
const FACETEC_PROCESS_URL = 'https://api.facetec.com/api/v4/biometrics/process-request';
const FACETEC_MATCH_PROFILE_PIC_URL = 'https://api.facetec.com/api/v4/biometrics/match-3d-2d-profile-pic';

function getFaceTecHeaders() {
  const deviceKey = process.env.FACETEC_DEVICE_KEY || functions.config().facetec?.device_key || '';
  return {
    'Content-Type': 'application/json',
    'X-Device-Key': deviceKey.trim(),
    'X-User-Agent': 'FaceTec-Server-1.0',
  };
}

exports.processFaceTecSession = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }
  const userId = (req.query.userId || (req.body && req.body.userId) || '').trim();
  if (!userId) {
    res.status(400).json({ error: 'userId required (query or body)' });
    return;
  }
  const requestBlob = (req.body && req.body.requestBlob) || '';
  if (!requestBlob) {
    res.status(400).json({ error: 'requestBlob required' });
    return;
  }
  const headers = getFaceTecHeaders();
  if (!headers['X-Device-Key']) {
    res.status(500).json({ error: 'FaceTec device key not configured (FACETEC_DEVICE_KEY or facetec.device_key)' });
    return;
  }
  try {
    const response = await fetch(FACETEC_PROCESS_URL, {
      method: 'POST',
      headers,
      body: JSON.stringify({ requestBlob, externalDatabaseRefID: userId }),
    });
    const data = await response.json().catch(() => ({}));
    const status = response.status;
    if (status !== 200) {
      res.status(status).json(data);
      return;
    }
    const responseBlob = data.responseBlob || data.sessionResponseBlob || data.sessionToken;
    if (!responseBlob) {
      res.status(502).json({ error: 'No responseBlob from FaceTec', data });
      return;
    }
    res.status(200).json({ responseBlob });
  } catch (e) {
    console.warn('processFaceTecSession error:', e);
    res.status(500).json({ error: e.message || 'FaceTec proxy failed' });
  }
});

// After liveness + enrollment, compare enrolled 3D FaceMap to user's profile photos (FaceTec 3D:2D Profile Pic).
exports.verifyFaceTecProfilePics = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }
  const userId = data?.userId;
  if (!userId || userId !== context.auth.uid) {
    throw new functions.https.HttpsError('permission-denied', 'userId must be current user');
  }
  const userDoc = await db.collection('users').doc(userId).get();
  if (!userDoc.exists) {
    return { match: false, error: 'User not found' };
  }
  const photoUrls = userDoc.data().photoUrls || [];
  if (photoUrls.length === 0) {
    return { match: false, error: 'Add at least one profile photo first' };
  }
  const headers = getFaceTecHeaders();
  if (!headers['X-Device-Key']) {
    return { match: false, error: 'FaceTec not configured (FACETEC_DEVICE_KEY or facetec.device_key)' };
  }
  const minMatchLevel = 3;
  for (const photoUrl of photoUrls) {
    try {
      const imageRes = await fetch(photoUrl);
      if (!imageRes.ok) continue;
      const buf = await imageRes.arrayBuffer();
      const base64 = Buffer.from(buf).toString('base64');
      const matchRes = await fetch(FACETEC_MATCH_PROFILE_PIC_URL, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          image: base64,
          externalDatabaseRefID: userId,
          minMatchLevel,
        }),
      });
      const matchData = await matchRes.json().catch(() => ({}));
      if (matchData.success === true) {
        return { match: true };
      }
    } catch (e) {
      console.warn('verifyFaceTecProfilePics photo error:', e);
    }
  }
  return { match: false, error: 'Face does not match your profile photos' };
});

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
