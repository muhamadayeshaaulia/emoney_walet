import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../main.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';

class GoogleAuthSetupPage extends StatefulWidget {
  const GoogleAuthSetupPage({super.key});

  @override
  State<GoogleAuthSetupPage> createState() => _GoogleAuthSetupPageState();
}

class _GoogleAuthSetupPageState extends State<GoogleAuthSetupPage> {
  bool _isLoading = true;
  String? _secret;
  String? _qrCodeBase64;
  Uint8List? _imageBytes;
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTOTPData();
  }

  void _fetchTOTPData() async {
    final data = await AuthService.registerTOTP();
    if (data == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data dari server. Pastikan koneksi internet aktif.';
        });
      }
      return;
    }

    final String secret = data['secret'] ?? '';
    final String qrCodeBase64 = data['qr_code'] ?? '';

    if (qrCodeBase64.isNotEmpty && secret.isNotEmpty) {
      final base64Image = qrCodeBase64.replaceFirst('data:image/png;base64,', '');
      if (mounted) {
        setState(() {
          _secret = secret;
          _qrCodeBase64 = qrCodeBase64;
          _imageBytes = base64Decode(base64Image);
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Kunci rahasia atau QR Code kosong.';
        });
      }
    }
  }

  void _copyToClipboard() async {
    if (_secret != null) {
      Clipboard.setData(ClipboardData(text: _secret!));
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'emoney_channel',
        'Notifikasi E-Money',
        channelDescription: 'Notifikasi sistem E-Money',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
      await flutterLocalNotificationsPlugin.show(
        5,
        'Kunci Rahasia Disalin! 📋',
        'Kunci rahasia Google Authenticator disalin ke papan klip.',
        notificationDetails,
      );
    }
  }

  void _verifyAndActivate() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Kode verifikasi harus 6 digit angka.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final error = await AuthService.verifyTOTP(code);

    if (mounted) {
      if (error == null) {
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'emoney_channel',
          'Notifikasi E-Money',
          channelDescription: 'Notifikasi sistem E-Money',
          importance: Importance.max,
          priority: Priority.high,
        );
        const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
        await flutterLocalNotificationsPlugin.show(
          4,
          'Google Authenticator Aktif! 🛡️',
          'Verifikasi 2-Langkah dengan Google Authenticator berhasil diaktifkan.',
          notificationDetails,
        );
        await NotificationService.addNotification(
          'Google Authenticator Aktif! 🛡️',
          'Verifikasi 2-Langkah dengan Google Authenticator berhasil diaktifkan.',
        );
        if (mounted) {
          Navigator.pop(context, true); // Mengembalikan true agar halaman sebelumnya tahu aktivasi sukses
        }
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Authenticator'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Meminta konfigurasi keamanan dari server...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _errorMessage != null && _secret == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _fetchTOTPData();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Amankan akun Anda dengan verifikasi 2 langkah menggunakan aplikasi Google Authenticator.',
                        style: TextStyle(fontSize: 15, color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                      
                      // STEP 1
                      _buildStepNumber(1, 'Pindai QR Code'),
                      const SizedBox(height: 12),
                      const Text(
                        'Buka aplikasi Google Authenticator Anda, ketuk tombol "+", lalu pilih "Pindai kode QR" untuk memindai gambar di bawah ini:',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      if (_imageBytes != null)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Image.memory(_imageBytes!, width: 200, height: 200),
                          ),
                        ),
                      const SizedBox(height: 24),
                      
                      // STEP 2
                      _buildStepNumber(2, 'Atau Masukkan Kunci Rahasia'),
                      const SizedBox(height: 12),
                      const Text(
                        'Jika tidak dapat memindai QR Code, Anda dapat memasukkan kunci rahasia ini secara manual pada Authenticator Anda:',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                _secret ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1.5,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _copyToClipboard,
                              icon: const Icon(Icons.copy, color: AppColors.primaryColor),
                              tooltip: 'Salin kunci',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // STEP 3
                      _buildStepNumber(3, 'Masukkan Kode Verifikasi'),
                      const SizedBox(height: 12),
                      const Text(
                        'Masukkan 6-digit kode verifikasi yang muncul di aplikasi Authenticator untuk mengonfirmasi:',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '000000',
                          hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 8),
                          border: const OutlineInputBorder(),
                          errorText: _errorMessage,
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyAndActivate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Verifikasi & Aktifkan',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStepNumber(int step, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
