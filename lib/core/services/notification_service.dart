import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _key = 'user_notifications';

  // Menyimpan notifikasi baru
  static Future<void> addNotification(String title, String body, {Map<String, dynamic>? extraData}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList(_key) ?? [];
    
    Map<String, dynamic> newNotif = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'date': DateTime.now().toIso8601String(),
    };
    if (extraData != null) {
      newNotif['extraData'] = extraData;
    }

    notifications.insert(0, jsonEncode(newNotif)); // Tambah di paling atas
    await prefs.setStringList(_key, notifications);
  }

  // Mengambil daftar notifikasi
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList(_key) ?? [];
    return notifications.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  // Menghapus 1 notifikasi
  static Future<void> deleteNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList(_key) ?? [];
    
    notifications.removeWhere((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map['id'] == id;
    });

    await prefs.setStringList(_key, notifications);
  }

  // Menghapus semua notifikasi
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
