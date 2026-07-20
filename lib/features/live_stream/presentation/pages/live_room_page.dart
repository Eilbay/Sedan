import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/features/live_stream/data/models/live_stream_model.dart';
import 'package:optombai/features/live_stream/presentation/logic/live_chat_cubit.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_ban_cubit.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_player/stream_player_cubit.dart';
import 'package:optombai/features/live_stream/presentation/widgets/ban_user_bottom_sheet.dart';
import 'package:optombai/features/live_stream/presentation/widgets/live_badge.dart';
import 'package:optombai/features/live_stream/presentation/widgets/live_chat_widget.dart';
import 'package:optombai/features/live_stream/presentation/widgets/viewers_bottom_sheet.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_cubit.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/custom_avatar.dart';
import 'package:optombai/core/route_observer.dart';
import 'package:optombai/data/models/report/report_target_type.dart';
import 'package:optombai/widgets/moderation/report_bottom_sheet.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class LiveRoomPage extends StatefulWidget {
  const LiveRoomPage({
    super.key,
    required this.stream,
    required this.playerCubit,
  });

  final StreamModel stream;
  final StreamPlayerCubit playerCubit;

  @override
  State<LiveRoomPage> createState() => _LiveRoomPageState();
}

class _LiveRoomPageState extends State<LiveRoomPage> with RouteAware {
  bool _hideUI = false;
  PageRoute<dynamic>? _subscribedRoute;

