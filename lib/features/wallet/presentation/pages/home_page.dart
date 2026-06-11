import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../main.dart';
import 'notification_page.dart';
import 'top_up_page.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _balance = 0.0;
  bool _isLoading = true;
  int _unreadNotifications = 0;
  final WalletRepository _repository = WalletRepository();

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _fetchBalance();
  }

  void _requestNotificationPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _fetchBalance() async {
    setState(() => _isLoading = true);
    try {
      final responseModel = await _repository.fetchBalance();
      if (responseModel != null) {
        setState(() {
          _balance = responseModel.balance;
        });
      }
    } catch (e) {
      debugPrint('Gagal mengambil saldo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToTopUp() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TopUpPage()),
    );
    if (result == true) {
      _fetchBalance(); // Refresh saldo otomatis dari server
      setState(() {
        _unreadNotifications++; // Tambah notifikasi baru
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('E-Money Mamah Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _unreadNotifications > 0,
              label: Text('$_unreadNotifications'),
              child: const Icon(Icons.notifications),
            ),
            onPressed: () {
              setState(() {
                _unreadNotifications = 0;
              });
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saldo Anda', style: TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  'Rp ${CurrencyFormatter.format(_balance)}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _navigateToTopUp,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Top Up Saldo', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _fetchBalance,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('Refresh', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Center(
                  child: Text(
                    'Menunggu permintaan pembayaran dari E-Commerce...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
    );
  }
}
