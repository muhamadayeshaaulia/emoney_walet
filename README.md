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

Struktur Folder Flutter:
* `lib/core/`: Sumber daya global (Dio, Local Notifications, Secure Storage, Theme, dll.)
* `lib/features/`: Pembagian modular berdasarkan Fitur (auth, wallet, checkout, dashboard, dll.) yang dibagi lagi menjadi layer `data`, `presentation`, dan `providers`.

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