  @override
  void initState() {
    super.initState();
    widget.playerCubit.setActive(true);
    // BottomNav updates its covered-route state during the same transition
    // and may pause the shared pool after this initState. Reassert ownership
    // once that frame is complete so room audio cannot remain muted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.playerCubit.setActive(true);
    });

    final ownerId = widget.stream.owner.id;
    if (ownerId.isNotEmpty) {
      context.read<UserBloc>().add(UserOtherWithoutTokenEvent(ownerId));
    }
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
  void didPushNext() => widget.playerCubit.setActive(false);

  @override
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.playerCubit.setActive(true);
    });
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  void _toggleUI() {
    setState(() => _hideUI = !_hideUI);
  }

  void _onStreamEnded() {
    debugPrint('[LiveRoomPage] Stream ended for ${widget.stream.id}');
    if (!mounted) return;
    context.read<StreamCubit>().removeStream(widget.stream.id);
    context.router.maybePop();
  }

  Future<void> _onBanned() async {
    debugPrint('[LiveRoomPage] Viewer banned from ${widget.stream.id}');
    if (!mounted) return;

    final durationLabel = context.read<LiveChatCubit>().state.banDurationLabel;
    // Persist ban across list refreshes so stream doesn't re-appear.
    context.read<StreamCubit>().addBannedStream(widget.stream.id);

    final subtitle = durationLabel != null
        ? 'Хост заблокировал вас на $durationLabel.'
        : 'Хост заблокировал вас в этом эфире.';

    // Black barrier covers the stream (feels like exit happened first).
    // Pop happens after the user acknowledges the dialog.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon:
            const Icon(Icons.block_rounded, color: Color(0xFFFF004D), size: 40),
        title: const Text(
          'Вы заблокированы',
          textAlign: TextAlign.center,
        ),
        content: Text(subtitle, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF004D),
              minimumSize: const Size(120, 40),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    context.router.maybePop();
  }

  void _showReportSheet(BuildContext ctx) {
    ReportBottomSheet.show(
      ctx,
      targetType: ReportTargetType.stream,
      targetId: widget.stream.id,
      authorUserId: widget.stream.owner.id,
      // No backend support for stream reports yet — picking a reason just
      // closes the live room for this viewer locally.
      submitToBackend: false,
      onReported: () => context.router.maybePop(),
    );
  }

  void _showBanSheet(BuildContext ctx, ChatMessage message) {
    if (message.userId.isEmpty) return;
    BanUserBottomSheet.show(
      ctx,
      username: message.username,
      userId: message.userId,
      messenger: ScaffoldMessenger.of(ctx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserBloc>().state;
    final currentUser = userState.user;
    final owner = widget.stream.owner;
    final isStreamOwner = currentUser.id == owner.id;
    debugPrint(
      '[LIVE_ROOM] currentUser.id=${currentUser.id} owner.id=${owner.id} '
      'isStreamOwner=$isStreamOwner',
    );

    final fetchedOwner = userState.otherUser.id == owner.id
        ? userState.otherUser
        : userState.otherUserWithoutToken.id == owner.id
            ? userState.otherUserWithoutToken
            : null;
    final fetchedOwnerImage = fetchedOwner?.image;
    final ownerAvatarUrl =
        fetchedOwnerImage is String && fetchedOwnerImage.isNotEmpty
            ? fetchedOwnerImage
            : owner.image;
    final ownerUsername = (fetchedOwner?.username ?? '').isNotEmpty
        ? fetchedOwner!.username
        : owner.username;

    return BlocProvider.value(
      value: widget.playerCubit,
      child: Builder(builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (ctx) => LiveChatCubit(
                streamUuid: widget.stream.id,
                token: ctx.read<AuthCubit>().getToken(),
                initialViewerCount: widget.stream.viewers,
              )..connect(),
            ),
            BlocProvider(
              create: (ctx) => StreamBanCubit(
                repository: ctx.read<StreamCubit>().repository,
                token: ctx.read<AuthCubit>().getToken(),
                streamId: widget.stream.id,
              ),
            ),
          ],
          child: Builder(builder: (ctx) {
            return MultiBlocListener(
              listeners: [
                BlocListener<StreamPlayerCubit, StreamPlayerState>(
                  listenWhen: (previous, current) =>
                      previous.status != current.status,
                  listener: (_, state) {
                    if (state.status == StreamPlayerStatus.ended) {
                      _onStreamEnded();
                    }
                  },
                ),
                BlocListener<LiveChatCubit, LiveChatState>(
                  listenWhen: (previous, current) =>
                      !previous.isBanned && current.isBanned,
                  listener: (_, __) => _onBanned(), // intentionally unawaited
                ),
                BlocListener<LiveChatCubit, LiveChatState>(
                  listenWhen: (previous, current) =>
                      !previous.streamEnded &&
                      current.streamEnded &&
                      !current.isBanned,
                  listener: (_, state) {
                    debugPrint(
                        '[LiveRoomPage] stream.ended reason=${state.endReason} '
                        'for ${widget.stream.id}');
                    _onStreamEnded();
                  },
                ),
              ],
              child: Scaffold(
                backgroundColor: Colors.black,
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: _RoomVideoPlayer(onTap: _toggleUI),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: _hideUI,
                        child: AnimatedOpacity(
                          opacity: _hideUI ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: SafeArea(
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 10,
                                  left: 12,
                                  right: 12,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          context.router.push(
                                            OtherUserProfileRoute(
                                              user: widget.stream.owner.id,
                                              username:
                                                  widget.stream.owner.username,
                                            ),
                                          );
                                        },
                                        child: _StreamerInfoPill(
                                          stream: widget.stream,
                                          isStreamOwner: isStreamOwner,
                                          onViewersTap: isStreamOwner
                                              ? () =>
                                                  ViewersBottomSheet.show(ctx)
                                              : null,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (!isStreamOwner) ...[
                                        GestureDetector(
                                          onTap: () => _showReportSheet(ctx),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: 0.45),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.6),
                                                width: 1,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.more_vert,
                                              size: 22,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                      ],
                                      GestureDetector(
                                        onTap: () => context.router.maybePop(),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.45),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.6),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 12,
                                  child: LiveChatWidget(
                                    streamOwnerUsername: ownerUsername,
                                    streamOwnerAvatarUrl: ownerAvatarUrl,
                                    currentUsername: currentUser.username,
                                    currentUserAvatarUrl: currentUser.image,
                                    isStreamOwner: isStreamOwner,
                                    onBanRequest: isStreamOwner
                                        ? (msg) => _showBanSheet(ctx, msg)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}

class _RoomVideoPlayer extends StatelessWidget {
  const _RoomVideoPlayer({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.black,
        child: BlocBuilder<StreamPlayerCubit, StreamPlayerState>(
          buildWhen: (previous, current) =>
              previous.status != current.status ||
              previous.renderer != current.renderer,
          builder: (context, state) {
            if (state.status == StreamPlayerStatus.ended) {
              return const ColoredBox(color: Colors.black);
            }
            if (state.status == StreamPlayerStatus.success &&
                state.renderer != null) {
              return RTCVideoView(
                state.renderer!,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: false,
              );
            }
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          },
        ),
      ),
    );
  }
}

class _StreamerInfoPill extends StatelessWidget {
  const _StreamerInfoPill({
    required this.stream,
    this.isStreamOwner = false,
    this.onViewersTap,
  });
  final StreamModel stream;
  final bool isStreamOwner;
  final VoidCallback? onViewersTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (previous, current) =>
          previous.otherUser != current.otherUser ||
          previous.otherUserWithoutToken != current.otherUserWithoutToken,
      builder: (context, userState) {
        final owner = stream.owner;
        final otherUser = userState.otherUser.id == owner.id
            ? userState.otherUser
            : userState.otherUserWithoutToken.id == owner.id
                ? userState.otherUserWithoutToken
                : null;

        final username = (otherUser?.username ?? '').isNotEmpty
            ? otherUser!.username
            : owner.username;
        final image = otherUser?.image;
        final imageUrl =
            image is String && image.isNotEmpty ? image : owner.image;
        final countryName = (otherUser?.country?.name ?? '').trim().isNotEmpty
            ? otherUser!.country!.name
            : owner.countryName;
        final countryFlag =
            (otherUser?.country?.square_flag ?? '').trim().isNotEmpty
                ? otherUser!.country!.square_flag
                : owner.countryFlag;
        final marketName =
            otherUser != null && otherUser.supplierMarkets.isNotEmpty
                ? otherUser.supplierMarkets.first.marketName
                : owner.marketName;
        final isVerified =
            (otherUser?.is_verified == true) || (owner.isVerified == true);

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 30.w,
                    height: 30.h,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(width: 2.w, color: Colors.transparent),
                        gradient: const LinearGradient(
                          colors: [Colors.red, Colors.purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: const Color(0xffF0F0F0),
                        backgroundImage: imageUrl != null
                            ? CachedNetworkImageProvider(imageUrl)
                            : null,
                        child: imageUrl == null
                            ? CustomAvatar(
                                sizeAvatar: 55,
                                width: 110.w,
                                height: 110.h,
                                size: 60,
                                colorContainer: Colors.black12,
                                colorContainerBorder: Colors.black12,
                                image: null,
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (isVerified == true)
                    const Positioned(
                      top: 0,
                      right: -2,
                      child: Icon(Icons.verified, color: Colors.blue, size: 16),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LiveBadge(),
                      const SizedBox(width: 6),
                      BlocBuilder<LiveChatCubit, LiveChatState>(
                        buildWhen: (previous, current) =>
                            previous.viewerCount != current.viewerCount,
                        builder: (context, chatState) {
                          // The server's viewer count always includes the host's
                          // own open connection — subtract it so viewers see the
                          // actual audience size, not audience+host.
                          final displayedCount = chatState.viewerCount > 0
                              ? chatState.viewerCount - 1
                              : 0;
                          final row = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.remove_red_eye_outlined,
                                  color: Colors.white70, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                '$displayedCount',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 9),
                              ),
                              if (isStreamOwner)
                                const Padding(
                                  padding: EdgeInsets.only(left: 2),
                                  child: Icon(Icons.keyboard_arrow_down,
                                      color: Colors.white54, size: 10),
                                ),
                            ],
                          );
                          if (onViewersTap == null) return row;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onViewersTap,
                            child: row,
                          );
                        },
                      ),
                    ],
                  ),
                  if ((countryName ?? '').isNotEmpty ||
                      (countryFlag ?? '').isNotEmpty)
                    Row(
                      children: [
                        if ((countryFlag ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: TextTranslated(
                              countryFlag!,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        if ((countryName ?? '').isNotEmpty)
                          TextTranslated(
                            countryName!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                  if ((marketName ?? '').isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          marketName!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  if (isVerified == true)
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 10,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Проверено',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}

