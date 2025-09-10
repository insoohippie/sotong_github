import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../view_model/record/daily_category_viewmodel.dart';
import 'daily_category_add_page.dart';

class DailyCategoryManagePage extends StatelessWidget {
  const DailyCategoryManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DailyCategoryViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('지출 카테고리', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DailyCategoryAddPage(),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded, color: Colors.black),
            tooltip: '카테고리 추가',
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: vm.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = vm.items[i];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Text(item.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              trailing: Switch(
                value: item.enabled,
                activeColor: Colors.white,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFCDD4E1),
                onChanged: (v) => context.read<DailyCategoryViewModel>().setEnabled(i, v),
              ),
              // 필요하면 길게 눌러 삭제
              onLongPress: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('삭제할까요?'),
                    content: Text('"${item.name}" 카테고리를 삭제합니다.'),
                    actions: [
                      TextButton(onPressed: ()=>Navigator.pop(context, false), child: const Text('취소')),
                      TextButton(onPressed: ()=>Navigator.pop(context, true), child: const Text('삭제')),
                    ],
                  ),
                );
                if (ok == true) context.read<DailyCategoryViewModel>().removeAt(i);
              },
            ),
          );
        },
      ),
    );
  }
}
