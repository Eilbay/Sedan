import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/features/live_stream/data/models/live_stream_model.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_cubit.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_player/stream_player_cubit.dart';

/// Opens a user's live room from anywhere in the app (feed, profile, chat,
/// notifications) — contexts that don't already have a [StreamPlayerCubit]
/// scoped to that stream, unlike the reels-style live browsing pages.
class LiveStreamNavigator {
  const LiveStreamNavigator();

  void openRoom(BuildContext context, StreamModel stream) {
    final repository = context.read<StreamCubit>().repository;
    final playerCubit = StreamPlayerCubit(
      streamId: stream.id,
      playApiUrl: stream.playApiUrl,
      streamUrl: stream.webrtc.url,
      repository: repository,
    )..init();

    context.router.push(LiveRoomRoute(stream: stream, playerCubit: playerCubit));
  }
}
