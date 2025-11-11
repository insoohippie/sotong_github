import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../view_model/record/daily_category_viewmodel.dart';
import '../../../../model/record/daily_category_item.dart';
import 'daily_category_add_page.dart';

class DailyCategoryManagePage extends StatelessWidget {
  const DailyCategoryManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DailyCategoryViewModel>();
    debugPrint(
      '[ManagePage] rebuild  items.len=${vm.items.length} vm.hash=${vm.hashCode}',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '지출 카테고리',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: vm.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = vm.items[i];
          return Dismissible(
            key: Key(item.name),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('카테고리 삭제'),
                  content: Text(
                    '"${item.name}" 카테고리를 삭제하시겠습니까?\n\n삭제된 카테고리는 복구할 수 없습니다.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                      ),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              context.read<DailyCategoryViewModel>().removeAt(i);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: item.color.withValues(alpha: 0.25),
                  child: Icon(item.icon, color: Colors.black),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 수정 버튼
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DailyCategoryAddPage(
                              editItem: item,
                              editIndex: i,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      tooltip: '수정',
                    ),
                    // 토글 스위치
                    Switch(
                      value: item.enabled,
                      activeTrackColor: AppColors.primary,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFCDD4E1),
                      onChanged: (v) => context
                          .read<DailyCategoryViewModel>()
                          .setEnabled(i, v),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 100), // 카테고리 목록과 겹치지 않도록 충분한 여백
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DailyCategoryAddPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            '추가',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
