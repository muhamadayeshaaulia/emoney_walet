import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';

// ─── Konstanta Package Name App E-Commerce ───────────────────────────────────
// Ganti nilai ini dengan package name app 716_production yang sebenarnya
const String _ecommercePackageName = 'com.example.uts_1123150188_sesester6';
const String _ecommerceAppName = 'E-Commerce 716 Production';
const String _ecommerceDeepLinkScheme = 'ecommerceapp'; // URL scheme custom (opsional)
// ─────────────────────────────────────────────────────────────────────────────

class ConnectedAppsPage extends StatefulWidget {
  const ConnectedAppsPage({super.key});

  @override
  State<ConnectedAppsPage> createState() => _ConnectedAppsPageState();
}

class _ConnectedAppsPageState extends State<ConnectedAppsPage> {
  List<_ConnectedApp> _apps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConnectedApps();
  }

  Future<void> _loadConnectedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final isConnected = prefs.getBool('is_ecommerce_connected') ?? false;
    
    if (isConnected) {
      setState(() {
        _apps = [
          const _ConnectedApp(
            name: 'E-Commerce 716 Production',
            description: 'E-Commerce terintegrasi dengan E-Money Wallet',
            icon: Icons.store_rounded,
            color: Color(0xFFFF6B35),
            permissions: ['Pembayaran otomatis', 'Akses Saldo Real-time', 'Riwayat Transaksi'],
            connectedSince: '25 Jun 2026',
            packageName: _ecommercePackageName,
            deepLinkScheme: _ecommerceDeepLinkScheme,
            isActive: true,
          ),
        ];
        _isLoading = false;
      });
    } else {
      setState(() {
        _apps = [];
        _isLoading = false;
      });
    }
  }

  /// Memutuskan hubungan aplikasi (Unlink)
  Future<void> _unlinkApp(_ConnectedApp app) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Putus Hubungan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin memutuskan hubungan dengan ${app.name}? Anda tidak akan bisa melakukan pembayaran langsung dari aplikasi tersebut sampai Anda menghubungkannya kembali.',
          style: const TextStyle(color: AppColors.slate600, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.slate500)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Putuskan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Tampilkan indikator loading atau snackbar proses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Memutuskan hubungan dengan ${app.name}...')),
      );

      // Simulasi delay jaringan
      await Future.delayed(const Duration(seconds: 1));

      // Hapus status dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_ecommerce_connected', false);

      setState(() {
        _apps.removeWhere((element) => element.packageName == app.packageName);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${app.name} berhasil diputuskan.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Aplikasi Terhubung', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryColor, Color(0xFF193475)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Banner
          if (_apps.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primaryColor, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Kelola aplikasi yang terhubung dengan akun E-Money Wallet kamu.',
                      style: TextStyle(fontSize: 13, color: AppColors.primaryDark, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

          // Daftar App atau State Kosong
          Expanded(
            child: _apps.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link_off_rounded, size: 80, color: AppColors.slate300),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum Ada Aplikasi',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Saat ini belum ada aplikasi pihak ketiga yang terhubung dengan E-Money Wallet kamu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.slate500, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _apps.length,
                    itemBuilder: (context, index) {
                      final app = _apps[index];
                      return _AppCard(
                        app: app,
                        onUnlink: () => _unlinkApp(app),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── App Card Widget ──────────────────────────────────────────────────────────

class _AppCard extends StatelessWidget {
  final _ConnectedApp app;
  final VoidCallback onUnlink;

  const _AppCard({
    required this.app,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.shadowSoft,
      ),
      child: Column(
        children: [
          // Header app
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // App Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        app.color.withOpacity(0.8),
                        app.color,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: app.color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(app.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              app.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Aktif',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app.description,
                        style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Terhubung sejak ${app.connectedSince}',
                        style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1, color: AppColors.line),

          // Izin (permissions)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IZIN DIBERIKAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppColors.slate400,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: app.permissions.map((perm) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.line2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 12, color: AppColors.primaryColor),
                        const SizedBox(width: 5),
                        Text(
                          perm,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.slate600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),

          // Tombol aksi (Putus Hubungan)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUnlink,
                icon: const Icon(Icons.link_off_rounded, size: 18, color: Colors.red),
                label: const Text(
                  'Putuskan Hubungan',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────

class _ConnectedApp {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> permissions;
  final String connectedSince;
  final String packageName;
  final String deepLinkScheme;
  final bool isActive;

  const _ConnectedApp({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.permissions,
    required this.connectedSince,
    required this.packageName,
    required this.deepLinkScheme,
    required this.isActive,
  });
}
