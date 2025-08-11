class EmotionSpendingDiary {
  final DateTime date;
  final String emotion;
  final String emotionAnimation;
  final double spendingAmount;
  final String spendingDescription;
  final String memo;

  EmotionSpendingDiary({
    required this.date,
    required this.emotion,
    required this.emotionAnimation,
    required this.spendingAmount,
    required this.spendingDescription,
    required this.memo,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'emotion': emotion,
      'emotionAnimation': emotionAnimation,
      'spendingAmount': spendingAmount,
      'spendingDescription': spendingDescription,
      'memo': memo,
    };
  }

  factory EmotionSpendingDiary.fromJson(Map<String, dynamic> json) {
    return EmotionSpendingDiary(
      date: DateTime.parse(json['date']),
      emotion: json['emotion'],
      emotionAnimation: json['emotionAnimation'],
      spendingAmount: json['spendingAmount'].toDouble(),
      spendingDescription: json['spendingDescription'],
      memo: json['memo'],
    );
  }
}
