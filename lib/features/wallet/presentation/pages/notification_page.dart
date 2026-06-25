import 'package:flutter/material.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'receipt_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifs = await NotificationService.getNotifications();
    await NotificationService.markAllAsRead(); // Tandai semua sebagai dibaca
    setState(() {
      _notifications = notifs;
      _isLoading = false;
    });
  }

  Future<void> _deleteNotification(String id) async {
    await NotificationService.deleteNotification(id);
    _loadNotifications(); // Reload UI
  }

  Future<void> _clearAll() async {
    await NotificationService.clearAll();
    _loadNotifications(); // Reload UI
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Hapus Semua',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Hapus Semua Notifikasi?'),
                    content: const Text('Anda yakin ingin menghapus semua riwayat notifikasi Anda?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearAll();
                        }, 
                        child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada notifikasi baru', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    return Dismissible(
                      key: Key(notif['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _deleteNotification(notif['id']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifikasi dihapus'), duration: Duration(seconds: 1)),
                        );
                      },
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primaryColor,
                          child: Icon(Icons.notifications, color: Colors.white),
                        ),
                        title: Text(notif['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${notif['body']}\n${_formatDate(notif['date'])}'),
                        isThreeLine: true,
                        onTap: () {
                          if (notif['extraData'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ReceiptPage(data: notif['extraData'])),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
