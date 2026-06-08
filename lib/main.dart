import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';
import 'pages/splash_page.dart';
import 'pages/main_navigation.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const EMoneyApp());
}

class EMoneyApp extends StatefulWidget {
  const EMoneyApp({super.key});

  @override
  State<EMoneyApp> createState() => _EMoneyAppState();
}

class _EMoneyAppState extends State<EMoneyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Error mendengarkan deep link: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'emoneyapp' && uri.host == 'pay') {
      final invoiceId = uri.queryParameters['invoice_id'];
      final amount = double.tryParse(uri.queryParameters['amount'] ?? '');
      final token = uri.queryParameters['token'];

      if (invoiceId != null && amount != null && token != null) {
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => PaymentConfirmationPage(
                invoiceId: invoiceId,
                amount: amount,
                token: token,
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'E-Money Mamah Saya',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}

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

  void _showPinDialog() {
    final TextEditingController pinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Masukkan PIN 2FA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan PIN 6 angka Anda untuk menyetujui pembayaran ini. (Gunakan 123456)'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '******',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == '123456') {
                Navigator.pop(context); // Tutup dialog
                _processPayment();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN Salah! Silakan coba lagi.')),
                );
              }
            },
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    try {
      // Gunakan IP yang sama dengan ApiConstants.baseUrl di UTS App
      final url = Uri.parse('http://192.168.100.218:8080/v1/wallet/pay');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'invoice_id': widget.invoiceId,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran Berhasil! Mengembalikan ke E-Commerce...')),
        );
        
        // Simpan notifikasi ke SharedPreferences
        await NotificationService.addNotification(
          'Pembayaran Sukses ✅',
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
          SnackBar(content: Text('Gagal: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error jaringan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Pembayaran'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
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
                      backgroundColor: Colors.blue,
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
