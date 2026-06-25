import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/repositories/wallet_repository.dart';

class PaymentConfirmationPage extends StatefulWidget {
  final String invoiceId;
  final double amount;
  final String token;

  const PaymentConfirmationPage({
    super.key,
    required this.invoiceId,
    required this.amount,
    required this.token,
  });

  @override
  State<PaymentConfirmationPage> createState() => _PaymentConfirmationPageState();
}

class _PaymentConfirmationPageState extends State<PaymentConfirmationPage> {
  bool _isLoading = false;

  void _showPinDialog() async {
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
                const Text('Masukkan PIN E-Money Anda untuk melanjutkan pembayaran', style: TextStyle(fontSize: 13, color: AppColors.slate500)),
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
              child: const Text('Lanjut'),
            ),
          ],
        );
      },
    );

    if (isPinValid != true || !mounted) return;

    // 2. Google Authenticator / Email OTP
    String currentOtpType = 'totp';
    
    final String? authCode = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final _authController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Google Authenticator / Email', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Masukkan 6 digit kode dari Google Authenticator atau Email Anda', style: TextStyle(fontSize: 13, color: AppColors.slate500)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _authController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(hintText: '123456', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final repository = WalletRepository();
                        bool success = await repository.requestEmailOtp(widget.token);
                        if (success) {
                          setDialogState(() {
                            currentOtpType = 'email';
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('OTP telah dikirim ke email Anda!')),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gagal mengirim OTP ke email.')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.email),
                      label: const Text('Kirim OTP ke Email'),
                    ),
                    if (currentOtpType == 'email')
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('Gunakan OTP dari email', style: TextStyle(color: Colors.green, fontSize: 12)),
                      )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Batal', style: TextStyle(color: AppColors.slate500)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_authController.text.length >= 4) {
                      Navigator.pop(ctx, _authController.text);
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Kode tidak valid!')));
                    }
                  },
                  child: const Text('Verifikasi'),
                ),
              ],
            );
          }
        );
      },
    );

    if (authCode != null && authCode.isNotEmpty) {
      _processPayment(authCode, currentOtpType);
    }
  }

  Future<void> _processPayment(String otpCode, String otpType) async {
    setState(() => _isLoading = true);

    try {
      final repository = WalletRepository();
      final responseModel = await repository.payTransaction(
        widget.amount,
        'Pembayaran Tagihan ${widget.invoiceId}',
        otpCode,
        otpType,
        widget.token
      );

      if (responseModel != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran Berhasil! Mengembalikan ke E-Commerce...')),
        );
        
        // Simpan notifikasi ke SharedPreferences
        await NotificationService.addNotification(
          'Pembayaran Sukses',
          'Pembayaran tagihan ${widget.invoiceId} sebesar Rp ${widget.amount} berhasil.',
        );

        // Kembali ke dashboard E-Money
        Navigator.pop(context);
        // Memanggil aplikasi E-Commerce
        final returnUrl = Uri.parse('ecommerceapp://success');
        try {
          await launchUrl(returnUrl, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('Gagal membuka E-Commerce: $e');
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal melakukan pembayaran. Coba lagi.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.receipt_long, size: 60, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'Permintaan Pembayaran E-Commerce',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Total Tagihan', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${widget.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Invoice ID:'),
                        Text(widget.invoiceId, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _showPinDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'LANJUTKAN (VERIFIKASI PIN)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
