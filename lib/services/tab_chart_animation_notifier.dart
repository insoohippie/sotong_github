import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// 홈/레포트 탭 전환(네비게이션·스와이프) 시 차트 애니메이션 재생 트리거
class TabChartAnimationNotifier extends ChangeNotifier {
  static const int reportTabIndex = 0;
  static const int homeTabIndex = 1;

  int _homeAnimationTick = 0;
  int _reportAnimationTick = 0;

  int get homeAnimationTick => _homeAnimationTick;
  int get reportAnimationTick => _reportAnimationTick;

  void onTabSelected(int index) {
    switch (index) {
      case homeTabIndex:
        _homeAnimationTick++;
        notifyListeners();
      case reportTabIndex:
        _reportAnimationTick++;
        notifyListeners();
      default:
        break;
    }
  }
}

extension TabChartAnimationWatch on BuildContext {
  int get homeChartAnimationTick =>
      _watchTabChartAnimationNotifier()?.homeAnimationTick ?? 0;

  int get reportChartAnimationTick =>
      _watchTabChartAnimationNotifier()?.reportAnimationTick ?? 0;

  TabChartAnimationNotifier? _watchTabChartAnimationNotifier() {
    try {
      return Provider.of<TabChartAnimationNotifier>(this, listen: true);
    } on ProviderNotFoundException {
      return null;
    }
  }
}
