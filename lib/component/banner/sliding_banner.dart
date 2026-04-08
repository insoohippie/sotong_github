// lib/component/banner/sliding_banner.dart

import 'dart:async';
import 'package:flutter/material.dart';

class SlidingBanner extends StatefulWidget {
  const SlidingBanner({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 44,
    this.autoSlideDuration,
    this.onPageChanged,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double height;
  final Duration? autoSlideDuration;
  final void Function(int index)? onPageChanged;

  @override
  State<SlidingBanner> createState() => _SlidingBannerState();
}

class _SlidingBannerState extends State<SlidingBanner> {
  static const int _virtualStartPage = 100000;

  late PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = _virtualStartPage;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      initialPage: widget.itemCount > 1 ? _virtualStartPage : 0,
    );

    if (widget.autoSlideDuration != null && widget.itemCount > 1) {
      _startAutoSlide();
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();

    if (widget.itemCount <= 1 || widget.autoSlideDuration == null) return;

    _autoSlideTimer = Timer.periodic(widget.autoSlideDuration!, (timer) async {
      if (!mounted || !_pageController.hasClients) return;
      if (_isUserInteracting) return;

      final next = _currentPage + 1;

      try {
        await _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } catch (_) {
        // dispose 중 등 예외 무시
      }
    });
  }

  void _stopAutoSlide() {
    _autoSlideTimer?.cancel();
  }

  @override
  void didUpdateWidget(covariant SlidingBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    final itemCountChanged = oldWidget.itemCount != widget.itemCount;
    final durationChanged =
        oldWidget.autoSlideDuration != widget.autoSlideDuration;

    if (itemCountChanged) {
      _stopAutoSlide();

      _currentPage = widget.itemCount > 1 ? _virtualStartPage : 0;

      _pageController.dispose();
      _pageController = PageController(
        initialPage: _currentPage,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(_currentPage);
      });
    }

    if (itemCountChanged || durationChanged) {
      _stopAutoSlide();
      if (widget.autoSlideDuration != null && widget.itemCount > 1) {
        _startAutoSlide();
      }
    }
  }

  @override
  void dispose() {
    _stopAutoSlide();
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
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            _isUserInteracting = true;
            _stopAutoSlide();
          } else if (notification is ScrollEndNotification) {
            _isUserInteracting = false;
            if (widget.autoSlideDuration != null && widget.itemCount > 1) {
              _startAutoSlide();
            }
          }
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            _currentPage = index;
            final logicalIndex = index % widget.itemCount;
            widget.onPageChanged?.call(logicalIndex);
          },
          itemBuilder: (context, index) {
            final logicalIndex = index % widget.itemCount;
            return widget.itemBuilder(context, logicalIndex);
          },
        ),
      ),
    );
  }
}