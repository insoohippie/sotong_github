import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

/// iOS 홈 화면 위젯과 앱 간 데이터 동기화
class HomeWidgetSyncService {
  HomeWidgetSyncService._();

  static const appGroupId = 'group.io.sotong.app';
  static const widgetKind = 'SotongHomeWidget';

  static const _keyBannerItemsJson = 'banner_items_json';
  static const _keyPlanPercent = 'plan_percent';
  static const _keyDDayText = 'd_day_text';
  static const _keyPlanName = 'plan_name';
  static const _keyHasPlan = 'has_plan';

  static List<Map<String, dynamic>> _reportBannerItems = const [];
  static List<Map<String, dynamic>> _communicationBannerItems = const [];

  static Future<void> configure() async {
    if (!Platform.isIOS) return;
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<void> syncPlanData({
    required String planName,
    required double planPercent,
    required String dDayText,
    required bool hasPlan,
  }) async {
    if (!Platform.isIOS) return;

    await configure();
    await Future.wait([
      HomeWidget.saveWidgetData<String>(_keyPlanName, planName),
      HomeWidget.saveWidgetData<double>(_keyPlanPercent, planPercent),
      HomeWidget.saveWidgetData<String>(_keyDDayText, dDayText),
      HomeWidget.saveWidgetData<bool>(_keyHasPlan, hasPlan),
    ]);
    await _updateWidget();
  }

  static Future<void> syncReportBannerItems(
    List<Map<String, dynamic>> insights,
  ) async {
    if (!Platform.isIOS) return;
    _reportBannerItems = insights.map(_insightToWidgetJson).toList();
    await _persistBannerItems();
  }

  static Future<void> syncCommunicationBannerItems(
    List<Map<String, dynamic>> insights,
  ) async {
    if (!Platform.isIOS) return;
    _communicationBannerItems = insights.map(_insightToWidgetJson).toList();
    await _persistBannerItems();
  }

  static Map<String, dynamic> _insightToWidgetJson(Map<String, dynamic> insight) {
    final color = insight['color'] as Color;
    final icon = insight['icon'] as IconData;
    return {
      'title': insight['title'] as String,
      'color': _colorToHex(color),
      'icon': _iconKey(icon),
    };
  }

  static String _colorToHex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  static String _iconKey(IconData icon) {
    final codePoint = icon.codePoint;
    if (codePoint == Icons.pie_chart.codePoint) return 'pie_chart';
    if (codePoint == Icons.access_time.codePoint) return 'access_time';
    if (codePoint == Icons.savings.codePoint) return 'savings';
    if (codePoint == Icons.edit_note.codePoint) return 'edit_note';
    if (codePoint == Icons.remove_shopping_cart.codePoint) {
      return 'remove_shopping_cart';
    }
    if (codePoint == Icons.mood.codePoint) return 'mood';
    if (codePoint == Icons.schedule.codePoint) return 'schedule';
    if (codePoint == Icons.shopping_bag_outlined.codePoint) return 'shopping_bag';
    return 'info';
  }

  static Future<void> _persistBannerItems() async {
    await configure();

    final merged = <Map<String, dynamic>>[
      ..._reportBannerItems,
      ..._communicationBannerItems,
    ];

    if (merged.isEmpty) {
      merged.addAll(_fallbackBannerItems);
    }

    await HomeWidget.saveWidgetData<String>(
      _keyBannerItemsJson,
      jsonEncode(merged),
    );
    await _updateWidget();
  }

  static Future<void> _updateWidget() async {
    await HomeWidget.updateWidget(iOSName: widgetKind);
  }

  static String formatDDayText(Duration? remain) {
    if (remain == null) return '목표일 없음';
    if (remain.isNegative || remain.inSeconds <= 0) return 'D-Day 달성';
    return 'D-${remain.inDays}';
  }

  static const _fallbackBannerItems = [
    {
      'title': '소비를 기록하면 소비 패턴을 분석해드릴게요.',
      'color': '#3C7BFF',
      'icon': 'pie_chart',
    },
    {
      'title': '소비 기록이 쌓이면 감정 패턴을 알려드릴게요.',
      'color': '#0062FF',
      'icon': 'mood',
    },
    {
      'title': '예산을 설정하면 소비 관리 상태를 볼 수 있어요.',
      'color': '#3C7BFF',
      'icon': 'savings',
    },
  ];
}
