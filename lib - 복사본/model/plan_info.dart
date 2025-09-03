import 'ref_data.dart';

class PlanInfo {
  String? planName;
  String? purpose;
  double? targetAmount; // 목표 금액
  double currentAmount; // 저축 금액
  double currentAsset; // 기존 자산
  DateTime? startDate;
  bool? autoService; // 자동 서비스 활성화 여부

  double? fixedIncomeSum;
  double? fixedConsumptionSum;
  double? dailyConsumptionSum;
  double? variableConsumptionSum;

  /*
  // 금액 관련(추후 날짜 계산 위해) => 어느 타이밍에 저장되는가?
  // 매 순간 RefData에서 연산하는 것 보다 이게 더 싸게 먹힐 듯
  // refData에서 참고하여 업데이트 하는 함수
  // => 결국 viewModel에서 각각의 비즈니스 로직 파트가 합쳐져야겠구나. 이 객체들이 해당 페이지에서 활용되는걸로 끝이 아니기 때문

  // amount가 필요한 이유 : ref_data를 전부 load하는 비효율 방지 위해
  int fixedIncomeAmount;
  int fixedConsumptionAmount;
  int additionalIncomeAmount;
  int additionalConsumptionAmount;

  // 날짜 관련
  DateTime? startDate;
  DateTime? endDate;
  DateTime? modEndDate;
  DateTime createdAt;
  DateTime? now;

  int get dDay {
    final referenceDate = modEndDate ?? endDate;
    if (referenceDate == null || now == null) return 0;
    return referenceDate.difference(now!).inDays;
  }
   */

  PlanInfo({
    this.planName,
    this.purpose,
    this.targetAmount,
    this.currentAmount = 0,
    this.currentAsset = 0,
    this.autoService,
    this.fixedIncomeSum,
    this.fixedConsumptionSum,
    this.dailyConsumptionSum,
    this.variableConsumptionSum,
    DateTime? planStartDate,
  }) : startDate = planStartDate ?? DateTime.now();

  /*
  PlanInfo({
    this.planName = '',
    this.purpose = '',
    this.targetAmount = 0,
    this.currentAmount = 0,
    this.currentAsset = 0,

    this.fixedIncomeSum = 0,
    this.fixedConsumptionSum = 0,
    this.dailyConsumptionSum = 0,
    this.variableConsumptionSum = 0,
    DateTime? planStartDate,
  }) : startDate = planStartDate ?? DateTime.now();
   */

  // ✅ Firestore 저장용
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'planName': planName,
      'purpose': purpose,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'currentAsset': currentAsset,
      'startDate': startDate?.toIso8601String(),
      'autoService': autoService,
      'fixedIncomeSum': fixedIncomeSum,
      'fixedConsumptionSum': fixedConsumptionSum,
      'dailyConsumptionSum': dailyConsumptionSum,
      'variableConsumptionSum': variableConsumptionSum,
    };

    return map;
  }

  // ✅ Firestore 로드용(옵션)
  factory PlanInfo.fromMap(Map<String, dynamic> map) {
    return PlanInfo(
      planName: map['planName'] as String?,
      purpose: map['purpose'] as String?,
      targetAmount: (map['targetAmount'] as num?)?.toDouble(),
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0,
      currentAsset: (map['currentAsset'] as num?)?.toDouble() ?? 0,
      autoService: map['autoService'] as bool?,
      fixedIncomeSum: (map['fixedIncomeSum'] as num?)?.toDouble(),
      fixedConsumptionSum: (map['fixedConsumptionSum'] as num?)?.toDouble(),
      dailyConsumptionSum: (map['dailyConsumptionSum'] as num?)?.toDouble(),
      variableConsumptionSum: (map['variableConsumptionSum'] as num?)?.toDouble(),
      planStartDate: _parseDate(map['startDate']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    // Firestore Timestamp로 온 경우 대응
    try {
      // ignore: avoid_dynamic_calls
      return (v as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() {
    return '''
    PlanInfo(
      planName: $planName,
      purpose: $purpose,
      targetAmount: $targetAmount,
      currentAsset: $currentAsset,
      currentAmount: $currentAmount,
      startDate: $startDate
    )
    ''';
  }
}
