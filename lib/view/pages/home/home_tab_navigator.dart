import 'package:flutter/material.dart';
import 'package:provider/provider.dart';import 'package:sotong/route.dart';

import '../../../component/theme/app_colors.dart'; // <-- appRoutes 가져오기
import '../../../component/theme/padding/horizontal_padding_clamped_fraction.dart';
import '../../../services/tab_chart_animation_notifier.dart';
import '../../../view_model/communication/communication_view_model.dart';
import '../../../view_model/report/report_view_model.dart';

class HomeTabNavigator extends StatefulWidget {
  const HomeTabNavigator({
    super.key,
    this.initialIndex = 1,
  });

  final int initialIndex;

  @override
  State<HomeTabNavigator> createState() => _HomeTabNavigatorState();
}

class _HomeTabNavigatorState extends State<HomeTabNavigator> {
  late PageController _pageController;
  late int _currentIndex;
  late final TabChartAnimationNotifier _tabChartAnimationNotifier;
  bool _skipNextPageChangedChartTrigger = false;

  // appRoutes 키 기반으로 탭 라우트 구성
  final List<String> _tabRoutes = ['/report', '/home', '/communication'];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _tabChartAnimationNotifier = TabChartAnimationNotifier();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReportViewModel>().loadInitial();
      context.read<CommunicationViewModel>().loadMonth(DateTime.now());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabChartAnimationNotifier.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      _tabChartAnimationNotifier.onTabSelected(index);
      return;
    }

    _skipNextPageChangedChartTrigger = true;
    setState(() {
      _currentIndex = index;
    });
    _tabChartAnimationNotifier.onTabSelected(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handlePageChanged(int index) {
    setState(() => _currentIndex = index);
    if (_skipNextPageChangedChartTrigger) {
      _skipNextPageChangedChartTrigger = false;
      return;
    }
    _tabChartAnimationNotifier.onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider.value(
      value: _tabChartAnimationNotifier,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: PageView.builder(
          controller: _pageController,
          itemCount: _tabRoutes.length,
          onPageChanged: _handlePageChanged,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final routeName = _tabRoutes[index];
            final routeBuilder = appRoutes[routeName];

            if (routeBuilder == null) {
              return const Center(child: Text('페이지를 찾을 수 없습니다.'));
            }

            return routeBuilder(context);
          },
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PaddingResponsive16_40Vw.horizontal(
              context,
              PaddingResponsive16_40Vw.fractionScreen075,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              elevation: 0,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded, size: 28),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.home, size: 28),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite, size: 28),
                  label: '',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
