import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../view_model/record/daily_category_viewmodel.dart';

class DailyCategoryAddPage extends StatefulWidget {
  const DailyCategoryAddPage({super.key});

  @override
  State<DailyCategoryAddPage> createState() => _DailyCategoryAddPageState();
}

class _DailyCategoryAddPageState extends State<DailyCategoryAddPage> {
  final _name = TextEditingController();
  String _emoji = '📌';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final n = _name.text.trim();
    if (n.isEmpty) return;
    context.read<DailyCategoryViewModel>().addCategory(n, _emoji);
    Navigator.pop(context); // 뷰모델에 이미 반영했으므로 그냥 닫기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('카테고리 추가', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          TextButton(onPressed: _save, child: const Text('저장', style: TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          const Text('카테고리명', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              hintText: '카테고리 이름을 입력하세요',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          const Text('이미지', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDialog<String>(
                context: context,
                builder: (_) => SimpleDialog(
                  title: const Text('이모지 선택'),
                  children: [
                    Wrap(
                      children: ['📌','🍽️','🚌','☕️','🎮','🏠','💡','💊','🛒','🎬','📚']
                          .map((e) => TextButton(
                        onPressed: ()=>Navigator.pop(context, e),
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ))
                          .toList(),
                    ),
                  ],
                ),
              );
              if (picked != null) setState(() => _emoji = picked);
            },
            child: Container(
              height: 64,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Text(_emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
        ],
      ),
    );
  }
}
