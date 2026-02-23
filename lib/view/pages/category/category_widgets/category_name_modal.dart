import 'package:flutter/material.dart';
import '../../../../component/buttons/custom_button.dart';
import '../../../../component/inputs/custom_text_field.dart';
import '../../../../component/theme/app_colors.dart';

class CategoryNameModal extends StatefulWidget {
  final bool isEditMode;
  final String? initialName;
  final String? initialEmoji;

  final VoidCallback onClose;
  final void Function(String name, String emoji) onComplete;

  const CategoryNameModal({
    super.key,
    required this.isEditMode,
    this.initialName,
    this.initialEmoji,
    required this.onClose,
    required this.onComplete,
  });

  @override
  State<CategoryNameModal> createState() => _CategoryNameModalState();
}

class _CategoryNameModalState extends State<CategoryNameModal> {
  late final TextEditingController _nameCtrl;
  String _selectedEmoji = '💰';
  bool _showEmojiPicker = false;

  static const List<String> _emojis = [
    '🍽️','☕','🛍️','🎮','🏠','📱','🚌','📺','💼','💰','💳','🏦','📚','🎁','🚗','✈️',
    '🍕','🍔','🍜','🧋','🍺','🍰','👕','👟','🎬','🎨','🏋️','🧘','⚽','🏀',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    final e = (widget.initialEmoji ?? '').trim();
    _selectedEmoji = e.isEmpty ? '💰' : e;
  }

  @override
  void didUpdateWidget(covariant CategoryNameModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialName != widget.initialName) {
      _nameCtrl.text = widget.initialName ?? '';
    }
    if (oldWidget.initialEmoji != widget.initialEmoji) {
      final e = (widget.initialEmoji ?? '').trim();
      _selectedEmoji = e.isEmpty ? '💰' : e;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    widget.onComplete(name, _selectedEmoji);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _nameCtrl.text.trim().isNotEmpty;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // ✅ scrim
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            child: Container(color: Colors.black54),
          ),

          // ✅ bottom sheet (시트 영역은 탭이 scrim으로 새지 않게 막기)
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // 중요: 시트 탭이 scrim으로 안 새게
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showEmojiPicker = !_showEmojiPicker;
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.greyBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(_selectedEmoji, style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomTextField(
                                controller: _nameCtrl,
                                hintText: widget.isEditMode
                                    ? '카테고리 이름을 수정하세요'
                                    : '새 카테고리 이름을 입력하세요',
                                keyboardType: TextInputType.text,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_showEmojiPicker) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Container(
                            height: 140,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 8,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                              ),
                              itemCount: _emojis.length,
                              itemBuilder: (context, index) {
                                final emoji = _emojis[index];
                                final selected = emoji == _selectedEmoji;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedEmoji = emoji;
                                      _showEmojiPicker = false;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFF3B82F6).withOpacity(0.12)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      emoji,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: selected ? const Color(0xFF3B82F6) : null,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      CustomButton(
                        text: widget.isEditMode ? '수정' : '추가',
                        enabled: enabled,
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        onPressed: enabled ? _submit : () {},
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
