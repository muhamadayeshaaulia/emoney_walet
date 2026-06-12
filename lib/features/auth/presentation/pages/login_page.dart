import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_field.dart';
import '../../../dashboard/presentation/pages/main_navigation.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _hasBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  void _checkBiometric() async {
    bool isAvailable = await BiometricService.isBiometricAvailable();
    setState(() {
      _hasBiometric = isAvailable;
    });
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password tidak boleh kosong!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    bool success = await AuthService.login(_emailController.text, _passwordController.text);
    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login gagal. Periksa kembali email dan password Anda.')),
      );
    }
  }

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    String? errorMessage = await AuthService.loginWithGoogle();
    setState(() => _isLoading = false);

    if (errorMessage == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _loginWithFingerprint() async {
    bool authenticated = await BiometricService.authenticate();
    if (authenticated) {
      setState(() => _isLoading = true);
      String? email = await AuthService.getSavedEmail();
      String? password = await AuthService.getSavedPassword();
      
      if (email != null && password != null) {
        bool success = await AuthService.login(email, password);
        setState(() => _isLoading = false);
        if (success) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigation()),
          );
          return;
        }
      }
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi Sidik Jari kadaluarsa. Silakan login manual.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 40, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.account_balance_wallet, size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              const Text('Masuk E-Money',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.4,
                  )),
              const SizedBox(height: 6),
              const Text('Selamat datang kembali',
                  style: TextStyle(fontSize: 14.5, color: AppColors.slate500)),
              const SizedBox(height: 32),
              
              // Google Login Button
              GestureDetector(
                onTap: _isLoading ? null : _loginWithGoogle,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line, width: 1.5),
                    boxShadow: AppColors.shadowSoft,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 21, height: 21,
                        child: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                          errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, size: 24, color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Text('Lanjut dengan Google',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(children: [
                const Expanded(child: Divider(color: AppColors.line)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('atau email',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate400,
                      )),
                ),
                const Expanded(child: Divider(color: AppColors.line)),
              ]),
              const SizedBox(height: 22),
              
              AppField(
                label: 'Email',
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
                obscureText: !_isPasswordVisible,
                placeholder: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      size: 20, color: AppColors.slate400),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Lupa kata sandi?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      )),
                ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Masuk',
                onPressed: _login,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              
              if (_hasBiometric)
                AppButton(
                  label: 'Masuk dengan Sidik Jari',
                  onPressed: _isLoading ? null : _loginWithFingerprint,
                  variant: AppButtonVariant.outline,
                  icon: const Icon(Icons.fingerprint, color: AppColors.primary),
                ),
                
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Belum punya akun? ',
                      style: TextStyle(fontSize: 14, color: AppColors.slate500)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: const Text('Daftar di sini',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
