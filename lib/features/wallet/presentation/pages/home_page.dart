import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../main.dart';
import 'notification_page.dart';
import '../../data/repositories/wallet_repository.dart';

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

  Future<void> _topUp() async {
    try {
      final responseModel = await _repository.topUp(500000);
      
      if (responseModel != null) {
        setState(() {
          _balance = responseModel.balance;
          _unreadNotifications++;
        });
        if (mounted) {
          // SnackBar dihapus sesuai permintaan
        }

        // Tampilkan Notifikasi
        const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'emoney_topup_channel',
          'Notifikasi Top Up',
          channelDescription: 'Notifikasi saat saldo berhasil ditambahkan',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
        const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
        
        await NotificationService.addNotification('Top Up Berhasil! 💸', 'Saldo E-Money Mamah Saya bertambah Rp 500.000');

        await flutterLocalNotificationsPlugin.show(
          0,
          'Top Up Berhasil! 💸',
          'Saldo E-Money Mamah Saya bertambah Rp 500.000',
          platformChannelSpecifics,
        );
      }
    } catch (e) {
      debugPrint('Top Up Gagal: $e');
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
                  'Rp ${_balance.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _topUp,
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
                          backgroundColor: Colors.blueAccent,
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
