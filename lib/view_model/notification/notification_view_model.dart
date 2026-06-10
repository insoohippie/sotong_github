// lib/view_model/notification/notification_view_model.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../model/notification/notification_item.dart';
import '../../repository/notification_repository.dart';
import '../../services/app_session_reset_service.dart';
import '../../services/notification_generate_service.dart';
import '../../services/record_event_bus.dart';

class NotificationViewModel extends ChangeNotifier implements SessionResettable {
  NotificationViewModel(
      this._notificationRepo,
      this._generateService,
      this._recordEventBus,
      ) {
    _recordSub = _recordEventBus.stream.listen((event) async {
      await refreshAfterRecordChanged();
    });
  }

  final NotificationRepository _notificationRepo;
  final NotificationGenerateService _generateService;
  final RecordEventBus _recordEventBus;

  StreamSubscription<RecordUpdatedEvent>? _recordSub;

  List<NotificationItem> _notifications = [];
  List<NotificationItem> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNotifications() async {
    _setLoading(true);
    _setError(null);
    notifyListeners();

    try {
      // 1) 오늘/어제 출석 알림 체크
      await _generateService.runDailyCheckIfNeeded();

      // 2) 예산/레포트/감정 알림도 항상 한 번 갱신
      //
      // 기존에는 hasAnyForCurrentUser()가 false일 때만 generateInitialBackfill()을 실행했는데,
      // 로그인 직후 출석 알림 하나가 먼저 생기면 hasAnyForCurrentUser()가 true가 되어
      // 나머지 알림 백필이 막힐 수 있었음.
      await _generateService.generateAfterRecordChanged();

      // 3) 현재 사용자 알림 다시 로드
      _notifications = _notificationRepo.getAllForCurrentUser();

      _setError(null);
    } catch (e) {
      _setError('알림 로드 실패: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> refreshAfterRecordChanged() async {
    try {
      await _generateService.generateAfterRecordChanged();
      _notifications = _notificationRepo.getAllForCurrentUser();
      notifyListeners();
    } catch (_) {
      // 알림 생성 실패가 기록 저장 흐름을 막으면 안 됨
    }
  }

  Future<void> removeNotification(String id) async {
    _notifications.removeWhere((notification) => notification.id == id);
    await _notificationRepo.remove(id);
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    await _notificationRepo.markAsRead(id);
    _notifications = _notificationRepo.getAllForCurrentUser();
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    await _notificationRepo.markAllAsRead();
    _notifications = _notificationRepo.getAllForCurrentUser();
    notifyListeners();
  }

  @override
  void dispose() {
    _recordSub?.cancel();
    _recordSub = null;
    super.dispose();
  }

  @override
  void resetSession() {
    _notifications = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  void _setError(String? value) {
    _error = value;
  }
}