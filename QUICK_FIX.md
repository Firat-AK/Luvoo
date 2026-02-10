# Flutter Build Hızlandırma - Hızlı Çözümler

## Sorun
Build'ler çok yavaş veya timeout oluyor. Eskiden hızlıydı, şimdi çok yavaş.

## Hızlı Çözümler (Sırayla Dene)

### 1. Flutter Cache Temizle (EN HIZLI)
```bash
cd /Users/firatak/Luvoo
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/.flutter/bin/cache/artifacts/engine
flutter precache --ios
```

### 2. Xcode Build Ayarlarını Hızlandır
Xcode'da:
- Product > Scheme > Edit Scheme
- Build Configuration: Debug
- Build Options: "Parallelize Build" ✅ açık olsun

### 3. Simulator'ı Sıfırla
```bash
xcrun simctl shutdown all
xcrun simctl erase all
```

### 4. Flutter'ı Yeniden Kur (Son Çare)
```bash
cd ~/Documents/flutter_new  # veya Flutter'ın kurulu olduğu yer
git clean -xfd
git pull
flutter doctor
```

### 5. Release Mode Kullan (Daha Hızlı)
```bash
flutter run --release -d D79BB78A-3E08-46C3-89DE-438BC685A0F7
```

## Geçici Çözüm: Android'de Test Et
Android build genelde daha hızlı:
```bash
flutter run  # Android cihaz/simulator'da
```

## Neden Oluyor?
- iOS 26.2 + Flutter 3.32.4 uyumsuzluğu
- Flutter cache bozuk olabilir
- Xcode DerivedData birikmiş olabilir
- İlk build her zaman yavaştır (Firebase bağımlılıkları)
