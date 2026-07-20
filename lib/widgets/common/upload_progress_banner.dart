import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/product_bloc/product_bloc.dart';
import 'package:optombai/bloc/reel_bloc/reel_bloc.dart';
import 'package:optombai/bloc/upload_cubit/upload_cubit.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

class UploadProgressBanner extends StatelessWidget {
  const UploadProgressBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UploadCubit, UploadState>(
      // Fire on:
      //  - first UploadUploading (inserts optimistic card)
      //  - any UploadError after optimistic insert (rolls it back)
      listenWhen: (prev, next) {
        final prevProduct = prev is UploadUploading ? prev.optimisticProduct : null;
        final nextProduct = next is UploadUploading ? next.optimisticProduct : null;
        final inserted =
            prevProduct?.id != nextProduct?.id && nextProduct != null;
        final errored = prev is UploadUploading && next is UploadError;
        return inserted || errored;
      },
      listener: (context, state) {
        if (state is UploadUploading && state.optimisticProduct != null) {
          context
              .read<ProductBloc>()
              .add(OptimisticAddProductEvent(state.optimisticProduct!));
        } else if (state is UploadError) {
          // Either the post still exists on the server (photo upload failed,
          // retry available) or it was rolled back (video failed).
          // In both cases, the optimistic card needs to go — it points to
          // a local thumbnail that either will be replaced on retry success
          // or never resolves.
          final idToRemove =
              state.postId.isNotEmpty ? state.postId : state.rolledBackPostId;
          if (idToRemove.isNotEmpty) {
            context
                .read<ProductBloc>()
                .add(OptimisticRemoveProductEvent(idToRemove));
          }
        }
      },
      builder: (context, state) {
        return switch (state) {
          UploadIdle() => const SizedBox.shrink(),
          UploadProcessing() =>
            _ProcessingBanner(statusText: state.statusText),
          UploadCreating() => _CreatingBanner(thumbnail: state.thumbnail),
          UploadUploading() => _UploadingBanner(
              thumbnail: state.thumbnail,
              progress: state.progress,
              uploaded: state.uploaded,
              total: state.total,
            ),
          UploadSuccess() => _SuccessBanner(postId: state.postId),
          UploadError() => _ErrorBanner(message: state.message),
        };
      },
    );
  }
}

class _BannerContainer extends StatelessWidget {
  final Widget child;

  const _BannerContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final File? thumbnail;

  const _Thumbnail({required this.thumbnail});

  @override
  Widget build(BuildContext context) {
    if (thumbnail == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image, size: 20, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        thumbnail!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _ProcessingBanner extends StatelessWidget {
  final String statusText;

  const _ProcessingBanner({required this.statusText});

  @override
  Widget build(BuildContext context) {
    return _BannerContainer(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.videocam, size: 20, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextTranslated(
                  statusText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  borderRadius: BorderRadius.circular(2),
                  minHeight: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatingBanner extends StatelessWidget {
  final File? thumbnail;

  const _CreatingBanner({required this.thumbnail});

  @override
  Widget build(BuildContext context) {
    return _BannerContainer(
      child: Row(
        children: [
          _Thumbnail(thumbnail: thumbnail),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const TextTranslated(
                  'Создание поста...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  borderRadius: BorderRadius.circular(2),
                  minHeight: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadingBanner extends StatelessWidget {
  final File? thumbnail;
  final double progress;
  final int uploaded;
  final int total;

  const _UploadingBanner({
    required this.thumbnail,
    required this.progress,
    required this.uploaded,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return _BannerContainer(
      child: Row(
        children: [
          _Thumbnail(thumbnail: thumbnail),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextTranslated(
                  'Публикуется... ($uploaded/$total)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  borderRadius: BorderRadius.circular(2),
                  minHeight: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatefulWidget {
  final String postId;

  const _SuccessBanner({required this.postId});

  @override
  State<_SuccessBanner> createState() => _SuccessBannerState();
}

class _SuccessBannerState extends State<_SuccessBanner> {
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _refreshFeedAndScheduleDismiss();
  }

  void _refreshFeedAndScheduleDismiss() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Re-runs the last ProductWithFilter from the home feed with
      // forceRefresh=true, so the new post (and its server cover) show up
      // under the user's current filters. Unlike FetchAllProductsEvent,
      // this preserves category/country/type filters.
      context.read<ProductBloc>().add(RefreshCurrentFilterEvent());
      context.read<ProductBloc>().add(InvalidateProfileCacheEvent());
      context.read<ReelBloc>().add(InvalidateReelsCacheEvent());

      // Actively refetch the owner's profile feed if we know the
      // username — covers the case where the user is currently on
      // their profile screen and would otherwise keep seeing the
      // stale list.
      final username = context.read<UserBloc>().state.user.username;
      if (username.isNotEmpty) {
        context.read<ProductBloc>().add(
              GetProfileProductsEvent(username, forceRefresh: true),
            );
      }
    });

    _autoDismissTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.read<UploadCubit>().dismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BannerContainer(
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: TextTranslated(
              'Опубликовано!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.read<UploadCubit>().dismiss(),
            child: const Icon(Icons.close, size: 20, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return _BannerContainer(
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const TextTranslated(
                  'Ошибка загрузки',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                if (message.isNotEmpty)
                  Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.read<UploadCubit>().retry(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const TextTranslated(
              'Повторить',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
          // Dismiss the failed-upload banner without retrying.
          GestureDetector(
            onTap: () => context.read<UploadCubit>().dismiss(),
            child: const Icon(Icons.close, size: 20, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
