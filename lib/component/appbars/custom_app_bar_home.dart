import 'package:flutter/material.dart';
import 'package:sotong_local/component/texts/header_text.dart';

import '../theme/app_spacing.dart';

class CustomAppBarHome extends StatelessWidget {
  final String text;
  final VoidCallback? onSettings;
  final VoidCallback? onNotifications;
  final int unreadCount;

  const CustomAppBarHome({
    super.key,
    required this.text,
    this.onSettings,
    this.onNotifications,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sectionSpacing,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          HeaderText(text: '$text'),
          Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, size: 28),
                    onPressed: onNotifications ?? () {},
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.settings, size: 28),
                onPressed: onSettings ?? () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
