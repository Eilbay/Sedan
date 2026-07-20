import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Blocks routes that require an authenticated session. Unauthenticated users
/// are sent to the sign-in screen first; navigation proceeds only if they come
/// back with a valid token.
class AuthGuard extends AutoRouteGuard {
  bool get _hasToken =>
      (getIt<SharedPreferences>().getString(TOKEN_KEY) ?? '').isNotEmpty;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    debugPrint(
      '[AUTH_GUARD] route=${resolver.route.name} hasToken=$_hasToken stack=${router.stack.map((r) => r.routeData.name).toList()}',
    );
    if (_hasToken) {
      resolver.next(true);
      return;
    }

    // Push sign-in over the current stack; allow the original navigation only
    // if the user authenticated while there.
    router.push(const SignInRoute()).then((_) => resolver.next(_hasToken));
  }
}
