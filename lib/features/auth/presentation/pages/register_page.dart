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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isOtpSent = false;
  String? _localError;

  void _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      setState(() => _localError = "Semua kolom harus diisi!");
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _localError = "Kata sandi dan konfirmasi tidak cocok!");
      return;
    }

    setState(() {
      _isLoading = true;
      _localError = null;
    });
    String? errorMessage = await AuthService.register(_nameController.text, _emailController.text, _passwordController.text);
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
      setState(() => _localError = errorMessage);
    }
  }

  void _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode OTP terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _localError = null;
    });
    String? error = await AuthService.verifyEmailOtp(_otpController.text);
    setState(() => _isLoading = false);

    if (error == null) {
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
      setState(() => _localError = error);
    }
  }

  void _resendOtp() async {
    setState(() {
      _isLoading = true;
      _localError = null;
    });
    String? error = await AuthService.resendEmailOtp(action: 'register');
    setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode OTP baru telah dikirim ke email Anda!')),
        );
      }
    } else {
      setState(() => _localError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/logo/logo.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person_add_rounded, size: 60, color: AppColors.primary);
                  },
                ),
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
                
                if (_localError != null) ...[
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
                          child: Text(_localError!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                AppField(
                  label: 'Nama Lengkap',
                  value: _nameController.text,
                  onChanged: (v) => _nameController.text = v,
                  placeholder: 'Budi Santoso',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                AppField(
                  label: 'Konfirmasi Kata sandi',
                  value: _confirmPasswordController.text,
                  onChanged: (v) => _confirmPasswordController.text = v,
                  obscureText: _obscureConfirmPassword,
                  placeholder: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        size: 20, color: AppColors.slate400),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'DAFTAR SEKARANG',
                  onPressed: _register,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? ',
                        style: TextStyle(fontSize: 14, color: AppColors.slate500)),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Masuk di sini',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          )),
                    ),
                  ],
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

                if (_localError != null) ...[
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
                          child: Text(_localError!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _resendOtp,
                    child: const Text('Kirim Ulang Kode OTP',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
