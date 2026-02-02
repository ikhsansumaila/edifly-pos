# Dokumentasi Flow Aplikasi Edifly POS

Dokumen ini menjelaskan alur penggunaan aplikasi (User Flow) mulai dari Login hingga manajemen transaksi dan Shift.

## 1. Autentikasi (Login)
- **Halaman**: `PosLoginPage`
- **Aksi**: Pengguna memasukkan Email dan Kata Sandi.
- **Validasi**:
  - Input tidak boleh kosong.
  - Kredensial diverifikasi via API.
- **Sukses**: Token dan data user disimpan lokal, pengguna diarahkan ke **Halaman Order**.

## 2. Manajemen Shift
Sistem memastikan integritas data penjualan per shift dengan mekanisme validasi otomatis.

### Pengecekan Shift (Middleware)
- **Trigger**: Aktif setiap kali pengguna masuk atau memuat ulang (Reload) aplikasi ke halaman utama.
- **Logika**:
  - Sistem mengecek status shift terakhir pengguna.
  - **Validasi Hari**: Jika ditemukan shift yang masih **OPEN** (Aktif) namun tanggal bukanya **bukan hari ini** (Active Shift from previous day), sistem akan memblokir akses ke halaman Order.
  - **Aksi**: Pengguna dipaksa (Redirect) ke halaman **Closing Shift** untuk menutup shift sebelumnya terlebih dahulu.

### Membuka Shift (Opening Shift)
- **Rute**: `/opening-shift`
- **Fungsi**: Memulai sesi penjualan baru. Biasanya diperlukan sebelum melakukan transaksi pertama hari itu.

### Menutup Shift (Closing Shift)
- **Akses**: Tombol "Tutup Pesanan" (Ikon Gembok) di Top Bar.
- **Halaman**: `ClosingShiftPage`
- **Fungsi**: Mengakhiri sesi penjualan.
- **Input**: Input nominal uang tunai aktual (untuk rekonsiliasi kas).
- **Output**: Laporan ringkasan shift (dapat dicetak).

## 3. Halaman Order (POS)
- **Halaman**: `PosOrderPage`
- **Orientasi**: Landscape (Tablet/Desktop).

### Area Menu (Kiri)
- **Kategori**: Filter produk berdasarkan kategori (Chip di atas).
- **Grid Produk**: Menampilkan daftar produk (Gambar & Harga).
- **Interaksi**: Tap produk untuk menambah ke keranjang.

### Area Keranjang Pesanan (Kanan)
1. **Daftar Item**:
   - Menambah/Mengurangi Qty.
   - Hapus item.
   - Tombol "HAPUS SEMUA" untuk mereset keranjang.
2. **Data Pelanggan**:
   - Input **Nama Pemesan** (Wajib).
   - Input **No. Antrian** (Wajib).
3. **Detail Transaksi**:
   - **Sumber Pesanan**: Pilih OFFLINE, GO, GRAB, SHOPEE, dll.
   - **Metode Pembayaran**: Tunai (Cash), QRIS, Transfer Bank.
   - **Input Uang (Khusus Tunai)**: Jika metode Tunai dipilih, kolom input nominal muncul untuk menghitung kembalian otomatis.

## 4. Proses Checkout
1. **Validasi**: Tombol Checkout hanya aktif jika data wajib terisi dan nominal bayar cukup (jika Tunai).
2. **Konfirmasi**:
   - Saat tombol "CHECK OUT" ditekan, muncul **Popup Konfirmasi**.
   - Menampilkan: Sumber, Total Tagihan, dan Metode Bayar.
   - Pilihan: "Proses Sekarang" atau "Cancel".
3. **Proses API**: Data dikirim ke server.
4. **Struk / Resi**:
   - Jika sukses, muncul **Dialog Resi**.
   - Opsi untuk **Cetak Struk** (Print via Bluetooth) atau tutup.
5. **Selesai**: Keranjang dikosongkan otomatis.

## 5. Pengaturan Printer
- **Akses**: Top Bar -> Tombol "Atur Printer" (Ikon Print).
- **Halaman**: `PrinterSettingsPage`.
- **Fitur**:
  - Scan perangkat Bluetooth.
  - Connect/Disconnect printer.
  - Tes Print.
- **Penting**: Pastikan printer terkoneksi untuk mencetak struk transaksi.

## 6. Logout
- **Akses**: Ikon Keluar di pojok kanan atas Top Bar.
- **Fungsi**: Menghapus sesi lokal dan kembali ke halaman Login.

---

## 7. Build & Deployment

### Versioning
Aplikasi menggunakan format **Semantic Versioning** dengan stage:
```
MAJOR.MINOR.PATCH[-STAGE]+BUILD_NUMBER
```
- **MAJOR**: Perubahan besar (breaking changes)
- **MINOR**: Fitur baru (backward compatible)
- **PATCH**: Bug fixes
- **STAGE**: dev, alpha, beta, rc (opsional)
- **BUILD_NUMBER**: Nomor build internal (wajib naik untuk Play Store)

### Stage Development

| Stage | Format | Keterangan |
|-------|--------|------------|
| `dev` | `0.0.4-dev+1` | Development |
| `alpha` | `0.0.4-alpha+1` | Alpha testing |
| `beta` | `0.0.4-beta+1` | Beta testing |
| `rc` | `0.0.4-rc+1` | Release Candidate |
| `prod` | `0.0.4+1` | Production |

### Build Script
Gunakan `build.sh` untuk build APK dengan opsi auto-increment versi dan stage:

```bash
# Format
./build.sh [mode] [increment] [stage]

# Mode: debug, release, both
# Increment: none, build, patch, minor, major
# Stage: dev, alpha, beta, rc, prod, keep

# Contoh
./build.sh release patch            # Build release + increment patch
./build.sh release patch dev        # Build release + patch + set ke dev
./build.sh release none prod        # Build release + pindah ke production
```

### Flow Development → Production

```
0.0.4-dev+1   → ./build.sh release patch        → 0.0.5-dev+2
0.0.5-dev+2   → ./build.sh release build beta   → 0.0.5-beta+3
0.0.5-beta+3  → ./build.sh release build rc     → 0.0.5-rc+4
0.0.5-rc+4    → ./build.sh release none prod    → 0.0.5+4  ← Production!
```

### Kapan Menggunakan Increment?

| Jenis Perubahan | Increment | Command | Contoh |
|-----------------|-----------|---------|--------|
| 🐛 Bug Fix | `patch` | `./build.sh release patch` | Fix login, fix crash |
| ✨ Fitur Baru | `minor` | `./build.sh release minor` | Tambah laporan, payment baru |
| 🔧 Tech Debt | `build` | `./build.sh release build` | Refactor, optimasi, cleanup |
| 🚀 Major Update | `major` | `./build.sh release major` | Redesign UI, migrasi DB |


### Output APK
File APK otomatis dinamai dengan format:
```
edifly-pos-v{version}-{mode}.apk
```

Lokasi output:
```
build/app/outputs/flutter-apk/
├── edifly-pos-v0.0.4-dev-debug.apk
└── edifly-pos-v0.0.4-dev-release.apk
```
