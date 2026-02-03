# Edifly POS

Aplikasi Point of Sale (POS) untuk bisnis cafe/restoran.

## 📋 Persyaratan

- Flutter SDK ^3.7.2
- Android SDK
- Java 11+

## 🚀 Getting Started

### Instalasi Dependencies

```bash
flutter pub get
```

### Menjalankan Aplikasi

```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

## 📦 Smart Build System

Project ini menggunakan sistem **Smart Build** yang memisahkan histori versi antara **Development** dan **Production**, serta otomatis mengatur konfigurasi API.

### Fitur Utama
1.  **Dual-Track Versioning**: 
    -   Histori versi **Dev** dan **Prod** disimpan terpisah.
    -   Contoh: Anda bisa sedang mengerjakan `0.2.5-dev` sementara Production stabil di `1.1.0`. Script akan mengingat versi terakhir masing-masing track.
2.  **Auto API Config**: 
    -   Script otomatis mengubah `lib/core/network/api_config.dart`.
    -   Stage `dev/alpha/beta/rc` → Menggunakan **URL DEV**.
    -   Stage `prod` → Menggunakan **URL PRODUCTION**.
3.  **Auto Clean**:
    -   Otomatis menjalankan `flutter clean` dan `flutter pub get` sebelum build untuk mencegah cache issue.
4.  **Auto App Rename**:
    -   Otomatis mengubah nama aplikasi di launcher.
    -   **Prod**: `Dimonggoin Kasir`
    -   **Dev**: `Dimonggoin Kasir (DEV)`

### Cara Penggunaan

```bash
./build.sh [mode] [increment] [stage] [target_version]
```

**Argument:**
1.  **mode**: `debug` | `release` | `both`
2.  **increment**: `none` | `build` | `patch` | `minor` | `major`
3.  **stage**: `dev` | `alpha` | `beta` | `rc` | `prod` | `keep`
4.  **target_version** (Opsional): Paksa set ke versi tertentu, mengabaikan histori.

### Contoh Skenario

#### 1. Rutinitas Development (Harian)
Untuk build debug sehari-hari dan menaikkan patch version di track dev:
```bash
./build.sh debug patch dev
# Hasil: 
# - Versi dev naik (misal: 0.2.0-dev -> 0.2.1-dev)
# - API set ke DEV
# - Build mode debug
```

#### 2. Rilis Production
Ketika ingin merilis update ke user. Script akan mengambil versi terakhir **Production**, bukan Development.
```bash
./build.sh release patch prod
# Hasil:
# - Versi prod naik (misal: 1.0.0 -> 1.0.1)
# - API set ke PROD
# - Build mode release
```

#### 3. Pindah Stage (Dev -> Beta)
```bash
./build.sh release build beta
# Hasil: 0.2.1-dev -> 0.2.1-beta+2
```

#### 4. Reset / Set Versi Manual
Jika Anda ingin memaksa versi kembali ke angka tertentu:
```bash
# Reset dev ke 0.5.0
./build.sh debug none dev 0.5.0

# Set production ke 2.0.0
./build.sh release none prod 2.0.0
```

### Tipe Increment

| Tipe | Keterangan | Contoh |
|------|------------|--------|
| `none` | Tidak ada perubahan versi | - |
| `build` | Naikkan build number saja | Fix internal / refactor |
| `patch` | Naikkan angka terakhir (0.0.**X**) | Bug fixes |
| `minor` | Naikkan angka tengah (0.**X**.0) | Fitur baru (backward compatible) |
| `major` | Naikkan angka depan (**X**.0.0) | Perubahan besar / Breaking changes |

### Lokasi Output

```
build/app/outputs/flutter-apk/
├── edifly-pos-v{version}-debug.apk
└── edifly-pos-v{version}-release.apk
```


## 🔧 Konfigurasi

### App Icon

Untuk mengubah app icon, update file di `assets/icons/app_icon.png` kemudian jalankan:

```bash
flutter pub run flutter_launcher_icons
```

### Package Name

Package name saat ini: `com.example.edifly_pos`

Untuk mengubah, edit di:
- `android/app/build.gradle.kts` → `applicationId`
- `android/app/build.gradle.kts` → `namespace`

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [GetX State Management](https://pub.dev/packages/get)
