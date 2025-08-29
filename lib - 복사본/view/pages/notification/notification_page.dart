import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../component/theme/app_border_radius.dart';
import '../../../model/notification_item.dart';
import '../../../view_model/notification/notification_view_model.dart';
import 'notification_setting.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // 테스트용 샘플 알림 생성
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().generateSampleNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '알림',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'Pretendard Variable',
          ),
        ),
        centerTitle: false,
        actions: [
          Consumer<NotificationViewModel>(
            builder: (context, vm, child) {
              if (vm.notifications.isNotEmpty) {
                return TextButton(
                  onPressed: () {
                    vm.markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('모든 알림을 읽음 처리했습니다.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text(
                    '모두 읽음',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 탭 바
            Container(
              color: const Color(0xFFF8F9FA),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF2563EB),
                tabs: const [
                  Tab(text: '출석'),
                  Tab(text: '홈'),
                  Tab(text: '레포트'),
                  Tab(text: '소통'),
                ],
              ),
            ),
            // 탭 뷰
            Expanded(
              child: Consumer<NotificationViewModel>(
                builder: (context, vm, child) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNotificationList(
                        NotificationCategory.attendance,
                        vm,
                      ),
                      _buildNotificationList(NotificationCategory.home, vm),
                      _buildNotificationList(NotificationCategory.report, vm),
                      _buildNotificationList(
                        NotificationCategory.communication,
                        vm,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    NotificationCategory category,
    NotificationViewModel vm,
  ) {
    final categoryNotifications = vm.notifications
        .where((n) => n.category == category)
        .toList();

    // 오늘과 지난 알림으로 분류
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayNotifications = categoryNotifications.where((n) {
      final notificationDate = DateTime(
        n.createdAt.year,
        n.createdAt.month,
        n.createdAt.day,
      );
      return notificationDate.isAtSameMomentAs(today);
    }).toList();

    final pastNotifications = categoryNotifications.where((n) {
      final notificationDate = DateTime(
        n.createdAt.year,
        n.createdAt.month,
        n.createdAt.day,
      );
      return notificationDate.isBefore(today);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 오늘 알림 섹션 (항상 표시)
        _buildSectionHeader('오늘 알림'),
        const SizedBox(height: 8),
        _buildNotificationSection(todayNotifications, vm),

        // 지난 알림 섹션 (항상 표시)
        const SizedBox(height: 24),
        _buildSectionHeader('지난 알림'),
        const SizedBox(height: 8),
        _buildNotificationSection(pastNotifications, vm),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          fontFamily: 'Pretendard Variable',
        ),
      ),
    );
  }

  Widget _buildNotificationSection(
    List<NotificationItem> notifications,
    NotificationViewModel vm,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '알림이 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: notifications
                  .map(
                    (notification) => _buildNotificationItem(notification, vm),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildNotificationItem(
    NotificationItem notification,
    NotificationViewModel vm,
  ) {
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
            action: SnackBarAction(
              label: '실행 취소',
              onPressed: () {
                // 삭제된 알림을 다시 추가하는 로직은 복잡하므로 간단히 처리
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 0.5),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: notification.isRead
                  ? Colors.grey.withOpacity(0.3)
                  : const Color(0xFF2563EB).withOpacity(0.1),
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
              fontWeight: notification.isRead
                  ? FontWeight.normal
                  : FontWeight.w600,
              color: Colors.black,
              fontFamily: 'Pretendard Variable',
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'Pretendard Variable',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _formatTime(notification.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontFamily: 'Pretendard Variable',
                ),
              ),
            ],
          ),
          onTap: () {
            if (!notification.isRead) {
              vm.markAsRead(notification.id);
            }
            if (notification.targetRoute != null) {
              // 네비게이션 로직
            }
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
