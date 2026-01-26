import 'package:flutter/material.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/model/refData/entry.dart';

import 'category_utils.dart'; // 여기 안에 새로운 openCategorySheet / CatPreset 있음

enum ItemKind { daily, income, fixed }

class InputItemRow extends StatelessWidget {
  final ItemKind kind;
  final Entry item;

  final TextEditingController categoryController;
  final TextEditingController amountController;

  final void Function(int idx, String field, dynamic value) onUpdate;
  final void Function(int idx) onRemove;

  final List<CatPreset> presets;

  // ---- 카테고리 관련 ----
  final List<String>? customCategories;                    // 사용자 커스텀 카테고리 이름 리스트
  final Function(String)? onCustomCategoryAdded;           // 이름만 추가할 때
  final Function(String)? onCustomCategoryRemoved;         // 이름 삭제
  final Function(String, String)? onCustomCategoryAddedWithEmoji; // (이름, 이모지) 같이 추가
  final Map<String, String>? categoryEmojis;               // {카테고리명: 이모지}

  /// 👉 새로 추가: 정렬 결과 콜백 (선택)
  final void Function(List<String> newOrder)? onCategoryOrderChanged;

  // ---- 금액/표시 관련 ----
  final String? amountHint;        // 기본 힌트 텍스트
  final bool showMonthlyHint;      // daily일 때 월환산 안내 표시 여부
  final bool isOverBudget;         // 예산 초과 여부(행 강조용)

  const InputItemRow({
    Key? key,
    required this.kind,
    required this.item,
    required this.categoryController,
    required this.amountController,
    required this.onUpdate,
    required this.onRemove,
    required this.presets,
    this.customCategories,
    this.onCustomCategoryAdded,
    this.onCustomCategoryRemoved,
    this.onCustomCategoryAddedWithEmoji,
    this.categoryEmojis,
    this.onCategoryOrderChanged,
    this.amountHint,
    this.showMonthlyHint = true,
    this.isOverBudget = false,
  }) : super(key: key);

  // ---------- 카테고리별 기본 힌트 ----------

  Map<String, String> get _incomeHints => const {
    '급여': '2,500,000원',
    '부업·아르바이트': '300,000원',
    '금융소득': '50,000원',
  };

  Map<String, String> get _fixedHints => const {
    '주거비': '600,000원',
    '통신비': '100,000원',
    '보험료': '150,000원',
  };

  Map<String, String> get _dailyHints => const {
    '식비': '15,000원',
    '교통비': '1,500원',
    '쇼핑': '10,000원',
  };

  // ---------- 숫자 포맷 유틸 ----------

  String _un(String v) => v.replaceAll(',', '');
  String _comma(String v) {
    if (v.isEmpty) return '';
    final n = int.tryParse(_un(v));
    if (n == null) return '';
    return n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
    );
  }

  String _dynamicAmountHint() {
    final cat = categoryController.text.trim();
    final map = switch (kind) {
      ItemKind.income => _incomeHints,
      ItemKind.fixed => _fixedHints,
      ItemKind.daily => _dailyHints,
    };

    if (cat.isNotEmpty && map.containsKey(cat)) {
      return '예: ${map[cat]}';
    }
    return amountHint ?? '예: 1,000,000원';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDaily = kind == ItemKind.daily;

    final raw = _un(amountController.text);
    final double value = double.tryParse(raw) ?? 0.0;
    final int monthly = isDaily ? (value * 30).round() : 0;

    // ✅ “입력이 있는 행”만 붉게
    final bool hasInput =
        categoryController.text.trim().isNotEmpty || value > 0.0;

    final Color? fieldBg =
    (isOverBudget && hasInput) ? const Color(0xFFFFF1F1) : null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Dismissible(
            key: ValueKey('row_${item.idx}'),
            direction: DismissDirection.endToStart,
            background: _swipeBg(Alignment.centerRight),
            onDismissed: (_) => onRemove(item.idx),
            child: Row(
              children: [
                // ✅ 카테고리 Pill
                Expanded(
                  flex: 2,
                  child: _buildCategoryPill(context),
                ),
                const SizedBox(width: 10),

                // 금액 입력
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    controller: amountController,
                    hintText: _dynamicAmountHint(),
                    keyboardType: TextInputType.number,
                    borderRadius: 12,
                    height: 60,
                    backgroundColor: fieldBg,
                    onChanged: (v) {
                      final un = _un(v);
                      final amt = double.tryParse(un) ?? 0.0;
                      onUpdate(item.idx, 'amount', amt);

                      final formatted = _comma(un);
                      if (formatted != v) {
                        amountController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // 일일 → 월환산 안내문
          if (isDaily && showMonthlyHint && value > 0.0)
            const SizedBox(height: 6),
          if (isDaily && showMonthlyHint && value > 0.0)
            Row(
              children: [
                const Text(
                  '30일 기준, 한 달에 ',
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                Text(
                  '${_comma(monthly.toString())}원',
                  style: const TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  ' 이에요.',
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// 카테고리 Pill + 바텀시트 오픈 로직 분리
  Widget _buildCategoryPill(BuildContext context) {
    // 1) 프리셋 이름 리스트
    final presetNames = presets.map((p) => p.name).toList();

    // 2) 커스텀 카테고리 (nullable 안전 처리)
    final custom = customCategories ?? const <String>[];

    // 3) 프리셋 + 커스텀 이름 통합 (중복 제거)
    final allNames = <String>{
      ...presetNames,
      ...custom,
    }.toList();

    // 4) 이모지 맵 (없으면 빈 맵)
    final emojiMap = categoryEmojis ?? const <String, String>{};

    final bool hasInput =
        categoryController.text.trim().isNotEmpty ||
            (double.tryParse(_un(amountController.text)) ?? 0.0) > 0.0;

    return CategoryPill(
      text: categoryController.text,
      presets: presets, // Pill 왼쪽 아이콘용 (예전대로)
      onTap: () {
        openCategorySheet(
          context,
          categoryController,
              (val) => onUpdate(item.idx, 'category', val),

          /// 새 구조로 변경된 파라미터들
          categories: allNames,
          categoryEmojis: emojiMap,

          // ✅ 새 카테고리 추가될 때: (이름, 이모지)
          onCategoryAdded: (name, emoji) {
            // ViewModel에서 (name, emoji)로 받고 싶으면 이 콜백을 연결해주면 됨
            if (onCustomCategoryAddedWithEmoji != null) {
              onCustomCategoryAddedWithEmoji!(name, emoji);
            } else if (onCustomCategoryAdded != null) {
              // 이모지 신경 안 쓰는 쪽(수입/고정 등)은 이름만 저장
              onCustomCategoryAdded!(name);
            }
          },

          // ✅ 카테고리 삭제될 때
          onCategoryRemoved: (name) {
            if (onCustomCategoryRemoved != null) {
              onCustomCategoryRemoved!(name);
            }
          },

          // ✅ 순서 변경 후 최종 리스트 올라감
          onReorder: (newOrder) {
            if (onCategoryOrderChanged != null) {
              onCategoryOrderChanged!(newOrder);
            }
          },
        );
      },
      onClear: () {
        categoryController.clear();
        onUpdate(item.idx, 'category', '');
      },
      height: 60,
      highlight: isOverBudget && hasInput,
      customEmoji: emojiMap[categoryController.text.trim()],
    );
  }

  Widget _swipeBg(AlignmentGeometry align) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.redAccent),
    );
  }
}
