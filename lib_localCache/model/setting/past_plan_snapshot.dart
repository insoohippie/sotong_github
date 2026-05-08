/// 완료된 플랜의 요약 스냅샷 (total_plan 4개 카드 기준).
/// 지난 플랜 돌아보기에서 목록/상세 표시 및 저장에 사용.
class PastPlanSnapshot {
  const PastPlanSnapshot({
    required this.id,
    required this.planName,
    required this.completedAt,
    required this.daysTaken,
    this.startDate,
    this.endDate,
    this.restraintProgress = 0,
    this.targetProgress = 0,
    this.savingProgress = 0,
    this.emotionCounts = const {},
    this.categorySpending = const {},
    this.diaries = const [],
    this.averagePace,
    this.averageDailySaving,
  });

  final String id;
  final String planName;
  final DateTime completedAt;
  final int daysTaken;
  final DateTime? startDate;
  final DateTime? endDate;

  /// 절제 달성률 0~100
  final int restraintProgress;

  /// 목표 달성률 0~100
  final int targetProgress;

  /// 평균 저축률 0~100
  final int savingProgress;
  final Map<String, int> emotionCounts;
  final Map<String, double> categorySpending;

  /// 간단 일지: { date, totalAmount, emotion, comment }
  final List<Map<String, dynamic>> diaries;
  final String? averagePace;
  final int? averageDailySaving;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planName': planName,
      'completedAt': completedAt.toIso8601String(),
      'daysTaken': daysTaken,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'restraintProgress': restraintProgress,
      'targetProgress': targetProgress,
      'savingProgress': savingProgress,
      'emotionCounts': emotionCounts,
      'categorySpending': categorySpending,
      'diaries': diaries,
      'averagePace': averagePace,
      'averageDailySaving': averageDailySaving,
    };
  }

  /// 예시용 "세계여행" 지난 플랜 (total_plan 4카드와 동일한 데이터)
  static PastPlanSnapshot demoWorldTravel() {
    final now = DateTime.now();
    final completedAt = now.subtract(const Duration(days: 30));
    final startDate = now.subtract(const Duration(days: 210));
    final endDate = now.subtract(const Duration(days: 30));
    final totalDays = endDate.difference(startDate).inDays;

    return PastPlanSnapshot(
      id: 'demo_world_travel',
      planName: '세계여행',
      completedAt: completedAt,
      daysTaken: totalDays,
      startDate: startDate,
      endDate: endDate,
      restraintProgress: 76,
      targetProgress: 23,
      savingProgress: 68,
      emotionCounts: {'좋음': 15, '평온': 12, '슬픔': 5, '스트레스': 3, '동기부여': 2},
      categorySpending: {
        '식비': 450000,
        '교통비': 120000,
        '카페': 80000,
        '쇼핑': 200000,
        '여가': 150000,
      },
      diaries: [
        {
          'date': now.subtract(const Duration(days: 1)).toIso8601String(),
          'totalAmount': 35000,
          'emotion': '좋음',
          'comment': '오늘은 친구들과 맛있는 식사를 했다. 기분이 좋았다!',
        },
        {
          'date': now.subtract(const Duration(days: 2)).toIso8601String(),
          'totalAmount': 28000,
          'emotion': '평온',
          'comment': '평범하지만 만족스러운 하루였다.',
        },
        {
          'date': now.subtract(const Duration(days: 3)).toIso8601String(),
          'totalAmount': 42000,
          'emotion': '동기부여',
          'comment': '저축 목표 달성까지 조금 더 힘내자!',
        },
      ],
      averagePace: '0.35',
      averageDailySaving: 26190,
    );
  }

  static PastPlanSnapshot fromJson(Map<String, dynamic> json) {
    final diariesRaw = json['diaries'] as List<dynamic>? ?? [];
    return PastPlanSnapshot(
      id: json['id'] as String? ?? '',
      planName: json['planName'] as String? ?? '',
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
      daysTaken: (json['daysTaken'] as num?)?.toInt() ?? 0,
      startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
      restraintProgress: (json['restraintProgress'] as num?)?.toInt() ?? 0,
      targetProgress: (json['targetProgress'] as num?)?.toInt() ?? 0,
      savingProgress: (json['savingProgress'] as num?)?.toInt() ?? 0,
      emotionCounts:
          (json['emotionCounts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
          ) ??
          {},
      categorySpending:
          (json['categorySpending'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0),
          ) ??
          {},
      diaries: diariesRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      averagePace: json['averagePace'] as String?,
      averageDailySaving: (json['averageDailySaving'] as num?)?.toInt(),
    );
  }
}
