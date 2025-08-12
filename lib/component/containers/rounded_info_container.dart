import 'package:flutter/material.dart';

class RoundedInfoContainer extends StatelessWidget {
  final Widget child;
  final double padding;
  final double borderRadius;
  final Color backgroundColor;

  const RoundedInfoContainer({
    super.key,
    required this.child,
    this.padding = 30,
    this.borderRadius = 16,
    this.backgroundColor = const Color(0xFFF0F6FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}
