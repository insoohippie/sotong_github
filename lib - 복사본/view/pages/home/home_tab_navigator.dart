import 'package:flutter/material.dart';
import 'package:sotong_local/route.dart';

import '../../../component/theme/app_colors.dart'; // <-- appRoutes 가져오기

class HomeTabNavigator extends StatefulWidget {
  const HomeTabNavigator({super.key});

  @override
  State<HomeTabNavigator> createState() => _HomeTabNavigatorState();
}

class _HomeTabNavigatorState extends State<HomeTabNavigator> {
  late PageController _pageController;
  int _currentIndex = 1;

  // appRoutes 키 기반으로 탭 라우트 구성
  final List<String> _tabRoutes = ['/report', '/home', '/communication'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _pageController,
        itemCount: _tabRoutes.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: '레포트'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: '소통'),
        ],
      ),
    );
  }
}
