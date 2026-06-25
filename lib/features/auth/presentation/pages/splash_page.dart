import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'login_page.dart';
import '../../../dashboard/presentation/pages/main_navigation.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Simulasi loading screen
    await Future.delayed(const Duration(seconds: 2));

    String? token = await AuthService.getToken();
    if (!mounted) return;

    if (token != null) {
      // Cek apakah sidik jari diaktifkan oleh user
      final prefs = await SharedPreferences.getInstance();
      bool isFingerprintEnabled = prefs.getBool('is_fingerprint_enabled') ?? false;

      if (isFingerprintEnabled) {
        bool isBiometricAvailable = await BiometricService.isBiometricAvailable();
        if (isBiometricAvailable) {
          bool authenticated = await BiometricService.authenticate();
          if (authenticated) {
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
            }
          } else {
            // Kalau batal/gagal sidik jari, lempar ke login
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            }
          }
          return;
        }
      }

      // Jika tidak diaktifkan atau perangkat tidak mendukung, langsung masuk dashboard
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
      }
    } else {
      // Tidak punya token (belum pernah login)
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white, // Agar logo transparan/PNG terlihat jelas di background biru
              ),
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'assets/logo/logo.png',
                height: 120,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet, size: 100, color: AppColors.primaryColor),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'E-Money Mamah Saya',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
