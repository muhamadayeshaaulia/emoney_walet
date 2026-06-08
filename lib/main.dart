import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

void main() {
  runApp(const EMoneyApp());
}

class EMoneyApp extends StatelessWidget {
  const EMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Money Wallet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  // Variabel dummy untuk saldo
  double _balance = 1500000.0;

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

    // Menangani link jika aplikasi dibuka dari keadaan tertutup
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Mendengarkan link saat aplikasi sedang berjalan (background/foreground)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Error mendengarkan deep link: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'emoneyapp' && uri.host == 'pay') {
      final invoiceId = uri.queryParameters['invoice_id'];
      final amountStr = uri.queryParameters['amount'];
      
      if (invoiceId != null && amountStr != null) {
        final amount = double.tryParse(amountStr) ?? 0.0;
        
        // Pindah ke halaman konfirmasi pembayaran
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PaymentConfirmationPage(
            invoiceId: invoiceId,
            amount: amount,
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Money Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text('Saldo Anda saat ini:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              'Rp ${_balance.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Menunggu permintaan pembayaran dari aplikasi E-Commerce...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentConfirmationPage extends StatelessWidget {
  final String invoiceId;
  final double amount;

  const PaymentConfirmationPage({
    super.key,
    required this.invoiceId,
    required this.amount,
  });

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
                      'Rp ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Invoice ID:'),
                        Text(invoiceId, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Nanti kita akan arahkan ke input PIN dan pemotongan saldo (API)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lanjut ke verifikasi PIN... (Belum diimplementasi)')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'LANJUTKAN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
