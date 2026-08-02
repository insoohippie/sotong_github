import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../model/notification/notification_settings.dart';

/// 알림 ID 상수
class _NotificationIds {
  static const int attendance = 1;
  static const int motivation = 2;
  static const int absence = 5;
  static const int weeklyReport = 3;
  static const int emotionReport = 4;
}

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService _instance =
      LocalNotificationService._();
  static LocalNotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _androidDetailsDaily = AndroidNotificationDetails(
    'daily',
    '일간 알림',
    channelDescription: '출석·동기부여·결석 알림',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@drawable/ic_notification',
    largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
  );

  static const _androidDetailsWeekly = AndroidNotificationDetails(
    'weekly',
    '주간 알림',
    channelDescription: '소비통계·감정 분석 레포트',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@drawable/ic_notification',
    largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
  );

  static const _androidDetailsTest = AndroidNotificationDetails(
    'test',
    '테스트',
    channelDescription: '테스트 알림',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@drawable/ic_notification',
    largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
  );

  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  /// 초기화 (main에서 호출)
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // 알림 탭 시 앱 열기 등 처리
  }

  /// iOS / Android 알림 권한 요청
  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// 시스템 알림 권한 허용 여부
  Future<bool> isPermissionGranted() async {
    if (!_initialized) {
      await initialize();
    }

    if (Platform.isIOS) {
      final permissions = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return permissions?.isEnabled ?? false;
    }

    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    }

    return false;
  }

  /// OS 설정 앱으로 이동 (iOS 16+: 앱 알림 설정, Android: 알림 설정)
  Future<void> openSystemNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  /// 예약된 로컬 알림 전부 취소
  Future<void> cancelAllScheduled() async {
    if (!_initialized) {
      await initialize();
    }
    await _plugin.cancelAll();
  }

  Future<void> _ensureReady() async {
    if (!_initialized) {
      await initialize();
    }
    await requestPermission();
  }

  /// 설정에 따라 스케줄 갱신
  Future<void> updateSchedules(NotificationSettings settings) async {
    if (!_initialized) {
      await initialize();
    }

    await _plugin.cancelAll();

    if (!await isPermissionGranted()) {
      return;
    }

    if (settings.attendanceEnabled) {
      await _scheduleDaily(
        id: _NotificationIds.attendance,
        hour: settings.attendanceHour,
        minute: settings.attendanceMinute,
        title: '출석알림',
        body: '오늘 소비를 기록하셨나요? 지금 입력해보세요!',
        androidDetails: _androidDetailsDaily,
      );
    }

    if (settings.motivationEnabled) {
      await _scheduleDaily(
        id: _NotificationIds.motivation,
        hour: settings.motivationHour,
        minute: settings.motivationMinute,
        title: '동기부여 알림',
        body: '오늘도 소비 통제 파이팅 💪',
        androidDetails: _androidDetailsDaily,
      );
    }

    if (settings.absenceEnabled) {
      await _scheduleDaily(
        id: _NotificationIds.absence,
        hour: settings.absenceHour,
        minute: settings.absenceMinute,
        title: '결석 알림',
        body: '플랜 기간 중 기록이 비어 있는 날이 있는지 확인해 볼까요?',
        androidDetails: _androidDetailsDaily,
      );
    }

    if (settings.weeklyReportEnabled) {
      await _scheduleWeekly(
        id: _NotificationIds.weeklyReport,
        weekday: DateTime.sunday,
        hour: 20,
        minute: 0,
        title: '소비통계레포트',
        body: '이번 주 소비 패턴을 확인해보세요!',
        androidDetails: _androidDetailsWeekly,
      );
    }

    if (settings.emotionReportEnabled) {
      await _scheduleWeekly(
        id: _NotificationIds.emotionReport,
        weekday: 7,
        hour: 20,
        minute: 0,
        title: '감정 분석 레포트',
        body: '이번 주 감정 기록을 확인해보세요!',
        androidDetails: _androidDetailsWeekly,
      );
    }
  }

  /// Android 정확 알람 권한이 허용된 기기에서는 exact,
  /// 거부된 기기(Android 14+ 기본값)에서는 inexact로 예약한다.
  /// inexact는 권한 없이 동작하며 발화 시각이 몇 분 내외로 유연해진다.
  Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    final canExact = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.canScheduleExactNotifications() ??
        false;
    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// 매일 반복 알림
  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required AndroidNotificationDetails androidDetails,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: androidDetails,
        iOS: _iosDetails,
      ),
      androidScheduleMode: await _androidScheduleMode(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 매주 반복 알림 (일요일 저녁)
  Future<void> _scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required AndroidNotificationDetails androidDetails,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    var daysToAdd = (weekday - now.weekday + 7) % 7;
    if (daysToAdd == 0 && scheduledDate.isBefore(now)) {
      daysToAdd = 7;
    }
    scheduledDate = scheduledDate.add(Duration(days: daysToAdd));

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: androidDetails,
        iOS: _iosDetails,
      ),
      androidScheduleMode: await _androidScheduleMode(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// 테스트용: N초 후 알림
  Future<void> scheduleTest(int seconds) async {
    await _ensureReady();

    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: seconds));
    await _plugin.zonedSchedule(
      999,
      '테스트 알림',
      '로컬 알림이 정상 작동합니다!',
      scheduledDate,
      const NotificationDetails(
        android: _androidDetailsTest,
        iOS: _iosDetails,
      ),
      androidScheduleMode: await _androidScheduleMode(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
