import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/auth_service.dart';
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
  String _userName = 'Pengguna E-Money';
  final WalletRepository _repository = WalletRepository();

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Transfer',
      'icon': Icons.send_rounded,
      'color': Colors.blue,
    },
    {
      'title': 'Isi Pulsa',
      'icon': Icons.phone_android_rounded,
      'color': Colors.orange,
    },
    {
      'title': 'E-Wallet',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Colors.purple,
    },
    {
      'title': 'Bayar BPJS',
      'icon': Icons.medical_services_rounded,
      'color': Colors.teal,
    },
    {
      'title': 'Bayar Listrik',
      'icon': Icons.bolt_rounded,
      'color': Colors.amber,
    },
    {
      'title': 'Pulsa Paket',
      'icon': Icons.language_rounded,
      'color': Colors.indigo,
    },
  ];

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _fetchBalance();
    _loadUnreadNotificationsCount();
    _loadUserName();
  }

  void _requestNotificationPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _loadUnreadNotificationsCount() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotifications = count;
      });
    }
  }

  void _loadUserName() async {
    final name = await AuthService.getUserName();
    if (name != null && name.isNotEmpty && mounted) {
      setState(() {
        _userName = name;
      });
    }
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
      _loadUnreadNotificationsCount(); // Muat ulang jumlah notifikasi
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return 'Selamat Pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  void _showDummyFeatureDialog(String featureName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.construction_rounded,
                size: 64,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Fitur $featureName Segera Hadir!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Layanan $featureName sedang dalam tahap pengembangan untuk memberikan pengalaman transaksi terbaik bagi Anda. Nantikan pembaruan berikutnya!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.slate500,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double headerHeight = 270.0;
    final double cardOffset = 200.0; // Posisi card saldo melayang (memberi lebih banyak ruang bagi salam)

    Widget topHeader = Stack(
      clipBehavior: Clip.none,
      children: [
        // Gradient background container with bottom border radius
        Container(
          height: headerHeight,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor,
                Color(0xFF193475), // Elegant deep blue gradient
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'E-Money Mamah Saya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: Badge(
                          isLabelVisible: _unreadNotifications > 0,
                          label: Text('$_unreadNotifications'),
                          child: const Icon(Icons.notifications, color: Colors.white),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationPage()),
                          );
                          _loadUnreadNotificationsCount();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Greeting & Username Row
                  Text(
                    '${_getGreeting()},',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Overlapping Balance Card
        Positioned(
          top: cardOffset,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Saldo',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.primaryColor.withOpacity(0.8),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp ${CurrencyFormatter.format(_balance)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchBalance,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    topHeader,
                    const SizedBox(height: 60), // Ruang agar content di bawah tidak tertutup card melayang
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Actions Section
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _navigateToTopUp,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Column(
                                      children: [
                                        Icon(Icons.add_circle_outline, color: Colors.green, size: 28),
                                        SizedBox(height: 8),
                                        Text(
                                          'Top Up',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: _fetchBalance,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySurface,
                                      border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Column(
                                      children: [
                                        Icon(Icons.sync, color: AppColors.primaryColor, size: 28),
                                        SizedBox(height: 8),
                                        Text(
                                          'Refresh',
                                          style: TextStyle(
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Layanan Menu Grid
                          const Text(
                            'Layanan Utama',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // 3 kolom menu
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: _menuItems.length,
                            itemBuilder: (context, index) {
                              final item = _menuItems[index];
                              return InkWell(
                                onTap: () => _showDummyFeatureDialog(item['title']),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.line),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: item['color'].withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          item['icon'],
                                          color: item['color'],
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item['title'],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                          // Waiting Section
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.hourglass_empty_rounded,
                                    size: 48,
                                    color: Colors.orange[400],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Menunggu Permintaan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Silakan lakukan transaksi di web E-Commerce kami. Permintaan pembayaran akan otomatis muncul di sini.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.slate500,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
