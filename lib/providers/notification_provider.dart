import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final title = data['title']?.toString() ?? json['type']?.toString() ?? 'Notification';
    final body = data['message']?.toString() ?? data['body']?.toString() ?? '';

    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'notification',
      title: title,
      body: body,
      isRead: json['read_at'] != null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  Timer? _pollTimer;
  bool _isFetching = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void startPolling() {
    fetchNotifications();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchNotifications();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> fetchNotifications() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final res = await ApiService.get('/notifications');
      if (res['success'] == true && res['data'] != null) {
        final rawList = res['data'] as List<dynamic>;
        _notifications = rawList
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (_) {}
    _isFetching = false;
  }

  Future<void> markAllRead() async {
    try {
      await ApiService.post('/notifications/mark-read', {});
      _notifications = _notifications.map((n) => AppNotification(
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        isRead: true,
        createdAt: n.createdAt,
      )).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}