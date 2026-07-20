import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/bloc/auth_bloc/auth_state.dart';
import 'package:optombai/bloc/reel_bloc/reel_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/services/i_video_pre_buffer_service.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How many of the first cached reels get their video pre-buffered during
/// splash, so opening the Reels tab plays instantly instead of showing a
/// loading spinner. Kept small — pre-buffering is a startup-time cost too.
const _prewarmReelCount = 3;

@RoutePage()
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minSplashDuration = Duration(seconds: 2);

  // STORE_RELEASE_HIDDEN:
  static const bool _enableOnboarding = false;

  bool _navigated = false;
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<UserState>? _userSub;
  StreamSubscription<ReelState>? _reelSub;

  final _splashSw = Stopwatch();

  @override
  void initState() {
    super.initState();
    _splashSw.start();
    debugPrint('[PRELOAD] Splash initState — auth only');

    _startPreloadFlow();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeFromPrefs();
    });
  }

  Future<void> _routeFromPrefs() async {
    debugPrint(
      '[PRELOAD] _routeFromPrefs entered mounted=$mounted '
      'navigated=$_navigated ${_splashSw.elapsedMilliseconds}ms',
    );

    if (!mounted || _navigated) return;

    final prefs = getIt<SharedPreferences>();

    final isFirstRun = !(prefs.getBool('first_launch_done') ?? false);

    // STORE_RELEASE_HIDDEN_START: ONBOARDING

    if (_enableOnboarding && isFirstRun) {
      _navigated = true;
      await prefs.setBool('first_launch_done', true);
      await _waitForMinSplashDuration();
      if (!mounted) return;
      debugPrint('[PRELOAD] ${_splashSw.elapsedMilliseconds}ms — navigating to ONBOARDING');
      context.router.replaceAll([const OnboardingLanguageRoute()]);
      return;
    }
    // STORE_RELEASE_HIDDEN_END: ONBOARDING

    if (isFirstRun) {
      await prefs.setBool('first_launch_done', true);
    }

    _navigated = true;

    final hasToken = (prefs.getString(TOKEN_KEY) ?? '').isNotEmpty;

    context.read<ThemeNotifier>().setRegistrationStatus(hasToken);
    await _waitForMinSplashDuration();
    if (!mounted) return;
    debugPrint(
      '[PRELOAD] ${_splashSw.elapsedMilliseconds}ms '
      '— navigating to HOME (hasToken=$hasToken)',
    );

    if (!mounted) return;

    context.router.replaceAll([
      // STORE_RELEASE_HIDDEN:

      BottomNavRoute(startTour: false),
    ]);
  }

  // Keeps the intro image on screen for a fixed duration regardless of how
  // fast the local-prefs routing decision above resolves.
  Future<void> _waitForMinSplashDuration() async {
    final remaining = _minSplashDuration - _splashSw.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    _reelSub?.cancel();
    super.dispose();
  }

  void _startPreloadFlow() {
    final authCubit = context.read<AuthCubit>();
    final userBloc = context.read<UserBloc>();

    // Reel metadata itself is still only *fetched from network* when the
    // user opens the Reels tab — keeps splash/home startup fast and avoids
    // the large /api/v2/posts/reels/ payload competing with home data.
    _prewarmFirstReels();

    // Background only: refresh the token and load the profile, then keep
    // the registration flag in sync. Navigation does NOT wait on any of
    // this — it is decided from local state in _routeFromPrefs.
    _authSub = authCubit.stream.listen((authState) {
      if (!mounted) return;

      if (authState is AuthStateSuccess) {
        userBloc.add(UserOwnerEvent());
      } else if (authState is AuthStateError && authState.isExit) {
        context.read<ThemeNotifier>().setRegistrationStatus(false);
      }
    });

    _userSub = userBloc.stream.listen((userState) {
      if (!mounted) return;

      if (userState.isSuccess) {
        context.read<ThemeNotifier>().setRegistrationStatus(true);
      } else if (userState.isExit) {
        context.read<ThemeNotifier>().setRegistrationStatus(false);
      }
    });

    authCubit.refreshToken();
  }

  // Reads whatever reel list is already cached locally (no network call)
  // and pre-buffers the first few videos, so opening the Reels tab right
  // after startup plays instantly instead of showing a loading spinner.
  // Quality is untouched — native HLS ABR picks the rendition, same as
  // regular reel playback.
  void _prewarmFirstReels() {
    final reelBloc = context.read<ReelBloc>();
    _reelSub = reelBloc.stream.listen((state) {
      if (state.reels.isEmpty) return;
      _reelSub?.cancel();

      final urls = state.reels
          .take(_prewarmReelCount)
          .map((reel) => reel.playbackUrl)
          .where((url) => url.isNotEmpty)
          .toList();
      if (urls.isNotEmpty) {
        getIt<IVideoPreBufferService>().enqueue(urls);
      }
    });
    reelBloc.add(LoadCachedReelsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/splash_intro.png",
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        if (state is AuthStateError && !state.isExit) {
                          return _retrySection(textTheme);
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                    BlocBuilder<UserBloc, UserState>(
                      builder: (context, state) {
                        if (state.isLoading) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state.errors.isNotEmpty) {
                          return _retrySection(textTheme);
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _retrySection(TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextTranslated(
          'Повторить попытку?',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        SizedBox(height: 20.h),
        CustomButton(
          borderRadius: 20,
          title: 'Повторить',
          isLoading: false,
          onPressed: () {
            context.read<AuthCubit>().refreshToken();
          },
        ),
      ],
    );
  }
}
