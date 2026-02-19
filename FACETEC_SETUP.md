# FaceTec Setup

FaceTec SDK dosyaları pub'da yok – manuel indirip projeye eklemen gerekiyor.

## 1. FaceTec SDK İndir

1. https://dev.facetec.com adresine git, giriş yap
2. Sol menüden **Download SDKs** veya **Device SDK Details → Download SDKs**
3. iOS ve Android SDK’yı indir (zip)

## 2. iOS Kurulumu

1. İndirdiğin zip’i aç
2. İçindeki **FaceTecSDK.xcframework** klasörünü bul
3. Bu klasörü `ios/` dizinine kopyala (`ios/FaceTecSDK.xcframework`)

```
Luvoo/
  ios/
    FaceTecSDK.xcframework/   ← buraya
    Runner/
    ...
```

4. Xcode’da projeyi aç
5. **Runner** target → **General** → **Frameworks, Libraries, and Embedded Content**
6. **+** → **Add Other** → **Add Files** → `FaceTecSDK.xcframework` seç
7. **Embed & Sign** seç

## 3. Android Kurulumu

1. İndirdiğin Android zip’i aç
2. İçindeki **facetec-sdk-*.aar** dosyasını bul
3. `android/app/libs/` klasörünü oluştur (yoksa)
4. .aar dosyasını `android/app/libs/` içine kopyala

```
Luvoo/
  android/
    app/
      libs/
        facetec-sdk-10.x.x.aar   ← buraya (versiyon farklı olabilir)
```

5. `android/app/build.gradle` içinde `dependencies` bloğuna ekle:

```gradle
implementation fileTree(dir: 'libs', include: ['*.aar'])
```

6. Sample App’taki **anim** ve **drawable** klasörlerini Android projesinin `res/` altına kopyala (FaceTec UI için gerekli)

## 4. Session endpoint (Test / Production)

- **Test:** `lib/core/config/facetec_config.dart` içinde `sessionEndpointUrl` FaceTec Testing API adresi (dev.facetec.com → API → Testing API’den kontrol et).
- **Production:** Kendi backend’inde FaceTec Server SDK’yı kullan; bu backend’in session endpoint URL’sini config’e yaz.

## 5. Test

Uygulamayı çalıştır, profil ayarlarında "Verify Face" butonuna bas. FaceTec ekranı açılıp liveness tamamlanıyorsa kurulum tamam.
