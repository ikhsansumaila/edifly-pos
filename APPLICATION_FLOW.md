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
