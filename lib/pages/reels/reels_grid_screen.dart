import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/reel_bloc/reel_bloc.dart';
import 'package:optombai/data/models/reel/reel_model.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/reel/reel_grid_card.dart';
import 'package:optombai/widgets/shimmer/shimmer_product_grid.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_cubit.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class ReelsGridScreen extends StatefulWidget {
  const ReelsGridScreen({super.key});

  @override
  State<ReelsGridScreen> createState() => _ReelsGridScreenState();
}

class _ReelsGridScreenState extends State<ReelsGridScreen> {
  @override
  void initState() {
    super.initState();
    final reelBloc = context.read<ReelBloc>();
    // Show the last cached reels instantly (no shimmer flash) while a
    // background refresh brings the list up to date. `LoadCachedReelsEvent`
    // was registered on the bloc but never actually dispatched anywhere —
    // every cold start/relaunch hit the network from an empty list even
    // when a valid on-disk cache existed, which read as "reels missing at
    // first start" until the fetch finished.
    reelBloc.add(LoadCachedReelsEvent());
    reelBloc.add(FetchReelsEvent(forceRefresh: true));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reelBloc = context.read<ReelBloc>();
      final lastIndex = reelBloc.getLastViewedReelIndex();

      // No upper-bound check on lastIndex any more — the viewer's
      // PageView is now infinite (loops on the loaded reels), so a
      // stored index beyond the current `reels.length` (because the
      // user wrapped around many times) is still a valid initial page.
      if (lastIndex > 0 && reelBloc.state.reels.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _openReelsViewer(context, reelBloc.state.reels, lastIndex);
          }
        });
      }
    });
  }

  Future<void> _handleRefresh() async {
    final reelBloc = context.read<ReelBloc>();
    reelBloc.add(FetchReelsEvent(forceRefresh: true));
    await reelBloc.stream
        .firstWhere((s) => !s.isLoading)
        .timeout(const Duration(seconds: 10), onTimeout: () => reelBloc.state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: BlocBuilder<ReelBloc, ReelState>(
        buildWhen: (previous, current) =>
            previous.reels != current.reels ||
            previous.isLoading != current.isLoading,
        builder: (context, state) {
          if (state.isLoading && state.reels.isEmpty) {
            return const ShimmerProductGrid(itemCount: 9);
          }

          if (state.reels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 80.sp,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16.h),
                  TextTranslated(
                    'Видео пока нет',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.all(4.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4.w,
              mainAxisSpacing: 4.h,
              childAspectRatio: 9 / 16,
            ),
            itemCount: state.reels.length,
            itemBuilder: (context, index) {
              final reel = state.reels[index];
              return RepaintBoundary(
                child: ReelGridCard(
                  reel: reel,
                  onTap: () => _openReelsViewer(context, state.reels, index),
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }

  void _openReelsViewer(
    BuildContext context,
    List<ReelModel> reels,
    int initialIndex,
  ) {
    context.read<ReelBloc>().add(SaveLastViewedReelIndexEvent(index: initialIndex));
    final streamCubit = context.read<StreamCubit>();

    context.router.push(ReelsAndStreamViewerRoute(
      reels: reels,
      reelInitialIndex: initialIndex,
      startWithStream: false,
      streamCubit: streamCubit,
    ));
  }
}
