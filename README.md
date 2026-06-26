## emoney_walet Mobile Application

    * Nama : Muhamad Ayesha Aulia
    * Nim : 1123150188
    * Kelas : TI SE SH 23
    * Teknik Informatika
    * Software Engineering

## Arsitektur & Struktur Sistem

Proyek ini terintegrasi erat dengan aplikasi E-Commerce menggunakan protokol **Deep Linking** (`emoneyapp://` dan `ecommerceapp://`) untuk alur pembayaran, serta berkomunikasi dengan backend masing-masing melalui REST API.

### 1. Diagram Arsitektur Gabungan (High-Level)
* **Client Apps (Flutter)**: E-Commerce App & E-Money Wallet App
* **Backend Services**: E-Commerce Go Backend, E-Money Go Backend, & Firebase Auth
* **Databases**: MySQL (E-Commerce DB & Wallet DB)

### 2. Arsitektur Kode Flutter (Clean Architecture / Feature-First)
Kedua aplikasi Flutter menggunakan pendekatan **Feature-First Clean Architecture** yang memisahkan kode berdasarkan fitur, mempermudah skalabilitas dan pemeliharaan.

Struktur Folder E-Money Wallet (`lib/`):
```text
lib/
├── core/                       # Sumber daya global & konfigurasi sistem
│   ├── constants/              # Konstanta aplikasi (API endpoint, assets, dll.)
│   ├── network/                # Client HTTP (DioClient, error interceptor)
│   ├── routes/                 # Konfigurasi rute halaman (AppRouter)
│   ├── services/               # Layanan eksternal (AuthService, BiometricService, NotificationService)
│   ├── theme/                  # Warna, tipografi, & style UI (AppColors)
│   ├── utils/                  # Utility helper (CurrencyFormatter, validator)
│   └── widgets/                # UI widget reusable (AppButton, AppField, dll.)
│
├── features/                   # Modul aplikasi berbasis Fitur
│   ├── auth/                   # Modul Autentikasi Pengguna
│   │   ├── data/               # Model data user (UserModel)
│   │   └── presentation/       # Halaman Login, Register, & OTP
│   │
│   ├── dashboard/              # Modul Tampilan Utama Wallet
│   │   └── presentation/       # Halaman Dashboard, Navigasi
│   │
│   └── wallet/                 # Modul Transaksi & Kelola Wallet
│       ├── data/               # Model transaksi, mutasi, & wallet info
│       └── presentation/       # Halaman Kirim Uang, Konfirmasi Pembayaran, & Aplikasi Terhubung
│
├── firebase_options.dart       # Konfigurasi otomatis Firebase SDK
└── main.dart                   # Entry point aplikasi & inisialisasi awal
```

Struktur Folder E-Commerce (`lib/`):
```text
lib/
├── core/                       # Sumber daya global & konfigurasi sistem
│   ├── routes/                 # Konfigurasi navigasi rute
│   ├── services/               # Layanan eksternal (Dio, Notification, dll.)
│   ├── theme/                  # Konfigurasi UI Theme & Warna
│   └── utils/                  # Helper (format mata uang, dll.)
│
├── features/                   # Modul aplikasi berbasis Fitur
│   ├── admin/                  # Modul Admin Kelola Produk
│   ├── auth/                   # Modul Registrasi & Login Customer
│   ├── cart/                   # Modul Keranjang Belanjaan
│   ├── catalog/                # Modul Katalog & Pencarian Produk
│   ├── checkout/               # Modul Alur Checkout Pesanan
│   └── dashboard/              # Modul Dashboard Utama & Riwayat Transaksi
│
├── firebase_options.dart       # Konfigurasi Firebase SDK
└── main.dart                   # Entry point aplikasi & inisialisasi Deep Link
```

### 3. Arsitektur Backend (Golang-Gin & GORM)
Layanan backend dibangun menggunakan bahasa **Go** dengan framework **Gin Gonic** untuk performa tinggi, serta **GORM** sebagai ORM ke database MySQL dengan fitur Auto-Migration.

### 4. Alur Integrasi Pembayaran (Inter-App Deep Linking)
1. E-Commerce request buat transaksi baru (Checkout) -> Backend mengembalikan `invoice_id` & `total_amount` dengan status `PENDING`.
2. E-Commerce membuka Deep Link: `emoneyapp://pay?invoice_id=...&amount=...&token=...`
3. E-Money memproses pembayaran & verifikasi keamanan (PIN + 2FA Google Authenticator/OTP).
4. E-Money mengirim callback sukses: `ecommerceapp://success?invoice_id=...`
5. E-Commerce memanggil API backend `PUT /v1/transactions/:invoice_id` untuk memperbarui status transaksi menjadi `SUCCESS`.

### 5. Fitur Keamanan Utama
* **Google Authenticator (2FA)**: Pembayaran mewajibkan input PIN diikuti kode OTP dinamis dari Google Authenticator.
* **Biometric Verification**: Fitur sidik jari di menu profil dilengkapi dengan pengaman aktif (verifikasi wajib berhasil sebelum toggle sidik jari aktif).

# UI Aplikasi E-money & E-commerce

* Tampilan ketika aplikasi berjalan

<p align="center">
  <img src="assets/images/emoney1.jpeg" width="200"/>
  <img src="assets/images/emoney2.jpeg" width="200"/>
  <img src="assets/images/emoney3.jpeg" width="200"/>
  <img src="assets/images/emoney4.jpeg" width="200"/>
  <img src="assets/images/emoney5.jpeg" width="200"/>
  <img src="assets/images/emoney6.jpeg" width="200"/>
  <img src="assets/images/emoney7.jpeg" width="200"/>
  <img src="assets/images/emoneytop.jpeg" width="200"/>
  <img src="assets/images/emoney8.jpeg" width="200"/>
  <img src="assets/images/emoney9.jpeg" width="200"/>
  <img src="assets/images/emoney10.jpeg" width="200"/>
  <img src="assets/images/emoney11.jpeg" width="200"/>
  <img src="assets/images/emoney12.jpeg" width="200"/>
  <img src="assets/images/emoney13.jpeg" width="200"/>
  <img src="assets/images/emoney14.jpeg" width="200"/>
  <img src="assets/images/emoney15.jpeg" width="200"/>
  <img src="assets/images/emoney16.jpeg" width="200"/>
  <img src="assets/images/emoney17.jpeg" width="200"/>
  <img src="assets/images/emoney18.jpeg" width="200"/>
  <img src="assets/images/emoney19.jpeg" width="200"/>
  <img src="assets/images/emoney20.jpeg" width="200"/>
  <img src="assets/images/emoney21.jpeg" width="200"/>
  <img src="assets/images/emoney22.jpeg" width="200"/>
  <img src="assets/images/emoney23.jpeg" width="200"/>
  <img src="assets/images/emoney24.jpeg" width="200"/>
  <img src="assets/images/emoney25.jpeg" width="200"/>
  <img src="assets/images/emoney26.jpeg" width="200"/>
</p>

* Tampilan Updated aplikasi [E-commerce Toko Bunga 716_Production](https://github.com/muhamadayeshaaulia/toko_bunga_uts_1123150188.git)
<p align="center">
  <img src="assets/images/ecommerce1.jpeg" width="200"/>
  <img src="assets/images/ecommerce2.jpeg" width="200"/>
  <img src="assets/images/ecommerce3.jpeg" width="200"/>
  <img src="assets/images/ecommerce4.jpeg" width="200"/>
  <img src="assets/images/ecommerce5.jpeg" width="200"/>
  <img src="assets/images/ecommerce6.jpeg" width="200"/>
</p>