# Backend setup (Cloud Functions)

## Agora – dinamik token

Görüntülü arama token'ı artık her aramada backend'den alınıyor (24 saat geçerli, channel'a özel).

1. Agora Console’dan **App Certificate**’ı al: Project → App Certificate → Enable → Copy.
2. Firebase’de config ayarla:
   ```bash
   firebase functions:config:set agora.app_id="YOUR_AGORA_APP_ID"
   firebase functions:config:set agora.app_certificate="YOUR_AGORA_APP_CERTIFICATE"
   ```
   Veya production’da environment variable: `AGORA_APP_ID`, `AGORA_APP_CERTIFICATE`.
3. Functions’ı deploy et:
   ```bash
   cd functions && npm install && cd .. && firebase deploy --only functions
   ```

`lib/core/config/agora_config.dart` içindeki `appId` ile `agora.app_id` aynı olmalı.

---

## Face verification – profil fotoğraflarıyla eşleştirme

Face verified rozeti artık sadece **3D liveness + selfie’nin profil fotoğraflarıyla eşleşmesi** sonrası veriliyor.

1. **Azure Face API** gerekir (yüz karşılaştırma için):
   - https://portal.azure.com → Create resource → “Face” → Create.
   - Keys and Endpoint’ten **Endpoint** ve **Key1** değerlerini al.
2. Firebase’de config:
   ```bash
   firebase functions:config:set face.endpoint="https://YOUR_RESOURCE.cognitiveservices.azure.com"
   firebase functions:config:set face.key="YOUR_FACE_API_KEY"
   ```
   Veya env: `FACE_API_ENDPOINT`, `FACE_API_KEY`.
3. Functions deploy:
   ```bash
   firebase deploy --only functions
   ```

Akış: Kullanıcı önce FaceTec 3D liveness yapar → başarılıysa “Take selfie & match with photos” ile selfie çeker → selfie Azure’da profil fotoğraflarıyla karşılaştırılır → eşleşirse `faceVerified: true` yazılır.

Endpoint’te sonda slash olmamalı (örn. `https://xxx.cognitiveservices.azure.com`).

---

## FaceTec 3D:2D Profile Pic (liveness + profil foto, Azure yok)

Azure kullanmadan: liveness → yüz 3D FaceMap olarak kaydedilir → profil fotoğraflarıyla FaceTec API ile karşılaştırılır. Selfie adımı yok.

1. **Firebase config:** Backend’in FaceTec API’yi çağırabilmesi için device key (uygulamadaki ile aynı):
   ```bash
   firebase functions:config:set facetec.device_key="BURAYA_DEVICE_KEY"
   ```
   Device Key: dev.facetec.com → Account Info & Encryption Keys. `facetec_config.dart` içindeki `deviceKeyIdentifier` ile aynı olmalı.
2. **Deploy:** `firebase deploy --only functions`
3. **Akış:** "Start verification" → 3D Liveness (session `processFaceTecSession` ile enrollment) → backend `verifyFaceTecProfilePics` ile profil fotoğraflarını FaceTec 3D:2D Profile Pic ile karşılaştırır → eşleşirse `faceVerified: true`.

**Not:** FaceTec Testing API enrollment ve match-3d-2d-profile-pic’i desteklemeyebilir; production FaceTec Server gerekebilir.
