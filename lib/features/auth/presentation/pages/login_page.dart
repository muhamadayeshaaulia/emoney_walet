import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../dashboard/presentation/pages/main_navigation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    setState(() => _isLoading = true);
    bool success = await AuthService.login(_emailController.text, _passwordController.text);
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Gagal. Periksa email dan password Anda.')),
        );
      }
    }
  }

  void _loginWithFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    bool isEnabled = prefs.getBool('is_fingerprint_enabled') ?? false; // Default OFF
    if (!isEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sidik jari belum terdaftar di akun Anda.')),
        );
      }
      return;
    }

    String? email = await AuthService.getSavedEmail();
    String? password = await AuthService.getSavedPassword();

    if (email != null && password != null) {
      bool isBiometricAvailable = await BiometricService.isBiometricAvailable();
      if (isBiometricAvailable) {
        bool authenticated = await BiometricService.authenticate();
        if (authenticated) {
          if (mounted) {
            setState(() => _isLoading = true);
          }
          bool success = await AuthService.login(email, password);
          if (mounted) {
            setState(() => _isLoading = false);
            if (success) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sesi fingerprint kedaluwarsa. Silakan login dengan password.')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Autentikasi sidik jari dibatalkan.')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur sidik jari tidak tersedia di perangkat ini.')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda belum pernah login sebelumnya. Silakan login googel atau email terlebih dahulu.')),
        );
      }
    }
  }

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    bool success = await AuthService.loginWithGoogle();
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Google dibatalkan atau gagal.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo/logo.png',
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet, size: 80, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 24),
                  const Text('Selamat Datang di E-Money', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Atau login dengan', style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Tombol Sidik Jari
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loginWithFingerprint,
                          icon: const Icon(Icons.fingerprint, size: 24, color: Colors.blueAccent),
                          label: const Text('Sidik Jari', style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Tombol Google
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loginWithGoogle,
                          icon: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'G',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                          label: const Text('Google', style: TextStyle(color: Colors.black87, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
