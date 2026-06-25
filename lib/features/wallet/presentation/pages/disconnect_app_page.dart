import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/auth_service.dart';

class DisconnectAppPage extends StatefulWidget {
  final bool fromDeepLink;
  
  const DisconnectAppPage({
    super.key,
    this.fromDeepLink = true,
  });

  @override
  State<DisconnectAppPage> createState() => _DisconnectAppPageState();
}

class _DisconnectAppPageState extends State<DisconnectAppPage> {
  bool _isLoading = false;

  void _startDisconnectionFlow() async {
    // 1. PIN Verifikasi Dummy
    if (!mounted) return;
    final bool? isPinValid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final _pinController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Masukkan PIN', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Masukkan PIN E-Money Anda untuk memutuskan hubungan', style: TextStyle(fontSize: 13, color: AppColors.slate500)),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(hintText: '******', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: AppColors.slate500)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_pinController.text.length >= 4) {
                  Navigator.pop(ctx, true);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('PIN tidak valid')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Lanjut', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (isPinValid != true || !mounted) return;

    // 2. Google Authenticator Asli
    final bool? isAuthValid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final _authController = TextEditingController();
        bool _isVerifying = false;
        
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Google Authenticator', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Masukkan 6 digit kode dari Google Authenticator Anda', style: TextStyle(fontSize: 13, color: AppColors.slate500)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _authController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(hintText: '123456', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isVerifying ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Batal', style: TextStyle(color: AppColors.slate500)),
                ),
                ElevatedButton(
                  onPressed: _isVerifying ? null : () async {
                    if (_authController.text.length == 6) {
                      setStateDialog(() => _isVerifying = true);
                      
                      final error = await AuthService.verifyTOTP(_authController.text);
                      
                      if (mounted) {
                        setStateDialog(() => _isVerifying = false);
                        if (error == null) {
                          Navigator.pop(ctx, true);
                        } else {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(error)));
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Kode harus 6 digit')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: _isVerifying 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );

    if (isAuthValid == true && mounted) {
      setState(() => _isLoading = true);
      // Hapus dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_ecommerce_connected', false);

      // Simpan notifikasi
      await NotificationService.addNotification(
        'Koneksi Terputus ',
        'Hubungan dengan E-Commerce 716 Production berhasil diputuskan.',
      );

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);

        // Kembali ke E-Commerce
        final returnUrl = Uri.parse('ecommerceapp://disconnect_success');
        try {
          await launchUrl(returnUrl, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('Gagal membuka E-Commerce: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        Navigator.pop(context);
        if (widget.fromDeepLink) {
          try {
            await launchUrl(Uri.parse('ecommerceapp://cancel'), mode: LaunchMode.externalApplication);
          } catch (e) {
            debugPrint('Gagal membuka E-Commerce: $e');
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              Navigator.pop(context);
              if (widget.fromDeepLink) {
                try {
                  await launchUrl(Uri.parse('ecommerceapp://cancel'), mode: LaunchMode.externalApplication);
                } catch (e) {
                  debugPrint('Gagal membuka E-Commerce: $e');
                }
              }
            },
          ),
          title: const Text('Putuskan Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.redAccent, Color(0xFF8B0000)]),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.link_off_rounded, size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text(
                'Putuskan hubungan dengan E-Commerce 716 Production?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aplikasi ini tidak akan lagi dapat melihat saldo atau melakukan pembayaran secara otomatis dari E-Money Wallet Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.slate500),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _startDisconnectionFlow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Putuskan Hubungan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
              const SizedBox(height: 16),
              if (!_isLoading)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (widget.fromDeepLink) {
                      try {
                        await launchUrl(Uri.parse('ecommerceapp://cancel'), mode: LaunchMode.externalApplication);
                      } catch (e) {
                        debugPrint('Gagal membuka E-Commerce: $e');
                      }
                    }
                  },
                  child: const Text('Batal', style: TextStyle(color: AppColors.slate500)),
                )
            ],
          ),
        ),
      ),
    ));
  }
}
