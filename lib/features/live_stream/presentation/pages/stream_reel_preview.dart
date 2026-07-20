import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/core/route_observer.dart';
import 'package:optombai/features/live_stream/data/models/live_stream_model.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_cubit.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_player/stream_player_cubit.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage(name: 'StreamReelPreviewRoute')
class StreamReelPreview extends StatefulWidget {
  const StreamReelPreview({
    super.key,
    required this.stream,
    required this.isActive,
  });

  final StreamModel stream;
  final bool isActive;

  @override
  State<StreamReelPreview> createState() => _StreamReelPreviewState();
}

class _StreamReelPreviewState extends State<StreamReelPreview> with RouteAware {
  // LiveRoomRoute reuses this same StreamPlayerCubit/renderer (and its
  // native textureId) so the WebRTC connection isn't dropped when opening
  // the room. But a Texture widget bound to that textureId is only ever
  // allowed to paint from one place in the tree at a time — if this
  // preview's RTCVideoView stays mounted while LiveRoomPage pushes another
  // RTCVideoView on top for the same texture, the new one renders black.
  // Swap to a placeholder whenever another route covers this one.
  bool _isRouteCovered = false;
  PageRoute<dynamic>? _subscribedRoute;

  @override
  void initState() {
    super.initState();
    _loadOwner();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _subscribedRoute) {
      appRouteObserver.unsubscribe(this);
      appRouteObserver.subscribe(this, route);
      _subscribedRoute = route;
    }
  }

  @override
  void didUpdateWidget(covariant StreamReelPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream.owner.id != widget.stream.owner.id) {
      _loadOwner();
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    setState(() => _isRouteCovered = true);
  }

  @override
  void didPopNext() {
    setState(() => _isRouteCovered = false);
  }

  void _loadOwner() {
    final ownerId = widget.stream.owner.id;
    if (ownerId.isNotEmpty) {
      context.read<UserBloc>().add(UserOtherWithoutTokenEvent(ownerId));
    }
  }

  void _enterRoom(BuildContext context) {
    final cubit = context.read<StreamPlayerCubit>();
    if (cubit.state.status == StreamPlayerStatus.error) {
      cubit.init();
      return;
    }
    if (cubit.state.status == StreamPlayerStatus.ended) return;
    context.router.push(LiveRoomRoute(
      stream: widget.stream,
      playerCubit: cubit,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final owner = widget.stream.owner;

    return BlocListener<StreamPlayerCubit, StreamPlayerState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == StreamPlayerStatus.ended) {
          context.read<StreamCubit>().removeStream(widget.stream.id);
        }
      },
      child: GestureDetector(
        onTap: () => _enterRoom(context),
        child: Stack(
          children: [
            Positioned.fill(
              child: BlocBuilder<StreamPlayerCubit, StreamPlayerState>(
                buildWhen: (previous, current) =>
                    previous.status != current.status ||
                    previous.renderer != current.renderer,
                builder: (context, state) {
                  if (state.status == StreamPlayerStatus.ended) {
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam_off_outlined,
                                color: Colors.white54, size: 40),
                            SizedBox(height: 8),
                            Text('Эфир завершён',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state.status == StreamPlayerStatus.success &&
                      state.renderer != null) {
                    // Keep adjacent pages painted during the PageView gesture.
                    // isActive controls audio/viewer state, not texture visibility.
                    if (_isRouteCovered) {
                      return const ColoredBox(color: Colors.black);
                    }
                    return RTCVideoView(
                      state.renderer!,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: false,
                    );
                  }
                  if (state.status == StreamPlayerStatus.loading) {
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                            SizedBox(height: 12),
                            Text(
                              'Подключение к эфиру...',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state.status == StreamPlayerStatus.error) {
                    return const ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh,
                                color: Colors.white70, size: 36),
                            SizedBox(height: 8),
                            Text(
                              'Не удалось подключиться. Нажмите, чтобы повторить',
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const ColoredBox(color: Colors.black);
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 30,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.router.push(OtherUserProfileRoute(
                        user: owner.id,
                        username: owner.username,
                      ));
                    },
                    child: BlocBuilder<UserBloc, UserState>(
                      buildWhen: (previous, current) =>
                          previous.otherUserWithoutToken !=
                          current.otherUserWithoutToken,
                      builder: (context, userState) {
                        final fetchedUser =
                            userState.otherUserWithoutToken.id == owner.id
                                ? userState.otherUserWithoutToken
                                : null;
                        final image = fetchedUser?.image;
                        final imageUrl = image is String && image.isNotEmpty
                            ? image
                            : owner.image;
                        final username =
                            (fetchedUser?.username ?? '').isNotEmpty
                                ? fetchedUser!.username
                                : owner.username;
                        final avatarText = username.isEmpty
                            ? 'U'
                            : username.substring(0, 1).toUpperCase();

                        return SizedBox(
                          width: 36.w,
                          height: 36.h,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  width: 2.w, color: Colors.transparent),
                              gradient: const LinearGradient(
                                colors: [Colors.red, Colors.purple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: const Color(0xffF0F0F0),
                              backgroundImage: imageUrl != null
                                  ? NetworkImage(imageUrl)
                                  : null,
                              child: imageUrl == null
                                  ? Text(
                                      avatarText,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<UserBloc, UserState>(
                    buildWhen: (previous, current) =>
                        previous.otherUserWithoutToken !=
                        current.otherUserWithoutToken,
                    builder: (context, userState) {
                      final fetchedUser =
                          userState.otherUserWithoutToken.id == owner.id
                              ? userState.otherUserWithoutToken
                              : null;
                      final username = (fetchedUser?.username ?? '').isNotEmpty
                          ? fetchedUser!.username
                          : owner.username;
                      final countryFlag =
                          (fetchedUser?.country?.square_flag ?? '')
                                  .trim()
                                  .isNotEmpty
                              ? fetchedUser!.country!.square_flag
                              : owner.countryFlag;
                      final countryName =
                          (fetchedUser?.country?.name ?? '').trim().isNotEmpty
                              ? fetchedUser!.country!.name
                              : owner.countryName;
                      final countryLine = [
                        if ((countryFlag ?? '').isNotEmpty) countryFlag!,
                        if ((countryName ?? '').isNotEmpty) countryName!,
                      ].join(' ');
                      final marketName = fetchedUser != null &&
                              fetchedUser.supplierMarkets.isNotEmpty
                          ? fetchedUser.supplierMarkets.first.marketName
                          : owner.marketName;
                      final isVerified = (fetchedUser?.is_verified == true) ||
                          (owner.isVerified == true);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "@$username",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF004D),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            ],
                          ),
                          if (countryLine.isNotEmpty)
                            Text(
                              countryLine,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          if ((marketName ?? '').isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  marketName!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          if (isVerified == true)
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 11,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Проверено',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          const Text(
                            'Нажмите, чтобы смотреть эфир',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
