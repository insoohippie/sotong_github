// lib/view/widgets/texts/multi_color_text.dart
import 'package:flutter/material.dart';

class MultiColorText extends StatelessWidget {
  final List<TextPart> parts;
  final TextStyle baseStyle;

  const MultiColorText({
    super.key,
    required this.parts,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        style: baseStyle,
        children: parts.map((part) {
          return TextSpan(
            text: part.text,
            style: baseStyle.copyWith(
              color: part.color,
              fontWeight: part.bold ? FontWeight.bold : baseStyle.fontWeight,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class TextPart {
  final String text;
  final Color color;
  final bool bold;

  const TextPart(this.text, this.color, {this.bold = false});
}
