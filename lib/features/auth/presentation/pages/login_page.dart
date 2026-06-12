import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _hasOtpQuickLogin = false;
  bool _hasSavedCredentials = false;

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials();
    _checkBiometric();
    _checkOtpQuickLogin();
  }

  void _checkSavedCredentials() async {
    final email = await AuthService.getSavedEmail();
    final password = await AuthService.getSavedPassword();
    if (mounted) {
      setState(() {
        _hasSavedCredentials = (email != null && password != null);
      });
    }
  }

  void _checkOtpQuickLogin() async {
    final uid = await AuthService.getSavedUid();
    final prefs = await SharedPreferences.getInstance();
    if (uid != null) {
      bool isEnabled = prefs.getBool('is_otp_login_enabled_$uid') ?? false;
      if (mounted) {
        setState(() {
          _hasOtpQuickLogin = isEnabled;
        });
      }
    }
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
    String? errorMessage = await AuthService.login(_emailController.text, _passwordController.text);
    setState(() => _isLoading = false);

    if (errorMessage == "OTP_REQUIRED") {
      _showOtpDialog();
    } else if (errorMessage == null) {
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

  void _loginWithOtpQuick() async {
    setState(() => _isLoading = true);
    String? email = await AuthService.getSavedEmail();
    String? password = await AuthService.getSavedPassword();
    if (email != null && password != null) {
      String? errorMessage = await AuthService.login(email, password, bypassOtp: false);
      setState(() => _isLoading = false);
      if (errorMessage == "OTP_REQUIRED") {
        _showOtpDialog();
      } else if (errorMessage == null) {
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
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data login tersimpan, silakan login manual.")),
      );
    }
  }

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    String? errorMessage = await AuthService.loginWithGoogle();
    setState(() => _isLoading = false);

    if (errorMessage == "VERIFY_BOTH") {
      _showVerificationChoiceDialog();
    } else if (errorMessage == "VERIFY_FINGERPRINT") {
      bool authenticated = await BiometricService.authenticate();
      if (authenticated) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        await AuthService.logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verifikasi biometrik gagal dibatalkan.')),
        );
      }
    } else if (errorMessage == "VERIFY_OTP") {
      _showOtpDialog();
    } else if (errorMessage == "OTP_REQUIRED") { // Fallback lama
      _showOtpDialog();
    } else if (errorMessage == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } else {
      await AuthService.logout(); // Rollback Google Login jika error lain
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _showVerificationChoiceDialog() {
    final rootContext = context; // context halaman Login, bukan context bottom sheet
    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Verifikasi Keamanan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink)),
              const SizedBox(height: 12),
              const Text('Pilih metode verifikasi untuk melanjutkan akses ke akun Anda.',
                style: TextStyle(fontSize: 14, color: AppColors.slate500)),
              const SizedBox(height: 24),
              AppButton(
                label: 'Sidik Jari (Biometrik)',
                onPressed: () async {
                  Navigator.pop(sheetContext); // tutup sheet dengan sheetContext
                  bool authenticated = await BiometricService.authenticate();
                  if (authenticated) {
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      rootContext, // pakai rootContext dari halaman Login
                      MaterialPageRoute(builder: (_) => const MainNavigation()),
                    );
                  } else {
                    await AuthService.logout();
                    if (!mounted) return;
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      const SnackBar(content: Text('Verifikasi biometrik gagal dibatalkan.')),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: AppColors.primary, width: 2),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  // Kirim OTP email hanya saat user memilih opsi ini
                  setState(() => _isLoading = true);
                  await AuthService.resendEmailOtp(action: 'login');
                  setState(() => _isLoading = false);
                  _showOtpDialog();
                },
                child: const Text('Gunakan Kode OTP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // Jika dialog ditutup tanpa memilih (di-dismiss), logout akun
      // Tetapi karena ini sulit melacak apakah dia klik tombol atau tidak,
      // kita biarkan saja (pengguna terjebak di layar login tanpa state masuk)
    });
  }

  void _loginWithFingerprint() async {
    bool authenticated = await BiometricService.authenticate();
    if (authenticated) {
      setState(() => _isLoading = true);
      String? email = await AuthService.getSavedEmail();
      String? password = await AuthService.getSavedPassword();
      if (email != null && password != null) {
        String? errorMessage = await AuthService.login(email, password, bypassOtp: true);
        setState(() => _isLoading = false);
        if (errorMessage == "OTP_REQUIRED") {
          _showOtpDialog();
          return;
        } else if (errorMessage == null) {
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

  void _showOtpDialog() {
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
                  const Text('Kami baru saja mengirimkan 6 digit kode OTP ke email Anda. Silakan masukkan kode tersebut untuk melanjutkan Login.',
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
                    label: 'VERIFIKASI',
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
                        Navigator.pop(context); // tutup bottom sheet
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MainNavigation()),
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
                        String? error = await AuthService.resendEmailOtp(action: 'login');
                        setModalState(() => isVerifying = false);
                        
                        if (!mounted) return;
                        if (error == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kode OTP baru telah dikirim ke email Anda!')),
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

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    bool isSending = false;

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
                  const Text('Atur Ulang Kata Sandi',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  const SizedBox(height: 12),
                  const Text('Masukkan alamat email yang terdaftar. Kami akan mengirimkan tautan untuk membuat kata sandi baru.',
                    style: TextStyle(fontSize: 14, color: AppColors.slate500)),
                  const SizedBox(height: 24),
                  AppField(
                    label: 'Email Terdaftar',
                    value: emailController.text,
                    onChanged: (v) => emailController.text = v,
                    placeholder: 'nama@email.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'KIRIM TAUTAN',
                    isLoading: isSending,
                    onPressed: () async {
                      if (emailController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email tidak boleh kosong')),
                        );
                        return;
                      }
                      setModalState(() => isSending = true);
                      String? error = await AuthService.resetPassword(emailController.text);
                      setModalState(() => isSending = false);

                      if (error == null) {
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tautan berhasil dikirim! Silakan periksa email Anda.')),
                        );
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      }
                    },
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
              Center(
                child: Image.asset(
                  'assets/logo/logo.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.account_balance_wallet, size: 60, color: AppColors.primary);
                  },
                ),
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
                  onPressed: _showForgotPasswordDialog,
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
              if (_hasSavedCredentials && (_hasBiometric || _hasOtpQuickLogin)) ...[
                const SizedBox(height: 16),
                const Center(
                  child: Text('ATAU', style: TextStyle(color: AppColors.slate500, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
              ],
              
              if (_hasSavedCredentials && _hasBiometric)
                AppButton(
                  label: 'Masuk dengan Sidik Jari',
                  onPressed: _isLoading ? null : _loginWithFingerprint,
                  variant: AppButtonVariant.outline,
                  icon: const Icon(Icons.fingerprint, color: AppColors.primary),
                ),
              if (_hasSavedCredentials && _hasBiometric && _hasOtpQuickLogin)
                const SizedBox(height: 12),
              if (_hasSavedCredentials && _hasOtpQuickLogin)
                AppButton(
                  label: 'Masuk dengan OTP',
                  onPressed: _isLoading ? null : _loginWithOtpQuick,
                  variant: AppButtonVariant.outline,
                  icon: const Icon(Icons.security, color: AppColors.primary),
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
