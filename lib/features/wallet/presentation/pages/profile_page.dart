import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../main.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_field.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'google_auth_setup_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool? _isFingerprintEnabled;
  bool? _isOtpLoginEnabled;
  bool? _isTotpEnabled;
  String _userName = 'Memuat...';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUserName();
  }

  void _loadUserName() async {
    final name = await AuthService.getUserName();
    if (mounted) {
      setState(() {
        _userName = name ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Pengguna E-Money';
      });
    }
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    // Ambil status TOTP dari backend
    final profile = await AuthService.getProfile();
    final totpEnabled = profile?['totp_enabled'] ?? false;

    if (mounted) {
      setState(() {
        _isFingerprintEnabled = prefs.getBool('is_fingerprint_enabled') ?? false;
        _isOtpLoginEnabled = prefs.getBool('is_otp_login_enabled_$uid') ?? false;
        _isTotpEnabled = totpEnabled;
      });
    }
  }

  void _toggleFingerprint(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_fingerprint_enabled', value);
    setState(() {
      _isFingerprintEnabled = value;
    });

    if (value) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'emoney_channel',
        'Notifikasi E-Money',
        channelDescription: 'Notifikasi sistem E-Money',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
      await flutterLocalNotificationsPlugin.show(
        1,
        'Sidik Jari Aktif! 🥳',
        'Yeyyy! Sekarang Anda bisa login dengan lebih mudah menggunakan sidik jari Anda',
        notificationDetails,
      );
      await NotificationService.addNotification(
        'Sidik Jari Aktif! 🥳',
        'Yeyyy! Sekarang Anda bisa login dengan lebih mudah menggunakan sidik jari Anda',
      );
    }
  }

  void _logout(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  void _showOtpVerificationDialog() async {
    // Kirim OTP dulu
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    String? sendError = await AuthService.resendEmailOtp(action: 'activation');
    if (!mounted) return;
    Navigator.pop(context); // Tutup loading

    if (sendError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sendError)));
      return;
    }

    final otpController = TextEditingController();
    bool isVerifying = false;
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 26, right: 26, top: 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Verifikasi Email (OTP)',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  const SizedBox(height: 12),
                  const Text('Untuk mengaktifkan Login OTP, silakan masukkan 6 digit kode OTP yang baru saja kami kirimkan ke email Anda.',
                    style: TextStyle(fontSize: 14, color: AppColors.slate500)),
                  const SizedBox(height: 24),
                  if (localError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(localError!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppField(
                    label: 'Kode OTP (6 digit)',
                    value: otpController.text,
                    onChanged: (v) => otpController.text = v,
                    placeholder: '123456',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    prefixIcon: const Icon(Icons.security, size: 20),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'AKTIFKAN OTP',
                    isLoading: isVerifying,
                    onPressed: () async {
                      if (otpController.text.isEmpty) return;
                      setModalState(() {
                        isVerifying = true;
                        localError = null;
                      });
                      String? error = await AuthService.verifyEmailOtp(otpController.text);
                      setModalState(() => isVerifying = false);

                      if (error == null) {
                        if (!mounted) return;
                        Navigator.pop(context); // Tutup bottom sheet
                        // Simpan settingan
                        final prefs = await SharedPreferences.getInstance();
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        await prefs.setBool('is_otp_login_enabled_$uid', true);
                        setState(() {
                          _isOtpLoginEnabled = true;
                        });
                        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
                          'emoney_channel',
                          'Notifikasi E-Money',
                          channelDescription: 'Notifikasi sistem E-Money',
                          importance: Importance.max,
                          priority: Priority.high,
                        );
                        const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
                        await flutterLocalNotificationsPlugin.show(
                          2,
                          'Keamanan OTP Aktif! 🛡️',
                          'Sekarang akun Anda dilindungi dengan kode OTP setiap kali login.',
                          notificationDetails,
                        );
                        await NotificationService.addNotification(
                          'Keamanan OTP Aktif! 🛡️',
                          'Sekarang akun Anda dilindungi dengan kode OTP setiap kali login.',
                        );
                      } else {
                        setModalState(() => localError = error);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: isVerifying ? null : () async {
                        setModalState(() {
                          isVerifying = true;
                          localError = null;
                        });
                        String? error = await AuthService.resendEmailOtp(action: 'activation');
                        setModalState(() => isVerifying = false);
                        if (!mounted) return;
                        if (error == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kode OTP baru telah dikirim!')),
                          );
                        } else {
                          setModalState(() => localError = error);
                        }
                      },
                      child: const Text('Kirim Ulang Kode OTP',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _toggleOtpLogin(bool value) async {
    if (value) {
      // Jika ingin menghidupkan, kita verifikasi OTP dulu
      _showOtpVerificationDialog();
    } else {
      // Jika mematikan, langsung saja
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await prefs.setBool('is_otp_login_enabled_$uid', false);
      setState(() {
        _isOtpLoginEnabled = false;
      });

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'emoney_channel',
        'Notifikasi E-Money',
        channelDescription: 'Notifikasi sistem E-Money',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
      await flutterLocalNotificationsPlugin.show(
        3,
        'Keamanan OTP Dinonaktifkan ⚠️',
        'Login dengan OTP telah dimatikan. Akun Anda sekarang lebih rentan.',
        notificationDetails,
      );
      await NotificationService.addNotification(
        'Keamanan OTP Dinonaktifkan ⚠️',
        'Login dengan OTP telah dimatikan. Akun Anda sekarang lebih rentan.',
      );
    }
  }

  void _setupGoogleAuthenticator() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoogleAuthSetupPage()),
    );

    if (result == true) {
      _loadSettings();
    }
  }

  void _resetGoogleAuthenticator() async {
    // Tampilkan dialog konfirmasi
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Atur Ulang Google Authenticator?'),
          content: const Text(
            'Jika Anda kehilangan akses atau menghapus aplikasi Google Authenticator, '
            'kami akan mengirimkan kode OTP ke email terdaftar Anda untuk memverifikasi tindakan ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendResetOtp();
              },
              child: const Text('Kirim OTP ke Email'),
            ),
          ],
        );
      },
    );
  }

  void _sendResetOtp() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final error = await AuthService.resendEmailOtp(action: 'deactivation');

    if (mounted) {
      Navigator.pop(context); // Tutup loading
    }

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim OTP: $error')));
      }
      return;
    }

    // Tampilkan modal verifikasi OTP
    final otpController = TextEditingController();
    bool isVerifying = false;
    String? localError;

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 26, right: 26, top: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Atur Ulang Authenticator',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    const SizedBox(height: 12),
                    const Text('Silakan masukkan 6 digit kode OTP yang kami kirimkan ke email Anda untuk menonaktifkan Google Authenticator.',
                      style: TextStyle(fontSize: 14, color: AppColors.slate500)),
                    const SizedBox(height: 24),
                    if (localError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(localError!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    AppField(
                      label: 'Kode OTP (6 digit)',
                      value: otpController.text,
                      onChanged: (v) => otpController.text = v,
                      placeholder: '123456',
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      prefixIcon: const Icon(Icons.security, size: 20),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'VERIFIKASI & NONAKTIFKAN',
                      isLoading: isVerifying,
                      onPressed: () async {
                        if (otpController.text.isEmpty) return;
                        setModalState(() {
                          isVerifying = true;
                          localError = null;
                        });

                        final verifyError = await AuthService.verifyEmailOtp(otpController.text);
                        if (verifyError == null) {
                          // Panggil registerTOTP untuk mereset totp_enabled ke false dan menghapus secret lama
                          await AuthService.registerTOTP();
                          
                          if (mounted) {
                            Navigator.pop(context); // Tutup bottom sheet
                            
                            // Kirim notifikasi lokal
                            const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
                              'emoney_channel',
                              'Notifikasi E-Money',
                              channelDescription: 'Notifikasi sistem E-Money',
                              importance: Importance.max,
                              priority: Priority.high,
                            );
                            const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
                            await flutterLocalNotificationsPlugin.show(
                              6,
                              'Google Authenticator Dinonaktifkan ⚠️',
                              'Verifikasi 2-Langkah dengan Google Authenticator telah dinonaktifkan.',
                              notificationDetails,
                            );
                            await NotificationService.addNotification(
                              'Google Authenticator Dinonaktifkan ⚠️',
                              'Verifikasi 2-Langkah dengan Google Authenticator telah dinonaktifkan.',
                            );

                            _loadSettings(); // Reload settings untuk update UI
                          }
                        } else {
                          setModalState(() {
                            isVerifying = false;
                            localError = verifyError;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: isVerifying ? null : () async {
                          setModalState(() {
                            isVerifying = true;
                            localError = null;
                          });
                          String? error = await AuthService.resendEmailOtp(action: 'deactivation');
                          setModalState(() => isVerifying = false);
                          if (!mounted) return;
                          if (error == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kode OTP baru telah dikirim!')),
                            );
                          } else {
                            setModalState(() => localError = error);
                          }
                        },
                        child: const Text('Kirim Ulang Kode OTP',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Tidak ada email';
    final isVerified = user?.emailVerified ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor,
                Color(0xFF193475),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryColor,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, color: AppColors.primaryColor, size: 24),
                ]
              ],
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: _isFingerprintEnabled == null
                    ? const ListTile(
                        leading: Icon(Icons.fingerprint, color: Colors.grey, size: 32),
                        title: Text('Memuat pengaturan...', style: TextStyle(color: Colors.grey)),
                        trailing: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : SwitchListTile(
                        title: const Text('Login dengan Sidik Jari', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Masuk lebih cepat & aman tanpa password'),
                        value: _isFingerprintEnabled!,
                        onChanged: _toggleFingerprint,
                        secondary: const Icon(Icons.fingerprint, color: AppColors.primaryColor, size: 32),
                        activeColor: AppColors.primaryColor,
                      ),
              ),
            ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: _isOtpLoginEnabled == null
                      ? const ListTile(
                          leading: Icon(Icons.security, color: Colors.grey, size: 32),
                          title: Text('Memuat pengaturan...', style: TextStyle(color: Colors.grey)),
                          trailing: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : SwitchListTile(
                          title: const Text('Login dengan OTP (2FA)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Kode OTP wajib dimasukkan saat masuk'),
                          value: _isOtpLoginEnabled!,
                          onChanged: _toggleOtpLogin,
                          secondary: const Icon(Icons.security, color: AppColors.primaryColor, size: 32),
                          activeColor: AppColors.primaryColor,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: _isTotpEnabled == null
                      ? const ListTile(
                          leading: Icon(Icons.phonelink_setup, color: Colors.grey, size: 32),
                          title: Text('Memuat pengaturan...', style: TextStyle(color: Colors.grey)),
                          trailing: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : ListTile(
                          leading: Icon(
                            _isTotpEnabled! ? Icons.verified_user : Icons.phonelink_setup,
                            color: _isTotpEnabled! ? Colors.green : AppColors.primaryColor,
                            size: 32,
                          ),
                          title: const Text('Google Authenticator (2FA)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            _isTotpEnabled!
                                ? 'Aktif (Digunakan saat pembayaran)' 
                                : 'Nonaktif — Tap untuk mengaktifkan',
                            style: TextStyle(
                              color: _isTotpEnabled! ? Colors.green : Colors.grey,
                            ),
                          ),
                          trailing: _isTotpEnabled!
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.chevron_right),
                          onTap: _isTotpEnabled! ? _resetGoogleAuthenticator : _setupGoogleAuthenticator,
                        ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Keluar (Logout)', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
