// lib/component/banner/sliding_banner.dart

import 'dart:async';
import 'package:flutter/material.dart';

/// 앱바 아래 슬라이드 배너 — 아래→위로 넘어가는 형태.
/// 각 뷰(Communication, Report 등)에서 itemCount + itemBuilder 로 내용만 채워 넣어 사용.
class SlidingBanner extends StatefulWidget {
  const SlidingBanner({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 44,
    this.autoSlideDuration,
    this.onPageChanged,
  });

  /// 슬라이드 개수 (1이면 한 장만 표시)
  final int itemCount;

  /// 각 인덱스별로 보여줄 위젯 (각 뷰에서 자유롭게 구성)
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// 배너 높이
  final double height;

  /// 주기마다 다음 슬라이드로 자동 이동 (null이면 자동 슬라이드 없음)
  final Duration? autoSlideDuration;

  /// 페이지가 바뀔 때 호출 (현재 인덱스 전달)
  final void Function(int index)? onPageChanged;

  @override
  State<SlidingBanner> createState() => _SlidingBannerState();
}

class _SlidingBannerState extends State<SlidingBanner> {
  late PageController _pageController;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.autoSlideDuration != null && widget.itemCount > 1) {
      _startAutoSlide();
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (widget.itemCount <= 1) return;

    _autoSlideTimer = Timer.periodic(widget.autoSlideDuration!, (timer) {
      if (!_pageController.hasClients || !mounted) return;
      final next = (_currentPage + 1) % widget.itemCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant SlidingBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoSlideDuration != widget.autoSlideDuration ||
        oldWidget.itemCount != widget.itemCount) {
      _autoSlideTimer?.cancel();
      if (widget.autoSlideDuration != null && widget.itemCount > 1) {
        _startAutoSlide();
      }
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount <= 0) {
      return SizedBox(height: widget.height);
    }

    if (widget.itemCount == 1) {
      return SizedBox(
        height: widget.height,
        child: widget.itemBuilder(context, 0),
      );
    }

    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: (index) {
          _currentPage = index;
          widget.onPageChanged?.call(index);
        },
        itemCount: widget.itemCount,
        itemBuilder: (context, index) => widget.itemBuilder(context, index),
      ),
    );
  }
}
