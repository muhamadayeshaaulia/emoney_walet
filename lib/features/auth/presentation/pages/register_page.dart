import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_field.dart';
import '../../../dashboard/presentation/pages/main_navigation.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isOtpSent = false;

  void _register() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);
    String? errorMessage = await AuthService.register(_emailController.text, _passwordController.text);
    setState(() => _isLoading = false);

    if (errorMessage == null) {
      setState(() {
        _isOtpSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi sukses! Cek email Anda untuk kode OTP')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  void _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode OTP terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);
    bool success = await AuthService.verifyEmailOtp(_otpController.text);
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email berhasil diverifikasi!')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode OTP salah atau kedaluwarsa')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Daftar Akun Baru', style: TextStyle(color: AppColors.ink)),
        backgroundColor: AppColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.person_add_rounded, size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              if (!_isOtpSent) ...[
                const Text('Daftar E-Money',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.4,
                    )),
                const SizedBox(height: 6),
                const Text('Daftar dengan Email & Password Anda',
                    style: TextStyle(fontSize: 14.5, color: AppColors.slate500)),
                const SizedBox(height: 32),
                
                AppField(
                  label: 'Email Aktif',
                  value: _emailController.text,
                  onChanged: (v) => _emailController.text = v,
                  placeholder: 'nama@email.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                ),
                const SizedBox(height: 16),
                AppField(
                  label: 'Kata sandi',
                  value: _passwordController.text,
                  onChanged: (v) => _passwordController.text = v,
                  obscureText: _obscurePassword,
                  placeholder: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                        size: 20, color: AppColors.slate400),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'DAFTAR SEKARANG',
                  onPressed: _register,
                  isLoading: _isLoading,
                ),
              ] else ...[
                const Text('Verifikasi Email (SMTP 2FA)',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.4,
                    )),
                const SizedBox(height: 16),
                Text(
                  'Kami telah mengirimkan 6 digit kode OTP ke email:\n${_emailController.text}\n\nSilakan cek Inbox atau folder Spam Anda.',
                  style: const TextStyle(fontSize: 14.5, color: AppColors.slate500),
                ),
                const SizedBox(height: 32),
                AppField(
                  label: 'Kode OTP (6 digit)',
                  value: _otpController.text,
                  onChanged: (v) => _otpController.text = v,
                  placeholder: '123456',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  prefixIcon: const Icon(Icons.security, size: 20),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'VERIFIKASI OTP',
                  onPressed: _verifyOtp,
                  isLoading: _isLoading,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
