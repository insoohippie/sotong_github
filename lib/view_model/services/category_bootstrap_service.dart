//최초 플랜 저장 완료 후
//→ refCategories/recordSpending 문서 생성
//→ refCategories/recordAddIncome 문서 생성
//→ refCategories/planSpendingRegistry 문서 생성
//→ planSpendingRegistry에는 RefData의 하루소비 카테고리 entries를 저장


import '../../model/category/ref_category_item.dart';
import '../../model/refData/entry.dart';
import '../../model/refData/ref_data.dart';
import '../../repository/ref_category_repository.dart';
import '../../services/category_key.dart';

class CategoryBootstrapService {
  CategoryBootstrapService(this._refCategoryRepo);

  final RefCategoryRepository _refCategoryRepo;

  static const String recordSpendingDocId = 'recordSpending';
  static const String recordAddIncomeDocId = 'recordAddIncome';
  static const String planSpendingRegistryDocId = 'planSpendingRegistry';

  String _normalizeName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  String _fallbackEmojiByName(String name, {String fallback = '💰'}) {
    switch (name.trim()) {
      case '급여':
        return '💼';
      case '식비':
        return '🍽️';
      case '카페':
        return '☕';
      case '쇼핑':
        return '🛍️';
      case '여가':
        return '🎮';
      case '주거':
        return '🏠';
      case '통신':
        return '📱';
      case '교통':
        return '🚌';
      case '구독':
        return '📺';
      default:
        return fallback;
    }
  }

  List<RefCategoryItem> _normalizeOrders(List<RefCategoryItem> items) {
    final sorted = List<RefCategoryItem>.from(items)
      ..sort((a, b) => a.order.compareTo(b.order));

    return [
      for (int i = 0; i < sorted.length; i++)
        sorted[i].copyWith(order: i),
    ];
  }

  List<RefCategoryItem> _planRegistryItemsFromRefData(RefData refData) {
    final byKey = <String, RefCategoryItem>{};
    final nameToKey = <String, String>{};

    final dailyConsumes = refData.dailyConsumeMap.values.toList();

    dailyConsumes.sort((a, b) {
      final startCompare = a.startDate.compareTo(b.startDate);
      if (startCompare != 0) return startCompare;
      return a.id.compareTo(b.id);
    });

    for (final daily in dailyConsumes) {
      final entries = List<Entry>.from(daily.entries)
        ..sort((a, b) => a.order.compareTo(b.order));

      for (final entry in entries) {
        if (entry.type != EntryType.daily) continue;

        final name = entry.category.trim();
        if (name.isEmpty) continue;

        final normalizedName = _normalizeName(name);

        final resolvedKey = CategoryKey.isValid(entry.categoryKey)
            ? entry.categoryKey.trim()
            : nameToKey[normalizedName] ?? CategoryKey.newKey();

        final resolvedEmoji = entry.emoji.trim().isNotEmpty
            ? entry.emoji.trim()
            : _fallbackEmojiByName(name);

        final existingKeyForName = nameToKey[normalizedName];

        if (existingKeyForName != null) {
          final old = byKey[existingKeyForName];

          if (old != null) {
            byKey[existingKeyForName] = old.copyWith(
              name: name,
              emoji: resolvedEmoji,
              hidden: false,
            );
          }

          continue;
        }

        nameToKey[normalizedName] = resolvedKey;

        final existing = byKey[resolvedKey];

        if (existing != null) {
          byKey[resolvedKey] = existing.copyWith(
            name: name,
            emoji: resolvedEmoji,
            hidden: false,
          );
        } else {
          byKey[resolvedKey] = RefCategoryItem(
            categoryKey: resolvedKey,
            name: name,
            emoji: resolvedEmoji,
            order: byKey.length,
            hidden: false,
          );
        }
      }
    }

    return _normalizeOrders(byKey.values.toList());
  }

  List<RefCategoryItem> _mergeByKeyAndName({
    required List<RefCategoryItem> existing,
    required List<RefCategoryItem> incoming,
  }) {
    final result = <RefCategoryItem>[];
    final keyIndex = <String, int>{};
    final nameIndex = <String, int>{};

    void upsert(RefCategoryItem item) {
      final key = item.categoryKey.trim();
      final name = item.name.trim();
      if (!CategoryKey.isValid(key) || name.isEmpty) return;

      final normalizedName = _normalizeName(name);

      final existingByKey = keyIndex[key];
      if (existingByKey != null) {
        final old = result[existingByKey];

        result[existingByKey] = old.copyWith(
          name: name,
          emoji: item.emoji.trim().isNotEmpty ? item.emoji.trim() : old.emoji,
          hidden: false,
        );

        nameIndex[normalizedName] = existingByKey;
        return;
      }

      final existingByName = nameIndex[normalizedName];
      if (existingByName != null) {
        final old = result[existingByName];

        result[existingByName] = old.copyWith(
          name: name,
          emoji: item.emoji.trim().isNotEmpty ? item.emoji.trim() : old.emoji,
          hidden: false,
        );

        keyIndex[old.categoryKey] = existingByName;
        return;
      }

      final next = item.copyWith(
        order: result.length,
        hidden: false,
      );

      keyIndex[next.categoryKey] = result.length;
      nameIndex[normalizedName] = result.length;
      result.add(next);
    }

    for (final item in existing) {
      upsert(item);
    }

    for (final item in incoming) {
      upsert(item);
    }

    return _normalizeOrders(result);
  }

  Future<void> _ensureEmptyDoc(String docId) async {
    final existing = await _refCategoryRepo.fetchRefCategories(docId: docId);

    if (existing.isNotEmpty) {
      return;
    }

    await _refCategoryRepo.saveRefCategories(
      docId: docId,
      items: const [],
      markDirty: true,
    );
  }

  Future<void> bootstrapFromInitialPlanRefData(RefData refData) async {
    // 참고 소비 카테고리 문서 생성.
    // 최초 플랜 생성 시에는 비워둔다.
    await _ensureEmptyDoc(recordSpendingDocId);

    // 참고 수입 카테고리 문서 생성.
    // 최초 플랜 생성 시에는 비워둔다.
    await _ensureEmptyDoc(recordAddIncomeDocId);

    // 플랜 카테고리 registry 생성/보강.
    // 하루소비한도 entries에서 categoryKey/name/emoji를 가져온다.
    final existingRegistry = await _refCategoryRepo.fetchRefCategories(
      docId: planSpendingRegistryDocId,
    );

    final initialPlanItems = _planRegistryItemsFromRefData(refData);

    final mergedRegistry = _mergeByKeyAndName(
      existing: existingRegistry,
      incoming: initialPlanItems,
    );

    await _refCategoryRepo.saveRefCategories(
      docId: planSpendingRegistryDocId,
      items: mergedRegistry,
      markDirty: true,
    );
  }
}