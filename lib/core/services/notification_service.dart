import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _key = 'user_notifications';

  // Notifier global untuk realtime update dot merah notifikasi
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier(0);

  static Future<void> updateUnreadCount() async {
    final count = await getUnreadCount();
    unreadCountNotifier.value = count;
  }

  // Menyimpan notifikasi baru
  static Future<void> addNotification(String title, String body, {Map<String, dynamic>? extraData}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList(_key) ?? [];

    Map<String, dynamic> newNotif = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'date': DateTime.now().toIso8601String(),
      'read': false, // Default: belum dibaca
    };
    if (extraData != null) {
      newNotif['extraData'] = extraData;
    }

    notifications.insert(0, jsonEncode(newNotif)); // Tambah di paling atas
    await prefs.setStringList(_key, notifications);
    await updateUnreadCount(); // Update realtime
  }

  // Mengambil daftar notifikasi
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList(_key) ?? [];
    return notifications.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  // Mengambil jumlah notifikasi yang belum dibaca
  static Future<int> getUnreadCount() async {
    final list = await getNotifications();
    return list.where((e) => e['read'] == false || e['read'] == null).length;
  }

  // Menandai satu notifikasi sebagai dibaca
  static Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList(_key) ?? [];
    List<String> updated = [];
    for (var item in notifications) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      if (map['id'] == id) {
        map['read'] = true;
      }
      updated.add(jsonEncode(map));
    }
    await prefs.setStringList(_key, updated);
    await updateUnreadCount();
  }

  // Menandai semua notifikasi sebagai dibaca
  static Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList(_key) ?? [];
    List<String> updated = [];
    for (var item in notifications) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      map['read'] = true;
      updated.add(jsonEncode(map));
    }
    await prefs.setStringList(_key, updated);
    await updateUnreadCount();
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
    await updateUnreadCount();
  }

  // Menghapus semua notifikasi
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await updateUnreadCount();
  }
}
