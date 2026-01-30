import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_meta_item.dart';

class CategoryPlanMetaDoc {
  final String id;
  final DateTime applyDate;
  final DateTime endDate;
  final List<CategoryMetaItem> planMeta;
  final bool isActive;
  final DateTime? endedAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoryPlanMetaDoc({
    required this.id,
    required this.applyDate,
    required this.endDate,
    required this.planMeta,
    this.isActive = true,
    this.endedAt,
    this.createdAt,
    this.updatedAt,
  });

  static DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _tsToDay(dynamic v) {
    if (v is Timestamp) {
      return _normalizeDay(v.toDate());
    }
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return _normalizeDay(parsed);
    }
    final now = DateTime.now();
    return _normalizeDay(now);
  }

  factory CategoryPlanMetaDoc.fromFirestore(
      String id,
      Map<String, dynamic> map,
      ) {
    final apply = _tsToDay(map['applyDate']);
    final end = _tsToDay(map['endDate']);

    final items = (map['planMeta'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CategoryMetaItem.fromMap)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final endedAtRaw = map['endedAt'];
    DateTime? endedAt;
    if (endedAtRaw != null) {
      endedAt = _tsToDay(endedAtRaw);
    }

    return CategoryPlanMetaDoc(
      id: id,
      applyDate: apply,
      endDate: end,
      planMeta: items,
      isActive: map['isActive'] as bool? ?? true,
      endedAt: endedAt,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'applyDate': Timestamp.fromDate(_normalizeDay(applyDate)),
    'endDate': Timestamp.fromDate(_normalizeDay(endDate)),
    'planMeta': planMeta.map((e) => e.toMap()).toList(),
    'isActive': isActive,
    'endedAt': endedAt != null ? Timestamp.fromDate(_normalizeDay(endedAt!)) : null,
  };
}
