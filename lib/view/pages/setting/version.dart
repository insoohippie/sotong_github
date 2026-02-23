import 'package:flutter/material.dart';

import '../../../component/theme/app_colors.dart';

/// 버전관리 화면: 앱 아이콘 + 소통 / 1.0.0 + 업데이트 버튼 (카톡 앱관리 스타일)
class VersionPage extends StatelessWidget {
  const VersionPage({Key? key}) : super(key: key);

  static const String appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        title: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '버전정보',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard Variable',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    // 앱 아이콘 (소통 로고/이미지)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/bot_profile.png',
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '소통',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Pretendard Variable',
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // 앱 이름 + 버전
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '소통',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard Variable',
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appVersion,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Pretendard Variable',
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 업데이트 버튼
                    Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () {
                          // TODO: 업데이트 로직 (스토어 이동 등)
                        },
                        borderRadius: BorderRadius.circular(8),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            '업데이트',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard Variable',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
