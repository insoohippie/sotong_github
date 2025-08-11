import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String hintText;
  final void Function(String?) onChanged;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          builder: (context) => ListView(
            padding: const EdgeInsets.all(16),
            children: items.map((item) {
              return ListTile(
                title: Text(item),
                onTap: () => Navigator.pop(context, item),
              );
            }).toList(),
          ),
        );

        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value ?? hintText,
              style: TextStyle(
                fontSize: 14,
                color: value == null ? Colors.grey : Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
