import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/theme/app_border_radius.dart';
import '../../../model/notification/notification_item.dart';
import '../../../view_model/notification/notification_view_model.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().loadNotifications();
    });
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _mondayOfWeek(DateTime any) {
    final day = _dateOnly(any);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static DateTime _sundayOfWeek(DateTime any) {
    return _mondayOfWeek(any).add(const Duration(days: 6));
  }

  static Map<String, List<NotificationItem>> _partitionByTime(
    List<NotificationItem> all,
  ) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final weekStart = _mondayOfWeek(now);
    final weekEnd = _sundayOfWeek(now);

    final todayList = <NotificationItem>[];
    final thisWeekList = <NotificationItem>[];
    final pastList = <NotificationItem>[];

    for (final n in all) {
      final d = _dateOnly(n.createdAt);

      if (d == today) {
        todayList.add(n);
      } else if (!d.isBefore(weekStart) && !d.isAfter(weekEnd)) {
        thisWeekList.add(n);
      } else {
        pastList.add(n);
      }
    }

    int byTimeDesc(NotificationItem a, NotificationItem b) {
      return b.createdAt.compareTo(a.createdAt);
    }

    todayList.sort(byTimeDesc);
    thisWeekList.sort(byTimeDesc);
    pastList.sort(byTimeDesc);

    return {'today': todayList, 'thisWeek': thisWeekList, 'past': pastList};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const BackOnlyAppBar(),
      body: SafeArea(
        child: Consumer<NotificationViewModel>(
          builder: (context, vm, _) {
            final buckets = _partitionByTime(vm.notifications);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('오늘 알림', context),
                const SizedBox(height: 8),
                _buildNotificationSection(buckets['today']!, vm, context),

                const SizedBox(height: 24),
                _buildSectionHeader('이번 주 알림', context),
                const SizedBox(height: 8),
                _buildNotificationSection(buckets['thisWeek']!, vm, context),

                const SizedBox(height: 24),
                _buildSectionHeader('지난 알림', context),
                const SizedBox(height: 8),
                _buildNotificationSection(buckets['past']!, vm, context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
          fontFamily: 'Pretendard Variable',
        ),
      ),
    );
  }

  Widget _buildNotificationSection(
    List<NotificationItem> notifications,
    NotificationViewModel vm,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: theme.dividerColor),
      ),
      child: notifications.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 32,
                      color: muted.withValues(alpha: 0.75),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '알림이 없습니다',
                      style: TextStyle(
                        fontSize: 11,
                        color: muted,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: notifications
                  .map((n) => _buildNotificationItem(n, vm))
                  .toList(),
            ),
    );
  }

  Widget _buildNotificationItem(
    NotificationItem notification,
    NotificationViewModel vm,
  ) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: AppBorderRadius.card,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      onDismissed: (direction) {
        vm.removeNotification(notification.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${notification.title} 알림을 삭제했습니다.'),
            action: SnackBarAction(label: '실행 취소', onPressed: () {}),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: notification.isRead
                  ? Colors.grey.withValues(alpha: 0.3)
                  : const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: AppBorderRadius.button,
            ),
            child: Icon(
              _getIconForType(notification.type),
              color: notification.isRead
                  ? Colors.grey
                  : const Color(0xFF2563EB),
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: notification.isRead
                  ? FontWeight.normal
                  : FontWeight.w600,
              color: theme.colorScheme.onSurface,
              fontFamily: 'Pretendard Variable',
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface,
                  fontFamily: 'Pretendard Variable',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                _formatTime(notification.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
            ],
          ),
          onTap: () async {
            if (!notification.isRead) {
              await vm.markAsRead(notification.id);
            }

            final route = notification.targetRoute;
            if (route == null) return;

            final Object? args =
                notification.targetTabIndex ?? notification.targetDate;

            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamed(route, arguments: args);
          },
        ),
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.recordReminder:
        return Icons.check_circle;
      case NotificationType.timeValue:
        return Icons.access_time;
      case NotificationType.report:
        return Icons.analytics;
      case NotificationType.emotion:
        return Icons.psychology;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
