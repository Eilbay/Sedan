import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocProvider;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/data/models/reel/reel_model.dart';
import 'package:optombai/pages/reels/reels_viewer_screen.dart';
import 'package:optombai/features/live_stream/presentation/pages/watch_stream_page.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_cubit.dart';
import 'package:optombai/widgets/category_tabs.dart';

@RoutePage(name: 'ReelsAndStreamViewerRoute')
class ReelsAndStreamViewer extends StatefulWidget {
  final List<ReelModel>? reels;
  final int? reelInitialIndex;
  final bool startWithStream;
  final StreamCubit streamCubit;

  const ReelsAndStreamViewer({
    super.key,
    this.reels,
    this.reelInitialIndex,
    this.startWithStream = false,
    required this.streamCubit,
  });

  @override
  State<ReelsAndStreamViewer> createState() => _ReelsAndStreamViewerState();
}

class _ReelsAndStreamViewerState extends State<ReelsAndStreamViewer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startWithStream ? 1 : 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: BlocProvider<StreamCubit>.value(
          value: widget.streamCubit,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: [
                    if (widget.reels != null && widget.reelInitialIndex != null)
                      ReelsViewerScreen(
                        reels: widget.reels!,
                        initialIndex: widget.reelInitialIndex!,
                      )
                    else
                      const SizedBox.shrink(),
                    WatchStreamPage(isActive: _currentIndex == 1),
                  ],
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top + 12.h,
                      bottom: 12.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: CategoryTabs(
                        currentIndex: _currentIndex,
                        labels: const ['Лента', 'Прямые эфиры'],
                        backgroundColor: Colors.transparent,
                        spacing: 6.w.toInt().toDouble(),
                        onTap: (index) => _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
