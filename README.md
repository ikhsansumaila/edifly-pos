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

## 📦 Build APK

Project ini memiliki script build otomatis dengan fitur:
- Auto-increment versi
- Stage management (dev, alpha, beta, rc, prod)
- Rename APK otomatis sesuai format: `edifly-pos-v{version}-{mode}.apk`

### Cara Penggunaan

```bash
# Format
./build.sh [mode] [increment] [stage]

# Lihat bantuan
./build.sh --help

# Build tanpa increment versi
./build.sh debug              # Build debug saja
./build.sh release            # Build release saja
./build.sh both               # Build keduanya

# Build dengan increment versi
./build.sh release patch              # Release + increment patch
./build.sh release patch dev          # Release + patch + set ke dev stage
./build.sh both build beta            # Keduanya + build number + set ke beta
./build.sh release none prod          # Release + pindah ke production
```

### Tipe Increment

| Tipe | Sebelum | Sesudah | Keterangan |
|------|---------|---------|------------|
| `none` | `0.0.4+1` | `0.0.4+1` | Tidak ada perubahan (default) |
| `build` | `0.0.4+1` | `0.0.4+2` | Increment build number saja |
| `patch` | `0.0.4+1` | `0.0.5+2` | Increment patch version |
| `minor` | `0.0.4+1` | `0.1.0+2` | Increment minor version |
| `major` | `0.0.4+1` | `1.0.0+2` | Increment major version |

### Kapan Menggunakan Increment?

#### 🐛 Bug Fix (Perbaikan Bug)
Gunakan **`patch`** untuk perbaikan bug kecil hingga sedang.

```bash
# Contoh: Fix login gagal, fix crash saat checkout, fix tampilan error
./build.sh release patch
# 0.0.4-dev+1 → 0.0.5-dev+2
```

#### ✨ Fitur Baru (New Feature)
Gunakan **`minor`** untuk penambahan fitur baru yang backward compatible.

```bash
# Contoh: Tambah fitur laporan, tambah metode pembayaran baru, tambah filter produk
./build.sh release minor
# 0.0.5-dev+2 → 0.1.0-dev+3
```

#### 🔧 Tech Debt / Refactor
Gunakan **`build`** untuk refactor internal yang tidak mengubah fungsionalitas.

```bash
# Contoh: Refactor kode, optimasi performa, update dependencies, cleanup code
./build.sh release build
# 0.1.0-dev+3 → 0.1.0-dev+4
```

#### 🚀 Major Update (Breaking Changes)
Gunakan **`major`** untuk perubahan besar yang tidak backward compatible.

```bash
# Contoh: Redesign total UI, ubah struktur database, migrasi arsitektur, ganti API
./build.sh release major
# 0.1.0-dev+4 → 1.0.0-dev+5
```

#### 📋 Ringkasan

| Jenis Perubahan | Increment | Contoh |
|-----------------|-----------|--------|
| Bug fix kecil | `patch` | Fix typo, fix minor UI |
| Bug fix besar | `patch` | Fix crash, fix security issue |
| Fitur baru | `minor` | Tambah modul laporan |
| Improvement UX | `minor` | Redesign halaman order |
| Refactor code | `build` | Cleanup, optimasi |
| Update library | `build` | Update dependencies |
| Breaking changes | `major` | Migrasi database |
| Rilis pertama | `major` | v1.0.0 production |

### Contoh Output

```bash
./build.sh both patch

# Output:
# 📦 Debug APK:
#    File: edifly-pos-v0.0.5-debug.apk
#    Path: build/app/outputs/flutter-apk/
#
# 📦 Release APK:
#    File: edifly-pos-v0.0.5-release.apk
#    Path: build/app/outputs/flutter-apk/
```

### Lokasi Output APK

```
build/app/outputs/flutter-apk/
├── edifly-pos-v{version}-debug.apk
└── edifly-pos-v{version}-release.apk
```

## 📝 Versioning

Format versi mengikuti Semantic Versioning dengan stage:

```
MAJOR.MINOR.PATCH[-STAGE]+BUILD_NUMBER
```

- **MAJOR**: Perubahan besar yang tidak backward compatible
- **MINOR**: Fitur baru yang backward compatible
- **PATCH**: Bug fixes
- **STAGE**: dev, alpha, beta, rc (opsional, dihapus untuk production)
- **BUILD_NUMBER**: Nomor build internal (wajib naik untuk upload ke Play Store)

### Stage Development

| Stage | Format | Keterangan |
|-------|--------|------------|
| `dev` | `0.0.4-dev+1` | Development |
| `alpha` | `0.0.4-alpha+1` | Alpha testing |
| `beta` | `0.0.4-beta+1` | Beta testing |
| `rc` | `0.0.4-rc+1` | Release Candidate |
| `prod` | `0.0.4+1` | Production (tanpa suffix) |

### Flow Development → Production

```
0.0.4-dev+1   → ./build.sh release patch        → 0.0.5-dev+2
0.0.5-dev+2   → ./build.sh release build beta   → 0.0.5-beta+3
0.0.5-beta+3  → ./build.sh release build rc     → 0.0.5-rc+4
0.0.5-rc+4    → ./build.sh release none prod    → 0.0.5+4  ← Production!
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
