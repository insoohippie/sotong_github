// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../component/theme/app_colors.dart';
// import '../../component/theme/app_text_styles.dart';
// import '../../component/inputs/custom_text_field.dart';
// import '../../component/buttons/custom_button.dart';
//
// /// 카테고리 편집 페이지
// /// 플랜 카테고리: 일일 소비한도 금액이 지정된 카테고리 (최대 5개)
// /// 참고 카테고리: 금액이 없는 카테고리 (최대 10개)
// class CategoryEditPage extends StatefulWidget {
//   const CategoryEditPage({super.key});
//
//   @override
//   State<CategoryEditPage> createState() => _CategoryEditPageState();
// }
//
// class _CategoryEditPageState extends State<CategoryEditPage>
//     with SingleTickerProviderStateMixin {
//   // 카테고리 개수 제한
//   static const int _maxPlanCategories = 5; // 플랜 카테고리 최대 개수
//   static const int _maxReferenceCategories = 10; // 참고 카테고리 최대 개수
//
//   // 카테고리 데이터 (메모리에서 관리)
//   List<EditableCategory> _categoryA = [];
//   List<EditableCategory> _categoryB = [];
//
//   // 플랜 목표값 (TODO: 실제 데이터 소스와 연동 필요)
//   double _targetAmount = 500000.0; // 예시: 50만원
//
//   // 모달 상태
//   bool _showNameModal = false;
//   bool _showAmountModal = false;
//   bool _showDateModal = false;
//   String? _editingCategoryId;
//   String? _editingCategoryName;
//   int? _editingCategoryAmount;
//   String? _editingCategoryEmoji;
//   bool _isAddingPlanCategory = false; // 플랜 카테고리 추가 중인지 여부
//
//   // 드래그 상태
//   bool _isDragging = false;
//
//   // 선택된 날짜
//   DateTime _selectedDate = DateTime.now();
//
//   @override
//   void initState() {
//     super.initState();
//     _loadInitialData();
//   }
//
//   /// 초기 데이터 로드 (TODO: CategoryRepository와 연동)
//   void _loadInitialData() {
//     // 예시 데이터
//     setState(() {
//       _categoryA = [
//         EditableCategory(
//           id: 'cat_a_1',
//           name: '식비',
//           emoji: '🍕',
//           dailyAmount: 10000,
//           sortOrder: 0,
//         ),
//         EditableCategory(
//           id: 'cat_a_2',
//           name: '교통비',
//           emoji: '🚗',
//           dailyAmount: 2000,
//           sortOrder: 1,
//         ),
//       ];
//       _categoryB = [
//         EditableCategory(
//           id: 'cat_b_1',
//           name: '카페',
//           emoji: '☕',
//           dailyAmount: null,
//           sortOrder: 0,
//         ),
//         EditableCategory(
//           id: 'cat_b_2',
//           name: '쇼핑',
//           emoji: '🛍️',
//           dailyAmount: null,
//           sortOrder: 1,
//         ),
//       ];
//     });
//   }
//
//   /// 플랜 카테고리의 일일금액 합계
//   int get _dailyLimitSum {
//     return _categoryA
//         .map((c) => c.dailyAmount ?? 0)
//         .fold(0, (sum, amount) => sum + amount);
//   }
//
//   /// 플랜 도달일 계산
//   PlanProgressInfo get _planProgress {
//     if (_dailyLimitSum == 0) {
//       return PlanProgressInfo(
//         dailyLimitSum: 0,
//         daysToReach: null,
//         reachDate: null,
//       );
//     }
//
//     final daysToReach = (_targetAmount / _dailyLimitSum).ceil();
//     final reachDate = DateTime.now().add(Duration(days: daysToReach));
//
//     return PlanProgressInfo(
//       dailyLimitSum: _dailyLimitSum,
//       daysToReach: daysToReach,
//       reachDate: reachDate,
//     );
//   }
//
//   /// 카테고리 추가
//   void _addCategory({bool isCategoryA = false}) {
//     // 개수 제한 체크
//     if (isCategoryA && _categoryA.length >= _maxPlanCategories) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('플랜 카테고리는 최대 $_maxPlanCategories개까지 생성할 수 있습니다.'),
//           duration: const Duration(seconds: 2),
//         ),
//       );
//       return;
//     }
//     if (!isCategoryA && _categoryB.length >= _maxReferenceCategories) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('참고 카테고리는 최대 $_maxReferenceCategories개까지 생성할 수 있습니다.'),
//           duration: const Duration(seconds: 2),
//         ),
//       );
//       return;
//     }
//
//     setState(() {
//       _editingCategoryId = null;
//       _editingCategoryName = null;
//       _editingCategoryAmount = isCategoryA ? 0 : null;
//       _editingCategoryEmoji = '💰';
//       _isAddingPlanCategory = isCategoryA;
//       _showNameModal = true;
//     });
//   }
//
//   /// 카테고리 이름 모달에서 완료 (이모지 포함)
//   void _onNameModalComplete(String name, String emoji) {
//     if (name.trim().isEmpty) return;
//
//     setState(() {
//       _showNameModal = false;
//     });
//
//     if (_editingCategoryId == null) {
//       // 새 카테고리 추가 - 중복 체크
//       final trimmedName = name.trim();
//       final isDuplicate =
//           _categoryA.any((c) => c.name == trimmedName) ||
//               _categoryB.any((c) => c.name == trimmedName);
//
//       if (isDuplicate) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('이미 "$trimmedName"이라는 이름의 카테고리가 있습니다.'),
//             duration: const Duration(seconds: 2),
//           ),
//         );
//         return;
//       }
//
//       // 새 카테고리 추가
//       final newCategory = EditableCategory(
//         id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
//         name: trimmedName,
//         emoji: emoji,
//         dailyAmount: _editingCategoryAmount,
//         sortOrder: _editingCategoryAmount != null
//             ? _categoryA.length
//             : _categoryB.length,
//       );
//
//       setState(() {
//         if (_editingCategoryAmount != null) {
//           _categoryA.add(newCategory);
//         } else {
//           _categoryB.add(newCategory);
//         }
//       });
//
//       // 플랜 카테고리로 추가했고 금액이 0이면 금액 입력 요청
//       if (_isAddingPlanCategory && _editingCategoryAmount == 0) {
//         _editingCategoryId = newCategory.id;
//         _editingCategoryName = newCategory.name;
//         _editingCategoryAmount = 0;
//         setState(() {
//           _showAmountModal = true;
//         });
//       }
//     } else {
//       // 기존 카테고리 이름 수정
//       setState(() {
//         if (_editingCategoryAmount != null) {
//           final index = _categoryA.indexWhere(
//                 (c) => c.id == _editingCategoryId,
//           );
//           if (index != -1) {
//             _categoryA[index] = _categoryA[index].copyWith(
//               name: name.trim(),
//               emoji: emoji,
//             );
//           }
//         } else {
//           final index = _categoryB.indexWhere(
//                 (c) => c.id == _editingCategoryId,
//           );
//           if (index != -1) {
//             _categoryB[index] = _categoryB[index].copyWith(
//               name: name.trim(),
//               emoji: emoji,
//             );
//           }
//         }
//       });
//     }
//   }
//
//   /// 카테고리 이름 수정
//   void _editCategoryName(EditableCategory category) {
//     setState(() {
//       _editingCategoryId = category.id;
//       _editingCategoryName = category.name;
//       _editingCategoryAmount = category.dailyAmount;
//       _editingCategoryEmoji = category.emoji;
//       _isAddingPlanCategory = category.dailyAmount != null;
//       _showNameModal = true;
//     });
//   }
//
//   /// 카테고리 금액 수정 (플랜 카테고리만)
//   void _editCategoryAmount(EditableCategory category) {
//     if (category.dailyAmount == null) return;
//
//     setState(() {
//       _editingCategoryId = category.id;
//       _editingCategoryName = category.name;
//       _editingCategoryAmount = category.dailyAmount ?? 0;
//       _showAmountModal = true;
//     });
//   }
//
//   /// 카테고리 금액 모달에서 완료
//   void _onAmountModalComplete(int amount) {
//     if (amount < 0) return;
//
//     setState(() {
//       _showAmountModal = false;
//       final index = _categoryA.indexWhere((c) => c.id == _editingCategoryId);
//       if (index != -1) {
//         _categoryA[index] = _categoryA[index].copyWith(dailyAmount: amount);
//       }
//     });
//   }
//
//   // 사용되지 않는 함수 제거됨 (섹션 간 이동은 직접 처리)
//
//   /// 카테고리 삭제
//   Future<void> _deleteCategory(EditableCategory category) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text(
//           '카테고리 삭제',
//           style: TextStyle(fontFamily: 'Pretendard'),
//         ),
//         content: Text(
//           '${category.name}을(를) 삭제하시겠어요?',
//           style: const TextStyle(fontFamily: 'Pretendard'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('취소', style: TextStyle(fontFamily: 'Pretendard')),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text(
//               '삭제',
//               style: TextStyle(fontFamily: 'Pretendard', color: Colors.red),
//             ),
//           ),
//         ],
//       ),
//     );
//
//     if (confirmed != true) return;
//
//     setState(() {
//       if (category.dailyAmount != null) {
//         _categoryA.removeWhere((c) => c.id == category.id);
//         // sortOrder 재정렬
//         for (int i = 0; i < _categoryA.length; i++) {
//           _categoryA[i] = _categoryA[i].copyWith(sortOrder: i);
//         }
//       } else {
//         _categoryB.removeWhere((c) => c.id == category.id);
//         // sortOrder 재정렬
//         for (int i = 0; i < _categoryB.length; i++) {
//           _categoryB[i] = _categoryB[i].copyWith(sortOrder: i);
//         }
//       }
//     });
//   }
//
//   /// 플랜 카테고리에서 참고 카테고리로 이동
//   Future<void> _moveAToB(EditableCategory category, int newIndex) async {
//     // 개수 제한 체크
//     if (_categoryB.length >= _maxReferenceCategories) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('참고 카테고리는 최대 $_maxReferenceCategories개까지 생성할 수 있습니다.'),
//           duration: const Duration(seconds: 2),
//         ),
//       );
//       return;
//     }
//     setState(() {
//       _categoryA.removeWhere((c) => c.id == category.id);
//       final movedCategory = category.copyWith(
//         dailyAmount: null,
//         sortOrder: newIndex,
//       );
//       _categoryB.insert(newIndex, movedCategory);
//
//       // sortOrder 재정렬
//       for (int i = 0; i < _categoryA.length; i++) {
//         _categoryA[i] = _categoryA[i].copyWith(sortOrder: i);
//       }
//       for (int i = 0; i < _categoryB.length; i++) {
//         _categoryB[i] = _categoryB[i].copyWith(sortOrder: i);
//       }
//     });
//   }
//
//   /// 참고 카테고리에서 플랜 카테고리로 이동
//   Future<void> _moveBToA(EditableCategory category, int newIndex) async {
//     // 개수 제한 체크
//     if (_categoryA.length >= _maxPlanCategories) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('플랜 카테고리는 최대 $_maxPlanCategories개까지 생성할 수 있습니다.'),
//           duration: const Duration(seconds: 2),
//         ),
//       );
//       return;
//     }
//     setState(() {
//       _categoryB.removeWhere((c) => c.id == category.id);
//       final movedCategory = category.copyWith(
//         dailyAmount: 0, // 기본값 0으로 설정
//         sortOrder: newIndex,
//       );
//       _categoryA.insert(newIndex, movedCategory);
//
//       // sortOrder 재정렬
//       for (int i = 0; i < _categoryA.length; i++) {
//         _categoryA[i] = _categoryA[i].copyWith(sortOrder: i);
//       }
//       for (int i = 0; i < _categoryB.length; i++) {
//         _categoryB[i] = _categoryB[i].copyWith(sortOrder: i);
//       }
//     });
//
//     // 금액 입력 요청
//     if (mounted) {
//       _editCategoryAmount(_categoryA[newIndex]);
//     }
//   }
//
//   /// 섹션 내 순서 변경
//   void _reorderWithinSection(
//       List<EditableCategory> list,
//       int oldIndex,
//       int newIndex,
//       ) {
//     if (oldIndex < newIndex) {
//       newIndex -= 1;
//     }
//
//     setState(() {
//       final item = list.removeAt(oldIndex);
//       list.insert(newIndex, item);
//
//       // sortOrder 재정렬
//       for (int i = 0; i < list.length; i++) {
//         list[i] = list[i].copyWith(sortOrder: i);
//       }
//     });
//   }
//
//   /// 저장 (TODO: CategoryRepository와 연동)
//   Future<void> _save() async {
//     // TODO: CategoryRepository.saveCategoryList() 호출
//     // 현재는 메모리에서만 관리
//
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('카테고리가 저장되었습니다.'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//       Navigator.pop(context);
//     }
//   }
//
//   /// 금액 포맷팅 (#,###원)
//   String _formatAmount(int amount) {
//     return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const SizedBox.shrink(),
//         centerTitle: false,
//         actions: const [],
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               // 카테고리 리스트 영역
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       // 플랜 카테고리 섹션
//                       if (_categoryA.isNotEmpty) ...[
//                         // 날짜 선택기
//                         _buildDateSelector(),
//                         _buildCategorySection(
//                           title: '플랜 카테고리',
//                           categories: _categoryA,
//                           isCategoryA: true,
//                         ),
//                         // 플랜 도달일 정보 (플랜 카테고리 하단, 참고 카테고리 상단 사이)
//                         _buildPlanProgressInfo(),
//                         // 플랜 카테고리 추가 버튼 (플랜 진행 정보 컨테이너 아래)
//                         _buildAddCategoryButton(isCategoryA: true),
//                         const Divider(height: 1, thickness: 1),
//                       ],
//
//                       // 참고 카테고리 섹션
//                       if (_categoryB.isNotEmpty)
//                         _buildCategorySection(
//                           title: '참고 카테고리',
//                           categories: _categoryB,
//                           isCategoryA: false,
//                         )
//                       else if (_categoryA.isNotEmpty)
//                       // 참고 카테고리가 비어있을 때도 드롭 존 표시
//                         _buildEmptySectionDropZone(isCategoryA: false),
//
//                       // 빈 상태 처리
//                       if (_categoryA.isEmpty && _categoryB.isEmpty)
//                         Padding(
//                           padding: const EdgeInsets.all(40),
//                           child: Text(
//                             '카테고리가 없습니다.\n아래 버튼으로 추가해주세요.',
//                             textAlign: TextAlign.center,
//                             style: AppTextStyles.subtext.copyWith(
//                               color: AppColors.subText,
//                             ),
//                           ),
//                         ),
//
//                       const SizedBox(height: 80), // 하단 버튼 공간
//                     ],
//                   ),
//                 ),
//               ),
//
//               // 하단 정보 및 버튼 영역
//               _buildBottomSection(),
//             ],
//           ),
//           // 모달들
//           if (_showNameModal)
//             _CategoryNameModal(
//               isOpen: _showNameModal,
//               onClose: () => setState(() => _showNameModal = false),
//               initialName: _editingCategoryName,
//               initialEmoji: _editingCategoryEmoji,
//               onComplete: _onNameModalComplete,
//             ),
//           if (_showAmountModal)
//             _CategoryAmountModal(
//               isOpen: _showAmountModal,
//               onClose: () => setState(() => _showAmountModal = false),
//               initialAmount: _editingCategoryAmount ?? 0,
//               onComplete: _onAmountModalComplete,
//             ),
//           if (_showDateModal)
//             _DatePickerModal(
//               isOpen: _showDateModal,
//               onClose: () => setState(() => _showDateModal = false),
//               initialDate: _selectedDate,
//               onDateSelected: (date) {
//                 setState(() {
//                   _selectedDate = date;
//                   _showDateModal = false;
//                 });
//               },
//             ),
//         ],
//       ),
//     );
//   }
//
//   /// 날짜 선택기 빌드
//   Widget _buildDateSelector() {
//     final formattedDate = '${_selectedDate.month}월 ${_selectedDate.day}일';
//
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // 이전 날짜 버튼
//           IconButton(
//             onPressed: () {
//               setState(() {
//                 _selectedDate = _selectedDate.subtract(const Duration(days: 1));
//               });
//             },
//             icon: const Icon(Icons.chevron_left, color: AppColors.subText),
//             padding: EdgeInsets.zero,
//             constraints: const BoxConstraints(),
//           ),
//           const SizedBox(width: 16),
//           // 날짜 표시 및 선택 버튼
//           GestureDetector(
//             onTap: () {
//               setState(() {
//                 _showDateModal = true;
//               });
//             },
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.transparent,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 formattedDate,
//                 style: AppTextStyles.paragraph.copyWith(
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
//           // 다음 날짜 버튼
//           IconButton(
//             onPressed: () {
//               setState(() {
//                 _selectedDate = _selectedDate.add(const Duration(days: 1));
//               });
//             },
//             icon: const Icon(Icons.chevron_right, color: AppColors.subText),
//             padding: EdgeInsets.zero,
//             constraints: const BoxConstraints(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// 카테고리 섹션 빌드
//   Widget _buildCategorySection({
//     required String title,
//     required List<EditableCategory> categories,
//     required bool isCategoryA,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: AppTextStyles.subtext.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               // 플랜 카테고리 설명
//               if (isCategoryA) ...[
//                 Text(
//                   '카테고리에 일일소비예산을 설정할 수 있습니다. (최대 $_maxPlanCategories개)',
//                   style: AppTextStyles.subtext.copyWith(
//                     color: AppColors.subText,
//                     fontSize: 13,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   '• 레포트 페이지에서 해당 카테고리로 자세한 분석을 받아볼 수 있습니다.',
//                   style: AppTextStyles.subtext.copyWith(
//                     color: AppColors.subText,
//                     fontSize: 13,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   '• 플랜 도달일자에 집계되는 소비입니다.',
//                   style: AppTextStyles.subtext.copyWith(
//                     color: AppColors.subText,
//                     fontSize: 13,
//                   ),
//                 ),
//               ] else ...[
//                 // 참고 카테고리 설명
//                 Text(
//                   '매일사용하진 않지만, 자주사용하는 카테고리입니다. (최대 $_maxReferenceCategories개)',
//                   style: AppTextStyles.subtext.copyWith(
//                     color: AppColors.subText,
//                     fontSize: 13,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   '• 레포트 페이지나, 플랜도달일자에 적용되지 않습니다.',
//                   style: AppTextStyles.subtext.copyWith(
//                     color: AppColors.subText,
//                     fontSize: 13,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//         // 다른 섹션으로 드롭 가능한 영역 (섹션 상단)
//         _buildDropZone(
//           isCategoryA: isCategoryA,
//           onDrop: (category) async {
//             if (isCategoryA) {
//               await _moveBToA(category, 0);
//             } else {
//               await _moveAToB(category, 0);
//             }
//           },
//         ),
//         // 카테고리 리스트
//         ...categories.asMap().entries.expand((entry) {
//           final index = entry.key;
//           final category = entry.value;
//           return [
//             // 아이템 위 드롭 영역 (같은 섹션 내 순서 변경 및 섹션 간 이동용)
//             _buildItemDropZone(
//               isCategoryA: isCategoryA,
//               targetIndex: index,
//               onDrop: (data) {
//                 if (data.id != category.id) {
//                   final isSameSection =
//                       (data.dailyAmount == null) == (!isCategoryA);
//                   if (isSameSection) {
//                     // 같은 섹션 내 순서 변경
//                     final oldIndex = categories.indexWhere(
//                           (c) => c.id == data.id,
//                     );
//                     if (oldIndex != -1) {
//                       _reorderWithinSection(categories, oldIndex, index);
//                     }
//                   } else {
//                     // 다른 섹션으로 이동
//                     if (isCategoryA) {
//                       _moveBToA(data, index);
//                     } else {
//                       _moveAToB(data, index);
//                     }
//                   }
//                 }
//               },
//             ),
//             _CategoryItem(
//               key: ValueKey(category.id),
//               category: category,
//               isCategoryA: isCategoryA,
//               itemIndex: index,
//               categories: categories,
//               onEditName: () => _editCategoryName(category),
//               onEditAmount: isCategoryA
//                   ? () => _editCategoryAmount(category)
//                   : null,
//               onDelete: () => _deleteCategory(category),
//               formatAmount: _formatAmount,
//               onDragStart: () {
//                 setState(() {
//                   _isDragging = true;
//                 });
//               },
//               onDragEnd: () {
//                 setState(() {
//                   _isDragging = false;
//                 });
//               },
//             ),
//           ];
//         }).toList(),
//         // 마지막 아이템 아래 드롭 영역
//         if (categories.isNotEmpty)
//           _buildItemDropZone(
//             isCategoryA: isCategoryA,
//             targetIndex: categories.length,
//             onDrop: (data) {
//               final isSameSection =
//                   (data.dailyAmount == null) == (!isCategoryA);
//               if (isSameSection) {
//                 // 같은 섹션 내 순서 변경
//                 final oldIndex = categories.indexWhere((c) => c.id == data.id);
//                 if (oldIndex != -1) {
//                   _reorderWithinSection(
//                     categories,
//                     oldIndex,
//                     categories.length,
//                   );
//                 }
//               } else {
//                 // 다른 섹션으로 이동
//                 if (isCategoryA) {
//                   _moveBToA(data, categories.length);
//                 } else {
//                   _moveAToB(data, categories.length);
//                 }
//               }
//             },
//           ),
//         // 다른 섹션으로 드롭 가능한 영역 (섹션 하단)
//         _buildDropZone(
//           isCategoryA: isCategoryA,
//           onDrop: (category) async {
//             if (isCategoryA) {
//               await _moveBToA(category, _categoryA.length);
//             } else {
//               await _moveAToB(category, _categoryB.length);
//             }
//           },
//         ),
//         // 참고 카테고리 섹션에만 추가 버튼 표시
//         if (!isCategoryA) _buildAddCategoryButton(isCategoryA: false),
//       ],
//     );
//   }
//
//   /// 아이템 사이 드롭 존 빌드 (순서 변경 및 섹션 간 이동용)
//   Widget _buildItemDropZone({
//     required bool isCategoryA,
//     required int targetIndex,
//     required void Function(EditableCategory) onDrop,
//   }) {
//     return DragTarget<EditableCategory>(
//       onWillAccept: (data) {
//         if (data == null) return false;
//         // 모든 드롭 허용 (같은 섹션 내 순서 변경 또는 섹션 간 이동)
//         return true;
//       },
//       onAccept: (data) {
//         onDrop(data);
//       },
//       builder: (context, candidateData, rejectedData) {
//         final isHighlighted = candidateData.isNotEmpty;
//         final shouldShow = isHighlighted || _isDragging;
//         return Container(
//           height: isHighlighted ? 12 : (shouldShow ? 6 : 4),
//           margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//           decoration: BoxDecoration(
//             color: isHighlighted
//                 ? AppColors.primary
//                 : (shouldShow
//                 ? Colors.grey.withOpacity(0.3)
//                 : Colors.transparent),
//             borderRadius: BorderRadius.circular(2),
//           ),
//         );
//       },
//     );
//   }
//
//   /// 빈 섹션 드롭 존 빌드
//   Widget _buildEmptySectionDropZone({required bool isCategoryA}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
//           child: Text(
//             isCategoryA ? '플랜 카테고리' : '참고 카테고리',
//             style: AppTextStyles.subtext.copyWith(
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//         ),
//         _buildDropZone(
//           isCategoryA: isCategoryA,
//           onDrop: (category) async {
//             if (isCategoryA) {
//               await _moveBToA(category, 0);
//             } else {
//               await _moveAToB(category, 0);
//             }
//           },
//         ),
//         Padding(
//           padding: const EdgeInsets.all(40),
//           child: Text(
//             '카테고리를 드래그하여 추가하세요.',
//             textAlign: TextAlign.center,
//             style: AppTextStyles.subtext.copyWith(color: AppColors.subText),
//           ),
//         ),
//       ],
//     );
//   }
//
//   /// 드롭 존 빌드
//   Widget _buildDropZone({
//     required bool isCategoryA,
//     required Future<void> Function(EditableCategory) onDrop,
//   }) {
//     return DragTarget<EditableCategory>(
//       onWillAccept: (data) {
//         if (data == null) return false;
//         // 플랜 카테고리로 이동하려면 참고 카테고리에서 온 것만, 참고 카테고리로 이동하려면 플랜 카테고리에서 온 것만
//         return isCategoryA
//             ? data.dailyAmount == null
//             : data.dailyAmount != null;
//       },
//       onAccept: (data) async {
//         await onDrop(data);
//       },
//       builder: (context, candidateData, rejectedData) {
//         final isHighlighted = candidateData.isNotEmpty;
//         return Container(
//           height: isHighlighted ? 60 : 20,
//           margin: const EdgeInsets.symmetric(horizontal: 24),
//           decoration: BoxDecoration(
//             color: isHighlighted
//                 ? AppColors.lightBlue.withOpacity(0.3)
//                 : Colors.transparent,
//             borderRadius: BorderRadius.circular(8),
//             border: isHighlighted
//                 ? Border.all(color: AppColors.primary, width: 2)
//                 : null,
//           ),
//           child: isHighlighted
//               ? Center(
//             child: Text(
//               isCategoryA ? '플랜 카테고리로 이동' : '참고 카테고리로 이동',
//               style: AppTextStyles.subtext.copyWith(
//                 color: AppColors.primary,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           )
//               : const SizedBox.shrink(),
//         );
//       },
//     );
//   }
//
//   /// 플랜 도달일 정보 (플랜 카테고리 하단, 참고 카테고리 상단 사이)
//   Widget _buildPlanProgressInfo() {
//     final progress = _planProgress;
//
//     if (progress.dailyLimitSum == 0) {
//       return const SizedBox.shrink();
//     }
//
//     if (progress.daysToReach == null || progress.reachDate == null) {
//       return const SizedBox.shrink();
//     }
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: AppColors.lightBlue,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // 첫 줄: 일일 한도 합계
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 '일일 한도 합계 ',
//                 style: AppTextStyles.subtext.copyWith(color: AppColors.text),
//               ),
//               Text(
//                 _formatAmount(progress.dailyLimitSum),
//                 style: AppTextStyles.paragraph.copyWith(
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.primary,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 4),
//           // 둘째 줄: 도달 예정일
//           Text(
//             '${progress.reachDate!.year}년 ${progress.reachDate!.month}월 ${progress.reachDate!.day}일 도달예정',
//             textAlign: TextAlign.center,
//             style: AppTextStyles.paragraph.copyWith(
//               fontWeight: FontWeight.w600,
//               color: AppColors.primary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// 카테고리 추가 버튼 빌드
//   Widget _buildAddCategoryButton({required bool isCategoryA}) {
//     final isMaxReached = isCategoryA
//         ? _categoryA.length >= _maxPlanCategories
//         : _categoryB.length >= _maxReferenceCategories;
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//       child: Center(
//         child: OutlinedButton(
//           onPressed: isMaxReached
//               ? null
//               : () => _addCategory(isCategoryA: isCategoryA),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: AppColors.primary,
//             disabledForegroundColor: Colors.grey.shade400,
//             side: BorderSide(
//               color: isMaxReached ? Colors.grey.shade300 : AppColors.primary,
//               width: 1.5,
//             ),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             minimumSize: const Size(0, 44),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 Icons.add_circle_outline,
//                 color: isMaxReached ? Colors.grey.shade400 : AppColors.primary,
//                 size: 20,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 '추가',
//                 style: TextStyle(
//                   color: isMaxReached
//                       ? Colors.grey.shade400
//                       : AppColors.primary,
//                   fontFamily: 'Pretendard',
//                   fontWeight: FontWeight.w600,
//                   fontSize: 15,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// 하단 정보 및 버튼 영역
//   Widget _buildBottomSection() {
//     return Container(
//       // 상단 여백 (회색 공간)
//       margin: const EdgeInsets.only(top: 8),
//       // 모달 스타일 컨테이너 - 둥근 모서리에 선 포함
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         border: Border.all(color: Colors.grey.shade300, width: 1),
//       ),
//       child: SafeArea(
//         top: false,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // 저장 버튼
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   onPressed: _save,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primary,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: const [
//                       Icon(Icons.save, color: Colors.white),
//                       SizedBox(width: 8),
//                       Text(
//                         '저장',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontFamily: 'Pretendard',
//                           fontWeight: FontWeight.w600,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // ================== 모델 클래스 ==================
//
// /// 편집 가능한 카테고리 모델
// class EditableCategory {
//   final String id;
//   final String name;
//   final String emoji; // 이모지
//   final int? dailyAmount; // null이면 참고 카테고리
//   final int sortOrder;
//
//   EditableCategory({
//     required this.id,
//     required this.name,
//     this.emoji = '💰',
//     this.dailyAmount,
//     required this.sortOrder,
//   });
//
//   EditableCategory copyWith({
//     String? id,
//     String? name,
//     String? emoji,
//     int? dailyAmount,
//     int? sortOrder,
//   }) {
//     return EditableCategory(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       emoji: emoji ?? this.emoji,
//       dailyAmount: dailyAmount ?? this.dailyAmount,
//       sortOrder: sortOrder ?? this.sortOrder,
//     );
//   }
// }
//
// /// 플랜 진행 정보
// class PlanProgressInfo {
//   final int dailyLimitSum;
//   final int? daysToReach;
//   final DateTime? reachDate;
//
//   PlanProgressInfo({
//     required this.dailyLimitSum,
//     this.daysToReach,
//     this.reachDate,
//   });
// }
//
// // ================== 위젯 클래스 ==================
//
// /// 카테고리 아이템 위젯
// class _CategoryItem extends StatelessWidget {
//   final EditableCategory category;
//   final bool isCategoryA;
//   final int itemIndex;
//   final List<EditableCategory> categories;
//   final VoidCallback onEditName;
//   final VoidCallback? onEditAmount;
//   final VoidCallback onDelete;
//   final String Function(int) formatAmount;
//   final VoidCallback? onDragStart;
//   final VoidCallback? onDragEnd;
//
//   const _CategoryItem({
//     super.key,
//     required this.category,
//     required this.isCategoryA,
//     required this.itemIndex,
//     required this.categories,
//     required this.onEditName,
//     this.onEditAmount,
//     required this.onDelete,
//     required this.formatAmount,
//     this.onDragStart,
//     this.onDragEnd,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Dismissible(
//       key: ValueKey(category.id),
//       direction: DismissDirection.endToStart, // 오른쪽에서 왼쪽으로 스와이프 (왼쪽으로 슬라이드)
//       background: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
//         decoration: BoxDecoration(
//           color: Colors.red,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         alignment: Alignment.centerRight,
//         padding: const EdgeInsets.only(right: 20),
//         child: const Icon(Icons.delete, color: Colors.white, size: 24),
//       ),
//       onDismissed: (_) => onDelete(),
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: Colors.grey.shade200),
//         ),
//         child: ListTile(
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 8,
//           ),
//           leading: Draggable<EditableCategory>(
//             data: category,
//             onDragStarted: onDragStart,
//             onDragEnd: (_) => onDragEnd?.call(),
//             feedback: Material(
//               elevation: 4,
//               borderRadius: BorderRadius.circular(8),
//               child: Opacity(
//                 opacity: 0.8,
//                 child: SizedBox(
//                   width: MediaQuery.of(context).size.width - 48,
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(
//                       horizontal: 24,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.grey.shade200),
//                     ),
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 8,
//                       ),
//                       leading: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Icon(
//                             Icons.drag_handle,
//                             color: AppColors.subText,
//                           ),
//                           const SizedBox(width: 8),
//                           Text(
//                             category.emoji,
//                             style: const TextStyle(fontSize: 20),
//                           ),
//                         ],
//                       ),
//                       title: Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               category.name,
//                               style: AppTextStyles.paragraph,
//                             ),
//                           ),
//                           if (isCategoryA && category.dailyAmount != null)
//                             Text(
//                               formatAmount(category.dailyAmount!),
//                               style: AppTextStyles.paragraph.copyWith(
//                                 fontWeight: FontWeight.w600,
//                                 color: AppColors.primary,
//                                 fontFeatures: [
//                                   const FontFeature.tabularFigures(),
//                                 ],
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             childWhenDragging: Opacity(
//               opacity: 0.3,
//               child: const Icon(Icons.drag_handle, color: AppColors.subText),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(Icons.drag_handle, color: AppColors.subText),
//                 const SizedBox(width: 8),
//                 Text(category.emoji, style: const TextStyle(fontSize: 20)),
//               ],
//             ),
//           ),
//           title: Row(
//             children: [
//               Expanded(
//                 child: GestureDetector(
//                   onTap: onEditName,
//                   child: Text(category.name, style: AppTextStyles.paragraph),
//                 ),
//               ),
//               if (isCategoryA && category.dailyAmount != null)
//                 GestureDetector(
//                   onTap: onEditAmount,
//                   child: Text(
//                     formatAmount(category.dailyAmount!),
//                     style: AppTextStyles.paragraph.copyWith(
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.primary,
//                       fontFeatures: [const FontFeature.tabularFigures()],
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // ================== 모달 ==================
//
// /// 카테고리 이름 입력 모달
// class _CategoryNameModal extends StatefulWidget {
//   final bool isOpen;
//   final VoidCallback onClose;
//   final String? initialName;
//   final String? initialEmoji;
//   final void Function(String name, String emoji) onComplete;
//
//   const _CategoryNameModal({
//     required this.isOpen,
//     required this.onClose,
//     this.initialName,
//     this.initialEmoji,
//     required this.onComplete,
//   });
//
//   @override
//   State<_CategoryNameModal> createState() => _CategoryNameModalState();
// }
//
// class _CategoryNameModalState extends State<_CategoryNameModal>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
//   late final Animation<Offset> _slide;
//   late final Animation<double> _scrimFade;
//   late final TextEditingController _controller;
//   late final FocusNode _focusNode;
//   String _selectedEmoji = '💰';
//   bool _showEmojiPicker = false;
//
//   static const _kSlideMs = 500;
//
//   // 이모지 리스트 (플랜 챗 뷰에서 가져옴)
//   static const List<String> _expenseEmojis = [
//     '💰',
//     '💸',
//     '💳',
//     '🏦',
//     '💵',
//     '💶',
//     '💷',
//     '💴',
//     '🪙',
//     '💎',
//     '🍕',
//     '🍔',
//     '🍟',
//     '🌭',
//     '🥪',
//     '🌮',
//     '🌯',
//     '🥙',
//     '🍱',
//     '🍜',
//     '☕',
//     '🥤',
//     '🧋',
//     '🍵',
//     '🍶',
//     '🍷',
//     '🍸',
//     '🍹',
//     '🍺',
//     '🍻',
//     '🛍️',
//     '🛒',
//     '💍',
//     '👕',
//     '👖',
//     '👗',
//     '👠',
//     '👟',
//     '🎒',
//     '👜',
//     '🎬',
//     '🎮',
//     '🎯',
//     '🎲',
//     '🎪',
//     '🎨',
//     '🎭',
//     '🎪',
//     '🎡',
//     '🎠',
//     '🚗',
//     '🚕',
//     '🚙',
//     '🚌',
//     '🚎',
//     '🏎️',
//     '🚓',
//     '🚑',
//     '🚒',
//     '🚐',
//     '✈️',
//     '🚁',
//     '🚀',
//     '🛸',
//     '🚢',
//     '⛵',
//     '🚤',
//     '🛥️',
//     '🚁',
//     '🚂',
//     '🏠',
//     '🏡',
//     '🏢',
//     '🏬',
//     '🏪',
//     '🏫',
//     '🏩',
//     '🏨',
//     '🏦',
//     '🏛️',
//     '💊',
//     '🏥',
//     '⚕️',
//     '🩺',
//     '💉',
//     '🧬',
//     '🦠',
//     '🧪',
//     '🧫',
//     '🧼',
//     '📱',
//     '💻',
//     '⌨️',
//     '🖥️',
//     '🖨️',
//     '📠',
//     '📞',
//     '☎️',
//     '📺',
//     '📻',
//     '🏋️',
//     '🤸',
//     '🧘',
//     '🏊',
//     '🚴',
//     '🏃',
//     '⚽',
//     '🏀',
//     '🏈',
//     '🎾',
//     '📚',
//     '✏️',
//     '📝',
//     '📋',
//     '📊',
//     '📈',
//     '📉',
//     '💼',
//     '🗂️',
//     '📁',
//     '🎁',
//     '🎂',
//     '🍰',
//     '🧁',
//     '🍭',
//     '🍬',
//     '🍫',
//     '🍩',
//     '🍪',
//     '🥧',
//     '🌱',
//     '🌿',
//     '🌾',
//     '🌻',
//     '🌺',
//     '🌸',
//     '🌼',
//     '🌷',
//     '🌹',
//     '🥀',
//     '🐕',
//     '🐈',
//     '🐭',
//     '🐹',
//     '🐰',
//     '🦊',
//     '🐻',
//     '🐼',
//     '🐨',
//     '🐯',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = TextEditingController(text: widget.initialName ?? '');
//     _focusNode = FocusNode();
//     _selectedEmoji = widget.initialEmoji ?? '💰';
//
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: _kSlideMs),
//       reverseDuration: const Duration(milliseconds: _kSlideMs),
//     );
//
//     _slide = Tween<Offset>(
//       begin: const Offset(0, 1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
//
//     _scrimFade = CurvedAnimation(
//       parent: _ctrl,
//       curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
//     );
//
//     if (widget.isOpen) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _ctrl.forward().then((_) {
//           // 애니메이션 완료 후 포커스 및 키보드 표시
//           Future.delayed(const Duration(milliseconds: 100), () {
//             if (mounted) {
//               _focusNode.requestFocus();
//             }
//           });
//         });
//       });
//     }
//   }
//
//   @override
//   void didUpdateWidget(covariant _CategoryNameModal oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.isOpen != widget.isOpen) {
//       if (widget.isOpen) {
//         _ctrl.forward().then((_) {
//           // 애니메이션 완료 후 포커스 및 키보드 표시
//           Future.delayed(const Duration(milliseconds: 100), () {
//             if (mounted) {
//               _focusNode.requestFocus();
//             }
//           });
//         });
//       } else {
//         _focusNode.unfocus();
//         _ctrl.reverse().whenComplete(() {
//           if (mounted) widget.onClose();
//         });
//       }
//     }
//     if (oldWidget.initialName != widget.initialName) {
//       _controller.text = widget.initialName ?? '';
//     }
//     if (oldWidget.initialEmoji != widget.initialEmoji) {
//       _selectedEmoji = widget.initialEmoji ?? '💰';
//     }
//   }
//
//   @override
//   void dispose() {
//     _focusNode.dispose();
//     _ctrl.dispose();
//     _controller.dispose();
//     super.dispose();
//   }
//
//   Future<void> _closeWithAnimation() async {
//     if (_ctrl.status == AnimationStatus.dismissed ||
//         _ctrl.status == AnimationStatus.reverse) {
//       return;
//     }
//     await _ctrl.reverse();
//     if (mounted) widget.onClose();
//   }
//
//   void _handleComplete() {
//     final name = _controller.text.trim();
//     if (name.isNotEmpty) {
//       widget.onComplete(name, _selectedEmoji);
//       _closeWithAnimation();
//     }
//   }
//
//   bool get _isValid => _controller.text.trim().isNotEmpty;
//
//   @override
//   Widget build(BuildContext context) {
//     return IgnorePointer(
//       ignoring: _ctrl.status == AnimationStatus.dismissed,
//       child: Stack(
//         children: [
//           // 스크림
//           FadeTransition(
//             opacity: _scrimFade,
//             child: GestureDetector(
//               onTap: _closeWithAnimation,
//               child: Container(color: Colors.black54),
//             ),
//           ),
//           // 모달
//           Positioned.fill(
//             child: SlideTransition(
//               position: _slide,
//               child: Align(
//                 alignment: Alignment.bottomCenter,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(40),
//                       topRight: Radius.circular(40),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         offset: const Offset(0, -4),
//                         blurRadius: 6,
//                         spreadRadius: 0,
//                       ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 30,
//                       horizontal: 20,
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(20),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Row(
//                             children: [
//                               // 이모지 아이콘
//                               GestureDetector(
//                                 onTap: () {
//                                   setState(() {
//                                     _showEmojiPicker = !_showEmojiPicker;
//                                   });
//                                 },
//                                 child: Container(
//                                   width: 60,
//                                   height: 60,
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFFF3F4F6),
//                                     borderRadius: BorderRadius.circular(12),
//                                     border: Border.all(
//                                       color: const Color(0xFFE5E7EB),
//                                     ),
//                                   ),
//                                   child: Center(
//                                     child: Text(
//                                       _selectedEmoji,
//                                       style: const TextStyle(fontSize: 24),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                               // 입력 필드
//                               Expanded(
//                                 child: SizedBox(
//                                   height: 60,
//                                   child: CustomTextField(
//                                     controller: _controller,
//                                     focusNode: _focusNode,
//                                     hintText: widget.initialName == null
//                                         ? '새 카테고리 이름'
//                                         : '카테고리 이름',
//                                     onChanged: (_) => setState(() {}),
//                                     height: 60,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           // 이모지 피커
//                           if (_showEmojiPicker) ...[
//                             const SizedBox(height: 12),
//                             Container(
//                               height: 120,
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFF9FAFB),
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: const Color(0xFFE5E7EB),
//                                 ),
//                               ),
//                               child: GridView.builder(
//                                 gridDelegate:
//                                 const SliverGridDelegateWithFixedCrossAxisCount(
//                                   crossAxisCount: 8,
//                                   crossAxisSpacing: 4,
//                                   mainAxisSpacing: 4,
//                                 ),
//                                 itemCount: _expenseEmojis.length,
//                                 itemBuilder: (context, index) {
//                                   final emoji = _expenseEmojis[index];
//                                   return GestureDetector(
//                                     onTap: () {
//                                       setState(() {
//                                         _selectedEmoji = emoji;
//                                         _showEmojiPicker = false;
//                                       });
//                                     },
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         color: _selectedEmoji == emoji
//                                             ? AppColors.primary.withOpacity(0.1)
//                                             : Colors.transparent,
//                                         borderRadius: BorderRadius.circular(6),
//                                       ),
//                                       child: Center(
//                                         child: Text(
//                                           emoji,
//                                           style: TextStyle(
//                                             fontSize: 18,
//                                             color: _selectedEmoji == emoji
//                                                 ? AppColors.primary
//                                                 : null,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ],
//                           const SizedBox(height: 12),
//                           // 추가 버튼
//                           SizedBox(
//                             width: double.infinity,
//                             height: 50,
//                             child: ElevatedButton(
//                               onPressed: _isValid ? _handleComplete : null,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: _isValid
//                                     ? AppColors.primary
//                                     : const Color(0xFF9CA3AF),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               child: Text(
//                                 widget.initialName == null ? '추가' : '수정',
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                   fontSize: 15,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /// 카테고리 금액 입력 모달
// class _CategoryAmountModal extends StatefulWidget {
//   final bool isOpen;
//   final VoidCallback onClose;
//   final int initialAmount;
//   final void Function(int) onComplete;
//
//   const _CategoryAmountModal({
//     required this.isOpen,
//     required this.onClose,
//     required this.initialAmount,
//     required this.onComplete,
//   });
//
//   @override
//   State<_CategoryAmountModal> createState() => _CategoryAmountModalState();
// }
//
// class _CategoryAmountModalState extends State<_CategoryAmountModal>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
//   late final Animation<Offset> _slide;
//   late final Animation<double> _scrimFade;
//   late final TextEditingController _controller;
//   late final FocusNode _focusNode;
//
//   static const _kSlideMs = 500;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = TextEditingController(
//       text: widget.initialAmount > 0 ? widget.initialAmount.toString() : '',
//     );
//     _focusNode = FocusNode();
//
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: _kSlideMs),
//       reverseDuration: const Duration(milliseconds: _kSlideMs),
//     );
//
//     _slide = Tween<Offset>(
//       begin: const Offset(0, 1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
//
//     _scrimFade = CurvedAnimation(
//       parent: _ctrl,
//       curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
//     );
//
//     if (widget.isOpen) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _ctrl.forward().then((_) {
//           // 애니메이션 완료 후 포커스 및 키보드 표시
//           Future.delayed(const Duration(milliseconds: 100), () {
//             if (mounted) {
//               _focusNode.requestFocus();
//             }
//           });
//         });
//       });
//     }
//   }
//
//   @override
//   void didUpdateWidget(covariant _CategoryAmountModal oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.isOpen != widget.isOpen) {
//       if (widget.isOpen) {
//         _ctrl.forward().then((_) {
//           // 애니메이션 완료 후 포커스 및 키보드 표시
//           Future.delayed(const Duration(milliseconds: 100), () {
//             if (mounted) {
//               _focusNode.requestFocus();
//             }
//           });
//         });
//       } else {
//         _focusNode.unfocus();
//         _ctrl.reverse().whenComplete(() {
//           if (mounted) widget.onClose();
//         });
//       }
//     }
//     if (oldWidget.initialAmount != widget.initialAmount) {
//       _controller.text = widget.initialAmount > 0
//           ? widget.initialAmount.toString()
//           : '';
//     }
//   }
//
//   @override
//   void dispose() {
//     _focusNode.dispose();
//     _ctrl.dispose();
//     _controller.dispose();
//     super.dispose();
//   }
//
//   Future<void> _closeWithAnimation() async {
//     if (_ctrl.status == AnimationStatus.dismissed ||
//         _ctrl.status == AnimationStatus.reverse) {
//       return;
//     }
//     await _ctrl.reverse();
//     if (mounted) widget.onClose();
//   }
//
//   bool get _isValid {
//     final text = _controller.text.replaceAll(',', '').trim();
//     if (text.isEmpty) return false;
//     final amount = int.tryParse(text);
//     return amount != null && amount >= 0;
//   }
//
//   String get _buttonText {
//     final text = _controller.text.replaceAll(',', '').trim();
//     if (text.isEmpty) {
//       return '일일 금액을 입력해주세요!';
//     }
//     final amount = int.tryParse(text);
//     if (amount == null || amount < 0) {
//       return '올바른 금액을 입력해주세요!';
//     }
//     return '제 일일 금액이에요!';
//   }
//
//   void _handleComplete() {
//     final text = _controller.text.replaceAll(',', '');
//     final amount = int.tryParse(text) ?? 0;
//     if (amount >= 0) {
//       widget.onComplete(amount);
//       _closeWithAnimation();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return IgnorePointer(
//       ignoring: _ctrl.status == AnimationStatus.dismissed,
//       child: Stack(
//         children: [
//           // 스크림
//           FadeTransition(
//             opacity: _scrimFade,
//             child: GestureDetector(
//               onTap: _closeWithAnimation,
//               child: Container(color: Colors.black54),
//             ),
//           ),
//           // 모달
//           Positioned.fill(
//             child: SlideTransition(
//               position: _slide,
//               child: Align(
//                 alignment: Alignment.bottomCenter,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(40),
//                       topRight: Radius.circular(40),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         offset: const Offset(0, -4),
//                         blurRadius: 6,
//                         spreadRadius: 0,
//                       ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 30,
//                       horizontal: 20,
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 20),
//                           child: CustomTextField(
//                             controller: _controller,
//                             focusNode: _focusNode,
//                             hintText: '일일 소비 한도 금액을 입력하세요',
//                             keyboardType: TextInputType.number,
//                             inputFormatters: [
//                               FilteringTextInputFormatter.digitsOnly,
//                             ],
//                             onChanged: (_) => setState(() {}),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         CustomButton(
//                           text: _buttonText,
//                           onPressed: _isValid ? _handleComplete : () {},
//                           enabled: _isValid,
//                         ),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /// 날짜 선택 모달
// class _DatePickerModal extends StatefulWidget {
//   final bool isOpen;
//   final VoidCallback onClose;
//   final DateTime initialDate;
//   final void Function(DateTime) onDateSelected;
//
//   const _DatePickerModal({
//     required this.isOpen,
//     required this.onClose,
//     required this.initialDate,
//     required this.onDateSelected,
//   });
//
//   @override
//   State<_DatePickerModal> createState() => _DatePickerModalState();
// }
//
// class _DatePickerModalState extends State<_DatePickerModal>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
//   late final Animation<Offset> _slide;
//   late final Animation<double> _scrimFade;
//   static const _kSlideMs = 300;
//
//   DateTime _selectedDate = DateTime.now();
//   int _currentYear = DateTime.now().year;
//   int _currentMonth = DateTime.now().month;
//
//   // 화면 전환을 위한 PageController
//   late final PageController _pageController;
//   int _currentPage = 0; // 0: 달력/리스트, 1: 변경 정보 상세
//   Map<String, dynamic>? _selectedChange;
//
//   // 예산 변경 내역 (TODO: 실제 데이터 소스와 연동 필요)
//   List<Map<String, dynamic>> _budgetChanges = [
//     {
//       'date': DateTime(2024, 1, 10),
//       'category': '식비',
//       'beforeAmount': 10000, // 변경 전 금액
//       'afterAmount': 11000, // 변경 후 금액
//       'isIncrease': true, // true: 인상, false: 인하
//       'totalDailyBefore': 15000, // 전체 일일소비 금액 (변경 전)
//       'totalDailyAfter': 16000, // 전체 일일소비 금액 (변경 후)
//       'targetDateBefore': DateTime(2024, 3, 15), // 목표도달일 (변경 전)
//       'targetDateAfter': DateTime(2024, 3, 10), // 목표도달일 (변경 후)
//     },
//     {
//       'date': DateTime(2024, 1, 24),
//       'category': '교통비',
//       'beforeAmount': 3000,
//       'afterAmount': 2500,
//       'isIncrease': false,
//       'totalDailyBefore': 16000,
//       'totalDailyAfter': 15500,
//       'targetDateBefore': DateTime(2024, 3, 10),
//       'targetDateAfter': DateTime(2024, 3, 12),
//     },
//     {
//       'date': DateTime(2024, 2, 13),
//       'category': '여가비',
//       'beforeAmount': 5000,
//       'afterAmount': 8000,
//       'isIncrease': true,
//       'totalDailyBefore': 15500,
//       'totalDailyAfter': 18500,
//       'targetDateBefore': DateTime(2024, 3, 12),
//       'targetDateAfter': DateTime(2024, 3, 8),
//     },
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedDate = widget.initialDate;
//     _currentYear = widget.initialDate.year;
//     _currentMonth = widget.initialDate.month;
//     _pageController = PageController();
//
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: _kSlideMs),
//       reverseDuration: const Duration(milliseconds: _kSlideMs),
//     );
//
//     _slide = Tween<Offset>(
//       begin: const Offset(0, 1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
//
//     _scrimFade = CurvedAnimation(
//       parent: _ctrl,
//       curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
//     );
//
//     if (widget.isOpen) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _ctrl.forward();
//       });
//     }
//   }
//
//   @override
//   void didUpdateWidget(_DatePickerModal oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.isOpen != widget.isOpen) {
//       if (widget.isOpen) {
//         _selectedDate = widget.initialDate;
//         _currentYear = widget.initialDate.year;
//         _currentMonth = widget.initialDate.month;
//         _ctrl.forward();
//       } else {
//         _ctrl.reverse();
//       }
//     }
//     if (oldWidget.initialDate != widget.initialDate) {
//       _selectedDate = widget.initialDate;
//       _currentYear = widget.initialDate.year;
//       _currentMonth = widget.initialDate.month;
//     }
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     _ctrl.dispose();
//     super.dispose();
//   }
//
//   void _closeWithAnimation() {
//     _ctrl.reverse().then((_) {
//       if (mounted) widget.onClose();
//     });
//   }
//
//   void _changeMonth(int delta) {
//     setState(() {
//       final newDate = DateTime(_currentYear, _currentMonth + delta, 1);
//       _currentYear = newDate.year;
//       _currentMonth = newDate.month;
//     });
//   }
//
//   Widget _buildMonthSelector() {
//     return Center(
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // 이전 달
//           Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: () => _changeMonth(-1),
//               borderRadius: BorderRadius.circular(20),
//               child: Container(
//                 padding: const EdgeInsets.all(4),
//                 child: Icon(
//                   Icons.chevron_left,
//                   color: Colors.grey[700],
//                   size: 20,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Text(
//             '$_currentMonth월',
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(width: 8),
//           // 다음 달
//           Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: () => _changeMonth(1),
//               borderRadius: BorderRadius.circular(20),
//               child: Container(
//                 padding: const EdgeInsets.all(4),
//                 child: Icon(
//                   Icons.chevron_right,
//                   color: Colors.grey[700],
//                   size: 20,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCalendarGrid() {
//     final firstDayOfMonth = DateTime(_currentYear, _currentMonth, 1);
//     final lastDayOfMonth = DateTime(_currentYear, _currentMonth + 1, 0);
//     // DateTime.weekday는 1(월요일)~7(일요일)
//     final firstWeekday = firstDayOfMonth.weekday;
//     final daysInMonth = lastDayOfMonth.day;
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // 요일 헤더: 월화수목금토일
//           Row(
//             children: ['월', '화', '수', '목', '금', '토', '일']
//                 .map(
//                   (day) => Expanded(
//                 child: Text(
//                   day,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                     color: day == '토'
//                         ? Colors.blue
//                         : day == '일'
//                         ? Colors.red
//                         : Colors.black87,
//                   ),
//                 ),
//               ),
//             )
//                 .toList(),
//           ),
//           const SizedBox(height: 8),
//           LayoutBuilder(
//             builder: (context, constraints) {
//               // 7칸 기준 한 칸의 "가로" 길이
//               final cellW = constraints.maxWidth / 7;
//
//               // ✅ 타이트하게 만들고 싶으면 1.10~1.25 사이로 조절
//               // childAspectRatio = width / height  -> 값이 커질수록 높이가 줄어듦
//               const ratio = 1.3; // 높이를 더 줄이기 위해 비율 증가
//
//               // 6주(42칸) 고정이므로 그리드 전체 높이
//               // 최대 높이 제한 (오버플로우 방지)
//               final gridH = ((cellW / ratio) * 6).clamp(
//                 0.0,
//                 200.0, // 고정 최대 높이로 제한
//               );
//
//               return SizedBox(
//                 height: gridH,
//                 child: GridView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 7,
//                     childAspectRatio: ratio,
//                   ),
//                   itemCount: 42,
//                   itemBuilder: (context, index) {
//                     // firstWeekday는 1(월요일)~7(일요일)
//                     // index는 0부터 시작하므로, 월요일이 첫 번째 칸(0)에 오도록 조정
//                     final day = index - (firstWeekday - 1) + 1;
//                     final isCurrentMonth = day > 0 && day <= daysInMonth;
//
//                     if (!isCurrentMonth) {
//                       return const SizedBox();
//                     }
//
//                     final date = DateTime(_currentYear, _currentMonth, day);
//                     final isSelected =
//                         date.year == _selectedDate.year &&
//                             date.month == _selectedDate.month &&
//                             date.day == _selectedDate.day;
//                     final weekday = date.weekday; // 1(월)~7(일)
//                     final isSaturday = weekday == 6;
//                     final isSunday = weekday == 7;
//
//                     return Material(
//                       color: Colors.transparent,
//                       child: InkWell(
//                         onTap: () {
//                           widget.onDateSelected(date);
//                           _closeWithAnimation();
//                         },
//                         borderRadius: BorderRadius.circular(8),
//                         child: Container(
//                           margin: const EdgeInsets.all(2),
//                           decoration: BoxDecoration(
//                             color: isSelected
//                                 ? AppColors.primary
//                                 : Colors.transparent,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Center(
//                             child: Text(
//                               '$day',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                                 color: isSelected
//                                     ? Colors.white
//                                     : isSunday
//                                     ? Colors.red
//                                     : isSaturday
//                                     ? Colors.blue
//                                     : Colors.black87,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!widget.isOpen && _ctrl.status == AnimationStatus.dismissed) {
//       return const SizedBox.shrink();
//     }
//
//     return Stack(
//       children: [
//         // 스크림
//         FadeTransition(
//           opacity: _scrimFade,
//           child: GestureDetector(
//             onTap: _closeWithAnimation,
//             child: Container(color: Colors.black54),
//           ),
//         ),
//         // 모달
//         Positioned.fill(
//           child: SlideTransition(
//             position: _slide,
//             child: Align(
//               alignment: Alignment.bottomCenter,
//               child: FractionallySizedBox(
//                 widthFactor: 1.0,
//                 heightFactor: 0.85,
//                 child: ClipRRect(
//                   borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(24),
//                     bottom: Radius.zero,
//                   ),
//                   child: Container(
//                     color: Colors.white,
//                     child: Column(
//                       children: [
//                         // 제목 영역
//                         Container(
//                           padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
//                           decoration: BoxDecoration(
//                             border: Border(
//                               bottom: BorderSide(
//                                 color: Colors.grey.shade200,
//                                 width: 1,
//                               ),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               _currentPage == 0
//                                   ? Text(
//                                 '날짜 선택',
//                                 style: AppTextStyles.header.copyWith(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               )
//                                   : IconButton(
//                                 onPressed: () {
//                                   setState(() {
//                                     _currentPage = 0;
//                                   });
//                                   _pageController.animateToPage(
//                                     0,
//                                     duration: const Duration(
//                                       milliseconds: 300,
//                                     ),
//                                     curve: Curves.easeInOut,
//                                   );
//                                 },
//                                 icon: const Icon(Icons.arrow_back),
//                                 padding: EdgeInsets.zero,
//                                 constraints: const BoxConstraints(),
//                               ),
//                               IconButton(
//                                 onPressed: _closeWithAnimation,
//                                 icon: const Icon(Icons.close),
//                                 padding: EdgeInsets.zero,
//                                 constraints: const BoxConstraints(),
//                               ),
//                             ],
//                           ),
//                         ),
//                         // PageView로 화면 전환
//                         Expanded(
//                           child: PageView(
//                             controller: _pageController,
//                             physics: const NeverScrollableScrollPhysics(),
//                             onPageChanged: (index) {
//                               setState(() {
//                                 _currentPage = index;
//                               });
//                             },
//                             children: [
//                               // 첫 번째 페이지: 달력 + 리스트
//                               _buildCalendarAndListPage(),
//                               // 두 번째 페이지: 변경 정보 상세
//                               _buildChangeDetailPage(),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildCalendarAndListPage() {
//     return Column(
//       children: [
//         // 달력 영역 (상단 고정)
//         Expanded(
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 // 월 선택기
//                 Padding(
//                   padding: const EdgeInsets.only(top: 16),
//                   child: _buildMonthSelector(),
//                 ),
//                 // 달력 그리드
//                 _buildCalendarGrid(),
//               ],
//             ),
//           ),
//         ),
//         // 구분선
//         Container(height: 1, color: Colors.grey.shade200),
//         // 예산 변경 내역 리스트 (하단 고정)
//         Padding(
//           padding: const EdgeInsets.only(top: 16, bottom: 24),
//           child: SizedBox(height: 140, child: _buildBudgetChangeList()),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildChangeDetailPage() {
//     if (_selectedChange == null) {
//       return const Center(child: Text('변경 정보를 불러올 수 없습니다.'));
//     }
//
//     final date = _selectedChange!['date'] as DateTime;
//     final category = _selectedChange!['category'] as String;
//     final beforeAmount = _selectedChange!['beforeAmount'] as int;
//     final afterAmount = _selectedChange!['afterAmount'] as int;
//     final isIncrease = _selectedChange!['isIncrease'] as bool;
//     final totalDailyBefore = _selectedChange!['totalDailyBefore'] as int;
//     final totalDailyAfter = _selectedChange!['totalDailyAfter'] as int;
//     final targetDateBefore = _selectedChange!['targetDateBefore'] as DateTime;
//     final targetDateAfter = _selectedChange!['targetDateAfter'] as DateTime;
//
//     // 오늘부터 변경일까지의 일수 계산
//     final today = DateTime.now();
//     final daysUntilChange = date.difference(today).inDays;
//     final daysUntilChangeStr = daysUntilChange > 0
//         ? '$daysUntilChange일 후부터'
//         : '오늘부터';
//
//     // 금액 포맷팅
//     final beforeAmountStr = beforeAmount.toString().replaceAllMapped(
//       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
//           (Match m) => '${m[1]},',
//     );
//     final afterAmountStr = afterAmount.toString().replaceAllMapped(
//       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
//           (Match m) => '${m[1]},',
//     );
//     final totalDailyBeforeStr = totalDailyBefore.toString().replaceAllMapped(
//       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
//           (Match m) => '${m[1]},',
//     );
//     final totalDailyAfterStr = totalDailyAfter.toString().replaceAllMapped(
//       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
//           (Match m) => '${m[1]},',
//     );
//
//     final changeType = isIncrease ? '인상' : '인하';
//     final changeColor = isIncrease ? Colors.red : Colors.blue;
//
//     // 목표도달일 차이 계산
//     final daysDifference = targetDateAfter.difference(targetDateBefore).inDays;
//     final isFaster = daysDifference < 0;
//     final daysDiffStr = daysDifference.abs().toString();
//     final speedText = isFaster ? '빨라져서' : '느려져서';
//
//     final targetDateStr =
//         '${targetDateAfter.year}년 ${targetDateAfter.month}월 ${targetDateAfter.day}일';
//
//     return Column(
//       children: [
//         Expanded(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 20),
//                 // 큰 글씨: 날짜
//                 RichText(
//                   text: TextSpan(
//                     style: AppTextStyles.header.copyWith(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                     children: [
//                       TextSpan(text: '${date.month}월 ${date.day}일부터'),
//                       TextSpan(
//                         text: ' ($daysUntilChangeStr)',
//                         style: AppTextStyles.subtext.copyWith(
//                           fontSize: 14,
//                           color: AppColors.subText,
//                           fontWeight: FontWeight.normal,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 // 카테고리
//                 Text(
//                   '$category가',
//                   style: AppTextStyles.header.copyWith(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 // 금액 변경
//                 Text(
//                   '$beforeAmountStr원에서 $afterAmountStr원으로',
//                   style: AppTextStyles.header.copyWith(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 // 인상/인하
//                 Text(
//                   '$changeType됩니다.',
//                   style: AppTextStyles.header.copyWith(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: changeColor,
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//                 // 구분선
//                 Container(height: 1, color: Colors.grey.shade300),
//                 const SizedBox(height: 32),
//                 // 전체 일일소비 금액
//                 Text(
//                   '전체 일일소비 금액은 $totalDailyBeforeStr원에서 $totalDailyAfterStr원으로 $changeType될 예정이에요.',
//                   style: AppTextStyles.subtext.copyWith(
//                     fontSize: 14,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 // 목표도달일
//                 Text(
//                   '목표도달일은 $daysDiffStr일 $speedText $targetDateStr 도달예정이에요.',
//                   style: AppTextStyles.subtext.copyWith(
//                     fontSize: 14,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         // 하단 버튼
//         Container(
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             border: Border(
//               top: BorderSide(color: Colors.grey.shade200, width: 1),
//             ),
//           ),
//           child: Row(
//             children: [
//               // 닫기 버튼
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () {
//                     setState(() {
//                       _currentPage = 0;
//                     });
//                     _pageController.animateToPage(
//                       0,
//                       duration: const Duration(milliseconds: 300),
//                       curve: Curves.easeInOut,
//                     );
//                   },
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     side: BorderSide(color: Colors.grey.shade300),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: Text(
//                     '닫기',
//                     style: AppTextStyles.paragraph.copyWith(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               // 수정하기 버튼
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // TODO: 수정하기 기능 구현
//                   },
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     backgroundColor: AppColors.primary,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: Text(
//                     '수정하기',
//                     style: AppTextStyles.paragraph.copyWith(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildBudgetChangeList() {
//     // 날짜 순으로 정렬
//     final sortedChanges = List<Map<String, dynamic>>.from(
//       _budgetChanges,
//     )..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
//
//     if (sortedChanges.isEmpty) {
//       return Center(
//         child: Text(
//           '예산 변경 내역이 없습니다.',
//           style: AppTextStyles.subtext.copyWith(color: AppColors.subText),
//         ),
//       );
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       itemCount: sortedChanges.length,
//       itemBuilder: (context, index) {
//         final change = sortedChanges[index];
//         final date = change['date'] as DateTime;
//         final category = change['category'] as String;
//         // 변경 금액 차이 계산
//         final beforeAmount = change['beforeAmount'] as int? ?? 0;
//         final afterAmount = change['afterAmount'] as int? ?? 0;
//         final amount = (afterAmount - beforeAmount).abs();
//         final isIncrease = change['isIncrease'] as bool;
//
//         final dateStr = '${date.month}월 ${date.day}일';
//         final amountStr =
//             '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
//         final changeType = isIncrease ? '인상' : '인하';
//         final changeColor = isIncrease ? Colors.red : Colors.blue;
//
//         return Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: () {
//               setState(() {
//                 _selectedChange = change;
//                 _currentPage = 1;
//               });
//               _pageController.animateToPage(
//                 1,
//                 duration: const Duration(milliseconds: 300),
//                 curve: Curves.easeInOut,
//               );
//             },
//             child: Padding(
//               padding: const EdgeInsets.only(bottom: 12),
//               child: Row(
//                 children: [
//                   // 날짜
//                   SizedBox(
//                     width: 70,
//                     child: Text(
//                       dateStr,
//                       style: AppTextStyles.paragraph.copyWith(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   // 카테고리
//                   Expanded(
//                     child: Text(
//                       category,
//                       style: AppTextStyles.paragraph.copyWith(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ),
//                   // 금액 및 변경 타입
//                   Text(
//                     '$amountStr $changeType',
//                     style: AppTextStyles.paragraph.copyWith(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: changeColor,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
